import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts";
import admin from "npm:firebase-admin@11.11.0";

// 1. SETUP
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, firebase-token, x-korra-timestamp, x-korra-signature', 
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

// 🛠️ HELPER: Safely parse date (Handles Timestamp OR String)
const parseFirestoreDate = (val) => {
    if (!val) return new Date(); // Fallback
    // If it has .toDate(), it's a Timestamp. Otherwise, it's a String/Date.
    return (typeof val.toDate === 'function') ? val.toDate() : new Date(val);
};

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
const PLATFORM_FEE_PERCENTAGE = 0.0; // Vendor side fee — currently 0
 
// ✅ CUSTOMER SIDE FEE CONSTANTS
const CUSTOMER_FEE_RATE = 0.035;           // 3.5% on cash payments
const STORE_FEE_RATE = 0.035 * 0.10;      // 0.35% on store balance usage  
const MIN_STORE_FEE = 100;                 // Minimum ₦100 for store balance fee
const PER_PAYMENT_THRESHOLD = 30000;       // Items above ₦30k charge per payment
const MAX_FEE = 7500;

// 3. MAIN HANDLER
serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    try {
        // =======================================================================
        // 🔐 LOCK 1: HMAC ANTI-FORGERY & ANTI-REPLAY
        // =======================================================================
        const clientTimestamp = req.headers.get('x-korra-timestamp');
        const clientSignature = req.headers.get('x-korra-signature');
        const KORRA_SECRET = "7f8a9b2d4c6e1f3a5b7c9d0e2f4a6b8c1d3e5f7a9b0c2d4e6f8a1b3c5d7e9f0a";

        if (!clientTimestamp || !clientSignature) {
            throw new Error("Unauthorized: Missing security signatures.");
        }

        // 🛑 1. The Time Check (Anti-Replay)
        // If the request is older than 2 minutes (120,000 milliseconds), kill it immediately.
        const now = Date.now();
        const requestTime = parseInt(clientTimestamp, 10);
        if (Math.abs(now - requestTime) > 120000) {
            throw new Error("Unauthorized: Request expired (Replay attack blocked).");
        }

        // 🛑 2. The Math Check (Anti-Forgery)
        // The server recalculates the hash using the exact same logic as Flutter
        const encoder = new TextEncoder();
        const key = await crypto.subtle.importKey(
            "raw",
            encoder.encode(KORRA_SECRET),
            { name: "HMAC", hash: "SHA-256" },
            false,
            ["sign"]
        );

        const signatureBuffer = await crypto.subtle.sign("HMAC", key, encoder.encode(clientTimestamp));
        const hashArray = Array.from(new Uint8Array(signatureBuffer));
        const expectedServerSignature = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

        if (clientSignature !== expectedServerSignature) {
            throw new Error("Unauthorized: Cryptographic signature mismatch.");
        }
    
        // =======================================================================
        // 🔐 LOCK 2: AUTH TOKEN (Proves WHO the user is)
        // =======================================================================
        const authHeader = req.headers.get('firebase-token');

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            throw new Error("Unauthorized Access: Missing VIP pass.");
        }

        const idToken = authHeader.split('Bearer ')[1];

        let secureUid: string;

        try {
            const decodedToken = await admin.auth().verifyIdToken(idToken);
            secureUid = decodedToken.uid;
        } catch (error) {
            throw new Error("Unauthorized Access: Token expired or invalid.");
        }

        const {
            action, customerUid, productId, planData, secureToken,
            planId, planIds, amount, pin, vendorUid, reason, category, adminPassword,
            variantLabel
        } = await req.json();

        // =======================================================================
        // 🚨 2. CONDITIONAL IDENTITY ROUTING (The Multi-Role Bouncer)
        // ======================================================================

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

            // VARIANTS: a plan reserves exactly ONE unit of ONE variant. When
            // the product has variants the customer must have chosen one, and
            // it must have stock; the choice is sealed inside the JWT below so
            // CREATE can trust it without trusting the client.
            let sealedVariant: string | null = null;
            const previewVariants = Array.isArray(productData.variants) ? productData.variants : [];
            if (previewVariants.length > 0) {
                const requested = (typeof variantLabel === 'string' ? variantLabel.trim() : '');
                if (!requested) throw "Please choose an option (size/variant) for this product.";
                const match = previewVariants.find((v: any) => String(v?.label ?? '') === requested);
                if (!match) throw "That option is no longer available.";
                if (Math.floor(Number(match.stock ?? 0)) < 1) throw "That option is out of stock.";
                sealedVariant = requested;
            }


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
                uid: customerUid,
                variant_label: sealedVariant
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

                // VARIANTS: the chosen variant comes from the VERIFIED token
                // (sealed at PREVIEW), never the client body. Re-check its
                // stock now inside the transaction.
                const tokenVariant = (typeof payload.variant_label === 'string' && payload.variant_label.trim() !== '')
                    ? payload.variant_label.trim() : null;
                const createVariants = Array.isArray(product.variants) ? product.variants : [];
                if (createVariants.length > 0) {
                    if (!tokenVariant) throw "Session expired. Please refresh.";
                    const vMatch = createVariants.find((v: any) => String(v?.label ?? '') === tokenVariant);
                    if (!vMatch) throw "That option is no longer available.";
                    if (Math.floor(Number(vMatch.stock ?? 0)) < 1) throw "That option just sold out.";
                }

                const vendorId = product.vendorId;

                const complianceRef = db.collection('vendor_compliance').doc(vendorId);
                const complianceDoc = await t.get(complianceRef);

                if (complianceDoc.exists) {
                    const compData = complianceDoc.data();
                    const isExplicitlyBlocked = compData.blockPayments === true;
                    const status = compData.status;

                    if (isExplicitlyBlocked || status === 'suspended' || status === 'banned') {
                        throw "Transactions paused. This store is currently unable to accept new digital reservations.";
                    }
                }

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
                const isAbove30k = price > PER_PAYMENT_THRESHOLD;

                // ─── DETECT PAYMENT INTENT ────────────────────────────────────────────
                // UI sends: for installment → deposit + fee
                //           for pay in full → full price + all fees
                // We detect by checking if amount covers the full price + expected full fee

                const maxPossibleCreditSweep = (availableStoreCredit >= price) ? price : availableStoreCredit;
                const maxPossibleCashPortion = to2DP(price - maxPossibleCreditSweep);

                // Expected full payment fee
                const expectedFeeCash = maxPossibleCashPortion > 0 ? to2DP(maxPossibleCashPortion * CUSTOMER_FEE_RATE) : 0;
                const expectedFeeCredit = maxPossibleCreditSweep > 0
                    ? Math.max(to2DP(maxPossibleCreditSweep * STORE_FEE_RATE), MIN_STORE_FEE)
                    : 0;
                const expectedFullPaymentFee = to2DP(expectedFeeCash + expectedFeeCredit);
                const expectedFullPaymentPayload = to2DP(price + expectedFullPaymentFee);

                const isFullPayment = amount >= (expectedFullPaymentPayload - 0.01);

                // ─── CREDIT SWEEP ─────────────────────────────────────────────────────
                // Store balance ONLY allowed for Pay in Full
                // Installment deposits must be fresh cash
                let creditSweep = 0;
                if (isFullPayment && availableStoreCredit > 0) {
                    creditSweep = maxPossibleCreditSweep;
                }

                // ─── FEE CALCULATION (WITH ₦7500 CAP) ─────────────────────────────────
                let processingFee = 0;
                let feeCashPart = 0;
                let feeCreditPart = 0;
                let cashPrincipalNeeded = 0;
                let creditUsed = creditSweep;

                if (isFullPayment) {
                    const cashPortion = to2DP(price - creditSweep);
                    if (cashPortion > 0) {
                        const rawFee = to2DP(cashPortion * CUSTOMER_FEE_RATE);
                        feeCashPart = rawFee > MAX_FEE ? MAX_FEE : rawFee;
                    }
                    
                    feeCreditPart = creditSweep > 0
                        ? Math.max(to2DP(creditSweep * STORE_FEE_RATE), MIN_STORE_FEE)
                        : 0;
                        
                    processingFee = to2DP(feeCashPart + feeCreditPart);
                    cashPrincipalNeeded = cashPortion;
                } else {
                    if (!isAbove30k) {
                        const rawFee = to2DP(price * CUSTOMER_FEE_RATE);
                        feeCashPart = rawFee > MAX_FEE ? MAX_FEE : rawFee;
                        processingFee = feeCashPart;
                        cashPrincipalNeeded = to2DP(amount - processingFee);
                    } else {
                        // UI sent: deposit + fee. 
                        // We check if the amount sent is large enough that the fee was capped at 7500.
                        // (7500 / 0.035 = 214285.71 principal. So total amount > 221785.71)
                        const capThreshold = (MAX_FEE / CUSTOMER_FEE_RATE) + MAX_FEE;
                        
                        if (amount > capThreshold) {
                            feeCashPart = MAX_FEE;
                            cashPrincipalNeeded = to2DP(amount - MAX_FEE);
                        } else {
                            cashPrincipalNeeded = to2DP(amount / (1 + CUSTOMER_FEE_RATE));
                            feeCashPart = to2DP(cashPrincipalNeeded * CUSTOMER_FEE_RATE);
                            
                            // Final safety clamp
                            if (feeCashPart > MAX_FEE) {
                                feeCashPart = MAX_FEE;
                                cashPrincipalNeeded = to2DP(amount - MAX_FEE);
                            }
                        }
                        processingFee = feeCashPart;
                    }

                    // Overpayment protection with capped fee recalculation
                    if (cashPrincipalNeeded > price) {
                        cashPrincipalNeeded = price;
                        if (isAbove30k) {
                            const rawRecalculatedFee = to2DP(cashPrincipalNeeded * CUSTOMER_FEE_RATE);
                            processingFee = rawRecalculatedFee > MAX_FEE ? MAX_FEE : rawRecalculatedFee;
                            feeCashPart = processingFee;
                        }
                    }
                }

                // ─── WALLET VALIDATION ────────────────────────────────────────────────
                // Wallet deduction = cash principal + all fees
                // (Store balance covers its portion directly, not from wallet)
                let userPrincipalPayment = to2DP(creditUsed + cashPrincipalNeeded);

                // =======================================================================
                // 🎁 THE AUTO-PROMO INTERCEPTOR
                // =======================================================================
                let promoAppliedAmount = 0;
                const promoRef = db.collection('promos').doc(vendorId);
                const promoDoc = await t.get(promoRef);

                if (promoDoc.exists) {
                    const promo = promoDoc.data();
                
                    const durationDays = planData.baseDurationDays;
                    
                    const usedUids = promo.usedByUids || [];
                    
                    // 🔎 DEBUG LOGS
                    console.log(`🔎 PROMO CHECK [${vendorId}]:`);
                    console.log(`- isActive: ${promo.isActive}`);
                    console.log(`- Price Check: ${price} >= ${promo.minItemPrice} (${price >= promo.minItemPrice})`);
                    console.log(`- Duration Check: ${durationDays.toFixed(1)} <= ${promo.maxDurationDays} (${durationDays <= promo.maxDurationDays})`);
                    console.log(`- Usage Check: ${usedUids.length} < ${promo.maxUses} (${usedUids.length < promo.maxUses})`);
                    console.log(`- New User Check: ${!usedUids.includes(customerUid)}`);

                    if (
                        promo.isActive === true &&
                        price >= promo.minItemPrice &&
                        durationDays <= promo.maxDurationDays &&
                        usedUids.length < promo.maxUses &&
                        !usedUids.includes(customerUid)
                    ) {
                        promoAppliedAmount = promo.promoValue;
                        const isFinalUse = (usedUids.length + 1) >= promo.maxUses;

                        t.update(promoRef, {
                            currentUses: admin.firestore.FieldValue.increment(1),
                            usedByUids: admin.firestore.FieldValue.arrayUnion(customerUid),
                            isActive: !isFinalUse
                        });
                        
                        console.log(`🎉 PROMO APPLIED: ₦${promoAppliedAmount} for user ${customerUid}`);
                    } else {
                        console.log("❌ PROMO SKIPPED: One or more conditions failed (see logs above).");
                    }
                } else {
                    console.log(`⚠️ No promo document found for vendor: ${vendorId}`);
                }
                // =======================================================================

                // 🚨 PREVENT OVERCHARGING ON FULL OR HIGH DEPOSITS
                if (userPrincipalPayment + promoAppliedAmount > price) {
                    // Calculate exactly how much extra money there is
                    const excess = to2DP((userPrincipalPayment + promoAppliedAmount) - price);
                    
                    // Deduct the excess from the cash they are paying today
                    if (cashPrincipalNeeded >= excess) {
                        cashPrincipalNeeded = to2DP(cashPrincipalNeeded - excess);
                    } else {
                        // Edge case: if excess is somehow more than the cash they are paying (e.g. using mostly store credit)
                        const remainingExcess = to2DP(excess - cashPrincipalNeeded);
                        cashPrincipalNeeded = 0;
                        creditUsed = to2DP(creditUsed - remainingExcess);
                    }
                    
                    // Recalculate their final deductions so we don't overcharge their wallet
                    userPrincipalPayment = to2DP(creditUsed + cashPrincipalNeeded);
                }

                const walletUsed = to2DP(cashPrincipalNeeded + processingFee);
                const userRequiredDownPayment = to2DP(requiredPrincipal);

                // Minimum Deposit Guard (Allows them to pass if the promo covered the gap)
                if (userPrincipalPayment < userRequiredDownPayment) {
                     if (userPrincipalPayment + promoAppliedAmount < userRequiredDownPayment) {
                        throw `Security Violation: Your down payment of ₦${userPrincipalPayment.toLocaleString()} is below the required minimum of ₦${userRequiredDownPayment.toLocaleString()}.`;
                     }
                }

                if (walletBalance < walletUsed) {
                    throw `Insufficient wallet balance. Fee: ₦${processingFee.toLocaleString()}. Deposit: ₦${cashPrincipalNeeded.toLocaleString()}. Total needed: ₦${walletUsed.toLocaleString()}.`;
                }

                console.log(` - Payment Mode: ${isFullPayment ? "FULL" : isAbove30k ? "INSTALLMENT >30k" : "INSTALLMENT ≤30k"}`);
                console.log(` - Price: ₦${price.toLocaleString()} | Above 30k: ${isAbove30k}`);
                console.log(` - Amount Received: ₦${amount.toLocaleString()}`);
                console.log(` - Cash Principal: ₦${cashPrincipalNeeded.toLocaleString()}`);
                console.log(` - Credit Used: ₦${creditUsed.toLocaleString()}`);
                console.log(` - Processing Fee: ₦${processingFee.toLocaleString()}`);
                console.log(` - Wallet Deducted: ₦${walletUsed.toLocaleString()}`);

                const newPlanRef = db.collection('plans').doc();
                const planId = newPlanRef.id;

                // ✅ FIX: Dust Tolerance for Immediate Completion
                let remainingOnCreate = to2DP(price - userPrincipalPayment - promoAppliedAmount);
                let isFinished = false;
                let pickupCode = null;

                // If remaining is less than 1 Naira, treat as fully paid immediately
                if (remainingOnCreate < 1.0) {
                    isFinished = true;
                    remainingOnCreate = 0;
                    // Generate PIN immediately if paid in full at start
                    pickupCode = Math.floor(1000 + Math.random() * 9000).toString();
                } else {
                    isFinished = false;
                }

                // ---------------------------------------------------------
                // 📅 PROCESS NEXT DUE DATE
                // ---------------------------------------------------------
                const parseFirestoreDate = (val: any) => {
                    if (!val) return new Date();
                    return (typeof val.toDate === 'function') ? val.toDate() : new Date(val);
                };

                const rightNow = new Date();
               let newNextDueDate = new Date();

                // Determine Cadence
                let addDays = 7; // Default Monthly
                if (planData.cadenceType === 'weekly') addDays = 7;
                if (planData.cadenceType === 'daily') addDays = 1;
                if (planData.cadenceType === 'bi-weekly') addDays = 14;
                if (planData.cadenceType === 'flexible') addDays = 14;
                if (planData.cadenceType === 'monthly') addDays = 30;
                
                // Add the days to today's date
                newNextDueDate.setDate(newNextDueDate.getDate() + addDays);

                // Ensure it doesn't push past the absolute final deadline
                const finalExpiry = new Date(planData.planExpiryDate);

                if (newNextDueDate > finalExpiry) {
                    // ✅ Set to 3 days before the expiry date
                    newNextDueDate = new Date(finalExpiry);
                    newNextDueDate.setDate(newNextDueDate.getDate() - 3);
                    
                    // Safety check: If 3 days before expiry is somehow in the past, 
                    // just use the final expiry date so we don't accidentally make them overdue.
                    if (newNextDueDate <= rightNow) {
                        newNextDueDate = finalExpiry;
                    }
                }

                // 1. Create Plan
                t.set(newPlanRef, {
                    ...planData,
                    // One plan = one unit of one variant; stamped from the
                    // verified token so cancel/expiry can restore that exact
                    // variant's stock later.
                    ...(tokenVariant ? { variantLabel: tokenVariant } : {}),
                    id: planId,
                    productId: productId,
                    vendorId: vendorId,
                    status: isFinished ? 'completed' : 'active',
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    modelType: planData.modelType || 'direct',
                    totalAmount: price,
                    amountPaid: userPrincipalPayment + promoAppliedAmount,
                    processingFee: processingFee,
                    initialDownPayment: userRequiredDownPayment,
                    loanAmount: remainingOnCreate,
                    outstandingLoanAmount: remainingOnCreate,
                    promoApplied: promoAppliedAmount,
                    pickupCode: pickupCode,
                    nextDueDate: isFinished ? null : admin.firestore.Timestamp.fromDate(newNextDueDate),
                    completedAt: isFinished ? admin.firestore.FieldValue.serverTimestamp() : null,
                    // ✅ Fee mode — tells PAY_INSTALLMENT how to charge future payments
                    feeMode: isFullPayment ? 'completed' : (isAbove30k ? 'per_payment' : 'upfront'),
                });

                // 2. Ledger
                const ledgerRef = db.collection('customers').doc(customerUid).collection('ledger_transactions').doc();
                
                // ✅ CONSTRUCT RECEIPT DATA FOR CREATE
                const appliedToItemCreate = to2DP(userPrincipalPayment + promoAppliedAmount); // Full principal goes to plan
                const receiptPayload = {
                    reference: ledgerRef.id,
                    date: new Date().toISOString(),
                    vendorName: planData.storeName || 'Store',
                    customerName: planData.customerName,
                    productName: product.name,
                    productCode: product.productCode || "",
                    totalValue: price,
                    amountPaidSoFar: appliedToItemCreate,
                    amountPaidNow: userPrincipalPayment,
                    paymentMethod: creditUsed > 0 ? (walletUsed > 0 ? "Mixed (Store Balance + Wallet)" : "Store Balance") : "Wallet Transfer",
                    balanceRemaining: remainingOnCreate,
                    status: isFinished ? "COMPLETED" : "IN PROGRESS",
                    isFinished: isFinished,
                    creditUsed: creditUsed,
                    walletUsed: walletUsed,
                    // ✅ FEE BREAKDOWN
                    feeAmount: processingFee,
                    cashFeeAmount: feeCashPart,
                    storeFeeAmount: feeCreditPart,
                    appliedToItem: appliedToItemCreate,
                    totalWalletDeducted: walletUsed,
                    nextDueDate: !isFinished ? newNextDueDate.toISOString() : null
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

                // ---------------------------------------------------------
                // 🧾 2b. SEPARATE PROMO LEDGER & RECEIPT
                // ---------------------------------------------------------
                if (promoAppliedAmount > 0) {
                    const promoLedgerRef = db.collection('customers').doc(customerUid).collection('ledger_transactions').doc();
                    
                    // Format a secondary receipt strictly for the bonus so the UI parses it cleanly
                    const promoReceiptPayload = {
                        reference: `PROMO-${planId.substring(0, 5)}`,
                        date: new Date().toISOString(),
                        vendorName: planData.storeName || 'Store',
                        customerName: planData.customerName,
                        productName: product.name,
                        productCode: product.productCode || "",
                        totalValue: price,
                        amountPaidSoFar: to2DP(userPrincipalPayment + promoAppliedAmount),
                        amountPaidNow: promoAppliedAmount,
                        paymentMethod: "Korra Sponsored Bonus", // Appears on receipt UI
                        balanceRemaining: remainingOnCreate,
                        status: "COMPLETED", 
                        isFinished: isFinished,
                        creditUsed: 0,
                        walletUsed: 0,
                        feeAmount: 0,
                        cashFeeAmount: 0,
                        storeFeeAmount: 0,
                        appliedToItem: promoAppliedAmount,
                        totalWalletDeducted: 0,
                        nextDueDate: !isFinished ? newNextDueDate.toISOString() : null
                    };

                    t.set(promoLedgerRef, {
                        id: promoLedgerRef.id,
                        customerId: customerUid,
                        amount: promoAppliedAmount, 
                        type: 'promo_credit', // UI will default to "System Transaction"
                        description: `Sponsored Bonus applied to ${product.name}`,
                        planId: planId,
                        reference: `PROMO-${planId.substring(0, 5)}`,
                        status: 'success',
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        metadata: { isPromo: true, promoValue: promoAppliedAmount },
                        receiptData: promoReceiptPayload 
                    });
                }

                // 3. Update Balance
                t.update(userRef, {
                    "monnify.availableBalance": admin.firestore.FieldValue.increment(-walletUsed)
                });
                
                // 4. Update Plan Count
                 if (isFinished) {
                    let upgradedTier = null;
                    const currentCompleted = statsData.completedPlansCount || 0;
                    const newCompletedCount = currentCompleted + 1;
                    
                    const currentTier = statsData.tier || 'Starter';
                    let newTier = currentTier;

                    if (newCompletedCount >= 25) newTier = 'VIP';
                    else if (newCompletedCount >= 10) newTier = 'Collector';
                    else if (newCompletedCount >= 3) newTier = 'Keeper';
                    
                    if (newTier !== currentTier) upgradedTier = newTier;

                    t.set(statsRef, {
                        activePlansCount: admin.firestore.FieldValue.increment(-1),
                        completedPlansCount: admin.firestore.FieldValue.increment(1),
                        tier: newTier, 
                        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                    }, { merge: true });

                    const now = new Date();
                    const currentMonth = now.toISOString().slice(0, 7);
                    const custMonthlyRef = db.collection('customers').doc(customerUid).collection('monthly_stats').doc(currentMonth);
                    
                    t.set(custMonthlyRef, {
                        month: currentMonth,
                        year: now.getFullYear().toString(),
                        completedCount: admin.firestore.FieldValue.increment(1),
                        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                    }, { merge: true });

                } else {
                    t.set(statsRef, {
                        activePlansCount: admin.firestore.FieldValue.increment(1),
                        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                    }, { merge: true });
                }

                // =======================================================================
                // 💸 VENDOR PAYOUT & LEDGER VISIBILITY (Escrow & Settlement Flow)
                // =======================================================================
                if (promoAppliedAmount > 0) {
                    const vendorPromoLedgerRef = db.collection('vendors').doc(vendorId).collection('ledger_transactions').doc();
                    const vendorStatsRef = db.collection('vendor_stats').doc(vendorId);

                    if (isFinished) {
                        // Plan is paid in full Day 1. Money is secured, but waits for settlement cron.
                        t.set(vendorPromoLedgerRef, {
                            id: vendorPromoLedgerRef.id, 
                            userId: vendorId, 
                            amount: promoAppliedAmount,
                            type: 'promo_credit', 
                            description: `Korra Sponsored Bonus: Completion reward for ${product.name}`,
                            reference: `PROMO-${planId.substring(0, 5)}`, 
                            planId: planId, 
                            status: 'success',           // 👈 Secured
                            settlementStatus: 'pending', // 👈 UI shows amber badge, Cron will pick it up
                            createdAt: admin.firestore.FieldValue.serverTimestamp()
                        });

                        // Deduct from company, add to vendor earnings (but not liquid yet)
                        const companyWalletRef = db.collection('company_wallet').doc('main');
                        t.update(companyWalletRef, { availableBalance: admin.firestore.FieldValue.increment(-promoAppliedAmount) });
                        t.update(vendorStatsRef, { totalEarnings: admin.firestore.FieldValue.increment(promoAppliedAmount) });
                        t.update(promoRef, { completedUses: admin.firestore.FieldValue.increment(1) });
                    } else {
                        // Plan is incomplete. Money is NOT secured yet.
                        t.set(vendorPromoLedgerRef, {
                            id: vendorPromoLedgerRef.id, 
                            userId: vendorId, 
                            amount: promoAppliedAmount,
                            type: 'promo_credit', 
                            description: `Pending Bonus for ${product.name} (Unlocks when customer completes plan)`,
                            reference: `PROMO-${planId.substring(0, 5)}`, 
                            planId: planId, 
                            status: 'pending',           // 👈 Not secured yet, Cron ignores it
                            settlementStatus: 'pending', // 👈 UI still shows the amber badge so they know it's coming
                            createdAt: admin.firestore.FieldValue.serverTimestamp()
                        });
                    }
                }

                // =======================================================================
                // 🎁 PROMO ACTIVITY LOGS (Vendor)
                // =======================================================================
                if (promoAppliedAmount > 0) {
                    // 1. Vendor Activity Feed
                    const vendorActivityRef = db.collection('vendors').doc(vendorId).collection('activity_feed').doc();
                    t.set(vendorActivityRef, {
                        id: vendorActivityRef.id,
                        type: 'system',
                        title: 'Promo Claimed 🏷️',
                        body: `${planData.customerName} applied your flash sale for ${product.name}. Korra covered ₦${promoAppliedAmount.toLocaleString()}.`,
                        ref_id: planId,
                        amount_display: `+₦${promoAppliedAmount.toLocaleString()}`,
                        date: admin.firestore.FieldValue.serverTimestamp(),
                        is_read: false
                    });
                }


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

                // 6b. VENDOR SIDE: Decrease Mirrored Store Credit
                const vendorBalanceRef = db.collection('vendors').doc(vendorId).collection('customer_balances').doc(customerUid);
                t.set(vendorBalanceRef, {
                    customerId: customerUid,
                    customerName: planData.customerName || "Customer",
                    storeCredit: admin.firestore.FieldValue.increment(-creditUsed),
                    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                }, { merge: true });

                // Stock: variant products deduct the chosen variant and keep
                // availableStock as the recomputed sum; flat products keep the
                // original blind decrement.
                if (createVariants.length > 0 && tokenVariant) {
                    const newVariants = createVariants.map((v: any) => {
                        const lbl = String(v?.label ?? '');
                        const stk = Math.floor(Number(v?.stock ?? 0));
                        return { label: lbl, stock: lbl === tokenVariant ? Math.max(0, stk - 1) : stk };
                    });
                    const newTotal = newVariants.reduce((acc: number, v: any) => acc + v.stock, 0);
                    t.update(productRef, { variants: newVariants, availableStock: newTotal });
                } else {
                    t.update(productRef, { availableStock: admin.firestore.FieldValue.increment(-1) });
                }

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

                t.set(activityRef, {
                    id: activityRef.id,
                    type: 'payment',
                    title: 'Payment Received',
                    body: `${planData.customerName} paid ₦${userPrincipalPayment.toLocaleString()} for ${planData.title} (Pending Settlement)`,
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
                        description: `Initial payment for ${product.name} received from ${planData.customerName} (pending settlement)`,
                        reference: `SALE-${planId.substring(0, 6)}`,
                        planId: planId,
                        status: 'success',
                        releaseDate: null,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        customerName: planData.customerName,
                        grossAmount: cashPrincipal,
                        feeAmount: feeDeducted,
                        settlementStatus: 'pending'
                    });
                }

                // 🚀 KORRA PROFIT LEDGER (Our 3.5% Vendor Commission)
                const korraLedger1 = db.collection('company_ledger').doc();
                t.set(korraLedger1, {
                    id: korraLedger1.id,
                    type: 'credit',
                    category: 'vendor_commission',
                    amount: feeDeducted, 
                    description: `${PLATFORM_FEE_PERCENTAGE * 100}% fee on ${product.name}`,
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
                    storeCreditRedeemed: creditUsed > 0 ? admin.firestore.FieldValue.increment(creditUsed) : admin.firestore.FieldValue.increment(0), // 🚀 Track debt cleared this month
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
                    price: price,
                    pickupCode: pickupCode, // Return code if exists
                    promoAppliedAmount: promoAppliedAmount
                };
            });

            // NOTIFICATIONS
            // Calculate percentage and remaining from result
            const createPercent = Math.round((result.downPayment / result.price) * 100);
            const createRemaining = to2DP(result.price - result.downPayment);

            // 1. Notify Customer
            await sendFcm(
                customerUid,
                "Reservation Confirmed 🔒",
                `Your plan for ${result.productName} is now active. You are ${createPercent}% there — ₦${createRemaining.toLocaleString()} left to complete it.`,
                { type: "plan_detail", planId: result.planIdStr, image: result.productImage },
                'customers'
            );

            // 2. If paid in full immediately
            if (result.pickupCode) {
                await sendFcm(
                    customerUid,
                    "It's Yours! 🎉",
                    `You have fully paid for ${result.productName}. Your pickup PIN is: ${result.pickupCode}. Show this to the vendor to collect.`,
                    { type: "plan_detail", planId: result.planIdStr }
                );
            }

            // 3. Notify Vendor — percentage context not raw amount
            await sendFcm(
                result.vendorId,
                "New Reservation 📦",
                `${result.customerName} just started a plan for ${result.productName} and is ${createPercent}% done. Please reserve this item immediately.`,
                { type: "vendor_order", planId: result.planIdStr, image: result.productImage },
                'vendors'
            );

            // ==========================================================
            // 🎁 PROMO NOTIFICATIONS
            // ==========================================================
            if (result.promoAppliedAmount > 0) {
                // 1. Hype up the Customer
                await sendFcm(
                    customerUid,
                    "🎁 Bonus Applied!",
                    `Awesome! A Sponsored Bonus of ₦${result.promoAppliedAmount.toLocaleString()} was automatically deducted from your ${result.productName} balance.`,
                    { type: "plan_detail", planId: result.planIdStr },
                    'customers'
                );

                // 2. Notify the Vendor their campaign is working
                await sendFcm(
                    result.vendorId,
                    "🏷️ Promo Claimed!",
                    `${result.customerName} just used your flash sale to reserve ${result.productName}. Korra covered ₦${result.promoAppliedAmount.toLocaleString()} of their balance.`,
                    { type: "promo_dashboard", planId: result.planIdStr },
                    'vendors'
                );
            }

            // await sendFcm(
            //     result.vendorId,
            //     "Platform Fee 📉",
            //     `A platform fee of -₦${result.feeDeducted.toLocaleString()} was deducted for the new order.`,
            //     { type: "payment", planId: result.planIdStr },
            //     'vendors'
            // );

            return new Response(JSON.stringify({ status: "SUCCESS", planId: result.planIdStr }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
        }

        // =======================================================================
        // 💸 ACTION: PAY INSTALLMENT (FINAL BUSINESS LOGIC)
        // =======================================================================
        if (action === 'PAY_INSTALLMENT') {
            let paymentAmount = to2DP(Number(amount));
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

                const promoBonus = plan.promoApplied || 0;
                let pendingPromoSnapshot = null;
                if (promoBonus > 0) {
                    pendingPromoSnapshot = await t.get(
                        db.collection('vendors').doc(plan.vendorId)
                          .collection('ledger_transactions')
                          .where('planId', '==', planId)
                          .where('type', '==', 'promo_credit')
                          .where('status', '==', 'pending')
                          .limit(1)
                    );
                }

                // ==========================================
                // 🛡️ THE OVERPAYMENT INTERCEPTOR (WITH ₦7500 CAP)
                // ==========================================
                const remainingDebt = to2DP(plan.outstandingLoanAmount);
                const isPerPaymentFee = plan.totalAmount > PER_PAYMENT_THRESHOLD;

                // Calculate fee with the 7500 ceiling
                let estimatedFee = 0;
                if (isPerPaymentFee) {
                    const rawFee = to2DP(paymentAmount * CUSTOMER_FEE_RATE);
                    estimatedFee = rawFee > MAX_FEE ? MAX_FEE : rawFee;
                }

                const estimatedNetContribution = to2DP(paymentAmount - estimatedFee);

                if (estimatedNetContribution > remainingDebt) {
                    if (isPerPaymentFee) {
                        // If the fee at 3.5% would exceed 7500, we just add flat 7500 to the debt.
                        // Otherwise, we use the percentage formula.
                        const uncappedGross = remainingDebt / (1 - CUSTOMER_FEE_RATE);
                        if (uncappedGross - remainingDebt > MAX_FEE) {
                            paymentAmount = remainingDebt + MAX_FEE;
                        } else {
                            paymentAmount = Math.ceil(uncappedGross);
                        }
                    } else {
                        paymentAmount = remainingDebt;
                    }
                    console.log(`🛡️ Intercepted Overpayment. Shrunk capped payment down to: ₦${paymentAmount}`);
                }
                // ==========================================
                
                // ✅ MONEY
                const walletBalance = to2DP_Floor(userData.monnify?.availableBalance || 0);
                const vendorId = plan.vendorId;

                const complianceRef = db.collection('vendor_compliance').doc(vendorId);
                const complianceDoc = await t.get(complianceRef);
                if (complianceDoc.exists) {
                    const compData = complianceDoc.data();
                    const isExplicitlyBlocked = compData.blockPayments === true;
                    const status = compData.status;

                    if (isExplicitlyBlocked || status === 'suspended' || status === 'banned') {
                        throw "Transactions paused due to a trust and compliance issue. This store is currently flagged for violating Korra's operational terms. All payments to this store are blocked until the merchant resolves the restrictions on their portal.";
                    }
                }

                // ✅ VENDOR RELATION
                const { ref: vendorRelRef, data: vendorRel } = await getVendorRelation(customerUid, vendorId);
                const availableStoreCredit = to2DP_Floor(vendorRel.storeCredit || 0);

                // --- FINANCIAL MATH ---
                // Store balance is ALWAYS used first
                let creditUsed = 0;
                let walletUsed = 0;

                if (availableStoreCredit >= paymentAmount) {
                    creditUsed = paymentAmount;
                    walletUsed = 0;
                } else {
                    creditUsed = availableStoreCredit;
                    walletUsed = to2DP(paymentAmount - creditUsed);
                }

                // Store balance fee — charged from wallet, minimum ₦100
                let storeFeeAmount = 0;
                if (isPerPaymentFee && creditUsed > 0) {
                    const rawStoreFee = to2DP(creditUsed * STORE_FEE_RATE);
                    storeFeeAmount = rawStoreFee < MIN_STORE_FEE ? MIN_STORE_FEE : rawStoreFee;
                }

                // Cash fee — capped at ₦7500 maximum
                let cashFeeAmount = 0;
                if (isPerPaymentFee && walletUsed > 0) {
                    const rawCashFee = to2DP(walletUsed * CUSTOMER_FEE_RATE);
                    cashFeeAmount = rawCashFee > MAX_FEE ? MAX_FEE : rawCashFee;
                }

                const totalFeeAmount = to2DP(storeFeeAmount + cashFeeAmount);

                // Applied to item = store credit (full) + cash minus cash fee
                const appliedToItem = to2DP((creditUsed) + (walletUsed - cashFeeAmount));

                // Total wallet deducted = cash portion + store balance fee
                const totalWalletDeducted = to2DP(walletUsed + storeFeeAmount);

                // ✅ WALLET VALIDATION — must have enough for cash portion + store balance fee
                const requiredFromWallet = totalWalletDeducted;
                if (walletBalance < requiredFromWallet) {
                    if (creditUsed > 0 && walletBalance < storeFeeAmount) {
                        throw `Insufficient wallet balance to cover store balance fee. You need at least ₦${storeFeeAmount.toLocaleString()} in your wallet to use store balance.`;
                    }
                    throw `Insufficient funds. Needed: ₦${requiredFromWallet.toLocaleString()}, Available: ₦${walletBalance.toLocaleString()}`;
                }

                // ✅ 1. STRICT DUST CLEARING LOGIC
                let newAmountPaid = to2DP(plan.amountPaid + appliedToItem);
                
                // 🎯 THE FIX: Calculate remaining balance directly from the outstanding debt!
                // This ignores UI fee-calculation mistakes and Store Balance drift.
                let remainingBalance = to2DP(plan.outstandingLoanAmount - appliedToItem);
                let isFinished = false;
                let pickupCode = null;

                console.log(`🔎 DEBUG: Total: ${plan.totalAmount}, Paid: ${newAmountPaid}, Remaining: ${remainingBalance}`);

                // 🎯 CHANGED: Tolerance is now strictly less than 100 Naira (e.g. 0.99 clears, 100.00 does not)
                if (remainingBalance < 1.0) {
                    isFinished = true;
                    newAmountPaid = plan.totalAmount; 
                    remainingBalance = 0;
                    
                    // 🔐 GENERATE PICKUP PIN
                    pickupCode = Math.floor(1000 + Math.random() * 9000).toString();
                } else {
                    isFinished = false;
                }

                // ---------------------------------------------------------
                // 📅 CALCULATE NEW NEXT DUE DATE (Milestone Goalpost)
                // ---------------------------------------------------------
                // Helper to safely read Firestore Timestamps
                const parseFirestoreDate = (val: any) => {
                    if (!val) return new Date();
                    return (typeof val.toDate === 'function') ? val.toDate() : new Date(val);
                };

                let newNextDueDate = parseFirestoreDate(plan.nextDueDate);
                const rightNow = new Date();

                // Determine Cadence
                let addDays = 7; // Default Monthly
                if (plan.cadenceType === 'weekly') addDays = 7;
                if (plan.cadenceType === 'daily') addDays = 1;
                if (plan.cadenceType === 'bi-weekly') addDays = 14;
                if (plan.cadenceType === 'flexible') addDays = 14;
                if (plan.cadenceType === 'monthly') addDays = 30;
 
                // Roll the date forward until it is in the future
                while (newNextDueDate <= rightNow) {
                    newNextDueDate.setDate(newNextDueDate.getDate() + addDays);
                }

                // Ensure it doesn't push past the absolute final deadline
                const finalExpiry = new Date(plan.planExpiryDate);
                if (newNextDueDate > finalExpiry) {
                    // ✅ Set to 3 days before the expiry date
                    newNextDueDate = new Date(finalExpiry);
                    newNextDueDate.setDate(newNextDueDate.getDate() - 3);
                    
                    // Safety check: If 3 days before expiry is somehow in the past, 
                    // just use the final expiry date so we don't accidentally make them overdue.
                    if (newNextDueDate <= rightNow) {
                        newNextDueDate = finalExpiry;
                    }
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
                    nextDueDate: isFinished ? null : admin.firestore.Timestamp.fromDate(newNextDueDate),
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
                    // ✅ FEE BREAKDOWN
                    feeAmount: totalFeeAmount,
                    cashFeeAmount: cashFeeAmount,
                    storeFeeAmount: storeFeeAmount,
                    appliedToItem: appliedToItem,
                    totalWalletDeducted: totalWalletDeducted,
                    // ✅ SAFE DATE HELPER
                    nextDueDate: !isFinished ? newNextDueDate.toISOString() : null
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
                    metadata: { 
                        paidWithWallet: walletUsed, 
                        paidWithCredit: creditUsed, 
                        vendorName: plan.storeName,
                        feeAmount: totalFeeAmount,
                        cashFeeAmount: cashFeeAmount,
                        storeFeeAmount: storeFeeAmount,
                        appliedToItem: appliedToItem,
                        totalWalletDeducted: totalWalletDeducted
                    },
                    receiptData: receiptPayload
                });

                // Deduct total wallet amount (cash portion + store balance fee)
                if (totalWalletDeducted > 0) {
                    t.update(userRef, {
                        "monnify.availableBalance": admin.firestore.FieldValue.increment(-totalWalletDeducted)
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

                    // =======================================================================
                    // 💸 VENDOR PAYOUT: Unlock Pending Promo Funds on Completion
                    // =======================================================================

                    if (promoBonus > 0) {
                        // 🎯 THE FIX: Use the snapshot we fetched at the top of the file!
                        if (pendingPromoSnapshot && !pendingPromoSnapshot.empty) {
                            const pendingDoc = pendingPromoSnapshot.docs[0];
                            
                            // 1. Flip it to success and tag it for the cron job!
                            t.update(pendingDoc.ref, {
                                status: 'success',
                                settlementStatus: 'pending', 
                                description: `Korra Bonus Unlocked: Completion reward for ${plan.title || 'item'}`,
                                updatedAt: admin.firestore.FieldValue.serverTimestamp()
                            });

                            // 2. Transfer the liability from Korra to Vendor Earnings
                            const companyWalletRef = db.collection('company_wallet').doc('main');
                            t.update(companyWalletRef, { availableBalance: admin.firestore.FieldValue.increment(-promoBonus) });

                            t.update(db.collection('vendor_stats').doc(vendorId), { 
                                totalEarnings: admin.firestore.FieldValue.increment(promoBonus) 
                            });
                            
                            // 3. Mark campaign success
                            const promoRefForCompletion = db.collection('promos').doc(vendorId);
                            t.update(promoRefForCompletion, { 
                                completedUses: admin.firestore.FieldValue.increment(1) 
                            });

                            console.log(`💸 Pending Promo Bonus of ₦${promoBonus} unlocked for vendor ${vendorId}`);
                        }
                    }
                    // =======================================================================
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

                // 📝 4b. VENDOR SIDE: Decrease Mirrored Store Credit
                const vendorBalanceRef = db.collection('vendors').doc(vendorId).collection('customer_balances').doc(customerUid);
                t.set(vendorBalanceRef, {
                    customerId: customerUid,
                    customerName: plan.customerName || "Customer",
                    storeCredit: admin.firestore.FieldValue.increment(-creditUsed),
                    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                }, { merge: true });

                // ---------------------------------------------------------
                // 📝 5. ACTIVITY FEED & VENDOR FINANCIALS
                // ---------------------------------------------------------
                const activityRef = db.collection('vendors').doc(vendorId).collection('activity_feed').doc();
                t.set(activityRef, {
                    id: activityRef.id,
                    type: 'payment',
                    title: 'Payment Received',
                    body: `${plan.customerName} paid ₦${paymentAmount.toLocaleString()} for ${plan.title} (Pending Settlement)`,
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
                const vendorFeeRate = PLATFORM_FEE_PERCENTAGE; // 3.5% fee
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
                        description: `${plan.customerName} paid ₦${paymentAmount.toLocaleString()} for ${plan.title} (pending settlement, minus ${PLATFORM_FEE_PERCENTAGE * 100}% fee)`,
                        reference: txRefId,
                        planId: planId,
                        status: 'success',
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        customerName: plan.customerName,
                        grossAmount: walletUsed,
                        feeAmount: feeDeducted,
                        settlementStatus: 'pending'
                    });

                    const korraLedger = db.collection('company_ledger').doc();
                    t.set(korraLedger, {
                        id: korraLedger.id,
                        type: 'credit',
                        category: 'vendor_commission',
                        amount: feeDeducted, 
                        description: `${PLATFORM_FEE_PERCENTAGE * 100}% fee on installment for ${plan.title}`,
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
                const monthlyRef = db.collection('vendors').doc(vendorId)
                                        .collection('monthly_stats').doc(currentMonthStr);
                
                t.set(monthlyRef, {
                    month: currentMonthStr,
                    year: currentYearStr,
                    earnings: admin.firestore.FieldValue.increment(vendorNet),
                    storeCreditRedeemed: creditUsed > 0 ? admin.firestore.FieldValue.increment(creditUsed) : admin.firestore.FieldValue.increment(0),
                    [`daily_breakdown.${currentDayStr}`]: admin.firestore.FieldValue.increment(vendorNet),
                    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                }, { merge: true });

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
            
            // Calculate percentage for smart notifications
            const totalAmount = result.receiptData.totalValue;
            const amountPaidSoFar = result.receiptData.amountPaidSoFar;
            const remaining = result.receiptData.balanceRemaining;
            const percentPaid = Math.round((amountPaidSoFar / totalAmount) * 100);
            const productName = result.receiptData.productName;
            const customerName = result.receiptData.customerName;
            const vendorId = result.receiptData.vendorId;

            // 1. Notify Customer progress focused
            let customerMessage = `You're ${percentPaid}% done on ${productName}. ₦${remaining.toLocaleString()} left keep going!`;

            // Milestone messages
            if (percentPaid >= 90 && percentPaid < 100) {
                customerMessage = `So close! You're 90% done on ${productName}. Just ₦${remaining.toLocaleString()} left finish strong! 💪`;
            } else if (percentPaid >= 75 && percentPaid < 90) {
                customerMessage = `Almost there! 75% paid on ${productName}. Only ₦${remaining.toLocaleString()} remaining.`;
            } else if (percentPaid >= 50 && percentPaid < 75) {
                customerMessage = `Halfway there! You're 50% done on ${productName}. ₦${remaining.toLocaleString()} left to go.`;
            }

            await sendFcm(
                customerUid,
                "Payment Confirmed ✅",
                customerMessage,
                { type: "plan_detail", planId: planId }
            );

            // 2. Notify Vendor percentage + remaining, not raw amount
            await sendFcm(
                vendorId,
                "Payment Received 💰",
                `${customerName} is now ${percentPaid}% done on ${productName}. ₦${remaining.toLocaleString()} remaining.`,
                { type: "vendor_order", planId: planId },
                'vendors'
            );

            // 3. Notify on completion
            if (result.receiptData.isFinished) {
                await sendFcm(
                    vendorId,
                    "Plan Completed! 🎉",
                    `${customerName} has fully paid for ${productName}. Ready for pickup confirm collection when done.`,
                    { type: "vendor_order", planId: planId },
                    'vendors'
                );

                if (result.pickupCode) {
                    await sendFcm(
                        customerUid,
                        "It's Yours! 🎉",
                        `You've completed payment for ${productName}. Your pickup PIN is: ${result.pickupCode}. Show this to the vendor to collect.`,
                        { type: "plan_detail", planId: planId }
                    );
                }
            }

            // 4. Tier upgrade notification
            if (result.upgradedTier) {
                await sendFcm(
                    customerUid,
                    "Level Up! 🌟",
                    `You've been upgraded to ${result.upgradedTier} tier. Enjoy your new perks and extra plan slots!`,
                    { type: "home" }
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

            const result = await db.runTransaction(async (t: any) => {
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
            );

            // To Vendor
            await sendFcm(
                result.vendorId,
                "Reservation Update ⏳",
                `Timeline extended by ${result.daysAdded} days for ${result.productName}. Order remains active.`,
                // 👇 Add image to data payload
                { type: "vendor_order", planId: planId, image: result.productImage }, 
                'vendors',
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
                // ==========================================
                // 🔍 PHASE 1: ALL READS FIRST (No Writes Allowed Yet)
                // ==========================================
                const planRef = db.collection("plans").doc(planId);
                const planDoc = await t.get(planRef);

                if (!planDoc.exists) throw "Plan not found.";
                const plan = planDoc.data();

                // Security Checks
                if (plan.customerId !== customerUid) throw "Unauthorized.";
                if (plan.status !== 'active') throw "Plan is not active.";

                const vendorId = plan.vendorId;

                // Pre-fetch User Stats
                const { statsRef } = await getUserAndStats(customerUid);

                // Pre-fetch the product when a variant must be restored
                // (reads are only allowed in this phase of the transaction).
                let productSnapForRestore: any = null;
                if (plan.productId && plan.variantLabel) {
                    productSnapForRestore = await t.get(db.collection("products").doc(plan.productId));
                }

                // Pre-fetch Promo Ledger (if applicable)
                const promoBonus = plan.promoApplied || 0;
                let promoLedgerSnapshot = null;
                
                if (promoBonus > 0) {
                    promoLedgerSnapshot = await t.get(
                        db.collection('vendors').doc(vendorId)
                          .collection('ledger_transactions')
                          .where('planId', '==', planId)
                          .where('type', '==', 'promo_credit')
                          .where('status', '==', 'pending') // Only cancel if it was still pending
                          .limit(1)
                    );
                }

                // ==========================================
                // 📝 PHASE 2: ALL WRITES (No Reads Allowed Below Here)
                // ==========================================
                
                // 🛡️ THE PROMO MATH: Customer only gets their CASH back, not the bonus
                const refundAmount = to2DP_Floor(plan.amountPaid - promoBonus);

                // 3. UPDATE PLAN: Mark Cancelled
                t.update(planRef, {
                    status: 'cancelled',
                    cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
                    refundAmount: refundAmount,
                    penaltyAmount: 0, // No penalty applied
                    cancellationReason: 'Converted to Store Balance',
                    outstandingLoanAmount: 0
                });

                // 4. CUSTOMER SIDE: Increase Store Credit
                const relRef = db.collection('customers').doc(customerUid).collection('my_vendors').doc(vendorId);
                t.set(relRef, {
                    vendorId: vendorId,
                    storeName: plan.storeName || 'Store',
                    storeCredit: admin.firestore.FieldValue.increment(refundAmount),
                    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                }, { merge: true });

                const vendorBalanceRef = db.collection('vendors').doc(vendorId).collection('customer_balances').doc(customerUid);
                t.set(vendorBalanceRef, {
                    customerId: customerUid,
                    customerName: plan.customerName || "Customer",
                    storeCredit: admin.firestore.FieldValue.increment(refundAmount),
                    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                }, { merge: true });

                // =======================================================================
                // 🛑 REVOKE PROMO (Don't let the Cron Job settle this!)
                // =======================================================================
                if (promoLedgerSnapshot && !promoLedgerSnapshot.empty) {
                    t.update(promoLedgerSnapshot.docs[0].ref, { 
                        status: 'cancelled',
                        settlementStatus: 'cancelled', // 👈 THE FIX: Clears the Amber Badge for the Merchant
                        description: `Promo revoked: Plan cancelled by customer.`,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                    console.log(`🛑 Promo funds revoked for cancelled plan ${planId}`);
                }
                // =======================================================================

                // 5. CUSTOMER SIDE: Stats & Ledger
                const now = new Date();
                const parseFirestoreDate = (val: any) => {
                    if (!val) return new Date();
                    return (typeof val.toDate === 'function') ? val.toDate() : new Date(val);
                };
                const expiryDate = parseFirestoreDate(plan.planExpiryDate);
                
                // Set both to midnight to strictly compare the days
                now.setHours(0, 0, 0, 0);
                expiryDate.setHours(0, 0, 0, 0);
                
                // If today is past or equal to the expiry date, it's an expiry strike
                const isExpired = now.getTime() >= expiryDate.getTime();

                if (isExpired) {
                    t.set(statsRef, {
                        activePlansCount: admin.firestore.FieldValue.increment(-1),
                        cancelledPlansCount: admin.firestore.FieldValue.increment(1),
                        expiredPlansCount: admin.firestore.FieldValue.increment(1), // Strike against customer
                        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                    }, { merge: true });
                } else {
                    t.set(statsRef, {
                        activePlansCount: admin.firestore.FieldValue.increment(-1),
                        cancelledPlansCount: admin.firestore.FieldValue.increment(1),
                        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                    }, { merge: true });
                }
                
                const currentMonth = now.toISOString().slice(0, 7); // e.g. "2026-02"
                const custMonthlyRef = db.collection('customers').doc(customerUid)
                                                .collection('monthly_stats').doc(currentMonth);
                    
                t.set(custMonthlyRef, {
                    month: currentMonth,
                    year: now.getFullYear().toString(),
                    closedCount: admin.firestore.FieldValue.increment(1),
                    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                }, { merge: true });

                // Log Transaction for Customer
                const ledgerRef = db.collection('customers').doc(customerUid).collection('ledger_transactions').doc();
                t.set(ledgerRef, {
                    id: ledgerRef.id,
                    customerId: customerUid,
                    amount: 0, // No cash returned to liquid wallet
                    type: 'plan_cancelled',
                    reference: ledgerRef.id,
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
                    type: 'conversion', 
                    description: `Plan Closed: ${plan.customerName}`,
                    planId: planId,
                    status: 'success',
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });

                // Update Vendor Stats
                t.update(vendorStatsRef, {
                    totalLiability: admin.firestore.FieldValue.increment(refundAmount),
                    activePlansCount: admin.firestore.FieldValue.increment(-1),
                });

                const currentMonthStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
                
                // UPDATE MONTHLY ANALYTICS
                const monthlyRef = db.collection('vendors').doc(vendorId).collection('monthly_stats').doc(currentMonthStr);
                t.set(monthlyRef, {
                    month: currentMonthStr,
                    year: now.getFullYear().toString(),
                    storeCreditIssued: admin.firestore.FieldValue.increment(refundAmount), 
                    cancelledPlansCount: admin.firestore.FieldValue.increment(1),
                    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                }, { merge: true });

                // Release Stock: restore the exact variant the plan reserved;
                // if the variant (or the product's variants) no longer exists,
                // fall back to the classic total-only +1.
                if (plan.productId) {
                    const productRef = db.collection("products").doc(plan.productId);
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
                }

                // 7. Activity Feed for Vendor
                const activityRef = db.collection('vendors').doc(vendorId).collection('activity_feed').doc();
                t.set(activityRef, {
                    id: activityRef.id,
                    type: 'reservation_cancel',
                    title: 'Plan Closed',
                    // 👈 THE FIX: Appends "Promo bonus revoked." to the body text if a promo was used
                    body: `${plan.customerName} closed ${plan.title || 'item'}. Refund secured in Store Balance.${promoBonus > 0 ? ' Promo bonus revoked.' : ''}`,
                    ref_id: planId,
                    amount_display: `+₦${refundAmount.toLocaleString()} Credit`,
                    date: admin.firestore.FieldValue.serverTimestamp(),
                    is_read: false
                });

                // Return everything needed for Notifications
                return { 
                    status: "SUCCESS", 
                    refundAmount: refundAmount,
                    storeName: plan.storeName,
                    vendorId: vendorId,
                    productName: plan.title || "Product",
                    promoBonus: promoBonus // 👈 CRITICAL: Exposes the bonus amount to the Notification code below
                };
            });

            // =======================================================================
            // 8. NOTIFICATIONS
            // =======================================================================
            
            // To Customer
            await sendFcm(
                customerUid, 
                "Refund Secured 🔒",
                // 👈 THE FIX: Appends "(Bonus revoked)" dynamically based on the returned promoBonus
                `Your ₦${result.refundAmount.toLocaleString()} is now available in your Store Balance at ${result.storeName}.${result.promoBonus > 0 ? ' (Bonus revoked)' : ''}`, 
                { type: "plan_detail", planId: planId }
            );

            // To Vendor
            await sendFcm(
                result.vendorId,
                "Plan Closed 📁",
                // 👈 THE FIX: Appends "Promo bonus revoked." dynamically
                `Customer closed the plan for ${result.productName}. Refund secured in their Store Balance.${result.promoBonus > 0 ? ' Promo bonus revoked.' : ''}`,
                { type: "vendor_order", planId: planId },
                'vendors'
            );

            return new Response(JSON.stringify(result), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
        }

        // =======================================================================
        // 🤝 ACTION: BULK FULFILL
        // =======================================================================
        if (action === 'BULK_FULFILL') {
            if (!vendorUid || !planIds || !Array.isArray(planIds) || planIds.length === 0) {
                throw "Missing or invalid fields: vendorUid or planIds must be a non-empty array.";
            }

            const batch = db.batch();

            // Loop through all selected plans and stamp them as fulfilled
            for (const id of planIds) {
                const planRef = db.collection("plans").doc(id);
                batch.update(planRef, {
                    finalFulfilledAt: admin.firestore.FieldValue.serverTimestamp(), // ✅ Updated
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }

            // Create ONE activity log for the bulk action (prevents spamming the feed)
            const activityRef = db.collection('vendors').doc(vendorUid).collection('activity_feed').doc();
            batch.set(activityRef, {
                id: activityRef.id,
                type: 'bulk_fulfilled',
                title: 'Orders Fulfilled',
                body: `Marked ${planIds.length} items as fulfilled.`,
                ref_id: 'bulk', 
                amount_display: null, 
                date: admin.firestore.FieldValue.serverTimestamp(),
                is_read: false
            });

            await batch.commit();

            return new Response(JSON.stringify({ success: true, count: planIds.length }), 
                { headers: { ...corsHeaders, "Content-Type": "application/json" } });
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