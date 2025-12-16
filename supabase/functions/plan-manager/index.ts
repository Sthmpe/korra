import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts"; 
import admin from "npm:firebase-admin@11.11.0";

// 1. SETUP
const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
const HMAC_SECRET = Deno.env.get('DP_SECRET_KEY') || "your-production-secret-key-123"; 

if (admin.apps.length === 0) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

// 2. HELPERS
function to2DP(num: number): number {
  return Math.round((num + Number.EPSILON) * 100) / 100;
}

function generateRandomDp(price: number): number {
  let minPct = 0.30; 
  let maxPct = 0.40;

  if (price <= 15000) { minPct = 0.35; maxPct = 0.45; } 
  else if (price <= 35000) { minPct = 0.30; maxPct = 0.40; } 
  else if (price <= 75000) { minPct = 0.35; maxPct = 0.45; } 
  else { minPct = 0.40; maxPct = 0.50; }

  const randomPct = minPct + Math.random() * (maxPct - minPct);
  return to2DP(price * randomPct);
}

async function getCustomerStats(uid: string) {
  const statsRef = db.collection('customers').doc(uid).collection('account_stats').doc('main');
  const doc = await statsRef.get();
  if (doc.exists) return { ref: statsRef, data: doc.data() };
  return { ref: statsRef, data: { activePlansCount: 0, walletBalance: 0, tier: 'Starter' } };
}

// Helper to get Vendor Relationship (Store Credit)
async function getVendorRelation(customerUid: string, vendorId: string) {
    const relRef = db.collection('customers').doc(customerUid).collection('my_vendors').doc(vendorId);
    const doc = await relRef.get();
    if (doc.exists) return { ref: relRef, data: doc.data() };
    return { ref: relRef, data: { storeCredit: 0 } }; // Default
}

// Reusable Notification Helper
async function sendFcm(uid: string, title: string, body: string, data: any) {
  try {
    const userDoc = await db.collection('customers').doc(uid).get();
    const fcmToken = userDoc.data()?.fcmToken;

    if (fcmToken) {
      await admin.messaging().send({
        token: fcmToken,
        notification: { title, body },
        data: data
      });
      console.log(`🔔 Notification sent to ${uid}: ${title}`);
    }
  } catch (e) {
    console.error(`🔕 Notification failed for ${uid}:`, e);
  }
}

