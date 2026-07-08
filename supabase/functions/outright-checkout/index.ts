// outright-checkout
//
// Customer pays IN FULL for a cart of products from one store (no plan).
// Records everything the same shape as plan-manager PAY_INSTALLMENT so the
// existing receipt/statement UIs keep working, and creates one `orders` doc
// the vendor Outright Orders screen already reads.
//
// FEE RULE (David):
//   vendors/{id}.store.absorbOutrightFee == true  -> merchant absorbs the fee
//     (customer pays subtotal; fee comes out of the vendor's take)
//   false/missing -> customer pays the fee on top (3.5% of subtotal, max ₦7,500)
//
// Payment split: the customer's store balance at this merchant is ALWAYS
// consumed first; the wallet covers the remainder.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, firebase-token, x-korra-timestamp, x-korra-signature',
};

const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

// ----- ROUNDING (identical to plan-manager) -----
// Charges round UP, balances round DOWN — dust beyond 4dp is ignored.
function to2DP(num: number): number {
  if (num === 0) return 0;
  return Math.ceil(Number((num * 100).toFixed(4))) / 100;
}
function to2DP_Floor(num: number): number {
  if (num === 0) return 0;
  return Math.floor(Number((num * 100).toFixed(4))) / 100;
}

// ----- FEE CONSTANTS (same economics as the cart sheet UI) -----
const OUTRIGHT_FEE_RATE = 0.035; // 3.5% of the subtotal
const MAX_FEE = 7500;            // fee ceiling

