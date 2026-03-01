import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts";
import admin from "npm:firebase-admin@11.11.0";

// 1. SETUP
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
const HMAC_SECRET = Deno.env.get('DP_SECRET_KEY') || "your-production-secret-key-123";

if (admin.apps.length === 0) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
    });
}

const db = admin.firestore();

// 2. HELPERS

// 🟢 FOR CHARGES: Always rounds UP (Protects Business)
// Logic: 5000.0000001 -> 5000.00 (Dust ignored)
// Logic: 5000.001 -> 5000.01 (Real fraction charged)
function to2DP(num: number): number {
    if (num === 0) return 0;
    // 1. Shift: 150.0000001 -> 15000.00001
    // 2. Snap: .toFixed(4) removes the 0.00001 dust -> 15000.0000
    // 3. Ceil: Rounds up to next integer
    // 4. Unshift: Divide by 100
    return Math.ceil(Number((num * 100).toFixed(4))) / 100;
}

// 🔴 FOR BALANCES: Always rounds DOWN (Protects Integrity)
// Logic: 5000.9999999 -> 5000.99 (Dust ignored)
function to2DP_Floor(num: number): number {
    if (num === 0) return 0;
    return Math.floor(Number((num * 100).toFixed(4))) / 100;
}

function generateRandomDp(price: number): number {
    let percentage: number;
    
    percentage = 0.30;

    return to2DP(price * percentage);
}

const calculateZoneFee = (amt: number): number => {
    if (amt <= 0) return 0;
    const raw = amt * 0.035; // 3.5%
    if (raw < 30000) return raw;
    if (raw >= 30000 && raw < 60000) return 30000;
    return 60000;
};

// ✅ HELPER: Safely convert any date format to ISO String (Prevents Crash)
function safeIsoDate(val: any): string | null {
    if (!val) return null;
    try {
        if (typeof val.toDate === 'function') return val.toDate().toISOString();
        if (val instanceof Date) return val.toISOString();
        return new Date(val).toISOString();
    } catch (e) {
        return null; 
    }
}

async function getUserAndStats(uid: string) {
    const userRef = db.collection('customers').doc(uid);
    const statsRef = userRef.collection('account_stats').doc('main');
    return { userRef, statsRef };
}

async function getVendorRelation(customerUid: string, vendorId: string) {
    const relRef = db.collection('customers').doc(customerUid).collection('my_vendors').doc(vendorId);
    const doc = await relRef.get();
    if (doc.exists) return { ref: relRef, data: doc.data() };
    return { ref: relRef, data: { storeCredit: 0 } };
}

