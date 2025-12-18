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

// Stats Helpers
async function getCustomerStats(uid: string) {
  const statsRef = db.collection('customers').doc(uid).collection('account_stats').doc('main');
  const doc = await statsRef.get();
  if (doc.exists) return { ref: statsRef, data: doc.data() };
  return { ref: statsRef, data: { activePlansCount: 0, walletBalance: 0, tier: 'Starter' } };
}

async function getVendorRelation(customerUid: string, vendorId: string) {
    const relRef = db.collection('customers').doc(customerUid).collection('my_vendors').doc(vendorId);
    const doc = await relRef.get();
    if (doc.exists) return { ref: relRef, data: doc.data() };
    return { ref: relRef, data: { storeCredit: 0 } }; 
}

// Notification Helper
async function sendFcm(uid: string, title: string, body: string, data: any, collection = 'customers') {
  try {
    const userDoc = await db.collection(collection).doc(uid).get();
    const fcmToken = userDoc.data()?.fcmToken;
    if (fcmToken) {
      await admin.messaging().send({
        token: fcmToken,
        notification: { title, body },
        data: data
      });
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
      planId, amount, useStoreCredit // Boolean flag from UI
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

        if (activeCount >= maxSlots) throw `Slot Limit Reached.`;

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

        const stats = statsDoc.exists ? statsDoc.data() : { walletBalance: 0, activePlansCount: 0, tier: 'Starter' };
        const walletBalance = to2DP(stats.walletBalance || 0);
        const activeCount = stats.activePlansCount || 0;

        // Slot Check
        let maxSlots = 3;
        if (stats.tier === 'Keeper') maxSlots = 5;
        if (stats.tier === 'Collector') maxSlots = 10;
        if (stats.tier === 'VIP') maxSlots = 9999;
        if (activeCount >= maxSlots) throw `Slot Limit Reached.`;

        // --- FINANCIALS ---
        const price = to2DP(product.price);
        
        // Fee 1: Customer Processing Fee (Added on top)
        const processingFee = to2DP(price * 0.035); 
        
        // Fee 2: Vendor Service Fee (Deducted from Principal)
        const vendorFeeRate = 0.035; 

        // User Input (Total Debit) includes Processing Fee
        const userTotalDebit = to2DP(downPaymentAmount);
        const userPrincipal = to2DP(userTotalDebit - processingFee);

        if (userPrincipal < (requiredPrincipal - 50)) throw `Payment too low.`;

        // --- STORE CREDIT LOGIC ---
        const vendorId = product.vendorId; 
        const { ref: vendorRelRef, data: vendorRel } = await getVendorRelation(customerUid, vendorId);
        
        // Only use credit if User explicitly allowed it
        const availableStoreCredit = useStoreCredit ? to2DP(vendorRel.storeCredit || 0) : 0;

        let creditUsed = 0;
        let walletUsed = 0;

        // Apply Credit to Principal first
        if (availableStoreCredit >= userPrincipal) {
            creditUsed = userPrincipal;
            walletUsed = processingFee; // Wallet pays the fee
        } else {
            creditUsed = availableStoreCredit;
            walletUsed = to2DP((userPrincipal - creditUsed) + processingFee);
        }

        if (walletBalance < walletUsed) throw "Insufficient wallet balance.";

        const newPlanRef = db.collection('plans').doc();
        const planId = newPlanRef.id;

        // 1. Create Plan (With 24h Vault Timer)
        t.set(newPlanRef, {
          ...planData,
          id: planId,
          productId: productId,
          vendorId: vendorId,
          status: 'active',
          
          // Vault Logic: 24h Buffer
          vaultExpiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + (24 * 60 * 60 * 1000)),
          isVaultSettled: false,

          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          totalAmount: price,
          amountPaid: userPrincipal, 
          processingFee: processingFee,        
          initialDownPayment: userPrincipal,
          loanAmount: to2DP(price - userPrincipal),
          outstandingLoanAmount: to2DP(price - userPrincipal),
        });

        // 2. Customer Ledger
        const ledgerRef = db.collection('customers').doc(customerUid).collection('ledger_transactions').doc();
        t.set(ledgerRef, {
          id: ledgerRef.id,
          customerId: customerUid,
          amount: -walletUsed, 
          type: 'plan_creation',
          description: `Down Payment for ${product.name}`,
          planId: planId,
          reference: ledgerRef.id,
          status: 'success',
          balanceBefore: walletBalance,
          balanceAfter: to2DP(walletBalance - walletUsed),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          metadata: { paidWithWallet: walletUsed, paidWithCredit: creditUsed }
        });

        // 3. Update Customer Stats
        t.set(statsRef, {
           walletBalance: to2DP(walletBalance - walletUsed),
           activePlansCount: admin.firestore.FieldValue.increment(1),
           lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

        // 4. Deduct Store Credit
        if (creditUsed > 0) {
            t.set(vendorRelRef, {
                storeCredit: to2DP(availableStoreCredit - creditUsed),
                storeName: planData.storeName || 'Store',
                lastInteraction: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });
        }

        t.update(productRef, { availableStock: admin.firestore.FieldValue.increment(-1) });

        // --- 🆕 VENDOR SIDE (VAULT LOGIC) ---
        const vendorStatsRef = db.collection('vendor_stats').doc(vendorId);

        // A. Cash Payment -> Goes to VAULT (Locked 24h)
        // Vendor Net = (Principal Paid in Cash) - (Vendor Fee 3.5%)
        const cashPrincipal = to2DP(userPrincipal - creditUsed);
        
        if (cashPrincipal > 0) {
            const vendorNet = to2DP(cashPrincipal * (1 - vendorFeeRate));
            
            const vLedgerRef = db.collection('vendors').doc(vendorId).collection('ledger_transactions').doc();
            t.set(vLedgerRef, {
                id: vLedgerRef.id,
                userId: vendorId,
                amount: vendorNet,
                grossAmount: cashPrincipal,
                feeAmount: to2DP(cashPrincipal * vendorFeeRate),
                type: 'locked', 
                description: `Pending Order: ${planData.customerName}`,
                reference: `LCK-${planId.substring(0,6)}`,
                planId: planId,
                status: 'pending_vault', // LOCKED
                releaseDate: admin.firestore.Timestamp.fromMillis(Date.now() + (24 * 60 * 60 * 1000)),
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                customerName: planData.customerName
            });
            
            // Increase Vault Balance (Not Wallet Balance)
            t.update(vendorStatsRef, {
                vaultBalance: admin.firestore.FieldValue.increment(vendorNet),
                currentActivePlanValue: admin.firestore.FieldValue.increment(price)
            });
        }

        // B. Store Credit -> Liability Reduction (Immediate)
        if (creditUsed > 0) {
            const vLiabRef = db.collection('vendors').doc(vendorId).collection('liabilities').doc();
            t.set(vLiabRef, {
                id: vLiabRef.id,
                userId: vendorId,
                amount: -creditUsed, 
                type: 'redemption',
                description: `Credit Used by ${planData.customerName}`,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                planId: planId
            });
            t.update(vendorStatsRef, {
                totalLiability: admin.firestore.FieldValue.increment(-creditUsed),
                // We do NOT deduct 3.5% from credit redemption usually
                currentActivePlanValue: admin.firestore.FieldValue.increment(price) 
            });
        }

        return { planId, productName: product.name, duration: planData.baseDurationDays, vendorId };
      });

      // 🔔 NOTIFICATIONS
      await sendFcm(customerUid, "Reservation Confirmed 🔒", `Plan for ${result.productName} active!`, { type: "plan_detail", planId: result.planId });
      await sendFcm(result.vendorId, "New Order Received 📦", `Pending Settlement (24h Lock)`, { type: "vendor_order", planId: result.planId }, 'vendors');

      return new Response(JSON.stringify({ status: "SUCCESS", planId: result.planId }), { headers: { "Content-Type": "application/json" } });
    }

    // =======================================================================
    // 💸 ACTION: PAY INSTALLMENT (Direct to Wallet/Vault depending on policy)
    // =======================================================================
    if (action === 'PAY_INSTALLMENT') {
      const paymentAmount = to2DP(Number(amount));
      
      const result = await db.runTransaction(async (t) => {
        const planRef = db.collection("plans").doc(planId);
        const planDoc = await t.get(planRef);
        const plan = planDoc.data();
        
        if (!planDoc.exists) throw "Plan not found";
        if (plan.status !== 'active') throw "Plan not active";

        const { ref: statsRef, data: stats } = await getCustomerStats(customerUid);
        const walletBalance = to2DP(stats.walletBalance || 0);

        // Store Credit Logic
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

        if (walletBalance < walletUsed) throw "Insufficient funds.";

        const newAmountPaid = to2DP(plan.amountPaid + paymentAmount);
        const isFinished = newAmountPaid >= to2DP(plan.totalAmount - 0.1); 

        t.update(planRef, {
          amountPaid: newAmountPaid,
          outstandingLoanAmount: to2DP(Math.max(0, plan.outstandingLoanAmount - paymentAmount)),
          status: isFinished ? 'completed' : 'active',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          completedAt: isFinished ? admin.firestore.FieldValue.serverTimestamp() : null
        });

        // Customer Ledger
        const ledgerRef = db.collection('customers').doc(customerUid).collection('ledger_transactions').doc();
        t.set(ledgerRef, {
          id: ledgerRef.id,
          customerId: customerUid,
          amount: -paymentAmount,
          type: 'installment',
          description: `Installment for ${plan.title}`,
          status: 'success',
          balanceBefore: walletBalance,
          balanceAfter: to2DP(walletBalance - walletUsed),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          metadata: { paidWithWallet: walletUsed, paidWithCredit: creditUsed }
        });

        t.update(statsRef, { walletBalance: to2DP(walletBalance - walletUsed) });
        if (isFinished) {
           t.update(statsRef, {
               activePlansCount: admin.firestore.FieldValue.increment(-1),
               completedPlansCount: admin.firestore.FieldValue.increment(1)
           });
        }

        if (creditUsed > 0) {
            t.update(vendorRelRef, { storeCredit: to2DP(availableStoreCredit - creditUsed) });
        }

        // --- VENDOR SIDE ---
        const vendorStatsRef = db.collection('vendor_stats').doc(vendorId);
        const vendorFeeRate = 0.035; 

        // Installments usually go straight to Wallet (Settled) 
        // OR to Vault if within 24h of Plan Creation? 
        // Assuming installments are settled immediately for simplicity unless specified.
        if (walletUsed > 0) {
            const vendorNet = to2DP(walletUsed * (1 - vendorFeeRate));
            
            const vLedgerRef = db.collection('vendors').doc(vendorId).collection('ledger_transactions').doc();
            t.set(vLedgerRef, {
                id: vLedgerRef.id,
                userId: vendorId,
                amount: vendorNet,
                grossAmount: walletUsed,
                type: 'sale',
                description: `Installment: ${plan.customerName}`,
                status: 'success',
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
            t.update(vendorStatsRef, {
                totalEarnings: admin.firestore.FieldValue.increment(vendorNet),
                walletBalance: admin.firestore.FieldValue.increment(vendorNet) // Direct to Wallet
            });
        }

        if (creditUsed > 0) {
            const vLiabRef = db.collection('vendors').doc(vendorId).collection('liabilities').doc();
            t.set(vLiabRef, {
                id: vLiabRef.id,
                userId: vendorId,
                amount: -creditUsed,
                type: 'redemption',
                description: `Credit Used: ${plan.customerName}`,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
            t.update(vendorStatsRef, {
                totalLiability: admin.firestore.FieldValue.increment(-creditUsed)
            });
        }

        return { title: plan.title, isFinished, vendorId };
      });

      // Notifications
      await sendFcm(customerUid, "Payment Successful", "Payment processed", {});
      if (result.isFinished) {
          await sendFcm(result.vendorId, "Order Completed!", "Full payment received.", {}, 'vendors');
      }

      return new Response(JSON.stringify({ status: "SUCCESS" }), { headers: { "Content-Type": "application/json" } });
    }

    // =======================================================================
    // 🛑 ACTION: CANCEL PLAN (Updated Logic)
    // =======================================================================
    if (action === 'CANCEL') {
      const result = await db.runTransaction(async (t) => {
        const planRef = db.collection("plans").doc(planId);
        const planDoc = await t.get(planRef);
        if (!planDoc.exists) throw "Plan not found";
        const plan = planDoc.data();
        
        // 1. CHECK 24H BUFFER (Grace Period)
        const now = Date.now();
        const createdAt = plan.createdAt.toMillis();
        const hoursElapsed = (now - createdAt) / (1000 * 60 * 60);
        const isWithin24Hours = hoursElapsed <= 24;

        // 2. DETERMINE PENALTY
        let penaltyRate = 0.0;
        let isBreakingFee = false;

        if (isWithin24Hours) {
            penaltyRate = 0.10; // 10% Breaking Fee
            isBreakingFee = true;
        } else if (plan.cancellationPolicy.includes("50%")) {
            penaltyRate = 0.50; // 50% Strict Penalty
        } else {
            penaltyRate = 0.0;  // 0% Direct
        }

        const totalPaid = to2DP(plan.amountPaid);
        const penaltyAmount = to2DP(totalPaid * penaltyRate);
        const refundAmount = to2DP(totalPaid - penaltyAmount);

        // 3. REFUND DESTINATION
        // Within 24h -> Wallet (because it was cash and vendor didn't get it yet)
        // After 24h -> Policy Dependent (Strict=Wallet, Direct=Store Credit)
        let refundToWallet = isBreakingFee ? true : (plan.cancellationPolicy.includes("50%") ? true : false);

        t.update(planRef, {
          status: 'cancelled',
          cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
          refundAmount: refundAmount,
          penaltyAmount: penaltyAmount
        });

        // 4. VENDOR IMPACT LOGIC
        const vendorId = plan.vendorId;
        const vendorStatsRef = db.collection('vendor_stats').doc(vendorId);
        const vendorFeeRate = 0.035;

        if (isBreakingFee) {
            // 🛑 SCENARIO A: < 24 Hours (Breaking Fee)
            // The money is currently LOCKED in 'vaultBalance'.
            // Vendor receives NOTHING. We must reverse the pending transaction.
            
            // We calculate the Net Cash we originally added to vault
            // (Assuming mostly cash was used for Down Payment)
            // Approximation: We reverse whatever Net Value corresponded to the total paid.
            const netCashInVault = to2DP(totalPaid * (1 - vendorFeeRate));
            
            t.update(vendorStatsRef, {
                vaultBalance: admin.firestore.FieldValue.increment(-netCashInVault), // WIPE IT
                currentActivePlanValue: admin.firestore.FieldValue.increment(-plan.totalAmount)
            });
            
            // We do NOT add to Liability because the deal never settled.
            
        } else {
            // 🛑 SCENARIO B: > 24 Hours (Standard Cancel)
            // Money is already in Vendor's 'walletBalance'.
            // Vendor KEEPS the Penalty as earnings.
            
            if (!refundToWallet) {
                // Refund -> Store Credit (Vendor Liability Increases)
                // Vendor keeps cash, but now owes debt.
                const vLiabRef = db.collection('vendors').doc(vendorId).collection('liabilities').doc();
                t.set(vLiabRef, {
                    id: vLiabRef.id,
                    userId: vendorId,
                    amount: refundAmount, // Positive = Debt Increase
                    type: 'issuance',
                    description: `Refund Issued: ${plan.customerName}`,
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });
                t.update(vendorStatsRef, {
                    totalLiability: admin.firestore.FieldValue.increment(refundAmount),
                    activeLocks: admin.firestore.FieldValue.increment(-1)
                });
            } else {
                // Refund -> Wallet (Strict 50%)
                // We must DEDUCT the refund portion from Vendor's Wallet
                // Because Vendor was paid fully, but now user gets 50% back.
                const refundNetDeduction = refundAmount; // Vendor pays back the refund
                
                const vLedgerRef = db.collection('vendors').doc(vendorId).collection('ledger_transactions').doc();
                t.set(vLedgerRef, {
                    id: vLedgerRef.id,
                    userId: vendorId,
                    amount: -refundNetDeduction,
                    type: 'refund_deduction',
                    description: `Strict Refund to ${plan.customerName}`,
                    status: 'success',
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });
                t.update(vendorStatsRef, {
                    walletBalance: admin.firestore.FieldValue.increment(-refundNetDeduction),
                    activeLocks: admin.firestore.FieldValue.increment(-1)
                });
            }
        }

        // 5. CUSTOMER REFUND
        if (refundToWallet) {
             const { ref: statsRef } = await getCustomerStats(customerUid);
             t.update(statsRef, { walletBalance: admin.firestore.FieldValue.increment(refundAmount) });
             
             // Log Refund
             const ledgerRef = db.collection('customers').doc(customerUid).collection('ledger_transactions').doc();
             t.set(ledgerRef, {
                 // ... standard refund log ...
                 customerId: customerUid,
                 amount: refundAmount,
                 type: 'refund',
                 description: isBreakingFee ? "Refund (Breaking Fee Applied)" : "Refund (Cancellation)",
                 createdAt: admin.firestore.FieldValue.serverTimestamp()
             });

        } else {
             // To Store Credit
             const { ref: vendorRelRef } = await getVendorRelation(customerUid, vendorId);
             t.set(vendorRelRef, {
                storeCredit: admin.firestore.FieldValue.increment(refundAmount),
             }, { merge: true });
        }

        // Release Slot
        const { ref: sRef } = await getCustomerStats(customerUid);
        t.update(sRef, {
           activePlansCount: admin.firestore.FieldValue.increment(-1),
           cancelledPlansCount: admin.firestore.FieldValue.increment(1)
        });
        
        t.update(db.collection("products").doc(plan.productId), { availableStock: admin.firestore.FieldValue.increment(1) });

        return { refundAmount, penaltyAmount, isBreakingFee };
      });

      // 🔔 NOTIFICATIONS
      await sendFcm(customerUid, "Plan Cancelled", `Refund: ₦${result.refundAmount}`, {});
      
      return new Response(JSON.stringify({ status: "SUCCESS", message: "Plan cancelled." }), { headers: { "Content-Type": "application/json" } });
    }

    return new Response(JSON.stringify({ error: "Invalid Action" }), { status: 400 });

  } catch (err) {
    const msg = err.toString().replace("Error: ", "");
    return new Response(JSON.stringify({ status: "ERROR", error: msg }), { status: 400, headers: { "Content-Type": "application/json" } });
  }
});