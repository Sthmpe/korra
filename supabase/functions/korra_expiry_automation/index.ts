import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

// --- 1. FIREBASE INIT ---
const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();
const messaging = admin.messaging();

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY') ?? '';

// --- HELPERS ---
const parseFirestoreDate = (val: any) => {
  if (!val) return new Date();
  if (typeof val === 'string') return new Date(val);
  return (typeof val.toDate === 'function') ? val.toDate() : new Date(val);
};

const to2DP_Floor = (num: number) => Math.floor(Number(num || 0) * 100) / 100;

async function sendNotification(userId: string, collectionName: 'customers' | 'vendors', title: string, body: string, type: string) {
  if (!userId) return;
  try {
    const userRef = db.collection(collectionName).doc(userId);
    const userDoc = await userRef.get();
    
    if (!userDoc.exists) return;

    await userRef.collection('notifications').add({
      title, body, type, isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      metadata: { source: "expiry_cron" } 
    });

    const fcmToken = userDoc.data()?.fcmToken;
    if (fcmToken) {
      await messaging.send({ token: fcmToken, notification: { title, body }, data: { type } });
    }
  } catch (error) {
    console.error(`❌ Push Error for ${userId}:`, error);
  }
}

// 🛡️ PREMIUM EMAIL TEMPLATE
const getEmailTemplate = (name: string, eyebrow: string, title: string, greetingText: string, cardLabel: string, cardValue: string, cardSub: string, infoRowHtml: string, ctaText: string, ctaLink: string) => `
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Korra Update</title>
<link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #EDE8E1; font-family: 'DM Sans', sans-serif; padding: 32px 12px; min-height: 100vh; }
  .email-wrap { max-width: 500px; margin: 0 auto; }
  .main-card { background: #FDFAF7; border-radius: 16px; border: 1px solid #EAE0D5; box-shadow: 0 8px 24px rgba(28, 13, 0, 0.04); overflow: hidden; }
  .hero { background: #1C0D00; padding: 40px 32px 32px; text-align: center; position: relative; }
  .hero-eyebrow { display: inline-block; font-size: 10px; font-weight: 600; letter-spacing: 2px; text-transform: uppercase; color: #C27641; margin-bottom: 16px; }
  .hero h1 { font-family: 'DM Serif Display', serif; font-size: 26px; font-weight: 400; color: #FDF6EE; line-height: 1.2; margin-bottom: 10px; }
  .body { padding: 36px 32px; }
  .greeting { font-size: 14px; color: #3D2B1A; line-height: 1.6; margin-bottom: 24px; font-weight: 300; }
  .greeting strong { font-weight: 600; color: #1C0D00; }
  .status-card { background: #1C0D00; border-radius: 12px; padding: 24px; margin-bottom: 28px; text-align: left; }
  .status-label { font-size: 10px; font-weight: 600; letter-spacing: 2px; text-transform: uppercase; color: #C27641; margin-bottom: 8px; }
  .status-value { font-family: 'DM Serif Display', serif; font-size: 32px; color: #FDF6EE; letter-spacing: -0.5px; line-height: 1; margin-bottom: 10px; }
  .status-sub { font-size: 12px; color: rgba(253,246,238,0.5); font-weight: 400; margin-bottom: 20px; }
  .due-pill { display: inline-block; background: #A54600; color: #FDF6EE; font-size: 12px; font-weight: 600; padding: 8px 20px; border-radius: 40px; text-decoration: none; }
  .info-row { background: #FDF0E6; border-radius: 10px; padding: 18px 20px; margin-bottom: 32px; font-size: 13px; color: #7C4A25; line-height: 1.5; }
  .info-row strong { font-weight: 600; color: #5C2D0E; display: block; margin-bottom: 4px; }
  .cta-wrap { text-align: center; margin-bottom: 8px; }
  .cta-btn { display: inline-block; background: #A54600; color: #FDF6EE; text-decoration: none; font-size: 14px; font-weight: 600; padding: 14px 40px; border-radius: 50px; }
  .signoff { padding: 0 32px 32px; font-size: 13px; color: #5A3E2B; }
  .signoff p { border-top: 1px solid #EAE0D5; padding-top: 28px; margin-bottom: 20px; }
  .sig-name { font-family: 'DM Serif Display', serif; font-size: 20px; color: #A54600; margin-bottom: 4px; }
  .sig-role { font-size: 12px; color: #B09080; }
  .footer { background: #1C0D00; text-align: center; padding: 28px 20px; font-size: 12px; color: rgba(253, 246, 238, 0.6); }
  @media only screen and (max-width: 600px) { body { padding: 24px 8px; } .status-card { text-align: center; } .cta-btn { display: block; width: 100%; padding: 14px 0; } }
</style>
</head>
<body>
<div class="email-wrap">
  <div class="main-card">
    <div class="hero">
      <div class="hero-eyebrow">${eyebrow}</div>
      <h1>${title}</h1>
    </div>
    <div class="body">
      <p class="greeting">${greetingText}</p>
      <div class="status-card">
        <div class="status-label">${cardLabel}</div>
        <div class="status-value">${cardValue}</div>
        <div class="status-sub">${cardSub}</div>
        ${ctaText ? `<a href="${ctaLink}" class="due-pill">${ctaText}</a>` : ''}
      </div>
      <div class="info-row">${infoRowHtml}</div>
    </div>
    <div class="signoff">
      <p>Need help? Our team is here for you at <strong>support@korra.com.ng</strong>.</p>
      <div class="sig-name">The Korra Team</div>
      <div class="sig-role">app.korra.com.ng</div>
    </div>
    <div class="footer">
      <div>© 2026 Korra | support@korra.com.ng</div>
      <div style="font-size: 11px; opacity: 0.5; margin-top: 8px;">Automated system update regarding your reservation.</div>
    </div>
  </div>
</div>
</body>
</html>
`;

