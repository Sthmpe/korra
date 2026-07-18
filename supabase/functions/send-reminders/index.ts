import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

// 1. ROBUST LOGGER
const Logger = {
    info: (context: string, message: string) => console.log(`[INFO] [${context}] ${message}`),
    warn: (context: string, message: string) => console.warn(`[WARN] [${context}] ${message}`),
    error: (context: string, error: any) => {
        const msg = error instanceof Error ? error.message : String(error);
        console.error(`[ERROR] [${context}] ${msg}`);
    }
};

Logger.info("INIT", "Starting Reminder & Cleanup Job...");

const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

// 2. HELPERS
function to2DP(num: number): number {
    if (num === 0) return 0;
    return Math.floor(Number((num * 100).toFixed(4))) / 100;
}

// 3. MAIN WORKER
serve(async (req) => {
  try {
    // Auth: relies on the Supabase gateway key only (same as the other cron
    // workers, e.g. korra_expiry_automation). No separate CRON_SECRET.

    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    // --- B. QUERY ACTIVE PLANS ---
    const snapshot = await db.collection('plans')
      .where('status', '==', 'active')
      .get();

    Logger.info("JOB", `Found ${snapshot.size} active plans to check.`);

    let reminderCount = 0;
    let autoCancelCount = 0;
    const operations = [];

    // --- C. PROCESS LOOP ---
    for (const doc of snapshot.docs) {
      const plan = doc.data();
      const planId = doc.id;
      
      // 1. Determine Due Date
      let dueDate;
      if (plan.planExpiryDate) {
          dueDate = plan.planExpiryDate.toDate();
      } else {
          const createdDate = plan.createdAt?.toDate() || new Date();
          const durationDays = plan.baseDurationDays || 30;
          dueDate = new Date(createdDate);
          dueDate.setDate(createdDate.getDate() + durationDays);
      }

      const dueMidnight = new Date(dueDate.getFullYear(), dueDate.getMonth(), dueDate.getDate());
      
      // 2. Calculate Difference
      const diffTime = dueMidnight.getTime() - today.getTime();
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)); 
      
      const productName = plan.title || "Product";

      // ====================================================
      // 💀 KILL ZONE (Day -4 or older)
      // ====================================================
      if (diffDays <= -4) {
          Logger.info(planId, `Auto-Cancel triggered (${Math.abs(diffDays)} days overdue)`);
          
          operations.push(
              performAutoCancellation(db, planId, plan)
                  .then(() => autoCancelCount++)
                  .catch(err => Logger.error(`Auto-Cancel Failed: ${planId}`, err))
          );
      } 
      
      // ====================================================
      // 🔔 REMINDER ZONE (Day 3 to -3)
      // ====================================================
      else {
          let title = "";
          let body = "";

          if (diffDays === 3) {
            title = "3 Days Left ⏳";
            body = `Heads up! Your plan for ${productName} is due in 3 days.`;
          } 
          else if (diffDays === 1) {
            title = "1 Day Left ⏰";
            body = `This is it! Your payment for ${productName} is due tomorrow.`;
          } 
          else if (diffDays === 0) {
            title = "Payment Due Today 🚨";
            body = `Today is the deadline for ${productName}. Pay now to complete your plan.`;
          } 
          else if (diffDays === -1) {
            title = "1 Day Overdue ⚠️";
            body = `You missed the date. Please pay for ${productName} now.`;
          } 
          else if (diffDays === -3) {
            title = "Final Notice ⛔";
            body = `Pay for ${productName} TODAY or your plan will be converted to Store Credit tomorrow.`;
          }

          if (title && plan.customerId) {
              operations.push(
                sendFcm(plan.customerId, title, body, { type: "plan_detail", planId: planId })
                  .then(() => reminderCount++)
                  .catch(err => Logger.error(`Reminder Failed: ${planId}`, err))
              );
          } else if (title && !plan.customerId) {
              Logger.warn(planId, "Skipping reminder: Missing customerId");
          }
      }
    }

    // --- D. EXECUTE ---
    await Promise.all(operations);
    
    Logger.info("SUMMARY", `Processed: ${snapshot.size}, Reminders: ${reminderCount}, Cancelled: ${autoCancelCount}`);
    
    return new Response(JSON.stringify({ 
        success: true, 
        processed: snapshot.size,
        remindersSent: reminderCount, 
        autoCancelled: autoCancelCount 
    }), { 
      headers: { "Content-Type": "application/json" } 
    });

  } catch (error) {
    Logger.error("FATAL", error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});