// 3. MAIN HANDLER
serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*' } });

  try {
    const { 
      action, customerUid, productId, productPrice, 
      downPaymentAmount, planData, secureToken, 
      planId, amount, useStoreCredit // New flag if we want to be explicit, but logic below auto-uses it
    } = await req.json();

    const secretKey = new TextEncoder().encode(HMAC_SECRET);

    // =======================================================================
    // 🔍 ACTION: PREVIEW
    // =======================================================================
    if (action === 'PREVIEW') {
        const { data: stats } = await getCustomerStats(customerUid);
        
        const activeCount = stats.activePlansCount || 0;
        const tier = stats.tier || 'Starter';
        
        let maxSlots = 3;
        if (tier === 'Keeper') maxSlots = 5;
        if (tier === 'Collector') maxSlots = 10;
        if (tier === 'VIP') maxSlots = 9999;

        if (activeCount >= maxSlots) {
            throw `Slot Limit Reached (${activeCount}/${maxSlots}). You cannot open a new reservation.`;
        }

        const price = Number(productPrice);
        const minPrincipal = generateRandomDp(price);
        
        const jwt = await new jose.SignJWT({ 
            min_principal: minPrincipal,
            product_id: productId,
            uid: customerUid
        })
        .setProtectedHeader({ alg: 'HS256' })
        .setIssuedAt()
        .setExpirationTime('15m')
        .sign(secretKey);

        return new Response(JSON.stringify({ 
            status: "SUCCESS", 
            minDownPayment: minPrincipal,
            secureToken: jwt 
        }), { headers: { "Content-Type": "application/json" } });
    }

    // =======================================================================
    // 🚀 ACTION: CREATE
    // =======================================================================
    if (action === 'CREATE') {
      if (!secureToken) throw "Security token missing.";
      
      let payload;
      try {
         const result = await jose.jwtVerify(secureToken, secretKey);
         payload = result.payload;
      } catch (_) {
         throw "Session expired. Please refresh.";
      }

      if (payload.product_id !== productId || payload.uid !== customerUid) throw "Security mismatch.";

      const requiredPrincipal = Number(payload.min_principal);

      // TRANSACTION
      const result = await db.runTransaction(async (t) => {
        const productRef = db.collection('products').doc(productId);
        const { ref: statsRef } = await getCustomerStats(customerUid); 
        
        const productDoc = await t.get(productRef);
        const statsDoc = await t.get(statsRef);

        if (!productDoc.exists) throw "Product not found";
        const product = productDoc.data();
        
        if (product.availableStock < 1) throw "Out of Stock";
        if (product.status !== 'approved') throw "Product unavailable";

        const stats = statsDoc.exists ? statsDoc.data() : { walletBalance: 0, activePlansCount: 0, tier: 'Starter' };
        const walletBalance = to2DP(stats.walletBalance || 0);
        const activeCount = stats.activePlansCount || 0;

        // Slot Check
        let maxSlots = 3;
        if (stats.tier === 'Keeper') maxSlots = 5;
        if (stats.tier === 'Collector') maxSlots = 10;
        if (stats.tier === 'VIP') maxSlots = 9999;

        if (activeCount >= maxSlots) throw `Slot Limit Reached.`;

        // Financials
        const price = to2DP(product.price);
        const fee = to2DP(price * 0.035);
        const userTotalDebit = to2DP(downPaymentAmount);
        const userPrincipal = to2DP(userTotalDebit - fee);

        if (userPrincipal < (requiredPrincipal - 50)) throw `Payment too low. System required ₦${requiredPrincipal} + Fee.`;

        // --- STORE CREDIT LOGIC START ---
        // 1. Get Store Credit for this Vendor
        const vendorId = product.vendorId; // Assuming product has vendorId
        const { ref: vendorRelRef, data: vendorRel } = await getVendorRelation(customerUid, vendorId);
        const availableStoreCredit = to2DP(vendorRel.storeCredit || 0);

        let creditUsed = 0;
        let walletUsed = 0;

        // 2. Logic: Use Store Credit First
        if (availableStoreCredit >= userTotalDebit) {
            creditUsed = userTotalDebit;
            walletUsed = 0;
        } else {
            creditUsed = availableStoreCredit;
            walletUsed = to2DP(userTotalDebit - creditUsed);
        }

        // 3. Check sufficiency
        if (walletBalance < walletUsed) throw "Insufficient wallet balance (after applying store credit).";
        // --- STORE CREDIT LOGIC END ---

        const newPlanRef = db.collection('plans').doc();
        const planId = newPlanRef.id;

        // Writes
        t.set(newPlanRef, {
          ...planData,
          id: planId,
          productId: productId,
          vendorId: vendorId, // Ensure vendorId is saved
          status: 'active',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          totalAmount: price,
          amountPaid: userPrincipal, 
          processingFee: fee,        
          initialDownPayment: userPrincipal,
          loanAmount: to2DP(price - userPrincipal),
          outstandingLoanAmount: to2DP(price - userPrincipal),
        });

        // Update Ledger
        const ledgerRef = db.collection('customers').doc(customerUid).collection('ledger_transactions').doc();
        t.set(ledgerRef, {
          id: ledgerRef.id,
          customerId: customerUid,
          amount: -userTotalDebit, 
          type: 'plan_creation',
          description: `Down Payment + Fee for ${product.name}`,
          planId: planId,
          reference: ledgerRef.id,
          status: 'success',
          balanceBefore: walletBalance,
          balanceAfter: to2DP(walletBalance - walletUsed), // Only wallet balance drops
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          metadata: { 
              principal: userPrincipal, 
              fee: fee,
              paidWithWallet: walletUsed,
              paidWithCredit: creditUsed,
              vendorId: vendorId
          }
        });

        // Update Wallet & Slot
        t.set(statsRef, {
           walletBalance: to2DP(walletBalance - walletUsed),
           activePlansCount: admin.firestore.FieldValue.increment(1),
           lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

        // Update Store Credit (Deduct used credit)
        // Also ensure vendor details are saved/updated in my_vendors
        t.set(vendorRelRef, {
            storeCredit: to2DP(availableStoreCredit - creditUsed),
            storeName: planData.storeName || 'Unknown Store', // Capture basic details
            // Add other fields from vendor profile if available in request or fetched
            lastInteraction: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

        t.update(productRef, { availableStock: admin.firestore.FieldValue.increment(-1) });

        return { planId, productName: product.name, duration: planData.baseDurationDays };
      });

      // 🔔 NOTIFICATION
      await sendFcm(
        customerUid,
        "Reservation Confirmed 🔒",
        `Your plan for ${result.productName} is active! You have ${result.duration} days to complete it.`,
        { type: "plan_detail", click_action: "FLUTTER_NOTIFICATION_CLICK", planId: result.planId }
      );

      return new Response(JSON.stringify({ status: "SUCCESS", planId: result.planId }), { headers: { "Content-Type": "application/json" } });
    }

    // =======================================================================
    // 💸 ACTION: PAY INSTALLMENT
    // =======================================================================
    if (action === 'PAY_INSTALLMENT') {
      const paymentAmount = to2DP(Number(amount));
      
      const result = await db.runTransaction(async (t) => {
        const planRef = db.collection("plans").doc(planId);
        const statsRef = db.collection('customers').doc(customerUid).collection('account_stats').doc('main');
        
        const planDoc = await t.get(planRef);
        const statsDoc = await t.get(statsRef);

        if (!planDoc.exists) throw "Plan not found";
        if (!statsDoc.exists) throw "Account stats missing";

        const plan = planDoc.data();
        const stats = statsDoc.data();
        const walletBalance = to2DP(stats.walletBalance || 0);

        if (plan.status !== 'active') throw "Plan is not active";

        // --- STORE CREDIT LOGIC START ---
        const vendorId = plan.vendorId;
        const { ref: vendorRelRef, data: vendorRel } = await getVendorRelation(customerUid, vendorId);
        const availableStoreCredit = to2DP(vendorRel.storeCredit || 0);

        let creditUsed = 0;
        let walletUsed = 0;

        if (availableStoreCredit >= paymentAmount) {
            creditUsed = paymentAmount;
            walletUsed = 0;
        } else {
            creditUsed = availableStoreCredit;
            walletUsed = to2DP(paymentAmount - creditUsed);
        }

        if (walletBalance < walletUsed) throw "Insufficient funds (Wallet + Store Credit).";
        // --- STORE CREDIT LOGIC END ---

        const newAmountPaid = to2DP(plan.amountPaid + paymentAmount);
        const newOutstanding = to2DP(Math.max(0, plan.outstandingLoanAmount - paymentAmount)); 
        const isFinished = newAmountPaid >= to2DP(plan.totalAmount - 0.1); 

        t.update(planRef, {
          amountPaid: newAmountPaid,
          outstandingLoanAmount: newOutstanding,
          status: isFinished ? 'completed' : 'active',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          completedAt: isFinished ? admin.firestore.FieldValue.serverTimestamp() : null
        });

        const ledgerRef = db.collection('customers').doc(customerUid).collection('ledger_transactions').doc();
        t.set(ledgerRef, {
          id: ledgerRef.id,
          customerId: customerUid,
          amount: -paymentAmount,
          type: 'installment',
          description: `Installment for ${plan.title}`,
          planId: planId,
          reference: ledgerRef.id,
          status: 'success',
          balanceBefore: walletBalance,
          balanceAfter: to2DP(walletBalance - walletUsed),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          metadata: {
              paidWithWallet: walletUsed,
              paidWithCredit: creditUsed
          }
        });

        const statsUpdate: any = {
           walletBalance: to2DP(walletBalance - walletUsed),
           lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        };

        if (isFinished) {
           statsUpdate.activePlansCount = admin.firestore.FieldValue.increment(-1);
           statsUpdate.completedPlansCount = admin.firestore.FieldValue.increment(1);
        }

        t.update(statsRef, statsUpdate);

        // Deduct used store credit
        if (creditUsed > 0) {
            t.update(vendorRelRef, {
                storeCredit: to2DP(availableStoreCredit - creditUsed),
                lastInteraction: admin.firestore.FieldValue.serverTimestamp()
            });
        }

        return { title: plan.title, isFinished };
      });

      // 🔔 NOTIFICATION
      await sendFcm(
        customerUid,
        result.isFinished ? "Plan Completed! 🎉" : "Payment Successful 💸",
        result.isFinished 
            ? `Congratulations! You have fully paid for ${result.title}.`
            : `You successfully paid ₦${paymentAmount.toLocaleString()} towards ${result.title}.`,
        { type: "plan_detail", click_action: "FLUTTER_NOTIFICATION_CLICK", planId: planId }
      );

      return new Response(JSON.stringify({ status: "SUCCESS" }), { headers: { "Content-Type": "application/json" } });
    }

    // =======================================================================
    // 🛑 ACTION: CANCEL PLAN
    // =======================================================================
    if (action === 'CANCEL') {
      const result = await db.runTransaction(async (t) => {
        const planRef = db.collection("plans").doc(planId);
        const statsRef = db.collection('customers').doc(customerUid).collection('account_stats').doc('main');
        
        const planDoc = await t.get(planRef);
        const statsDoc = await t.get(statsRef);

        if (!planDoc.exists) throw "Plan not found";
        const plan = planDoc.data();
        const stats = statsDoc.exists ? statsDoc.data() : { walletBalance: 0 };
        const walletBalance = to2DP(stats.walletBalance || 0);

        if (plan.status !== 'active') throw "Cannot cancel inactive plan";

        const policy = plan.cancellationPolicy || "Store Credit"; 
        const totalPaid = to2DP(plan.amountPaid);
        let refundAmount = 0;
        let penaltyAmount = 0;
        let isStoreCreditRefund = false;

        // Policy Logic
        if (policy.includes("50%")) {
           // STRICT: 50% Refund to Wallet
           penaltyAmount = to2DP(totalPaid * 0.50);
           refundAmount = to2DP(totalPaid - penaltyAmount);
           isStoreCreditRefund = false;
        } else {
           // DIRECT: 100% Refund to Store Credit
           refundAmount = totalPaid;
           penaltyAmount = 0;
           isStoreCreditRefund = true;
        }

        t.update(planRef, {
          status: 'cancelled',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
          refundAmount: refundAmount,
          penaltyAmount: penaltyAmount
        });

        if (refundAmount > 0) {
           const ledgerRef = db.collection('customers').doc(customerUid).collection('ledger_transactions').doc();
           t.set(ledgerRef, {
             id: ledgerRef.id,
             customerId: customerUid,
             amount: refundAmount, 
             type: 'refund',
             description: isStoreCreditRefund 
                ? `Store Credit Refund for ${plan.title}` 
                : `Wallet Refund for ${plan.title}`,
             planId: planId,
             reference: ledgerRef.id,
             status: 'success',
             balanceBefore: walletBalance,
             balanceAfter: isStoreCreditRefund ? walletBalance : to2DP(walletBalance + refundAmount), // Wallet bal only changes if NOT store credit
             createdAt: admin.firestore.FieldValue.serverTimestamp(),
             metadata: {
                 refundDestination: isStoreCreditRefund ? 'store_credit' : 'wallet'
             }
           });
        }

        // Apply Refund
        if (isStoreCreditRefund) {
            // Update My Vendors Store Credit
            const vendorId = plan.vendorId;
            const { ref: vendorRelRef } = await getVendorRelation(customerUid, vendorId);
            
            // Use set with merge to ensure doc exists if it was somehow deleted
            t.set(vendorRelRef, {
                storeCredit: admin.firestore.FieldValue.increment(refundAmount),
                storeName: plan.storeName || 'Unknown Store',
                lastInteraction: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });

        } else {
            // Update Main Wallet
            t.update(statsRef, {
               walletBalance: admin.firestore.FieldValue.increment(refundAmount)
            });
        }

        // Always release the slot
        t.update(statsRef, {
           activePlansCount: admin.firestore.FieldValue.increment(-1),
           cancelledPlansCount: admin.firestore.FieldValue.increment(1),
           lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        });

        if (plan.productId) {
           const productRef = db.collection("products").doc(plan.productId);
           t.update(productRef, { availableStock: admin.firestore.FieldValue.increment(1) });
        }

        return { title: plan.title, refundAmount, penaltyAmount, isStoreCredit: isStoreCreditRefund };
      });

      // 🔔 NOTIFICATION
      await sendFcm(
        customerUid,
        "Plan Cancelled 🛑",
        result.isStoreCredit 
            ? `Plan Cancelled. ₦${result.refundAmount} has been added to your Store Credit.`
            : `Refund: ₦${result.refundAmount}. Penalty: ₦${result.penaltyAmount}. Wallet credited.`,
        { type: "wallet_history", click_action: "FLUTTER_NOTIFICATION_CLICK" }
      );

      return new Response(JSON.stringify({ status: "SUCCESS", message: "Plan cancelled." }), { headers: { "Content-Type": "application/json" } });
    }

    return new Response(JSON.stringify({ error: "Invalid Action" }), { status: 400 });

  } catch (err) {
    const msg = err.toString().replace("Error: ", "");
    return new Response(JSON.stringify({ status: "ERROR", error: msg }), { status: 400, headers: { "Content-Type": "application/json" } });
  }
});