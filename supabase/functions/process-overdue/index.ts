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
    // Auth: relies on the Supabase gateway key only (same as the other cron
    // workers, e.g. korra_expiry_automation). No separate CRON_SECRET.

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

    // Pre-read products for plans that reserved a specific VARIANT (batches
    // cannot read). A mutable working copy accumulates restores so several
    // overdue plans on the same product each add their unit back. The tiny
    // read-then-batch race vs a concurrent sale is acceptable for this cron.
    const workingVariants = new Map<string, { label: string; stock: number }[]>();
    {
      const ids = [...new Set(
        snapshot.docs
          .map((d) => d.data())
          .filter((p) => p.productId && p.variantLabel)
          .map((p) => p.productId as string),
      )];
      if (ids.length > 0) {
        const docs = await Promise.all(ids.map((id) => db.collection('products').doc(id).get()));
        for (const d of docs) {
          if (d.exists && Array.isArray(d.data()?.variants)) {
            workingVariants.set(d.id, d.data()!.variants.map((v: any) => ({
              label: String(v?.label ?? ''),
              stock: Math.floor(Number(v?.stock ?? 0)),
            })));
          }
        }
      }
    }

    // Returns the stock-release update for a plan: the exact variant +1 with
    // a recomputed total, or the classic total-only +1 fallback.
    function stockReleaseUpdate(plan: any): Record<string, unknown> {
      const variants = plan.variantLabel ? workingVariants.get(plan.productId) : undefined;
      const hasLabel = !!variants && variants.some((v) => v.label === plan.variantLabel);
      if (!variants || !hasLabel) {
        return { availableStock: admin.firestore.FieldValue.increment(1) };
      }
      for (const v of variants) {
        if (v.label === plan.variantLabel) v.stock += 1;
      }
      const newTotal = variants.reduce((acc, v) => acc + v.stock, 0);
      return {
        variants: variants.map((v) => ({ label: v.label, stock: v.stock })),
        availableStock: newTotal,
      };
    }

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
        
        // Release Stock (variant-aware)
        const productRef = db.collection("products").doc(plan.productId);
        batch.update(productRef, stockReleaseUpdate(plan));

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
      // 4. CLEANUP (Stock, variant-aware)
      // ==============================================================
      const productRef = db.collection("products").doc(plan.productId);
      batch.update(productRef, stockReleaseUpdate(plan));

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