async function sendFcm(uid: string, title: string, body: string, data: any, collection = 'customers') {
  if (!uid) return;
  try {
    const userRef = db.collection(collection).doc(uid);
    const userDoc = await userRef.get();
    if (!userDoc.exists) return;

    await userRef.collection('notifications').add({
      title,
      body,
      type: data.type || 'system',
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      metadata: data,
    });

    const fcmToken = userDoc.data()?.fcmToken;
    if (fcmToken) {
      await admin.messaging().send({
        token: fcmToken,
        notification: { title, body },
        data,
      });
    }
  } catch (e) {
    console.error(`🔕 Notification failed for ${uid}:`, e);
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // =======================================================================
    // 🔐 LOCK 1: HMAC ANTI-FORGERY & ANTI-REPLAY (same as plan-manager)
    // =======================================================================
    const clientTimestamp = req.headers.get('x-korra-timestamp');
    const clientSignature = req.headers.get('x-korra-signature');
    const KORRA_SECRET = "7f8a9b2d4c6e1f3a5b7c9d0e2f4a6b8c1d3e5f7a9b0c2d4e6f8a1b3c5d7e9f0a";

    if (!clientTimestamp || !clientSignature) {
      throw new Error("Unauthorized: Missing security signatures.");
    }

    const now = Date.now();
    const requestTime = parseInt(clientTimestamp, 10);
    if (Math.abs(now - requestTime) > 120000) {
      throw new Error("Unauthorized: Request expired (Replay attack blocked).");
    }

    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      "raw",
      encoder.encode(KORRA_SECRET),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"],
    );
    const signatureBuffer = await crypto.subtle.sign("HMAC", key, encoder.encode(clientTimestamp));
    const hashArray = Array.from(new Uint8Array(signatureBuffer));
    const expectedServerSignature = hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
    if (clientSignature !== expectedServerSignature) {
      throw new Error("Unauthorized: Cryptographic signature mismatch.");
    }

    // =======================================================================
    // 🔐 LOCK 2: FIREBASE AUTH TOKEN
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
    } catch (_error) {
      throw new Error("Unauthorized Access: Token expired or invalid.");
    }

    const { vendorId, items } = await req.json();
    const customerUid = secureUid; // the token IS the identity — never trust a body uid

    if (!vendorId || typeof vendorId !== 'string') throw "Missing store.";
    if (!Array.isArray(items) || items.length === 0) throw "Your cart is empty.";
    if (items.length > 25) throw "Too many items in one checkout.";
    for (const it of items) {
      if (!it?.productId || typeof it.productId !== 'string') throw "Invalid cart item.";
      const qty = Number(it.quantity);
      if (!Number.isInteger(qty) || qty <= 0 || qty > 99) throw "Invalid item quantity.";
    }

    // =======================================================================
    // 💳 ATOMIC CHECKOUT
    // =======================================================================
    const result = await db.runTransaction(async (t) => {
      // --- READS (all before writes) ---
      const vendorRef = db.collection('vendors').doc(vendorId);
      const complianceRef = db.collection('vendor_compliance').doc(vendorId);
      const userRef = db.collection('customers').doc(customerUid);
      const relRef = userRef.collection('my_vendors').doc(vendorId);

      const [vendorDoc, complianceDoc, userDoc, relDoc] = await Promise.all([
        t.get(vendorRef), t.get(complianceRef), t.get(userRef), t.get(relRef),
      ]);

      if (!vendorDoc.exists) throw "Store not found.";
      if (!userDoc.exists) throw "Customer profile not found.";

      // 🛡️ COMPLIANCE GATE — identical rule to plan payments
      if (complianceDoc.exists) {
        const compData = complianceDoc.data()!;
        if (compData.blockPayments === true || compData.status === 'suspended' || compData.status === 'banned') {
          throw "Transactions paused due to a trust and compliance issue. This store is currently flagged for violating Korra's operational terms. All payments to this store are blocked until the merchant resolves the restrictions on their portal.";
        }
      }

      const vendorData = vendorDoc.data()!;
      const storeMap = vendorData.store ?? {};
      const storeName = storeMap.storeName ?? 'Merchant Store';
      const absorbOutrightFee = storeMap.absorbOutrightFee === true; // 🚩 THE MERCHANT FLAG

      const userData = userDoc.data()!;
      const customerName = `${userData.firstName ?? userData.name ?? 'Korra'} ${userData.lastName ?? 'Customer'}`.trim();
      const customerPhone = userData.phone ?? userData.phoneNumber ?? '';

      // --- PRODUCTS: server-side prices, never the client's ---
      const productRefs = items.map((it: any) => db.collection('products').doc(it.productId));
      const productDocs = await Promise.all(productRefs.map((r) => t.get(r)));

      let subtotal = 0;
      const orderItems: any[] = [];
      const stockUpdates: { ref: FirebaseFirestore.DocumentReference; qty: number }[] = [];

      for (let i = 0; i < items.length; i++) {
        const doc = productDocs[i];
        const qty = Number(items[i].quantity);
        if (!doc.exists) throw "One of the items is no longer available.";
        const p = doc.data()!;
        if (p.vendorId !== vendorId) throw "Cart items must all belong to this store.";
        if (p.status !== 'approved') throw `"${p.name}" is no longer available.`;

        const stock = Number(p.availableStock ?? 0);
        if (stock < qty) throw `Only ${stock} left of "${p.name}" — please adjust your cart.`;

        const unitPrice = to2DP(
          (p.discountedPrice != null && Number(p.discountedPrice) > 0)
            ? Number(p.discountedPrice)
            : Number(p.price ?? 0),
        );
        if (unitPrice <= 0) throw `"${p.name}" has an invalid price.`;

        subtotal = to2DP(subtotal + unitPrice * qty);
        orderItems.push({
          productId: doc.id,
          title: p.name ?? 'Product',
          imageUrl: Array.isArray(p.images) && p.images.length > 0 ? p.images[0] : '',
          quantity: qty,
          unitPrice,
        });
        stockUpdates.push({ ref: doc.ref, qty });
      }

      // --- FEE (3.5% of subtotal, capped ₦7,500) ---
      let feeAmount = to2DP(subtotal * OUTRIGHT_FEE_RATE);
      if (feeAmount > MAX_FEE) feeAmount = MAX_FEE;

      // Who pays it: customer on top, or merchant out of their take.
      const customerTotal = absorbOutrightFee ? subtotal : to2DP(subtotal + feeAmount);

      // --- PAYMENT SPLIT: store balance first, wallet covers the rest ---
      const walletBalance = to2DP_Floor(userData.monnify?.availableBalance ?? 0);
      const relData = relDoc.exists ? relDoc.data()! : {};
      const availableStoreCredit = to2DP_Floor(relData.storeCredit ?? 0);

      let creditUsed = 0;
      let walletUsed = 0;
      if (availableStoreCredit >= customerTotal) {
        creditUsed = customerTotal;
      } else {
        creditUsed = availableStoreCredit;
        walletUsed = to2DP(customerTotal - creditUsed);
      }

      if (walletBalance < walletUsed) {
        throw `Insufficient funds. Needed: ₦${walletUsed.toLocaleString()}, Available: ₦${walletBalance.toLocaleString()}`;
      }

      // Vendor's take: gross entitlement minus the platform fee. The store
      // credit portion is money the vendor already holds (liability), so only
      // the wallet portion creates fresh earnings — mirror of plan-manager.
      // vendorNet can be negative when store credit covered nearly everything
      // and the merchant absorbs the fee; the increment handles that.
      const vendorNet = to2DP_Floor(walletUsed - feeAmount);

      // --- WRITES ---
      const orderRef = db.collection('orders').doc();
      const txRefId = `OUT-${orderRef.id.substring(0, 5)}-${Date.now().toString().slice(-4)}`;
      const nowDate = new Date();
      const currentDateStr = nowDate.toISOString().slice(0, 10);
      const currentMonthStr = nowDate.toISOString().slice(0, 7);
      const currentYearStr = nowDate.getFullYear().toString();
      const currentDayStr = nowDate.toISOString().slice(8, 10);

      // 1. Decrement stock
      for (const s of stockUpdates) {
        t.update(s.ref, { availableStock: admin.firestore.FieldValue.increment(-s.qty) });
      }

      // 2. The order doc (schema the vendor Outright Orders screen reads)
      const summaryTitle = orderItems.length === 1
        ? orderItems[0].title
        : `${orderItems[0].title} +${orderItems.length - 1} more`;

      t.set(orderRef, {
        vendorId,
        customerId: customerUid,
        customerName,
        customerPhone,
        totalAmount: subtotal,
        feeAmount,
        feePaidBy: absorbOutrightFee ? 'merchant' : 'customer',
        amountCharged: customerTotal,
        creditUsed,
        walletUsed,
        status: 'pending',
        reference: txRefId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        items: orderItems,
      });

      // 3. Customer ledger + receipt payload (same shape the receipt UI reads)
      const receiptPayload = {
        reference: txRefId,
        date: nowDate.toISOString(),
        vendorName: storeName,
        vendorId,
        customerName,
        customerPhone,
        productName: summaryTitle,
        productCode: orderItems[0].productId,
        totalValue: customerTotal,
        amountPaidSoFar: customerTotal,
        amountPaidNow: customerTotal,
        paymentMethod: creditUsed > 0 ? (walletUsed > 0 ? "Mixed (Store Balance + Wallet)" : "Store Balance") : "Wallet Transfer",
        balanceRemaining: 0,
        status: "COMPLETED",
        isFinished: true,
        creditUsed,
        walletUsed,
        feeAmount,
        cashFeeAmount: absorbOutrightFee ? 0 : feeAmount,
        storeFeeAmount: 0,
        appliedToItem: subtotal,
        totalWalletDeducted: walletUsed,
        nextDueDate: null,
        orderType: 'outright',
        items: orderItems,
      };

      const ledgerRef = userRef.collection('ledger_transactions').doc();
      t.set(ledgerRef, {
        id: ledgerRef.id,
        customerId: customerUid,
        amount: -customerTotal,
        type: 'outright_purchase',
        description: `Outright purchase: ${summaryTitle} from ${storeName}`,
        reference: txRefId,
        orderId: orderRef.id,
        status: 'success',
        balanceBefore: walletBalance,
        balanceAfter: to2DP_Floor(walletBalance - walletUsed),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          paidWithWallet: walletUsed,
          paidWithCredit: creditUsed,
          vendorName: storeName,
          feeAmount,
          feePaidBy: absorbOutrightFee ? 'merchant' : 'customer',
          appliedToItem: subtotal,
          totalWalletDeducted: walletUsed,
        },
        receiptData: receiptPayload,
      });

      // 4. Customer wallet
      if (walletUsed > 0) {
        t.update(userRef, {
          "monnify.availableBalance": admin.firestore.FieldValue.increment(-walletUsed),
        });
      }

      // 5. Store credit relation (both mirrors)
      t.set(relRef, {
        vendorId,
        storeName,
        lastInteraction: admin.firestore.FieldValue.serverTimestamp(),
        storeCredit: to2DP_Floor(availableStoreCredit - creditUsed),
      }, { merge: true });

      const vendorBalanceRef = vendorRef.collection('customer_balances').doc(customerUid);
      t.set(vendorBalanceRef, {
        customerId: customerUid,
        customerName,
        storeCredit: admin.firestore.FieldValue.increment(-creditUsed),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      // 6. Vendor ledger: sale for the fresh cash, redemption for credit
      const vendorStatsRef = db.collection('vendor_stats').doc(vendorId);

      const vLedgerRef = vendorRef.collection('ledger_transactions').doc();
      t.set(vLedgerRef, {
        id: vLedgerRef.id,
        userId: vendorId,
        amount: vendorNet,
        type: 'sale',
        description: `${customerName} bought ${summaryTitle} outright (₦${customerTotal.toLocaleString()}${absorbOutrightFee ? ", fee absorbed" : ""}, pending settlement)`,
        reference: txRefId,
        orderId: orderRef.id,
        status: 'success',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        customerName,
        grossAmount: walletUsed,
        feeAmount,
        settlementStatus: 'pending',
      });

      if (creditUsed > 0) {
        const vLiabRef = vendorRef.collection('liabilities').doc();
        t.set(vLiabRef, {
          id: vLiabRef.id,
          userId: vendorId,
          amount: -creditUsed,
          type: 'redemption',
          description: `Store Balance Used: ${customerName} (outright)`,
          status: 'success',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          orderId: orderRef.id,
        });
        t.set(vendorStatsRef, {
          totalLiability: admin.firestore.FieldValue.increment(-creditUsed),
        }, { merge: true });
      }

      t.set(vendorStatsRef, {
        totalEarnings: admin.firestore.FieldValue.increment(vendorNet),
        walletBalance: admin.firestore.FieldValue.increment(vendorNet),
      }, { merge: true });

      // 7. Korra's fee
      if (feeAmount > 0) {
        const korraLedger = db.collection('company_ledger').doc();
        t.set(korraLedger, {
          id: korraLedger.id,
          type: 'credit',
          category: 'outright_fee',
          amount: feeAmount,
          description: `${OUTRIGHT_FEE_RATE * 100}% outright fee (${absorbOutrightFee ? 'merchant absorbed' : 'customer paid'}) on ${summaryTitle}`,
          orderId: orderRef.id,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          dateStr: currentDateStr,
          monthStr: currentMonthStr,
          yearStr: currentYearStr,
        });
        const companyWalletRef = db.collection('company_wallet').doc('main');
        t.set(companyWalletRef, {
          availableBalance: admin.firestore.FieldValue.increment(feeAmount),
          totalAllTimeEarnings: admin.firestore.FieldValue.increment(feeAmount),
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      }

      // 8. Vendor activity feed + monthly analytics
      const activityRef = vendorRef.collection('activity_feed').doc();
      t.set(activityRef, {
        id: activityRef.id,
        type: 'payment',
        title: 'Outright Order Paid',
        body: `${customerName} paid ₦${customerTotal.toLocaleString()} outright for ${summaryTitle} (Pending Settlement)`,
        ref_id: orderRef.id,
        amount_display: `+₦${customerTotal.toLocaleString()}`,
        date: admin.firestore.FieldValue.serverTimestamp(),
        is_read: false,
      });

      const monthlyRef = vendorRef.collection('monthly_stats').doc(currentMonthStr);
      t.set(monthlyRef, {
        month: currentMonthStr,
        year: currentYearStr,
        earnings: admin.firestore.FieldValue.increment(vendorNet),
        storeCreditRedeemed: admin.firestore.FieldValue.increment(creditUsed),
        [`daily_breakdown.${currentDayStr}`]: admin.firestore.FieldValue.increment(vendorNet),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      return {
        orderId: orderRef.id,
        receiptData: receiptPayload,
        storeName,
        summaryTitle,
        customerTotal,
        customerName,
      };
    });

    // =======================================================================
    // 🔔 NOTIFICATIONS (outside the transaction)
    // =======================================================================
    // Customer notification is transactional — no vendorId in metadata so a
    // store mute never hides a payment confirmation.
    await sendFcm(
      customerUid,
      "Purchase Confirmed 🛍️",
      `You paid ₦${result.customerTotal.toLocaleString()} for ${result.summaryTitle} from ${result.storeName}. The store will prepare your order for delivery/pickup.`,
      { type: "payment", orderId: result.orderId },
    );

    await sendFcm(
      vendorId,
      "New Outright Order 📦",
      `${result.customerName} just bought ${result.summaryTitle} outright. Head to Orders to fulfil it.`,
      { type: "vendor_order", orderId: result.orderId },
      'vendors',
    );

    return new Response(
      JSON.stringify({ status: "SUCCESS", orderId: result.orderId, receiptData: result.receiptData }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error) {
    const message = typeof error === 'string' ? error : (error as Error)?.message ?? "Checkout failed.";
    console.error("❌ outright-checkout error:", error);
    return new Response(
      JSON.stringify({ status: "ERROR", error: message }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