async function sendFcm(uid: string, title: string, body: string, data: any, collection = 'customers') {
  try {
    const userRef = db.collection(collection).doc(uid);
    const userDoc = await userRef.get();
    
    await userRef.collection('notifications').add({
        title: title,
        body: body,
        type: data.type || 'system',
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        metadata: data 
    });

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

// CONSTANTS
const PLATFORM_FEE_PERCENTAGE = 0.035; // 3.5%

// 3. MAIN HANDLER
serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    try {
        const {
            action, customerUid, productId, planData, secureToken,
            planId, amount, pin, vendorUid, reason, category, adminPassword
        } = await req.json();

        const secretKey = new TextEncoder().encode(HMAC_SECRET);

        // =======================================================================
        // 🔍 ACTION: PREVIEW
        // =======================================================================
        if (action === 'PREVIEW') {
            if (!productId || typeof productId !== 'string') throw "Product ID is missing or invalid.";
            if (!customerUid) throw "Customer UID is missing.";

            const { statsRef } = await getUserAndStats(customerUid);
            const statsDoc = await statsRef.get();
            const statsData = statsDoc.exists ? statsDoc.data() : {};

            const activeCount = statsData.activePlansCount || 0;
            const tier = statsData.tier || 'Starter';

            let maxSlots = 3;
            if (tier === 'Keeper') maxSlots = 5;
            if (tier === 'Collector') maxSlots = 10;
            if (tier === 'VIP') maxSlots = 9999;

            if (activeCount >= maxSlots) throw `Slot Limit Reached.`;

            const productRef = db.collection('products').doc(productId);
            const productDoc = await productRef.get();
            if (!productDoc.exists) throw "Product not found";
            const productData = productDoc.data();
                if (productData.availableStock < 1) throw "Out of Stock";

            
            const dbPrice = Number(productData.price);
            if (!dbPrice || isNaN(dbPrice)) throw "System Error: Product price is missing in database.";

            let minPrincipal = 0;
            const manualDp = Number(productData.directDownPayment || 0);

            if (manualDp > 0) {
                minPrincipal = to2DP(manualDp);
            } else {
                minPrincipal = generateRandomDp(dbPrice);
            }

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
            }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
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

            const result = await db.runTransaction(async (t) => {
                const productRef = db.collection('products').doc(productId);

                // ✅ Get Refs
                const { userRef, statsRef } = await getUserAndStats(customerUid);
                const productDoc = await t.get(productRef);
                
                if (!productDoc.exists) throw "Product not found";
                const product = productDoc.data();
                if (product.availableStock < 1) throw "Out of Stock";
                
                const vendorId = product.vendorId;

                // Vendor Relations
                const { ref: vendorRelRef, data: vendorRel } = await getVendorRelation(customerUid, vendorId);
                
                const userDoc = await t.get(userRef);
                if (!userDoc.exists) throw "User not found";
                
                const userData = userDoc.data();
                const statsDoc = await t.get(statsRef);
                const statsData = statsDoc.exists ? statsDoc.data() : {};

                // ✅ 1. MONEY
                const walletBalance = to2DP_Floor(userData.monnify?.availableBalance || 0);

                const activeCount = statsData.activePlansCount || 0;
                const tier = statsData.tier || 'Starter';

                let maxSlots = 3;
                if (tier === 'Keeper') maxSlots = 5;
                if (tier === 'Collector') maxSlots = 10;
                if (tier === 'VIP') maxSlots = 9999;
                if (activeCount >= maxSlots) throw `Slot Limit Reached.`;

                // --- FINANCIALS ---
                const price = to2DP(product.price);
                const availableStoreCredit = to2DP_Floor(vendorRel.storeCredit || 0);

                // 1. 🧹 THE MANDATORY SWEEP
                // Rule: "Store Credit First. Always." 
                // We take all available credit, capped only by the product price.
                let creditSweep = 0;
                if (availableStoreCredit > 0) {
                    creditSweep = (availableStoreCredit >= price) ? price : availableStoreCredit;
                }

                // 2. 🧮 CALCULATE FEE (The Split)
                const cashPortionOfPrice = price - creditSweep;

                // Fee on Cash Part (Standard Zone Logic)
                let feeCashPart = 0;
                if (cashPortionOfPrice > 0) {
                    feeCashPart = calculateZoneFee(cashPortionOfPrice);
                }

                // Fee on Credit Part (10% Rule)
                let feeCreditPart = 0;
                if (creditSweep > 0) {
                    const standard = calculateZoneFee(creditSweep);
                    // Apply 10% logic, ensure min N100
                    feeCreditPart = Math.max(standard * 0.10, 100); 
                }

                const processingFee = to2DP(feeCashPart + feeCreditPart);
                
                // 3. 🔍 DETERMINE USER PAYMENT
                // The 'amount' from UI is treated as 'User Desired Principal'
                let userDesiredPrincipal = amount - processingFee;

                // Cap the Principal at the Product Price (Overpayment Protection)
                if (userDesiredPrincipal > price) {
                    userDesiredPrincipal = price;
                }

                // 4. 🧱 VALIDATE MINIMUMS
                // The absolute minimum Principal is max(RiskMin, CreditSweep).
                const effectiveMinDown = Math.max(requiredPrincipal, creditSweep);

                // if (userDesiredPrincipal < effectiveMinDown) {
                //     const gap = to2DP(effectiveMinDown - userDesiredPrincipal);
                //     throw `Payment too low. Min Required: ₦${effectiveMinDown.toLocaleString()}.`;
                // }

                const userRequiredDownPayment = to2DP(requiredPrincipal);
                // const minRequiredPrincipal = to2DP(userRequiredDownPayment + processingFee);

                // if (amount < minRequiredPrincipal) throw `Payment too low. Min: ${minRequiredPrincipal}`;

               
                // 5. 🧮 CALCULATE WHO PAYS WHAT (The Split)
                let creditUsed = creditSweep; // We always use the full sweep

                let cashPrincipalNeeded = to2DP(userDesiredPrincipal - creditUsed);
                if (cashPrincipalNeeded < 0) cashPrincipalNeeded = 0;

                // Calculate Total Wallet Deduction (Cash Principal + Fee)
                let walletUsed = to2DP(cashPrincipalNeeded + processingFee);
                let userPrincipalPayment = to2DP(creditUsed + cashPrincipalNeeded);

                // 6. 💳 CHECK WALLET BALANCE
                if (walletBalance < walletUsed) {
                    const shortBy = to2DP(walletUsed - walletBalance);
                    throw `Insufficient wallet balance.\nFee: ₦${processingFee.toLocaleString()}.\nCash Initial Deposit: ₦${cashPrincipalNeeded.toLocaleString()}.\nTotal needed: ₦${walletUsed.toLocaleString()}.`;
                }

                const newPlanRef = db.collection('plans').doc();
                const planId = newPlanRef.id;

                // ✅ FIX: Dust Tolerance for Immediate Completion
                let remainingOnCreate = to2DP(price - userPrincipalPayment);
                let isFinished = false;
                let pickupCode = null;

                // If remaining is less than 1 Naira, treat as fully paid immediately
                if (remainingOnCreate < 100.0) {
                    isFinished = true;
                    userPrincipalPayment = price; // Auto-fill the dust
                    remainingOnCreate = 0;
                    // Generate PIN immediately if paid in full at start
                    pickupCode = Math.floor(1000 + Math.random() * 9000).toString();
                } else {
                    isFinished = false;
                }

                // 1. Create Plan
                t.set(newPlanRef, {
                    ...planData,
                    id: planId,
                    productId: productId,
                    vendorId: vendorId,
                    status: isFinished ? 'completed' : 'active',
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    modelType: planData.modelType || 'direct',
                    totalAmount: price,
                    amountPaid: userPrincipalPayment,
                    processingFee: processingFee,
                    initialDownPayment: userRequiredDownPayment,
                    loanAmount: remainingOnCreate,
                    outstandingLoanAmount: remainingOnCreate,
                    pickupCode: pickupCode, // Saves null or code
                    completedAt: isFinished ? admin.firestore.FieldValue.serverTimestamp() : null
                });

                // 2. Ledger
                const ledgerRef = db.collection('customers').doc(customerUid).collection('ledger_transactions').doc();
                
                // ✅ CONSTRUCT RECEIPT DATA FOR CREATE
                const receiptPayload = {
                    reference: ledgerRef.id,
                    date: new Date().toISOString(),
                    vendorName: planData.storeName || 'Store',
                    customerName: planData.customerName,
                    productName: product.name,
                    productCode: product.productCode || "",
                    totalValue: price,
                    amountPaidSoFar: userPrincipalPayment,
                    amountPaidNow: userPrincipalPayment,
                    paymentMethod: creditUsed > 0 ? (walletUsed > 0 ? "Mixed (Store Balance + Wallet)" : "Store Balance") : "Wallet Transfer",
                    balanceRemaining: remainingOnCreate,
                    status: isFinished ? "COMPLETED" : "IN PROGRESS",
                    isFinished: isFinished,
                    creditUsed: creditUsed,
                    walletUsed: walletUsed,
                    // ✅ SAFE DATE HELPER
                    nextDueDate: (!isFinished && planData.nextDueDate) ? safeIsoDate(planData.nextDueDate) : null
                };

                t.set(ledgerRef, {
                    id: ledgerRef.id,
                    customerId: customerUid,
                    amount: -walletUsed,
                    type: 'plan_creation',
                    description: `Initial deposit for ${product.name}`,
                    planId: planId,
                    reference: ledgerRef.id,
                    status: 'success',
                    balanceBefore: walletBalance,
                    balanceAfter: to2DP_Floor(walletBalance - walletUsed),
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    metadata: { paidWithWallet: walletUsed, paidWithCredit: creditUsed },
                    receiptData: receiptPayload 
                });

                // 3. Update Balance
                t.update(userRef, {
                    "monnify.availableBalance": admin.firestore.FieldValue.increment(-walletUsed)
                });

                // 4. Update Plan Count
                t.set(statsRef, {
                    activePlansCount: admin.firestore.FieldValue.increment(1),
                    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                }, { merge: true });

                // 5. UPDATE ANALYTICS
               const now = new Date();
                const currentMonth = now.toISOString().slice(0, 7); // e.g. "2026-02"
                const currentDay = now.toISOString().slice(8, 10);  // e.g. "13"
                const currentDateStr = now.toISOString().slice(0, 10); // e.g. "2026-02-13"
                const currentYearStr = now.getFullYear().toString();   // e.g. "2026"
                
                const custMonthlyRef = db.collection('customers').doc(customerUid)
                                            .collection('monthly_stats').doc(currentMonth);

                t.set(custMonthlyRef, {
                    month: currentMonth,
                    year: now.getFullYear().toString(),
                    completedCount: isFinished ? admin.firestore.FieldValue.increment(1) : admin.firestore.FieldValue.increment(0),
                    createdCount: admin.firestore.FieldValue.increment(1),
                    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                }, { merge: true });

                // 6. UPDATE MY VENDORS
                const currentCredit = to2DP_Floor(vendorRel.storeCredit || 0);
                const newCreditBalance = to2DP_Floor(currentCredit - creditUsed);

                t.set(vendorRelRef, {
                    vendorId: vendorId,
                    storeName: planData.storeName || 'Store',
                    lastInteraction: admin.firestore.FieldValue.serverTimestamp(),
                    storeCredit: newCreditBalance
                }, { merge: true });

                t.update(productRef, { availableStock: admin.firestore.FieldValue.increment(-1) });

                // 7. CREATE ACTIVITY FEED
                const activityRef = db.collection('vendors').doc(vendorId).collection('activity_feed').doc();
                t.set(activityRef, {
                    id: activityRef.id,
                    type: 'reservation_new',
                    title: 'New Reservation',
                    body: `${planData.customerName} reserved ${product.name}`,
                    ref_id: planId,
                    amount_display: `+₦${userPrincipalPayment.toLocaleString()}`,
                    date: admin.firestore.FieldValue.serverTimestamp(),
                    is_read: false
                });

                // --- VENDOR SIDE ---
                const vendorStatsRef = db.collection('vendor_stats').doc(vendorId);
                const cashPrincipal = to2DP_Floor(userPrincipalPayment - creditUsed);
                let vendorNet = 0;
                let feeDeducted = 0;

                if (cashPrincipal > 0) {
                    vendorNet = to2DP_Floor(cashPrincipal * (1 - PLATFORM_FEE_PERCENTAGE));
                    feeDeducted = to2DP(cashPrincipal * PLATFORM_FEE_PERCENTAGE);
                    const vLedgerRef = db.collection('vendors').doc(vendorId).collection('ledger_transactions').doc();

                    t.set(vLedgerRef, {
                        id: vLedgerRef.id,
                        userId: vendorId,
                        amount: vendorNet,
                        type: 'sale',
                        description: `Initial payment for ${product.name} (minus 3.5% fee)`,
                        reference: `SALE-${planId.substring(0, 6)}`,
                        planId: planId,
                        status: 'success',
                        releaseDate: null,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        customerName: planData.customerName,
                        grossAmount: cashPrincipal,
                        feeAmount: feeDeducted
                    });
                }

                // 🚀 KORRA PROFIT LEDGER (Our 3.5% Vendor Commission)
                const korraLedger1 = db.collection('company_ledger').doc();
                t.set(korraLedger1, {
                    id: korraLedger1.id,
                    type: 'credit',
                    category: 'vendor_commission',
                    amount: feeDeducted, 
                    description: `3.5% fee on ${product.name}`,
                    planId: planId,
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                    dateStr: currentDateStr,
                    monthStr: currentMonth,
                    yearStr: currentYearStr
                });

                // 🚀 KORRA PROFIT LEDGER (Customer Processing Fee)
                if (processingFee > 0) {
                    const korraLedger2 = db.collection('company_ledger').doc();
                    t.set(korraLedger2, {
                        id: korraLedger2.id,
                        type: 'credit',
                        category: 'customer_processing_fee',
                        amount: processingFee, 
                        description: `Processing fee from ${planData.customerName}`,
                        planId: planId,
                        timestamp: admin.firestore.FieldValue.serverTimestamp(),
                        dateStr: currentDateStr,
                        monthStr: currentMonth,
                        yearStr: currentYearStr
                    });
                }

                // 🚀 MASTER COMPANY WALLET (Total Cash Available)
                const totalProfitEarned = feeDeducted + processingFee;
                if (totalProfitEarned > 0) {
                    const companyWalletRef = db.collection('company_wallet').doc('main');
                    t.set(companyWalletRef, {
                        availableBalance: admin.firestore.FieldValue.increment(totalProfitEarned),
                        totalAllTimeEarnings: admin.firestore.FieldValue.increment(totalProfitEarned),
                        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                    }, { merge: true });
                }

                if (creditUsed > 0) {
                    const vLiabRef = db.collection('vendors').doc(vendorId).collection('liabilities').doc();
                    t.set(vLiabRef, {
                        id: vLiabRef.id,
                        userId: vendorId,
                        amount: -creditUsed,
                        type: 'redemption',
                        description: `Store Balance applied by ${planData.customerName}`,
                        status: 'success',
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        planId: planId
                    });
                }

                // GLOBAL STATS
                t.update(vendorStatsRef, {
                    totalEarnings: admin.firestore.FieldValue.increment(vendorNet),
                    currentActivePlanValue: admin.firestore.FieldValue.increment(-(vendorNet + creditUsed)),
                    totalSalesVolume: admin.firestore.FieldValue.increment(price),
                    totalLiability: admin.firestore.FieldValue.increment(-creditUsed),
                    activePlansCount: admin.firestore.FieldValue.increment(1)
                });

                // MONTHLY ANALYTICS
                const monthlyRef = db.collection('vendors').doc(vendorId).collection('monthly_stats').doc(currentMonth);

                t.set(monthlyRef, {
                    month: currentMonth,
                    year: now.getFullYear().toString(),
                    earnings: admin.firestore.FieldValue.increment(vendorNet),
                    salesVolume: admin.firestore.FieldValue.increment(price),
                    newPlansCount: admin.firestore.FieldValue.increment(1),
                    [`daily_breakdown.${currentDay}`]: admin.firestore.FieldValue.increment(vendorNet),
                    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                }, { merge: true });

                return {
                    planId: planId,
                    productName: product.name,
                    productImage: (product.images && product.images.length > 0) ? product.images[0] : null,
                    vendorId: vendorId,
                    customerName: planData.customerName,
                    downPayment: userPrincipalPayment,
                    planIdStr: planId,
                    feeDeducted: feeDeducted,
                    pickupCode: pickupCode // Return code if exists
                };
            });

            // NOTIFICATIONS
            await sendFcm(
                customerUid, 
                "Reservation Confirmed 🔒", 
                `Plan for ${result.productName} is active!`, 
                { type: "plan_detail", planId: result.planIdStr, image: result.productImage }, // Added to data
                'customers', // Assuming default role is customers
                result.productImage // ✅ Pass image explicitly if your sendFcm supports it
            );

            if (result.pickupCode) {
                 await sendFcm(customerUid, "Plan Completed! 🎉", `Your item is ready. Your Pickup PIN is: ${result.pickupCode}. Show this to your merchant.`, { type: "plan_detail", planId: result.planIdStr });
            }

            await sendFcm(
                result.vendorId,
                "New Order: Action Required 📦",
                `Please RESERVE ${result.productName} immediately, Customer ${result.customerName} just paid ₦${result.downPayment.toLocaleString()} initial deposit.`,
                { type: "vendor_order", planId: result.planIdStr, image: result.productImage },
                'vendors',
                result.productImage // ✅ 
            );

            await sendFcm(
                result.vendorId,
                "Platform Fee 📉",
                `A platform fee of -₦${result.feeDeducted.toLocaleString()} was deducted for the new order.`,
                { type: "payment", planId: result.planIdStr },
                'vendors'
            );

            return new Response(JSON.stringify({ status: "SUCCESS", planId: result.planIdStr }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
        }

        // =======================================================================
        // 💸 ACTION: PAY INSTALLMENT (FINAL BUSINESS LOGIC)
        // =======================================================================
        if (action === 'PAY_INSTALLMENT') {
            const paymentAmount = to2DP(Number(amount));
            if (paymentAmount <= 0) throw "Invalid payment amount.";

            if (!customerUid) throw "User not authenticated.";

            const result = await db.runTransaction(async (t) => {
                const planRef = db.collection("plans").doc(planId);

                // ✅ Get Refs
                const { userRef, statsRef } = await getUserAndStats(customerUid);
                const planDoc = await t.get(planRef);
                const userDoc = await t.get(userRef);
                
                if (!planDoc.exists) throw "Reservation not found";
                const plan = planDoc.data();
                
                if (plan.status !== 'active') throw "This plan is not active.";
                if (plan.customerId !== customerUid) throw "Plan does not belong to user.";

                const userData = userDoc.exists ? userDoc.data() : {};
                const statsDoc = await t.get(statsRef);
                const statsData = statsDoc.exists ? statsDoc.data() : {};
                
                // ✅ MONEY
                const walletBalance = to2DP_Floor(userData.monnify?.availableBalance || 0);
                const vendorId = plan.vendorId;

                // ✅ VENDOR RELATION
                const { ref: vendorRelRef, data: vendorRel } = await getVendorRelation(customerUid, vendorId);
                const availableStoreCredit = to2DP_Floor(vendorRel.storeCredit || 0);

                // --- FINANCIAL MATH ---
                let creditUsed = 0;
                let walletUsed = 0;

                if (availableStoreCredit >= paymentAmount) {
                    creditUsed = paymentAmount;
                    walletUsed = 0;
                } else {
                    creditUsed = availableStoreCredit;
                    walletUsed = to2DP(paymentAmount - creditUsed);
                }

                if (walletBalance < walletUsed) {
                    throw `Insufficient funds. Needed: ₦${walletUsed.toLocaleString()}, Available: ₦${walletBalance.toLocaleString()}`;
                }

                // ✅ 1. STRICT DUST CLEARING LOGIC (The Fix)
                let newAmountPaid = to2DP(plan.amountPaid + paymentAmount);
                let remainingBalance = to2DP(plan.totalAmount - newAmountPaid);
                let isFinished = false;
                let pickupCode = null;

                // 🎯 CHANGED: Tolerance is now strictly less than 100 Naira (e.g. 0.99 clears, 100.00 does not)
                if (remainingBalance < 100.0) {
                    isFinished = true;
                    newAmountPaid = plan.totalAmount; 
                    remainingBalance = 0;
                    
                    // 🔐 GENERATE PICKUP PIN
                    pickupCode = Math.floor(1000 + Math.random() * 9000).toString();
                } else {
                    isFinished = false;
                }

                // ---------------------------------------------------------
                // 📝 1. UPDATE PLAN
                // ---------------------------------------------------------
                t.update(planRef, {
                    amountPaid: newAmountPaid,
                    outstandingLoanAmount: remainingBalance,
                    status: isFinished ? 'completed' : 'active',
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    completedAt: isFinished ? admin.firestore.FieldValue.serverTimestamp() : null,
                    // ✅ SAVE PIN ONLY IF FINISHED
                    ...(isFinished && { pickupCode: pickupCode }) 
                });

                // ---------------------------------------------------------
                // 📝 2. USER LEDGER & WALLET
                // ---------------------------------------------------------
                const ledgerRef = db.collection('customers').doc(customerUid).collection('ledger_transactions').doc();
                const txRefId = `PAY-${planId.substring(0, 5)}-${Date.now().toString().slice(-4)}`;

                // ✅ CONSTRUCT RECEIPT DATA
                const receiptPayload = {
                    reference: txRefId,
                    date: new Date().toISOString(),
                    vendorName: plan.storeName,
                    vendorId: vendorId,
                    customerName: plan.customerName || "Customer",
                    customerPhone: plan.customerPhone || "",
                    productName: plan.title, 
                    productCode: plan.productCode,
                    totalValue: plan.totalAmount,
                    amountPaidSoFar: newAmountPaid,
                    amountPaidNow: paymentAmount,
                    paymentMethod: creditUsed > 0 ? (walletUsed > 0 ? "Mixed (Store Balance + Wallet)" : "Store Balance") : "Wallet Transfer",
                    balanceRemaining: remainingBalance,
                    status: isFinished ? "COMPLETED" : "IN PROGRESS",
                    isFinished: isFinished,
                    creditUsed: creditUsed,
                    walletUsed: walletUsed,
                    // ✅ SAFE DATE HELPER
                    nextDueDate: (!isFinished && plan.nextDueDate) ? safeIsoDate(plan.nextDueDate) : null
                };

                t.set(ledgerRef, {
                    id: ledgerRef.id,
                    customerId: customerUid,
                    amount: -paymentAmount,
                    type: 'installment',
                    description: `Payment for ${plan.title}`,
                    reference: txRefId,
                    planId: planId,
                    status: 'success',
                    balanceBefore: walletBalance,
                    balanceAfter: to2DP_Floor(walletBalance - walletUsed),
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    metadata: { paidWithWallet: walletUsed, paidWithCredit: creditUsed, vendorName: plan.storeName },
                    receiptData: receiptPayload
                });

                if (walletUsed > 0) {
                    t.update(userRef, {
                        "monnify.availableBalance": admin.firestore.FieldValue.increment(-walletUsed)
                    });
                }

                // ---------------------------------------------------------
                // 📝 3. USER STATS (If Finished) & ANALYTICS
                // ---------------------------------------------------------
                let upgradedTier = null;
                
                if (isFinished) {
                    // 1. Calculate the new completed count
                    const currentCompleted = statsData.completedPlansCount || 0;
                    const newCompletedCount = currentCompleted + 1;
                    
                    // 2. Determine the new Tier (Auto-Upgrade Logic)
                    const currentTier = statsData.tier || 'Starter';
                    let newTier = currentTier;

                    if (newCompletedCount >= 25) {
                        newTier = 'VIP';
                    } else if (newCompletedCount >= 10) {
                        newTier = 'Collector';
                    } else if (newCompletedCount >= 3) {
                        newTier = 'Keeper';
                    }
                    // Else: It stays as whatever it currently is

                    
                    if (newTier !== currentTier) {
                        upgradedTier = newTier;
                    }

                    // 3. Save Stats & New Tier to Database
                    t.set(statsRef, {
                        activePlansCount: admin.firestore.FieldValue.increment(-1),
                        completedPlansCount: admin.firestore.FieldValue.increment(1),
                        tier: newTier, // ✅ Auto-upgrade applied here
                        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                    }, { merge: true });

                    const now = new Date();
                    const currentMonth = now.toISOString().slice(0, 7);
                    const custMonthlyRef = db.collection('customers').doc(customerUid)
                                                .collection('monthly_stats').doc(currentMonth);
                    
                    t.set(custMonthlyRef, {
                        month: currentMonth,
                        year: now.getFullYear().toString(),
                        completedCount: admin.firestore.FieldValue.increment(1),
                        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                    }, { merge: true });
                }

                // ---------------------------------------------------------
                // 📝 4. VENDOR RELATION (Store Credit)
                // ---------------------------------------------------------
                const newCreditBalance = to2DP_Floor(availableStoreCredit - creditUsed);
                
                t.set(vendorRelRef, {
                    vendorId: vendorId,
                    storeName: plan.storeName,
                    lastInteraction: admin.firestore.FieldValue.serverTimestamp(),
                    storeCredit: newCreditBalance 
                }, { merge: true });

                // ---------------------------------------------------------
                // 📝 5. ACTIVITY FEED & VENDOR FINANCIALS
                // ---------------------------------------------------------
                const activityRef = db.collection('vendors').doc(vendorId).collection('activity_feed').doc();
                t.set(activityRef, {
                    id: activityRef.id,
                    type: 'payment',
                    title: 'Payment Received',
                    body: `${plan.customerName} paid ₦${paymentAmount.toLocaleString()} for ${plan.title}`,
                    ref_id: planId,
                    amount_display: `+₦${paymentAmount.toLocaleString()}`,
                    date: admin.firestore.FieldValue.serverTimestamp(),
                    is_read: false
                });

                const nowForLedger = new Date();
                const currentDateStr = nowForLedger.toISOString().slice(0, 10); // "2026-02-13"
                const currentMonthStr = nowForLedger.toISOString().slice(0, 7); // "2026-02"
                const currentYearStr = nowForLedger.getFullYear().toString();   // "2026"
                const currentDayStr = nowForLedger.toISOString().slice(8, 10);  // "13"

                // Vendor Stats & Ledger
                const vendorStatsRef = db.collection('vendor_stats').doc(vendorId);
                const vendorFeeRate = 0.035; 
                let vendorNet = 0;
                let feeDeducted = 0;

                // A. Handle Wallet Portion
                if (walletUsed > 0) {
                    vendorNet = to2DP_Floor(walletUsed * (1 - vendorFeeRate));
                    feeDeducted = to2DP(walletUsed * vendorFeeRate);
                    
                    const vLedgerRef = db.collection('vendors').doc(vendorId).collection('ledger_transactions').doc();
                    t.set(vLedgerRef, {
                        id: vLedgerRef.id,
                        userId: vendorId,
                        amount: vendorNet,
                        type: 'sale',
                        description: `${plan.customerName} paid ₦${paymentAmount.toLocaleString()} for ${plan.title}`,
                        reference: txRefId,
                        planId: planId,
                        status: 'success',
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        customerName: plan.customerName,
                        grossAmount: walletUsed,
                        feeAmount: feeDeducted
                    });

                    const korraLedger = db.collection('company_ledger').doc();
                    t.set(korraLedger, {
                        id: korraLedger.id,
                        type: 'credit',
                        category: 'vendor_commission',
                        amount: feeDeducted, 
                        description: `3.5% fee on installment for ${plan.title}`,
                        planId: planId,
                        timestamp: admin.firestore.FieldValue.serverTimestamp(),
                        dateStr: currentDateStr,
                        monthStr: currentMonthStr,
                        yearStr: currentYearStr
                    });

                    // 🚀 MASTER COMPANY WALLET (Total Cash Available)
                    if (feeDeducted > 0) {
                        const companyWalletRef = db.collection('company_wallet').doc('main');
                        t.set(companyWalletRef, {
                            availableBalance: admin.firestore.FieldValue.increment(feeDeducted),
                            totalAllTimeEarnings: admin.firestore.FieldValue.increment(feeDeducted),
                            lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                        }, { merge: true });
                    }

                    t.update(vendorStatsRef, {
                        totalEarnings: admin.firestore.FieldValue.increment(vendorNet),
                        walletBalance: admin.firestore.FieldValue.increment(vendorNet),
                        currentActivePlanValue: admin.firestore.FieldValue.increment(-walletUsed) 
                    });
                }

                // B. Handle Credit Portion
                if (creditUsed > 0) {
                    const vLiabRef = db.collection('vendors').doc(vendorId).collection('liabilities').doc();
                    t.set(vLiabRef, {
                        id: vLiabRef.id,
                        userId: vendorId,
                        amount: -creditUsed,
                        type: 'redemption',
                        description: `Store Balance Used: ${plan.customerName}`,
                        status: 'success',
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        planId: planId
                    });
                    
                    t.update(vendorStatsRef, {
                        totalLiability: admin.firestore.FieldValue.increment(-creditUsed),
                        currentActivePlanValue: admin.firestore.FieldValue.increment(-creditUsed)
                    });
                }

                // C. Vendor Monthly Analytics
                if (walletUsed > 0) {                
                    const monthlyRef = db.collection('vendors').doc(vendorId)
                                            .collection('monthly_stats').doc(currentMonthStr);
                    
                    t.set(monthlyRef, {
                        month: currentMonthStr,
                        year: currentYearStr,
                        earnings: admin.firestore.FieldValue.increment(vendorNet),
                        [`daily_breakdown.${currentDayStr}`]: admin.firestore.FieldValue.increment(vendorNet),
                        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                    }, { merge: true });
                }

                return {
                    success: true,
                    upgradedTier: upgradedTier,
                    receiptData: { ...receiptPayload, feeDeducted: feeDeducted },
                    pickupCode: pickupCode, // Pass back to display if needed immediately
                };
            });

            // ---------------------------------------------------------
            // 🔔 NOTIFICATIONS
            // ---------------------------------------------------------
            
            // 1. Notify Customer
            await sendFcm(customerUid, "Payment Successful ✅", `You paid ₦${paymentAmount.toLocaleString()} for ${result.receiptData.productName}.`, { type: "plan_detail", planId: planId });

            // 2. Notify Vendor (Money In)
            await sendFcm(
                result.receiptData.vendorId,
                "Payment Received 💰",
                `${result.receiptData.customerName} just paid ₦${paymentAmount.toLocaleString()}.`,
                { type: "vendor_order", planId: planId },
                'vendors'
            );

            // 3. Notify Vendor (Fee Deduction)
            if (result.receiptData.feeDeducted > 0) {
                await sendFcm(
                    result.receiptData.vendorId,
                    "Platform Fee 📉",
                    `A fee of ₦${result.receiptData.feeDeducted.toLocaleString()} was deducted from the recent payment.`,
                    { type: "payment", planId: planId },
                    'vendors'
                );
            }

            // 4. Notify Vendor (Completion)
            if (result.receiptData.isFinished) {
                await sendFcm(result.receiptData.vendorId, "Order Completed! 🎉", `${result.receiptData.customerName} has finished paying for ${result.receiptData.productName}.`, { type: "vendor_order", planId: planId }, 'vendors');
                
                // 5. ✅ Notify Customer with PIN
                if (result.pickupCode) {
                    await sendFcm(
                        customerUid, 
                        "Plan Completed! 🎉", 
                        `Your item is ready. Your Pickup PIN is: ${result.pickupCode}. Show this to the vendor.`, 
                        { type: "plan_detail", planId: planId }
                    );
                }
            }

            // 6. 🏆 NEW: Notify Customer of Tier Upgrade
            if (result.upgradedTier) {
                await sendFcm(
                    customerUid,
                    "Level Up! 🌟",
                    `Congratulations! You've been upgraded to the ${result.upgradedTier} tier. Enjoy your new perks and extra active plan slots!`,
                    { type: "home" } // You can route this to 'home', 'profile', or wherever makes sense
                );
            }

            return new Response(JSON.stringify(result), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
        }

        // =======================================================================
        // ⏳ ACTION: EXTEND PLAN
        // =======================================================================
        if (action === 'EXTEND') {
            // 1. Validate
            if (!planId || !customerUid) throw "Missing planId or customerUid.";

            const result = await db.runTransaction(async (t) => {
                const planRef = db.collection("plans").doc(planId);
                const planDoc = await t.get(planRef);

                if (!planDoc.exists) throw "Plan not found.";
                const plan = planDoc.data();
                const vendorId = plan.vendorId;

                // 2. Security & State Checks
                if (plan.customerId !== customerUid) throw "Unauthorized.";
                if (plan.status !== 'active') throw "Plan is not active.";
                
                // 3. The 80% Rule Check
                const total = Number(plan.totalAmount) || 1; // Prevent div by zero
                const paid = Number(plan.amountPaid) || 0;
                const percentPaid = paid / total;

                if (percentPaid < 0.80) {
                    throw `Eligibility Failed: You have paid ${(percentPaid * 100).toFixed(1)}%. You need 80% to extend.`;
                }

                // 4. Check if "Lifeline" is available
                // We store the 'potential' days in extensionGraceDays. 
                // If it is 0, it means they used it already.
                const daysToAdd = Number(plan.extensionGraceDays || 0);
                if (daysToAdd <= 0) {
                    throw "Extension unavailable. You may have already used your one-time extension.";
                }

                // 🛠️ HELPER: Safely parse date (Handles Timestamp OR String)
                const parseFirestoreDate = (val) => {
                    if (!val) return new Date(); // Fallback
                    // If it has .toDate(), it's a Timestamp. Otherwise, it's a String/Date.
                    return (typeof val.toDate === 'function') ? val.toDate() : new Date(val);
                };



                // 5. Calculate New Dates
                const oldExpiry = parseFirestoreDate(plan.planExpiryDate);
                const newExpiry = new Date(oldExpiry);
                newExpiry.setDate(oldExpiry.getDate() + daysToAdd);

                const oldNextDue = parseFirestoreDate(plan.nextDueDate);
                const newNextDue = new Date(oldNextDue);
                newNextDue.setDate(oldNextDue.getDate() + daysToAdd);

                // 6. UPDATE PLAN
                t.update(planRef, {
                    planExpiryDate: admin.firestore.Timestamp.fromDate(newExpiry),
                    nextDueDate: admin.firestore.Timestamp.fromDate(newNextDue),
                    extensionGraceDays: 0, // 🔥 Burn the lifeline (One-time use)
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    isExtended: true // Optional flag for UI badges
                });

                // 7. CUSTOMER LEDGER (Audit Trail)
                const ledgerRef = db.collection('customers').doc(customerUid).collection('ledger_transactions').doc();
                t.set(ledgerRef, {
                    id: ledgerRef.id,
                    customerId: customerUid,
                    amount: 0, // No money moved
                    type: 'plan_extension',
                    description: `Timeline Extended (+${daysToAdd} Days)`,
                    planId: planId,
                    reference: `EXT-${planId.substring(0,6)}`,
                    status: 'success',
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    metadata: { daysAdded: daysToAdd }
                });

                // 8. VENDOR ACTIVITY
                const activityRef = db.collection('vendors').doc(vendorId).collection('activity_feed').doc();
                t.set(activityRef, {
                    id: activityRef.id,
                    type: 'reservation_extended',
                    title: 'Reservation Extended',
                    body: `${plan.customerName} extended timeline by ${daysToAdd} days.`,
                    ref_id: planId,
                    amount_display: null,
                    date: admin.firestore.FieldValue.serverTimestamp(),
                    is_read: false
                });

                const productImage = (plan.imageUrls && plan.imageUrls.length > 0) 
                    ? plan.imageUrls[0] 
                    : null;

                return { 
                    status: "SUCCESS", 
                    daysAdded: daysToAdd,
                    newDate: newExpiry.toISOString(),
                    vendorId: plan.vendorId,
                    productName: plan.title || "Product",
                    productImage: productImage
                };
            });

            // 9. NOTIFICATIONS
            
            // To Customer
            await sendFcm(
                customerUid, 
                "Timeline Extended ✅", 
                `You have secured +${result.daysAdded} extra days. Keep your momentum and finish strong.`, 
                // 👇 Add image to data payload
                { type: "plan_detail", planId: planId, image: result.productImage }, 
                'customers',
                result.productImage // 👈 Pass explicitly if your helper uses it for iOS
            );

            // To Vendor
            await sendFcm(
                result.vendorId,
                "Reservation Update ⏳",
                `Timeline extended by ${result.daysAdded} days for ${result.productName}. Order remains active.`,
                // 👇 Add image to data payload
                { type: "vendor_order", planId: planId, image: result.productImage }, 
                'vendors',
                result.productImage // 👈 Pass explicitly
            );

            return new Response(JSON.stringify(result), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
        }

        // =======================================================================
        // 🛑 ACTION: CANCEL PLAN (Store Credit Conversion)
        // =======================================================================
        if (action === 'CANCEL') {
            // 1. Validate
            if (!planId || !customerUid) throw "Missing planId or customerUid.";

            const result = await db.runTransaction(async (t) => {
                const planRef = db.collection("plans").doc(planId);
                const planDoc = await t.get(planRef);

                if (!planDoc.exists) throw "Plan not found.";
                const plan = planDoc.data();

                // 2. Security Checks
                if (plan.customerId !== customerUid) throw "Unauthorized.";
                if (plan.status !== 'active') throw "Plan is not active.";

                const vendorId = plan.vendorId;
                const refundAmount = to2DP_Floor(plan.amountPaid); // Full amount
                const penaltyAmount = 0; // No penalty

                // 3. UPDATE PLAN: Mark Cancelled
                t.update(planRef, {
                    status: 'cancelled',
                    cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
                    refundAmount: refundAmount,
                    penaltyAmount: 0,
                    cancellationReason: 'Converted to Store Balance'
                });

                // 4. CUSTOMER SIDE: Increase Store Credit
                // We update the specific relationship doc for this vendor
                const relRef = db.collection('customers').doc(customerUid).collection('my_vendors').doc(vendorId);
                t.set(relRef, {
                    vendorId: vendorId,
                    storeName: plan.storeName || 'Store', // Ensure name exists
                    storeCredit: admin.firestore.FieldValue.increment(refundAmount),
                    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                }, { merge: true });

                // 5. CUSTOMER SIDE: Stats & Ledger
                const { statsRef } = await getUserAndStats(customerUid);
                
                // Update Counts
                t.set(statsRef, {
                    activePlansCount: admin.firestore.FieldValue.increment(-1),
                    cancelledPlansCount: admin.firestore.FieldValue.increment(1),
                    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                }, { merge: true });

                // Log Transaction
                const ledgerRef = db.collection('customers').doc(customerUid).collection('ledger_transactions').doc();
                t.set(ledgerRef, {
                    id: ledgerRef.id,
                    customerId: customerUid,
                    amount: 0, // No cash returned to wallet, so 0 flow
                    type: 'plan_cancelled',
                    description: `Credited ₦${refundAmount.toLocaleString()} to Store Balance`,
                    planId: planId,
                    status: 'success',
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    metadata: { 
                        convertedAmount: refundAmount, 
                        vendorName: plan.storeName 
                    }
                });

                // 6. VENDOR SIDE: Liability & Inventory
                const vendorStatsRef = db.collection('vendor_stats').doc(vendorId);
                
                // Log Liability (Vendor owes goods worth this amount)
                const vLiabRef = db.collection('vendors').doc(vendorId).collection('liabilities').doc();
                t.set(vLiabRef, {
                    id: vLiabRef.id,
                    userId: vendorId,
                    amount: refundAmount,
                    type: 'conversion', // New type for clarity
                    description: `Plan Closed: ${plan.customerName}`,
                    planId: planId,
                    status: 'success',
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });

                // Update Vendor Stats
                t.update(vendorStatsRef, {
                    totalLiability: admin.firestore.FieldValue.increment(refundAmount),
                    activePlansCount: admin.firestore.FieldValue.increment(-1),
                    // Note: We do NOT touch 'currentActivePlanValue' here because that tracks potential revenue. 
                    // Since the plan is dead, that potential revenue is gone, replaced by liability.
                    // If you track 'projected_revenue', decrease it here.
                });

                // Release Stock
                const productRef = db.collection("products").doc(plan.productId);
                t.update(productRef, { 
                    availableStock: admin.firestore.FieldValue.increment(1) 
                });

                // 7. Activity Feed
                const activityRef = db.collection('vendors').doc(vendorId).collection('activity_feed').doc();
                t.set(activityRef, {
                    id: activityRef.id,
                    type: 'reservation_cancel',
                    title: 'Plan Closed',
                    body: `${plan.customerName} closed ${plan.title}. Funds secured in Store Balance.`,
                    ref_id: planId,
                    amount_display: `+₦${refundAmount.toLocaleString()} Credit`,
                    date: admin.firestore.FieldValue.serverTimestamp(),
                    is_read: false
                });

                return { 
                    status: "SUCCESS", 
                    refundAmount: refundAmount,
                    storeName: plan.storeName,
                    vendorId: vendorId,
                    productName: plan.title || "Product"
                };
            });

            // 8. NOTIFICATIONS
            await sendFcm(
                customerUid, 
                "Funds Secured 🔒", // Title focuses on the MONEY, not the cancellation.
                // "Your money is safe here."
                `Your ₦${result.refundAmount.toLocaleString()} is now available in your Store Balance at ${result.storeName}.`, 
                { type: "plan_detail", planId: planId }
            );

            // To Vendor
            await sendFcm(
                result.vendorId,
                "Plan Closed 📁", // "Closed" implies the file is put away.
                // clear instruction: The deal is off, money moved.
                `Customer closed the plan for ${result.productName}. Funds moved to their Store Balance.`,
                { type: "vendor_order", planId: planId },
                'vendors'
            );

            return new Response(JSON.stringify(result), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
        }

        
        // =======================================================================
        // 🤝 ACTION: VERIFY PICKUP
        // =======================================================================
        if (action === 'VERIFY_PICKUP') {
            // 1. Validate Inputs
            if (!planId || !pin || !vendorUid) {
                throw "Missing required fields: planId, pin, or vendorUid.";
            }

            const result = await db.runTransaction(async (t) => {
                const planRef = db.collection("plans").doc(planId);
                const planDoc = await t.get(planRef);
                
                if (!planDoc.exists) throw "Reservation not found.";
                const plan = planDoc.data();

                // 2. Security Checks
                if (plan.vendorId !== vendorUid) {
                    throw "Unauthorized: You do not own this order.";
                }
                if (plan.status !== 'completed') {
                    throw "Plan is not fully paid yet.";
                }
                if (plan.fulfilledAt != null) {
                    throw "Item already collected.";
                }

                // 3. Verify PIN (String comparison)
                // We use String() to ensure '1234' matches 1234
                if (String(plan.pickupCode).trim() !== String(pin).trim()) {
                    throw "Incorrect PIN.";
                }

                // 4. Update Plan
                t.update(planRef, {
                    fulfilledAt: admin.firestore.FieldValue.serverTimestamp(),
                    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
                    // We keep the PIN for audit logs, but you could delete it here
                });

                // 5. Log to Vendor Activity
                const activityRef = db.collection('vendors').doc(vendorUid).collection('activity_feed').doc();
                t.set(activityRef, {
                    id: activityRef.id,
                    type: 'reservation_fulfilled',
                    title: 'Order Fulfilled',
                    body: `Handed over ${plan.title} to ${plan.customerName}`,
                    ref_id: planId,
                    amount_display: null, 
                    date: admin.firestore.FieldValue.serverTimestamp(),
                    is_read: false
                });

                return { 
                    success: true,
                    customerId: customerUid
                };
            });

            // 6. Notify Customer
            await sendFcm(
                result.customerId, // Ensure result has this if you return it from transaction, or query it
                "Order Collected ✅", 
                "You have successfully picked up your item. Thanks for using Korra!", 
                { type: "plan_detail", planId: planId }
            );

            return new Response(JSON.stringify(result), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
        }

        // =======================================================================
        // 🚀 ACTION: RECORD EXPENSE (Admin Only - Money Out)
        // =======================================================================
        if (action === 'RECORD_EXPENSE') {
            // 1. Extract from your payload (ensure these are passed from your frontend/Postman)
            const { amount, reason, category, adminPassword } = payload; // or req.body depending on your setup
            
            // 🔐 SECURITY: Protect your company funds!
            if (adminPassword !== "David2026Boss") throw "Unauthorized Access. Admin only.";
            if (!amount || Number(amount) <= 0) throw "Amount must be greater than zero.";
            if (!reason) throw "You must provide a reason for the expense.";

            const expenseAmount = to2DP(Number(amount));
            
            // --- GLOBAL DATE HELPERS FOR LEDGERS ---
            const nowForLedger = new Date();
            const currentDateStr = nowForLedger.toISOString().slice(0, 10); // "2026-02-13"
            const currentMonthStr = nowForLedger.toISOString().slice(0, 7); // "2026-02"
            const currentYearStr = nowForLedger.getFullYear().toString();   // "2026"

            const result = await db.runTransaction(async (t) => {
                const walletRef = db.collection('company_wallet').doc('main');
                const walletDoc = await t.get(walletRef);
                
                let currentBalance = 0;
                if (walletDoc.exists) {
                    currentBalance = walletDoc.data().availableBalance || 0;
                }

                // 🛑 Prevent withdrawing more than Korra has earned!
                if (currentBalance < expenseAmount) {
                    throw `Insufficient Company Funds. You only have ₦${currentBalance.toLocaleString()} available.`;
                }

                // 📝 1. LOG THE DEBIT IN KORRA'S LEDGER
                const expenseLedgerRef = db.collection('company_ledger').doc();
                t.set(expenseLedgerRef, {
                    id: expenseLedgerRef.id,
                    type: 'debit', // MONEY OUT
                    category: category || 'general_expense', // e.g., 'salary', 'marketing', 'software'
                    amount: -expenseAmount, // Negative number for expenses
                    description: reason,
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                    dateStr: currentDateStr,
                    monthStr: currentMonthStr,
                    yearStr: currentYearStr
                });

                // 📉 2. DEDUCT FROM MASTER COMPANY WALLET
                t.set(walletRef, {
                    availableBalance: admin.firestore.FieldValue.increment(-expenseAmount),
                    totalAllTimeExpenses: admin.firestore.FieldValue.increment(expenseAmount),
                    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                }, { merge: true });

                return {
                    expenseId: expenseLedgerRef.id,
                    amountSpent: expenseAmount,
                    newBalance: to2DP(currentBalance - expenseAmount)
                };
            });

            return new Response(JSON.stringify({ 
                status: "SUCCESS", 
                message: `₦${result.amountSpent.toLocaleString()} expense recorded. Reason: ${reason}.`,
                newBalance: result.newBalance 
            }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
        }

        return new Response(JSON.stringify({ error: "Invalid Action" }), { status: 400 });

    } catch (err) {
        const msg = err.toString().replace("Error: ", "");
        return new Response(JSON.stringify({ status: "ERROR", error: msg }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }
});