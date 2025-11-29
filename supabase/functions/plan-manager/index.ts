import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

// 1. SETUP
const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');

if (admin.apps.length === 0) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

// =========================================================
// 2. HELPER FUNCTIONS (LOGIC)
// =========================================================

// ✅ NEW HELPER: Forces 2 Decimal Places
function to2DP(num: number): number {
  return Math.round((num + Number.EPSILON) * 100) / 100;
}

// A. Random DP%
function generateRandomPercentage(price: number): number {
  let minPct = 0.0; let maxPct = 0.0;
  if (price <= 15000) { minPct = 0.35; maxPct = 0.45; } 
  else if (price <= 25000) { minPct = 0.30; maxPct = 0.35; } 
  else if (price <= 35000) { minPct = 0.32; maxPct = 0.38; } 
  else if (price <= 40000) { minPct = 0.35; maxPct = 0.40; } 
  else if (price <= 55000) { minPct = 0.38; maxPct = 0.43; } 
  else { minPct = 0.40; maxPct = 0.45; }
  return minPct + Math.random() * (maxPct - minPct);
}

// B. Buying Logic (Preview)
function calculateBuyingLogic(productPrice: number, availableLimit: number, isEligible: boolean, lastLimit: number | null) {
  let gap = 0.0;
  let lendablePortion = 0.0;

  if (productPrice > availableLimit) {
    gap = to2DP(productPrice - availableLimit); // Round Gap
    lendablePortion = availableLimit;
  } else {
    gap = 0.0;
    lendablePortion = productPrice;
  }

  if (gap > (productPrice * 0.65)) {
    return { status: "DECLINED", reason: "Low resevation limit the gap is too high" };
  }

  const dpPercentage = generateRandomPercentage(productPrice);
  const percentageAmount = to2DP(lendablePortion * dpPercentage); // Round % amount
  const totalUpfront = to2DP(gap + percentageAmount); // Round total
  const loanAmount = to2DP(productPrice - totalUpfront); // Round loan

  return {
    status: "APPROVED",
    result: {
      productPrice: to2DP(productPrice), 
      totalUpfront, 
      loanAmount,
      gap, 
      dpPercentage // Keep percentage raw for precision, or round if display needed
    }
  };
}

// C. STANDARD LIMIT GROWTH (Runs on every completion)
function calculateNewLimit(currentLimit: number, daysTaken: number, hasDefaulted: boolean) {
  const MAX_CAP = 100000.0;
  const BASE_LIMIT = 15000.0;

  if (hasDefaulted || daysTaken > 90) {
    if (currentLimit <= 35000) return BASE_LIMIT;
    return to2DP(Math.max(BASE_LIMIT, currentLimit * 0.50)); // Round penalty
  }

  let increase = 0.0;
  // Category A: Low Limit
  if (currentLimit <= 35000) {
    if (daysTaken <= 14) increase = 0.70;
    else if (daysTaken <= 30) increase = 0.50;
    else if (daysTaken <= 45) increase = 0.25;
    else if (daysTaken <= 60) increase = 0.20;
    else if (daysTaken <= 80) increase = 0.15;
    else if (daysTaken <= 90) increase = 0.05;
  } 
  // Category B: High Limit
  else if (currentLimit <= 50000) {
    if (daysTaken <= 14) increase = 0.30;
    else if (daysTaken <= 30) increase = 0.20;
    else if (daysTaken <= 45) increase = 0.10;
    else if (daysTaken <= 65) increase = 0.05;
  } 
  // Category C: Higher Limit
  else {
    if (daysTaken <= 14) increase = 0.25;
    else if (daysTaken <= 30) increase = 0.15;
    else if (daysTaken <= 45) increase = 0.05;
  }

  const newLimit = to2DP(currentLimit + (currentLimit * increase)); // Round new limit
  return Math.min(newLimit, MAX_CAP);
}