serve(async (req) => {
  console.log("🚀 KORRA EXPIRY CRON TRIGGERED");
  
  try {
    const nowLagosStr = new Date().toLocaleString("en-US", { timeZone: "Africa/Lagos" });
    const todayLagos = new Date(nowLagosStr);
    
    const currentHour = todayLagos.getHours();
    const runPeriod = currentHour < 12 ? 'AM' : 'PM'; 
    todayLagos.setHours(0, 0, 0, 0); 

    console.log(`🕒 Current Run: ${runPeriod} | Base Date: ${todayLagos.toDateString()}`);
    
    const plansSnapshot = await db.collection('plans').where('status', '==', 'active').get();

    if (plansSnapshot.empty) {
      return new Response(JSON.stringify({ message: "No active plans found." }), { status: 200 });
    }

    let warnedCount = 0;
    let cancelledCount = 0;
    
    // 🚀 BATCH TRACKER FOR VENDORS
    const vendorCancellations = new Map<string, number>(); 

    for (const doc of plansSnapshot.docs) {
      const plan = doc.data();
      const planId = doc.id;
      
      if (!plan.planExpiryDate) continue;

      const expiryDate = parseFirestoreDate(plan.planExpiryDate);
      const expiryLagos = new Date(expiryDate.toLocaleString("en-US", { timeZone: "Africa/Lagos" }));
      expiryLagos.setHours(0, 0, 0, 0);

      const diffTime = expiryLagos.getTime() - todayLagos.getTime();
      const daysLeft = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
      
      const warningKey = `${daysLeft}-${runPeriod}`;
      const lastWarning = plan.lastExpiryWarningSent || "";

      const customerId = plan.customerId || plan.customerUid;
      const vendorId = plan.vendorId;
      const name = plan.customerName || "Customer";
      const email = plan.customerEmail;
      const productName = plan.title || "your item";

      // =========================================================
      // ⚠️ SCENARIO A: WARNING NOTIFICATIONS (3, 2, 1 days)
      // =========================================================
      if (daysLeft > 0 && daysLeft <= 3) {
        if (lastWarning !== warningKey) {
          console.log(`⚠️ Warning: ${name}'s plan for ${productName} expires in ${daysLeft} days.`);
          // 🚀 NEW: 80% Extension Eligibility Logic
          const amountPaid = plan.amountPaid || 0;
          const outstanding = plan.outstandingLoanAmount || 0;
          const totalAmount = plan.totalAmount || (amountPaid + outstanding);
          const percentagePaid = totalAmount > 0 ? (amountPaid / totalAmount) * 100 : 0;

          const title = `⚠️ ${daysLeft} day${daysLeft > 1 ? 's' : ''} left`;

          const body = percentagePaid >= 80
            ? `You’re almost done. Complete payment or extend your plan to stay on track.`
            : `Your plan is close to ending. A quick payment keeps it active.`;
          
          await sendNotification(customerId, 'customers', title, body, 'reminder');
          
          // Dynamically change the email text based on the 80% rule
          const actionText = percentagePaid >= 80 
            ? `<strong>You’re almost done.</strong><br>Complete your payment or use your one-time extension to keep your plan active.`
            : `<strong>Keep your plan active.</strong><br>Make a payment today to stay on track and avoid cancellation.`;

          if (email) {
             const userEmailRes = await fetch('https://api.resend.com/emails', {
              method: 'POST',
              headers: { 'Authorization': `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
              body: JSON.stringify({
                from: 'Korra <notifications@korra.com.ng>',
                to: [email],
                subject: `⚠️ ${daysLeft} Day${daysLeft > 1 ? 's' : ''} Left Keep Your Plan Active`,
                html: getEmailTemplate(
                  name, "Friendly Warning", "Your timeline is ending", 
                  `Hi <strong>${name}</strong>, your plan for <strong>${productName}</strong> is nearing its time limit.`,
                  "Time Remaining", `${daysLeft} Day${daysLeft > 1 ? 's' : ''}`, "Remaining before plan ends.",
                  actionText, // 🚀 Injecting the dynamic text here
                  "Manage Plan", "https://app.korra.com.ng"
                ),
                tags: [{ name: 'category', value: 'expiry_warning' }]
              })
            });
          }

          await db.collection('plans').doc(planId).update({ lastExpiryWarningSent: warningKey });
          warnedCount++;
        }
      }
      
      // =========================================================
      // 🛑 SCENARIO B: EXPIRED & CANCELLED (0 days)
      // =========================================================
      else if (daysLeft <= 0) {
        console.log(`🛑 EXPIRED: Processing Financial Cancellation for ${planId}`);
        
        try {
          const result = await db.runTransaction(async (t) => {
            // ==========================================
            // 🔍 PHASE 1: ALL READS FIRST
            // ==========================================
            const planRef = db.collection("plans").doc(planId);
            const planDoc = await t.get(planRef);

            if (!planDoc.exists) throw "Plan not found.";
            const currentPlan = planDoc.data()!;
            if (currentPlan.status !== 'active') throw "Plan is already inactive.";

            const promoBonus = currentPlan.promoApplied || 0;
            const refundAmount = to2DP_Floor(currentPlan.amountPaid - promoBonus); 

            // Pre-fetch the product when the plan reserved a specific
            // variant, so its stock can be restored (reads-first phase).
            let productSnapForRestore: any = null;
            if (currentPlan.productId && currentPlan.variantLabel) {
                productSnapForRestore = await t.get(db.collection("products").doc(currentPlan.productId));
            }

            // 🚨 PRE-FETCH THE PROMO LEDGER HERE!
            let promoSnap = null;
            if (promoBonus > 0) {
                promoSnap = await t.get(
                    db.collection('vendors').doc(vendorId)
                      .collection('ledger_transactions')
                      .where('planId', '==', planId)
                      .where('type', '==', 'promo_credit')
                      .where('status', '==', 'pending')
                      .limit(1)
                );
            }

            // ==========================================
            // 📝 PHASE 2: ALL WRITES
            // ==========================================
            t.update(planRef, {
                status: 'cancelled',
                cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
                refundAmount: refundAmount,
                penaltyAmount: 0,
                cancellationReason: 'System Auto-Cancelled (Expired)',
                outstandingLoanAmount: 0
            });

            // 🚨 REVOKE THE PROMO PROPERLY
            if (promoSnap && !promoSnap.empty) {
                t.update(promoSnap.docs[0].ref, { 
                    status: 'cancelled', 
                    settlementStatus: 'cancelled', // 👈 CLEARS THE AMBER BADGE
                    description: `Promo revoked: Plan expired/cancelled.`,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }

            const relRef = db.collection('customers').doc(customerId).collection('my_vendors').doc(vendorId);
            t.set(relRef, {
                vendorId: vendorId, storeName: currentPlan.storeName || 'Store', 
                storeCredit: admin.firestore.FieldValue.increment(refundAmount),
                lastUpdated: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });

            const vendorBalanceRef = db.collection('vendors').doc(vendorId).collection('customer_balances').doc(customerId);
            t.set(vendorBalanceRef, {
                customerId: customerId, customerName: currentPlan.customerName || "Customer",
                storeCredit: admin.firestore.FieldValue.increment(refundAmount),
                lastUpdated: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });

            const statsRef = db.collection('customer_stats').doc(customerId); 
            t.set(statsRef, {
                activePlansCount: admin.firestore.FieldValue.increment(-1),
                cancelledPlansCount: admin.firestore.FieldValue.increment(1),
                lastUpdated: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });

            const ledgerRef = db.collection('customers').doc(customerId).collection('ledger_transactions').doc();
            t.set(ledgerRef, {
                id: ledgerRef.id, customerId: customerId, amount: 0, 
                type: 'plan_cancelled_expired',
                description: `Plan Expired Credited ₦${refundAmount.toLocaleString()}...`,
                planId: planId, status: 'success', createdAt: admin.firestore.FieldValue.serverTimestamp(),
                metadata: { convertedAmount: refundAmount, vendorName: currentPlan.storeName }
            });

            const vendorStatsRef = db.collection('vendor_stats').doc(vendorId);
            const vLiabRef = db.collection('vendors').doc(vendorId).collection('liabilities').doc();
            
            t.set(vLiabRef, {
                id: vLiabRef.id, userId: vendorId, amount: refundAmount, type: 'conversion_expiry', 
                description: `Plan Expired: ${currentPlan.customerName}`, planId: planId, status: 'success',
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

            t.update(vendorStatsRef, {
                totalLiability: admin.firestore.FieldValue.increment(refundAmount),
                activePlansCount: admin.firestore.FieldValue.increment(-1),
            });

            if (currentPlan.productId) {
                const productRef = db.collection("products").doc(currentPlan.productId);
                // Restore the exact variant this plan reserved; total-only +1
                // when the product has no variants (or the label vanished).
                const restoreVariants = (currentPlan.variantLabel && productSnapForRestore?.exists &&
                    Array.isArray(productSnapForRestore.data()?.variants))
                    ? productSnapForRestore.data().variants : [];
                const hasLabel = restoreVariants.some((v: any) => String(v?.label ?? '') === currentPlan.variantLabel);
                if (hasLabel) {
                    const newVariants = restoreVariants.map((v: any) => {
                        const lbl = String(v?.label ?? '');
                        const stk = Math.floor(Number(v?.stock ?? 0));
                        return { label: lbl, stock: lbl === currentPlan.variantLabel ? stk + 1 : stk };
                    });
                    const newTotal = newVariants.reduce((acc: number, v: any) => acc + v.stock, 0);
                    t.update(productRef, { variants: newVariants, availableStock: newTotal });
                } else {
                    t.update(productRef, { availableStock: admin.firestore.FieldValue.increment(1) });
                }
            }

            const activityRef = db.collection('vendors').doc(vendorId).collection('activity_feed').doc();
            t.set(activityRef, {
                id: activityRef.id, type: 'reservation_cancel', title: 'Plan Expired & Closed',
                // 🚨 ADD THE DYNAMIC PROMO TEXT FOR THE VENDOR
                body: `${currentPlan.customerName}'s timeline elapsed. Funds secured in Store Balance.${promoBonus > 0 ? ' Promo bonus revoked.' : ''}`,
                ref_id: planId, amount_display: `+₦${refundAmount.toLocaleString()} Credit`,
                date: admin.firestore.FieldValue.serverTimestamp(), is_read: false
            });

            // 🚨 RETURN PROMOBONUS SO NOTIFICATIONS WORK
            return { 
                refundAmount, 
                storeName: currentPlan.storeName || 'the store',
                promoBonus 
            };
          });

          // 1. INDIVIDUAL NOTIFICATION TO CUSTOMER
          await sendNotification(customerId, 'customers', "Plan ended funds safe 🔒", `Your plan has ended. ₦${result.refundAmount.toLocaleString()} is now available as Store Balance.${result.promoBonus > 0 ? ' Bonus revoked.' : ''}`, 'cancellation');
          
          if (email) {
            await fetch('https://api.resend.com/emails', {
              method: 'POST',
              headers: { 'Authorization': `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
              body: JSON.stringify({
                from: 'Korra <notifications@korra.com.ng>',
                to: [email],
                subject: `Plan Ended - ${productName}`,
                html: getEmailTemplate(
                  name, "Status Update", "Reservation Expired", 
                  `Hi <strong>${name}</strong>, your plan for <strong>${productName}</strong> has ended.`,
                  "Funds Secured", `₦${result.refundAmount.toLocaleString()}`, `Moved to Store Balance`,
                  `<strong>Your cash is safe.</strong><br>Your payment has been moved to your Store Balance with ${result.storeName}.${result.promoBonus > 0 ? '<br><small>Note: Promo bonus was revoked due to expiration.</small>' : ''}`,
                  "View Store Balance", "https://app.korra.com.ng"
                ),
              })
            });
          }

          // 2. INCREMENT VENDOR TALLY (No immediate ping)
          const currentCount = vendorCancellations.get(vendorId) || 0;
          vendorCancellations.set(vendorId, currentCount + 1);

          cancelledCount++;
        } catch (err) {
          console.error(`❌ Transaction failed for ${planId}:`, err);
        }
      }
    }

    // =========================================================
    // 🚀 3. SEND BATCHED VENDOR NOTIFICATIONS
    // =========================================================
    for (const [vId, count] of vendorCancellations.entries()) {
      const title = "Reservations Expired 🛑";
      const body = count === 1 
        ? `1 plan ended. Item is now available for sale again.`
        : `${count} plans ended. Items are now available for sale again.`;

      console.log(`📲 Sending batched expiry alert to Vendor ${vId}: ${count} plans.`);
      await sendNotification(vId, 'vendors', title, body, 'vendor_alert');
    }

    console.log(`✅ EXPIRY CRON COMPLETE: Warned ${warnedCount}, Auto-Cancelled ${cancelledCount}`);
    return new Response(JSON.stringify({ success: true, warned: warnedCount, cancelled: cancelledCount }), { headers: { "Content-Type": "application/json" } });

  } catch (error: any) {
    console.error("🔥 FATAL EXPIRY CRON ERROR:", error.message);
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});