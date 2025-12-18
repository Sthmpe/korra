import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

console.log("[INIT] Starting Overdue Processor...");

// 1. SETUP
const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

// Helper to round numbers
function to2DP(num: number): number {
  return Math.round((num + Number.EPSILON) * 100) / 100;
}

serve(async (req) => {
  try {
    // --- SECURITY CHECK ---
    const cronSecret = Deno.env.get('CRON_SECRET');
    const authHeader = req.headers.get('Authorization');
    if (authHeader !== `Bearer ${cronSecret}`) {
      return new Response("Unauthorized", { status: 401 });
    }

    // --- DATE CALCULATION ---
    const now = new Date();
    // We want plans due BEFORE (Now - 4 Days)
    const cutoffDate = new Date(now);
    cutoffDate.setDate(now.getDate() - 4); 

    console.log(`[INFO] Searching for plans due before: ${cutoffDate.toISOString()}`);

    // --- QUERY ---
    // Find active plans that missed the deadline 4 days ago
    const snapshot = await db.collection('plans')
      .where('status', '==', 'active')
      .where('nextDueDate', '<=', admin.firestore.Timestamp.fromDate(cutoffDate))
      .limit(100) // Process in batches to avoid timeouts
      .get();

    if (snapshot.empty) {
      console.log("[INFO] No overdue plans found.");
      return new Response(JSON.stringify({ success: true, processed: 0 }), { headers: { "Content-Type": "application/json" } });
    }

    console.log(`[INFO] Found ${snapshot.size} plans to process.`);

    const batch = db.batch();
    let processedCount = 0;

    for (const doc of snapshot.docs) {
      const plan = doc.data();
      const planId = doc.id;
      const { customerId, vendorId, amountPaid, productName, customerName } = plan;
      
      const refundAmount = to2DP(amountPaid);

      if (refundAmount <= 0) {
        // Just cancel if no money was paid yet
        batch.update(doc.ref, { 
            status: 'cancelled', 
            cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
            cancellationReason: 'Automatic: Payment Default'
        });
        
        // Release Stock
        const productRef = db.collection("products").doc(plan.productId);
        batch.update(productRef, { availableStock: admin.firestore.FieldValue.increment(1) });
        
        // Release Slot
        const statsRef = db.collection('customers').doc(customerId).collection('account_stats').doc('main');
        batch.update(statsRef, { 
            activePlansCount: admin.firestore.FieldValue.increment(-1),
            cancelledPlansCount: admin.firestore.FieldValue.increment(1),
            defaultsCount: admin.firestore.FieldValue.increment(1) // Mark as default
        });
        
        processedCount++;
        continue;
      }

      // ==============================================================
      // 1. UPDATE PLAN STATUS
      // ==============================================================
      batch.update(doc.ref, {
        status: 'cancelled',
        cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        cancellationReason: 'Automatic: Payment Default (Converted to Credit)',
        refundAmount: refundAmount,
        penaltyAmount: 0 // No penalty fee taken, just locked into store credit
      });

      // ==============================================================
      // 2. CUSTOMER SIDE: GIVE STORE CREDIT
      // ==============================================================
      
      // Update relationship doc
      const vendorRelRef = db.collection('customers').doc(customerId).collection('my_vendors').doc(vendorId);
      batch.set(vendorRelRef, {
        storeCredit: admin.firestore.FieldValue.increment(refundAmount),
        storeName: plan.storeName || 'Store',
        lastInteraction: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      // Log Ledger (Customer)
      const custLedgerRef = db.collection('customers').doc(customerId).collection('ledger_transactions').doc();
      batch.set(custLedgerRef, {
        id: custLedgerRef.id,
        customerId: customerId,
        amount: refundAmount,
        type: 'refund_credit',
        description: `Store Credit: ${productName} (Defaulted)`,
        planId: planId,
        reference: `DEF-${planId.substring(0,6)}`,
        status: 'success',
        balanceBefore: 0, // We don't track credit history balance strictly here, just the log
        balanceAfter: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      // Release Slot & Mark Default
      const custStatsRef = db.collection('customers').doc(customerId).collection('account_stats').doc('main');
      batch.update(custStatsRef, { 
          activePlansCount: admin.firestore.FieldValue.increment(-1),
          cancelledPlansCount: admin.firestore.FieldValue.increment(1),
          defaultsCount: admin.firestore.FieldValue.increment(1) // Increases risk score
      });

      // ==============================================================
      // 3. VENDOR SIDE: CONVERT CASH TO LIABILITY
      // ==============================================================
      
      // Since the money was previously settled to the Vendor's wallet (or Vault),
      // we essentially leave the cash with them but increase their debt column.
      // However, we must ensure they know this money isn't "free" anymore—it's owed service.

      const vendorStatsRef = db.collection('vendor_stats').doc(vendorId);
      
      // Increase Liability
      batch.update(vendorStatsRef, {
          totalLiability: admin.firestore.FieldValue.increment(refundAmount),
          // We assume funds were already settled to wallet/vault, so we don't touch wallet balance here.
          // We simply record that they now owe this value in goods.
          currentActivePlanValue: admin.firestore.FieldValue.increment(-plan.totalAmount) // Remove plan value from active calculations
      });

      // Log Liability Transaction
      const liabRef = db.collection('vendors').doc(vendorId).collection('liabilities').doc();
      batch.set(liabRef, {
        id: liabRef.id,
        userId: vendorId,
        amount: refundAmount,
        type: 'liability_issuance',
        description: `Auto-Default: ${customerName}`,
        reference: `DEF-${planId.substring(0,6)}`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        planId: planId
      });

      // ==============================================================
      // 4. CLEANUP (Stock)
      // ==============================================================
      const productRef = db.collection("products").doc(plan.productId);
      batch.update(productRef, { availableStock: admin.firestore.FieldValue.increment(1) });

      // Notifications
      const notifRef = db.collection('customers').doc(customerId).collection('notifications').doc();
      batch.set(notifRef, {
          title: "Plan Converted to Credit ⚠️",
          body: `Your plan for ${productName} defaulted. Funds have been moved to Store Credit.`,
          type: "plan_default",
          createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      processedCount++;
    }

    await batch.commit();

    console.log(`[SUCCESS] Automatically defaulted ${processedCount} plans.`);
    return new Response(JSON.stringify({ success: true, processed: processedCount }), { 
      headers: { "Content-Type": "application/json" } 
    });

  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});