// D. BONUS BOOSTER (Runs separately, updates strictly if criteria met)
async function checkAndApplyCreditBooster(db: any, customerUid: string) {
  const limitRef = db.collection("customer_limits").doc(customerUid);
  
  try {
    await db.runTransaction(async (t: any) => {
      const doc = await t.get(limitRef);
      if (!doc.exists) return;

      const data = doc.data();
      const completions = data.successfulRepayments || 0;
      const cancels = data.cancellationCount || 0;
      const historyCount = completions + cancels;
      const currentLimit = data.totalCreditLimit || 0;

      // RULE 1: Minimum History
      if (historyCount < 20) return;

      // RULE 2: Completion Rate > 80%
      const completionRate = completions / historyCount;
      if (completionRate < 0.80) return;

      // RULE 3: Analyze Speed (Last 5 completed)
      const recentPlans = await db.collection("plans")
                                .where("customerId", "==", customerUid)
                                .where("status", "==", "completed")
                                .orderBy("completedAt", "desc")
                                .limit(5)
                                .get();
      
      let fastCount = 0;
      recentPlans.forEach((planDoc: any) => {
        const p = planDoc.data();
        const start = p.createdAt.toDate();
        const end = p.completedAt.toDate();
        const days = (end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24);
        if (days <= 14) fastCount++;
      });

      let speedBonus = 0.05; // Base 5% boost
      if (fastCount >= 3) speedBonus = 0.15; // 15% boost

      const newLimit = to2DP(currentLimit * (1 + speedBonus)); // Round Booster
      const MAX_CAP = 500000;

      if (newLimit > currentLimit && newLimit <= MAX_CAP) {
        t.update(limitRef, {
          totalCreditLimit: newLimit,
          lastBoosterDate: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`🚀 Booster Applied for ${customerUid}`);
      }
    });
  } catch (e) {
    console.error("Booster Check Failed:", e);
  }
}

// =========================================================
// 3. REQUEST HANDLER
// =========================================================
serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*' } });

  try {
    const { action, customerUid, productPrice, planData, planId, amount, reason } = await req.json();

    // --- ACTION: PREVIEW ---
    if (action === 'PREVIEW') {
      const limitRef = db.collection("customer_limits").doc(customerUid);
      const limitDoc = await limitRef.get();
      let available = 0;
      let isEligible = true;
      if (limitDoc.exists) {
        const d = limitDoc.data();
        available = to2DP((d.totalCreditLimit || 0) - (d.activeDebt || 0)); // Round Available
        isEligible = (d.defaultCount || 0) === 0;
      }
      const riskResult = calculateBuyingLogic(Number(productPrice), available, isEligible, null);
      return new Response(JSON.stringify(riskResult), { headers: { "Content-Type": "application/json" } });
    }

    // --- ACTION: CREATE ---
    if (action === 'CREATE') {
      const productQuery = await db.collection("products").where("code", "==", planData.productCode).limit(1).get();
      if (productQuery.empty) throw `Product '${planData.productCode}' not found.`;
      const productDocRef = productQuery.docs[0].ref;

      const result = await db.runTransaction(async (t: any) => {
        const limitRef = db.collection("customer_limits").doc(customerUid);
        const userRef = db.collection("customer").doc(customerUid);
        
        const limitDoc = await t.get(limitRef);
        const productDoc = await t.get(productDocRef);
        const userDoc = await t.get(userRef);

        if (!limitDoc.exists || !userDoc.exists) throw "User profile missing";
        
        const limitData = limitDoc.data();
        const productData = productDoc.data();
        const userData = userDoc.data();
        
        const availableCredit = to2DP((limitData.totalCreditLimit || 0) - (limitData.activeDebt || 0)); // Round
        const currentStock = productData.availableStock || 0;
        const walletBalance = userData.monnify?.availableBalance || 0;
        const downPayment = to2DP(planData.initialDownPayment); // Round input

        // --- CRITICAL GAP CHECK (Added Here) ---
        const price = to2DP(productData.price || planData.totalAmount); // Round

        let gap = 0;
        if (price > availableCredit) {
           gap = to2DP(price - availableCredit); // Round
        }

        // Reject if Gap is > 65% of Price (Your Logic)
        if (gap > (price * 0.65)) {
            throw `Reservation declined, low reservation limit.`;
        }

        if (availableCredit < planData.loanAmount) throw "Insufficient Credit Limit.";
        if (currentStock < 1) throw "Out of Stock.";
        if (walletBalance < downPayment) throw "Insufficient Wallet Balance.";

        const newPlanRef = db.collection("plans").doc();
        
        t.set(newPlanRef, {
          ...planData,
          id: newPlanRef.id,
          productId: productDocRef.id,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          status: 'active',
          // Ensure stored values are rounded
          totalAmount: to2DP(planData.totalAmount),
          amountPaid: to2DP(planData.amountPaid),
          initialDownPayment: to2DP(planData.initialDownPayment),
          loanAmount: to2DP(planData.loanAmount),
          outstandingLoanAmount: to2DP(planData.outstandingLoanAmount),
        });

        t.update(userRef, { "monnify.availableBalance": admin.firestore.FieldValue.increment(-downPayment) });
        t.update(limitRef, {
          activeDebt: admin.firestore.FieldValue.increment(to2DP(planData.loanAmount)),
          lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        });
        t.update(productDocRef, { availableStock: admin.firestore.FieldValue.increment(-1) });

        const txnRef = db.collection('customer').doc(customerUid).collection('ledger_transactions').doc();
        t.set(txnRef, {
          id: txnRef.id, customerId: customerUid, amount: -downPayment,
          type: 'down_payment', description: `Down payment for ${planData.title}`,
          planId: newPlanRef.id, reference: txnRef.id, status: 'success',
          balanceBefore: walletBalance, balanceAfter: walletBalance - downPayment,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        const myVendorRef = db.collection('customer').doc(customerUid).collection('my_vendors').doc(planData.vendorId);
        t.set(myVendorRef, {
          vendorId: planData.vendorId, storeName: planData.storeName,
          lastInteractionAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        return { planId: newPlanRef.id };
      });

      return new Response(JSON.stringify({ status: "SUCCESS", planId: result.planId }), { headers: { "Content-Type": "application/json" } });
    }

    // --- ACTION: PAY_INSTALLMENT (Logic updated to include Standard Growth) ---
    if (action === 'PAY_INSTALLMENT') {
      const paymentAmount = to2DP(Number(amount)); // Round Input
      let isFinished = false;
      
      await db.runTransaction(async (t: any) => {
        const planRef = db.collection("plans").doc(planId);
        const userRef = db.collection("customer").doc(customerUid);
        const limitRef = db.collection("customer_limits").doc(customerUid);

        const planDoc = await t.get(planRef);
        const userDoc = await t.get(userRef);
        const limitDoc = await t.get(limitRef);
        
        if (!planDoc.exists) throw "Plan not found";
        
        const planData = planDoc.data();
        const limitData = limitDoc.data();
        const currentBalance = userDoc.data()?.monnify?.availableBalance || 0;

        if (planData.status !== 'active') throw "Plan is not active";
        if (currentBalance < paymentAmount) throw "Insufficient Balance";

        const newAmountPaid = to2DP(planData.amountPaid + paymentAmount); // Round
        const newOutstanding = to2DP(Math.max(0, planData.outstandingLoanAmount - paymentAmount)); // Round
        isFinished = newAmountPaid >= to2DP(planData.totalAmount);

        // 1. Standard Logic: Determine new limit if finished
        let newTotalLimit = limitData.totalCreditLimit;
        if (isFinished) {
           const created = planData.createdAt.toDate();
           const now = new Date();
           const daysTaken = Math.ceil((now.getTime() - created.getTime()) / (1000 * 60 * 60 * 24));
           
           // Apply Standard Growth Function
           newTotalLimit = calculateNewLimit(newTotalLimit, daysTaken, false);
        }

        // 2. Writes
        t.update(planRef, {
          amountPaid: newAmountPaid,
          outstandingLoanAmount: newOutstanding,
          status: isFinished ? 'completed' : 'active',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          completedAt: isFinished ? admin.firestore.FieldValue.serverTimestamp() : null
        });

        t.update(userRef, { "monnify.availableBalance": admin.firestore.FieldValue.increment(-paymentAmount) });
        
        // Release Debt & Apply New Limit
        t.update(limitRef, { 
          activeDebt: admin.firestore.FieldValue.increment(-paymentAmount),
          successfulRepayments: isFinished ? admin.firestore.FieldValue.increment(1) : admin.firestore.FieldValue.increment(0),
          totalCreditLimit: newTotalLimit, // Already rounded in function
          lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        });

        const txnRef = db.collection('customer').doc(customerUid).collection('ledger_transactions').doc();
        t.set(txnRef, {
          id: txnRef.id, customerId: customerUid, amount: -paymentAmount,
          type: 'repayment', description: `Installment for ${planData.title}`,
          planId: planId, reference: txnRef.id, status: 'success',
          balanceBefore: currentBalance, balanceAfter: currentBalance - paymentAmount,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
      });

      // 3. Check Booster (Async/Bonus)
      // Runs only if finished, to see if they qualify for EXTRA bonus
      if (isFinished) {
         checkAndApplyCreditBooster(db, customerUid);
      }
      
      return new Response(JSON.stringify({ status: "SUCCESS" }), { headers: { "Content-Type": "application/json" } });
    }

    // --- ACTION: CANCEL (10% Fee, 42h Delay, 10-Day Rule) ---
    if (action === 'CANCEL') {
      await db.runTransaction(async (t: any) => {
        const planRef = db.collection("plans").doc(planId);
        const userRef = db.collection("customer").doc(customerUid);
        const limitRef = db.collection("customer_limits").doc(customerUid);
        
        const planDoc = await t.get(planRef);
        const userDoc = await t.get(userRef);
        const limitDoc = await t.get(limitRef); // Get limit to apply penalty
        
        if (!planDoc.exists) throw "Plan not found";
        const planData = planDoc.data();
        const userData = userDoc.data();

        if (planData.status !== 'active') throw "Cannot cancel inactive plan";

        // A. 10-Day Rule Check
        const created = planData.createdAt.toDate();
        const now = new Date();
        const diffTime = Math.abs(now.getTime() - created.getTime());
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        
        if (diffDays > 10) {
            throw "Cancellation period expired. You can only cancel within 10 days of reservation.";
        }

        // B. Breakage Fee Logic
        const initialDP = planData.initialDownPayment || 0;
        const breakingFee = to2DP(initialDP * 0.10); // Round Fee
        const totalPaid = planData.amountPaid;
        const refundAmount = to2DP(totalPaid - breakingFee); // Round Refund

        if (refundAmount < 0) throw "Refund amount negative. Contact support.";

        // C. Create Payout Request
        const payoutRef = db.collection("customers_payouts").doc();
        t.set(payoutRef, {
          id: payoutRef.id,
          customerId: customerUid,
          planId: planId,
          amount: refundAmount,
          feeDeducted: breakingFee,
          status: 'pending', 
          reason: reason || 'plan_cancellation',
          bankName: userData.monnify?.bankName || 'Unknown',
          accountNumber: userData.monnify?.accountNumber || 'Unknown',
          accountName: userData.monnify?.accountName || 'Unknown',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          scheduledFor: admin.firestore.Timestamp.fromMillis(Date.now() + (42 * 60 * 60 * 1000))
        });

        // D. Update Plan
        t.update(planRef, {
          status: 'cancelled',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
          refundStatus: 'processing_42hr_hold'
        });

        // E. Ledger
        const txnRef = db.collection('customer').doc(customerUid).collection('ledger_transactions').doc();
        t.set(txnRef, {
          id: txnRef.id, customerId: customerUid, amount: 0,
          type: 'cancellation', description: `Cancelled. Fee: ${breakingFee}. Refund Pending: ${refundAmount}`,
          planId: planId, reference: payoutRef.id, status: 'pending',
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // F. Penalty Logic (Decrease Limit)
        const limitData = limitDoc.data();
        let currentLimit = limitData.totalCreditLimit;
        const totalHistory = (limitData.successfulRepayments || 0) + (limitData.cancellationCount || 0) + 1;
        const cancels = (limitData.cancellationCount || 0) + 1;
        
        // If cancellation rate > 30%, reduce by 15%
        if (totalHistory > 5 && (cancels / totalHistory) > 0.30) {
             currentLimit = to2DP(currentLimit * 0.85); // Round Penalty
        }

        t.update(limitRef, {
          activeDebt: admin.firestore.FieldValue.increment(-to2DP(planData.outstandingLoanAmount)), // Round Debt Release
          cancellationCount: admin.firestore.FieldValue.increment(1),
          totalCreditLimit: currentLimit,
          lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        });

        // G. Restock
        if (planData.productId) {
           const productRef = db.collection("products").doc(planData.productId);
           t.update(productRef, { stockCount: admin.firestore.FieldValue.increment(1) });
        }
      });

      return new Response(JSON.stringify({ status: "SUCCESS", message: "Plan cancelled. Refund processing." }), { headers: { "Content-Type": "application/json" } });
    }

    return new Response("Invalid Action", { status: 400 });

  } catch (err) {
    return new Response(JSON.stringify({ error: err.toString() }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});