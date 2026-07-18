import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";
import {
  orderConfirmedEmail,
  orderFailedEmail,
  sendOrderEmail,
  WebOrderEmailData,
} from "../_shared/web_order_emails.ts";

// 1. SETUP FIREBASE ADMIN
const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
const MONNIFY_SECRET_KEY = Deno.env.get("MONNIFY_SECRET_KEY");

if (admin.apps.length === 0) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();
const messaging = admin.messaging();

// =========================================================================
// 🛍️ GUEST WEB PURCHASES (korra.com.ng storefront, no account)
//
// web-checkout `init` created the order with paymentStatus 'awaiting' and
// touched NOTHING else. This handler is the single place a web order becomes
// real money: verify amount, decrement stock, credit the merchant ledger as
// pending settlement (mirror of outright-checkout), write the dispute copy,
// notify the merchant, email the guest. Idempotent via paymentStatus.
// =========================================================================
const WEB_FEE_RATE = 0.035;

async function handleWebOutrightPurchase(eventType: string, eventData: any): Promise<Response> {
  const orderId = eventData.metaData?.orderId;
  if (!orderId) {
    console.error("web_outright webhook missing orderId:", eventData.metaData);
    return new Response(JSON.stringify({ error: "Missing orderId" }), { status: 400 });
  }

  const orderRef = db.collection('orders').doc(orderId);

  // ---- FAILED payment: cancel the awaiting order, email the guest ----
  if (eventType === "FAILED_TRANSACTION") {
    const orderDoc = await orderRef.get();
    if (!orderDoc.exists) return new Response(JSON.stringify({ status: "ignored" }), { status: 200 });
    const order = orderDoc.data()!;
    if (order.paymentStatus !== 'awaiting') {
      return new Response(JSON.stringify({ status: "ignored" }), { status: 200 });
    }
    await orderRef.update({
      status: 'cancelled',
      paymentStatus: 'failed',
      failedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    if (order.customerEmail) {
      const d = webEmailData(orderDoc.id, order, order.storeName ?? 'the store', '');
      const { subject, html } = orderFailedEmail(d);
      await sendOrderEmail(order.customerEmail, subject, html);
    }
    return new Response(JSON.stringify({ status: "success" }), { status: 200 });
  }

  // ---- SUCCESSFUL payment ----
  const amountPaid = Number(eventData.amountPaid);
  const transactionReference = eventData.transactionReference ?? '';

  let vendorFcmToken = "";
  let shouldNotifyVendor = false;
  let vendorIdForPush = "";
  let emailPayload: WebOrderEmailData | null = null;
  let customerTotalForPush = 0;
  let summaryForPush = "";
  let customerNameForPush = "";

  await db.runTransaction(async (t) => {
    // READS (all before writes)
    const orderDoc = await t.get(orderRef);
    if (!orderDoc.exists) throw "Web order not found";
    const order = orderDoc.data()!;

    // 🛑 Idempotency: webhook retries must be no-ops.
    if (order.paymentStatus === 'paid') {
      console.log(`Web order ${orderId} already paid. Skipping.`);
      return;
    }
    if (order.webPurchase !== true) throw "Order is not a web purchase";

    // 🛑 Amount check: what Monnify collected must cover what we quoted.
    const amountCharged = Number(order.amountCharged ?? 0);
    if (amountPaid + 0.01 < amountCharged) {
      console.error(`Web order ${orderId} underpaid: ${amountPaid} < ${amountCharged}`);
      t.update(orderRef, { paymentStatus: 'underpaid', amountPaidActual: amountPaid });
      return;
    }

    const vendorRef = db.collection('vendors').doc(order.vendorId);
    const vendorDoc = await t.get(vendorRef);
    if (!vendorDoc.exists) throw "Vendor not found for web order";
    const vendorData = vendorDoc.data()!;
    const storeMap = vendorData.store ?? {};
    const storeName = storeMap.storeName ?? 'Merchant Store';
    vendorFcmToken = vendorData.fcmToken ?? "";
    vendorIdForPush = order.vendorId;

    const items: any[] = order.items ?? [];
    const productRefs = items.map((it) => db.collection('products').doc(it.productId));
    const productDocs = await Promise.all(productRefs.map((r) => t.get(r)));

    const subtotal = Number(order.totalAmount ?? 0);
    const feeAmount = Number(order.feeAmount ?? 0);
    const absorbed = order.feePaidBy === 'merchant';
    // Merchant take: full subtotal when the customer paid the fee on top,
    // subtotal minus the (capped) fee when the merchant absorbs it.
    const vendorNet = absorbed ? Math.floor((subtotal - feeAmount) * 100) / 100 : subtotal;

    const timestamp = admin.firestore.FieldValue.serverTimestamp();
    const nowDate = new Date();
    const currentDateStr = nowDate.toISOString().slice(0, 10);
    const currentMonthStr = nowDate.toISOString().slice(0, 7);
    const currentYearStr = nowDate.getFullYear().toString();
    const currentDayStr = nowDate.toISOString().slice(8, 10);
    const summaryTitle = items.length === 1
      ? items[0].title
      : `${items[0].title} +${items.length - 1} more`;

    // WRITES
    // 1. Stock (reversible: merchant cancel restores it, same as app orders).
    // Sold units also release the capacity their listing was holding in
    // vendor_stats.totalLiability (listing price x qty — the same math
    // delete-product-secure and outright-checkout use).
    let capacityToRestore = 0;
    // Variant-aware: order items carry variantLabel (stamped by
    // web-checkout). Lines are aggregated per product so a cart holding
    // XL and XXL of the same product deducts each variant once and keeps
    // availableStock as the recomputed sum. Flat products keep the exact
    // increment(-qty) behavior they always had.
    const processedProducts = new Set<string>();
    for (const doc of productDocs) {
      if (!doc.exists || processedProducts.has(doc.id)) continue;
      processedProducts.add(doc.id);
      const lines = items.filter((x) => x.productId === doc.id);
      if (lines.length === 0) continue;
      const totalQty = lines.reduce((acc, l) => acc + Number(l.quantity), 0);

      const pData = doc.data()!;
      const productVariants: { label: string; stock: number }[] =
        Array.isArray(pData.variants)
          ? pData.variants.map((v: any) => ({
              label: String(v?.label ?? ''),
              stock: Math.floor(Number(v?.stock ?? 0)),
            }))
          : [];

      if (productVariants.length > 0) {
        const newVariants = productVariants.map((v) => {
          const deducted = lines
            .filter((l) => (l.variantLabel ?? '').toString() === v.label)
            .reduce((acc, l) => acc + Number(l.quantity), 0);
          return { label: v.label, stock: Math.max(0, v.stock - deducted) };
        });
        const newTotal = newVariants.reduce((acc, v) => acc + v.stock, 0);
        t.update(doc.ref, { variants: newVariants, availableStock: newTotal });
      } else {
        t.update(doc.ref, {
          availableStock: admin.firestore.FieldValue.increment(-totalQty),
        });
      }
      capacityToRestore += (Number(pData.price) || 0) * totalQty;
    }
    capacityToRestore = Math.round(capacityToRestore * 100) / 100;

    // 2. Flip the order to paid. status is set back to 'pending' explicitly:
    // if the customer closed the overlay (order cancelled as abandoned) but
    // the transfer landed anyway, the confirmed payment restores the order.
    t.update(orderRef, {
      status: 'pending',
      paymentStatus: 'paid',
      paidAt: timestamp,
      transactionReference,
      amountPaidActual: amountPaid,
    });

    // 3. Merchant ledger: pending settlement, exactly like an app sale.
    const vLedgerRef = vendorRef.collection('ledger_transactions').doc();
    t.set(vLedgerRef, {
      id: vLedgerRef.id,
      userId: order.vendorId,
      amount: vendorNet,
      type: 'sale',
      description: `${order.customerName} bought ${summaryTitle} outright on your web store (₦${amountCharged.toLocaleString()}${absorbed ? ", fee absorbed" : ""}, pending settlement)`,
      reference: order.reference,
      orderId: orderDoc.id,
      status: 'success',
      createdAt: timestamp,
      customerName: order.customerName,
      grossAmount: amountPaid,
      feeAmount,
      settlementStatus: 'pending',
      webPurchase: true,
    });

    const vendorStatsRef = db.collection('vendor_stats').doc(order.vendorId);
    t.set(vendorStatsRef, {
      totalEarnings: admin.firestore.FieldValue.increment(vendorNet),
      walletBalance: admin.firestore.FieldValue.increment(vendorNet),
      totalSalesVolume: admin.firestore.FieldValue.increment(subtotal),
      // Sold stock frees the capacity its listing was holding.
      totalLiability: admin.firestore.FieldValue.increment(-capacityToRestore),
    }, { merge: true });

    // 4. Korra's fee
    if (feeAmount > 0) {
      const korraLedger = db.collection('company_ledger').doc();
      t.set(korraLedger, {
        id: korraLedger.id,
        type: 'credit',
        category: 'outright_fee',
        amount: feeAmount,
        description: `${WEB_FEE_RATE * 100}% outright fee (${absorbed ? 'merchant absorbed' : 'customer paid'}) on ${summaryTitle} (web)`,
        orderId: orderDoc.id,
        timestamp,
        dateStr: currentDateStr,
        monthStr: currentMonthStr,
        yearStr: currentYearStr,
      });
      const companyWalletRef = db.collection('company_wallet').doc('main');
      t.set(companyWalletRef, {
        availableBalance: admin.firestore.FieldValue.increment(feeAmount),
        totalAllTimeEarnings: admin.firestore.FieldValue.increment(feeAmount),
        lastUpdated: timestamp,
      }, { merge: true });
    }

    // 4b. Campaign conversion: one purchase per campaign attributed at init
    // (order.promotionCampaignIds — internal, never displayed). set+merge so
    // an archived campaign doc can never abort the payment finalisation.
    const promoCampaignIds: string[] = Array.isArray(order.promotionCampaignIds)
      ? order.promotionCampaignIds
      : [];
    for (const cId of promoCampaignIds) {
      t.set(
        db.collection('campaigns').doc(String(cId)),
        { purchases: admin.firestore.FieldValue.increment(1) },
        { merge: true },
      );
    }

    // 4c. Web Activity: raw web-purchase count for the merchant's Web
    // Activity card (separate stat, never a rate against page views).
    t.set(db.collection('web_activity').doc(order.vendorId), {
      purchasesTotal: admin.firestore.FieldValue.increment(1),
      purchasesDaily: { [currentDateStr]: admin.firestore.FieldValue.increment(1) },
    }, { merge: true });

    // 5. Dispute archive: full copy under web_purchases/{vendor}/purchases
    const disputeRef = db
      .collection('web_purchases').doc(order.vendorId)
      .collection('purchases').doc(orderDoc.id);
    t.set(disputeRef, {
      orderId: orderDoc.id,
      vendorId: order.vendorId,
      storeName,
      customerName: order.customerName,
      customerEmail: order.customerEmail,
      customerPhone: order.customerPhone,
      items,
      subtotal,
      feeAmount,
      feePaidBy: order.feePaidBy,
      amountCharged,
      amountPaidActual: amountPaid,
      reference: order.reference,
      transactionReference,
      paidAt: timestamp,
      createdAt: order.createdAt ?? timestamp,
    });

    // 6. Merchant activity feed + monthly analytics (same as app sales)
    const activityRef = vendorRef.collection('activity_feed').doc();
    t.set(activityRef, {
      id: activityRef.id,
      type: 'payment',
      title: 'Web Order Paid',
      body: `${order.customerName} paid ₦${amountCharged.toLocaleString()} outright for ${summaryTitle} on your web store (Pending Settlement)`,
      ref_id: orderDoc.id,
      amount_display: `+₦${amountCharged.toLocaleString()}`,
      date: timestamp,
      is_read: false,
    });

    const monthlyRef = vendorRef.collection('monthly_stats').doc(currentMonthStr);
    t.set(monthlyRef, {
      month: currentMonthStr,
      year: currentYearStr,
      earnings: admin.firestore.FieldValue.increment(vendorNet),
      [`daily_breakdown.${currentDayStr}`]: admin.firestore.FieldValue.increment(vendorNet),
      lastUpdated: timestamp,
    }, { merge: true });

    // 7. Merchant in-app notification (push goes out after commit)
    const notifRef = vendorRef.collection('notifications').doc();
    t.set(notifRef, {
      id: notifRef.id,
      title: "New Web Order 🌐",
      body: `${order.customerName} just bought ${summaryTitle} on your web store. Head to Orders to fulfil it.`,
      type: "vendor_order",
      isRead: false,
      createdAt: timestamp,
      metadata: { type: "vendor_order", orderId: orderDoc.id },
    });

    shouldNotifyVendor = true;
    customerTotalForPush = amountCharged;
    summaryForPush = summaryTitle;
    customerNameForPush = order.customerName ?? 'A customer';

    emailPayload = webEmailData(
      orderDoc.id,
      order,
      storeName,
      storeMap.contactPhone ?? vendorData.personal?.phone ?? '',
    );
  });

  // Push + email outside the transaction, same pattern as the wallet route.
  if (shouldNotifyVendor && vendorFcmToken) {
    await messaging.send({
      token: vendorFcmToken,
      notification: {
        title: "New Web Order 🌐",
        body: `${customerNameForPush} paid ₦${customerTotalForPush.toLocaleString()} for ${summaryForPush} on your web store.`,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "korra_high_importance_channel",
          priority: "max",
          color: "#A54600",
          // Same small icon the manifest default uses — "ic_launcher" resolved
          // to the wrong resource and rendered the Flutter logo in the tray.
          icon: "notification_icon",
        },
      },
      apns: { payload: { aps: { sound: "default", contentAvailable: true } } },
    }).catch((e) => console.error("❌ Web order FCM failed:", e));
  }

  if (shouldNotifyVendor && emailPayload && (emailPayload as WebOrderEmailData).customerEmail) {
    const { subject, html } = orderConfirmedEmail(emailPayload);
    await sendOrderEmail((emailPayload as WebOrderEmailData).customerEmail, subject, html);
  }

  return new Response(JSON.stringify({ status: "success" }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
}

function webEmailData(orderId: string, order: any, storeName: string, merchantPhone: string): WebOrderEmailData {
  return {
    customerName: order.customerName ?? 'there',
    customerEmail: order.customerEmail ?? '',
    orderIdShort: orderId.substring(0, 8).toUpperCase(),
    orderId,
    storeName,
    merchantPhone,
    items: order.items ?? [],
    subtotal: Number(order.totalAmount ?? 0),
    feeAmount: Number(order.feeAmount ?? 0),
    feePaidBy: order.feePaidBy ?? 'customer',
    amountCharged: Number(order.amountCharged ?? 0),
  };
}

// 2. CRYPTO HELPER
async function verifyMonnifyHash(bodyText: string, signature: string, secret: string): Promise<boolean> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw", encoder.encode(secret), { name: "HMAC", hash: "SHA-512" }, false, ["verify"]
  );
  
  const signatureBytes = new Uint8Array(signature.match(/.{1,2}/g)!.map((byte) => parseInt(byte, 16)));

  return await crypto.subtle.verify("HMAC", key, signatureBytes, encoder.encode(bodyText));
}

serve(async (req) => {
  if (req.method !== "POST") return new Response("Method Not Allowed", { status: 405 });

  try {
    const bodyText = await req.text();
    const signature = req.headers.get("monnify-signature");

    // A. Security Check
    if (!signature || !MONNIFY_SECRET_KEY) return new Response("Unauthorized", { status: 401 });

    const isValid = await verifyMonnifyHash(bodyText, signature, MONNIFY_SECRET_KEY);
    if (!isValid) return new Response("Unauthorized", { status: 401 }); 

    const payload = JSON.parse(bodyText);
    const { eventType, eventData } = payload;

    // =========================================================================
    // 🚦 ROUTE 0: GUEST WEB PURCHASES (storefront, no account)
    // metaData.purchaseType === 'web_outright' is set ONLY by the website's
    // checkout. Anything without it falls through to the existing routes
    // completely unchanged.
    // =========================================================================
    if (
      (eventType === "SUCCESSFUL_TRANSACTION" || eventType === "FAILED_TRANSACTION") &&
      eventData?.metaData?.purchaseType === 'web_outright'
    ) {
      return await handleWebOutrightPurchase(eventType, eventData);
    }

    // =========================================================================
    // 🚦 ROUTE 1: CUSTOMER DEPOSITS (FUND WALLET)
    // =========================================================================
    if (eventType === "SUCCESSFUL_TRANSACTION") {
      const transactionId = eventData.paymentReference;
      let uid = "";
      
      // 1. Try to get it from SDK MetaData (Instant Top-Up)
      if (eventData.metaData && eventData.metaData.customerUid) {
          uid = eventData.metaData.customerUid;
      } 
      // 2. Fallback to Product Reference (Permanent Virtual Account Transfer)
      else if (eventData.product && eventData.product.reference) {
          uid = eventData.product.reference; 
      }

      // Safety check to prevent crashing
      if (!uid) {
          console.error("CRITICAL: No UID found in webhook payload:", eventData);
          return new Response(JSON.stringify({ error: "Missing UID in payload" }), { status: 400 });
      }

      const amountPaid = Number(eventData.amountPaid);
      const formattedAmount = new Intl.NumberFormat('en-NG', { style: 'currency', currency: 'NGN' }).format(amountPaid);

      console.log(`Processing ${transactionId} for ${uid}`);

      // --- PREPARE DATA FOR PUSH (To be used AFTER transaction) ---
      let fcmToken = "";
      let shouldSendPush = false;

      // C. RUN ATOMIC TRANSACTION
      // ⚠️ CRITICAL: All Reads MUST come before Writes
      await db.runTransaction(async (t) => {
        
        // 1. SETUP REFS
        const userRef = db.collection('customers').doc(uid);
        const ledgerRef = db.collection('customers').doc(uid).collection('ledger_transactions').doc(`${transactionId}`);
        
        // 2. READS (Do these FIRST)
        const userDoc = await t.get(userRef);
        const ledgerDoc = await t.get(ledgerRef); // Check for duplicates

        // 3. LOGIC CHECKS
        if (ledgerDoc.exists) {
          console.log("Duplicate transaction detected. Skipping.");
          return; 
        }
        
        if (!userDoc.exists) throw "User not found";

        const userData = userDoc.data();
        const currentBalance = userData?.monnify?.availableBalance || 0.00;
        fcmToken = userData?.fcmToken; 

        // 4. CALCULATIONS (Full Amount - No Fee Deduction)
        const newBalance = currentBalance + amountPaid;
        const timestamp = admin.firestore.FieldValue.serverTimestamp();

        // 5. WRITES (Do these LAST)
        
        // Write A: Ledger Entry (Matches TransactionModel)
        t.set(ledgerRef, {
          id: `${transactionId}`,
          customerId: uid,
          amount: amountPaid,
          type: 'deposit', // Matches your model
          description: 'Wallet Top-up',
          planId: 'none',
          reference: transactionId,
          status: 'success',
          balanceBefore: currentBalance,
          balanceAfter: newBalance,
          createdAt: timestamp
        });

        // Write B: Update Balance
        t.update(userRef, {
          "monnify.availableBalance": admin.firestore.FieldValue.increment(amountPaid)
        });

        // Write C: In-App Notification
        const notifRef = db.collection('customers').doc(uid).collection('notifications').doc();
        t.set(notifRef, {
          id: notifRef.id,
          title: "Wallet Funded 💰",
          body: `You received ${formattedAmount} in your wallet.`,
          type: "payment", 
          isRead: false,
          createdAt: timestamp
        });

        // Flag to send push after transaction commits
        shouldSendPush = true;
      });

      // SEND PUSH NOTIFICATION (Outside Transaction)
      if (shouldSendPush && fcmToken) {
        if (fcmToken) {
            console.log(`Attempting to send Push to token: ${fcmToken.substring(0, 10)}...`);
            await messaging.send({
                token: fcmToken,
                notification: {
                  title: "Wallet Funded 💰",
                  body: `You received ${formattedAmount} in your Korra wallet.`,
                },
                android: {
                  priority: "high",
                  notification: {
                    channelId: "korra_high_importance_channel",
                    priority: "max",
                    color: "#A54600",
                    icon: "ic_launcher"
                  }
                },
                apns: { payload: { aps: { sound: "default", contentAvailable: true } } }
            })
            .then(() => console.log("✅ FCM Push Sent Successfully"))
            .catch((e) => console.error("❌ FCM Failed:", e));
        } else {
            console.error("⚠️ Push Skipped: No FCM Token found for user.");
        }
      }

      return new Response(JSON.stringify({ status: "success" }), { 
        status: 200, 
        headers: { "Content-Type": "application/json" } 
      });
    }

    // =========================================================================
    // 🚦 ROUTE 2: VENDOR PAYOUTS (DISBURSEMENTS)
    // =========================================================================
    if (eventType === "SUCCESSFUL_DISBURSEMENT" || eventType === "FAILED_DISBURSEMENT" || eventType === "REVERSED_DISBURSEMENT") {
      
      const reference = eventData.reference; // e.g., PAYOUT|LTT8F140|EYT2
      
      // 1. LOOKUP THE MAPPING PHONEBOOK
      const mappingDoc = await db.collection('monnify_mappings').doc(reference).get();
      if (!mappingDoc.exists) {
        console.log(`⚠️ Mapping not found for ${reference}. Skipping.`);
        return new Response(JSON.stringify({ status: "ignored" }), { status: 200 });
      }
      const vendorUid = mappingDoc.data()?.vendorUid;

      // 2. FIND THE EXACT LEDGER DOC ID BEFORE TRANSACTION
      const ledgerQuery = await db.collection('vendors').doc(vendorUid).collection('ledger_transactions').where('reference', '==', reference).get();
      if (ledgerQuery.empty) return new Response(JSON.stringify({ status: "ignored" }), { status: 200 });
      const ledgerRef = ledgerQuery.docs[0].ref;

      // Check if there was an EMTL fee attached to this payout
      const feeQuery = await db.collection('vendors').doc(vendorUid).collection('ledger_transactions').where('reference', '==', `FEE-${reference}`).get();
      const feeRef = feeQuery.empty ? null : feeQuery.docs[0].ref;

      const vendorRef = db.collection('vendors').doc(vendorUid);
      const statsRef = db.collection('vendor_stats').doc(vendorUid);

      // Data for Push Notifications
      let fcmToken = "";
      let shouldSendPush = false;
      let pushTitle = "";
      let pushBody = "";

      // 3. ATOMIC TRANSACTION FOR PAYOUT
      await db.runTransaction(async (t) => {
        // READS FIRST
        const ledgerDoc = await t.get(ledgerRef);
        const vendorDoc = await t.get(vendorRef);
        let feeDoc = null;
        if (feeRef) feeDoc = await t.get(feeRef);
        
        if (!ledgerDoc.exists) return;
        const ledgerData = ledgerDoc.data();

        // 🛑 DOUBLE-PROCESSING CHECK
        if (ledgerData?.status === 'success' || ledgerData?.status === 'failed') {
          console.log(`Payout ${reference} is already marked ${ledgerData.status}. Skipping.`);
          return;
        }

        fcmToken = vendorDoc.data()?.fcmToken;
        const originalAmount = Math.abs(ledgerData?.amount || 0);
        const formattedAmount = new Intl.NumberFormat('en-NG', { style: 'currency', currency: 'NGN' }).format(originalAmount);
        const timestamp = admin.firestore.FieldValue.serverTimestamp();

        // WRITES: SUCCESS CASE
        if (eventType === "SUCCESSFUL_DISBURSEMENT") {
          t.update(ledgerRef, { status: 'success' });
          
          const notifRef = db.collection('vendors').doc(vendorUid).collection('notifications').doc();
          t.set(notifRef, {
            id: notifRef.id,
            title: "Payout Completed 💸",
            body: `Your withdrawal of ${formattedAmount} has been sent to your bank.`,
            type: "payout_success",
            isRead: false,
            createdAt: timestamp
          });

          shouldSendPush = true;
          pushTitle = "Payout Completed 💸";
          pushBody = `Your withdrawal of ${formattedAmount} was successful.`;
        } 
        // WRITES: FAILED OR REVERSED CASE
        else {
          t.update(ledgerRef, { 
            status: 'failed', 
            gatewayResponse: eventData.transactionDescription || "Bank reversal" 
          });

          // Calculate total refund (Main amount + EMTL fee if it existed)
          let feeToRefund = 0;
          if (feeDoc && feeDoc.exists) {
            feeToRefund = Math.abs(feeDoc.data()?.amount || 0);
          }
          const totalToRefund = originalAmount + feeToRefund;

          const refundRef = db.collection('vendors').doc(vendorUid).collection('ledger_transactions').doc();
          t.set(refundRef, {
            amount: totalToRefund, // Positive to refund
            type: 'refund',
            status: 'success',
            reference: `REFUND-${reference}`,
            description: `Refund for failed payout (${eventType})`,
            createdAt: timestamp
          });

          t.update(statsRef, {
            totalPayouts: admin.firestore.FieldValue.increment(-totalToRefund)
          });

          const notifRef = db.collection('vendors').doc(vendorUid).collection('notifications').doc();
          t.set(notifRef, {
            id: notifRef.id,
            title: "Payout Failed ⚠️",
            body: `Your withdrawal of ${formattedAmount} failed. Funds returned to your wallet.`,
            type: "payout_failed",
            isRead: false,
            createdAt: timestamp
          });

          shouldSendPush = true;
          pushTitle = "Payout Failed ⚠️";
          pushBody = `Your withdrawal of ${formattedAmount} failed. Funds returned to your wallet.`;
        }
      });

      // SEND PUSH NOTIFICATION FOR VENDOR (Outside Transaction)
      if (shouldSendPush && fcmToken) {
         try {
           console.log(`Attempting to send Payout Push to token: ${fcmToken.substring(0, 10)}...`);
           await messaging.send({
             token: fcmToken,
             notification: { title: pushTitle, body: pushBody },
             android: { priority: "high", notification: { channelId: "korra_high_importance_channel", priority: "max", color: "#A54600", icon: "ic_launcher" } },
             apns: { payload: { aps: { sound: "default", contentAvailable: true } } }
           });
           console.log("✅ FCM Payout Push Sent Successfully");
         } catch(e) { console.error("❌ FCM Failed:", e); }
      }

      return new Response(JSON.stringify({ status: "success" }), { status: 200, headers: { "Content-Type": "application/json" } });
    }

    // Ignore unknown events
    return new Response(JSON.stringify({ status: "ignored" }), { status: 200, headers: { "Content-Type": "application/json" } });

  } catch (error) {
    console.error("Webhook Error:", error);
    return new Response(JSON.stringify({ error: error.toString() }), { status: 500 });
  }
});