// ===========================================================
// 🛠️ HELPER: AUTO CANCELLATION
// ===========================================================
async function performAutoCancellation(db: any, planId: string, plan: any) {
    // Validate Essentials
    if (!plan.vendorId || !plan.customerId) {
        throw new Error("Missing vendorId or customerId in plan data.");
    }

    return db.runTransaction(async (t: any) => {
        const vendorId = plan.vendorId;
        const customerUid = plan.customerId;
        const refundAmount = to2DP(Number(plan.amountPaid) || 0);

        // Reads first: fetch the product when the plan reserved a specific
        // variant, so its stock can be restored below.
        let productSnapForRestore: any = null;
        if (plan.productId && plan.variantLabel) {
            productSnapForRestore = await t.get(db.collection("products").doc(plan.productId));
        }

        // 1. UPDATE PLAN
        const planRef = db.collection("plans").doc(planId);
        t.update(planRef, {
            status: 'cancelled',
            cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
            refundAmount: refundAmount,
            penaltyAmount: 0,
            cancellationReason: 'Auto-Converted: Overdue > 4 Days'
        });

        // 2. CUSTOMER: Add Store Credit
        const relRef = db.collection('customers').doc(customerUid).collection('my_vendors').doc(vendorId);
        t.set(relRef, {
            vendorId: vendorId,
            storeName: plan.storeName || 'Store',
            storeCredit: admin.firestore.FieldValue.increment(refundAmount),
            lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

        // 3. CUSTOMER: Ledger & Stats
        const userRef = db.collection('customers').doc(customerUid);
        const statsRef = userRef.collection('account_stats').doc('main');
        
        t.set(statsRef, {
            activePlansCount: admin.firestore.FieldValue.increment(-1),
            cancelledPlansCount: admin.firestore.FieldValue.increment(1),
            lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

        const ledgerRef = userRef.collection('ledger_transactions').doc();
        t.set(ledgerRef, {
            id: ledgerRef.id,
            customerId: customerUid,
            amount: 0,
            type: 'plan_cancelled',
            description: `Auto-Converted ₦${refundAmount.toLocaleString()} to Store Credit`,
            planId: planId,
            status: 'success',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            metadata: { convertedAmount: refundAmount, isAuto: true, vendorName: plan.storeName }
        });

        // 4. VENDOR: Liability & Inventory
        const vStatsRef = db.collection('vendor_stats').doc(vendorId);
        const vLiabRef = db.collection('vendors').doc(vendorId).collection('liabilities').doc();
        
        t.set(vLiabRef, {
            id: vLiabRef.id,
            userId: vendorId,
            amount: refundAmount,
            type: 'conversion',
            description: `Auto-Cancel: ${plan.customerName || 'Customer'}`,
            planId: planId,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        t.update(vStatsRef, {
            totalLiability: admin.firestore.FieldValue.increment(refundAmount),
            activePlansCount: admin.firestore.FieldValue.increment(-1),
        });

        const productRef = db.collection("products").doc(plan.productId);
        // Restore the exact variant this plan reserved; total-only +1 when
        // the product has no variants (or the label vanished after an edit).
        const restoreVariants = (plan.variantLabel && productSnapForRestore?.exists &&
            Array.isArray(productSnapForRestore.data()?.variants))
            ? productSnapForRestore.data().variants : [];
        const hasLabel = restoreVariants.some((v: any) => String(v?.label ?? '') === plan.variantLabel);
        if (hasLabel) {
            const newVariants = restoreVariants.map((v: any) => {
                const lbl = String(v?.label ?? '');
                const stk = Math.floor(Number(v?.stock ?? 0));
                return { label: lbl, stock: lbl === plan.variantLabel ? stk + 1 : stk };
            });
            const newTotal = newVariants.reduce((acc: number, v: any) => acc + v.stock, 0);
            t.update(productRef, { variants: newVariants, availableStock: newTotal });
        } else {
            t.update(productRef, {
                availableStock: admin.firestore.FieldValue.increment(1)
            });
        }

        // 5. Activity Feed
        const actRef = db.collection('vendors').doc(vendorId).collection('activity_feed').doc();
        t.set(actRef, {
            id: actRef.id,
            type: 'reservation_cancel',
            title: 'System Auto-Cancel',
            body: `Plan for ${plan.customerName || 'Customer'} expired. Funds converted to Credit.`,
            ref_id: planId,
            amount_display: `+₦${refundAmount.toLocaleString()} Credit`,
            date: admin.firestore.FieldValue.serverTimestamp(),
            is_read: false
        });
    }).then(async () => {
        Logger.info(planId, "Cancellation Transaction Successful");
        await sendFcm(
            plan.customerId, 
            "Plan Expired 🔄", 
            `Your plan was overdue. We've moved your ₦${plan.amountPaid} to Store Credit safely.`, 
            { type: "plan_detail", planId: planId }
        );
    });
}

// --- HELPER: SEND FCM (SAFE VERSION) ---
async function sendFcm(uid: string, title: string, body: string, data: any) {
  // ✅ 1. Input Validation
  if (!uid || typeof uid !== 'string' || uid.trim() === '') {
      Logger.error("FCM", `Invalid UID provided: '${uid}'. Skipping.`);
      return;
  }

  try {
    const userRef = db.collection('customers').doc(uid);
    const userDoc = await userRef.get();
    
    // ✅ 2. User Existence Check
    if (!userDoc.exists) {
        Logger.warn("FCM", `User doc not found for UID: ${uid}`);
        return;
    }

    // ✅ 3. Save to In-App Notifications
    // We use .collection().add() which auto-generates ID, 
    // avoiding the "invalid resource path" error on document creation.
    await userRef.collection('notifications').add({
        title: title,
        body: body,
        type: 'system',
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        metadata: data
    });

    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) return;

    // ✅ 4. Send Push
    await admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      data: data 
    });
  } catch (e) {
    Logger.error("FCM", `Failed to send to ${uid}: ${e.message}`);
  }
}