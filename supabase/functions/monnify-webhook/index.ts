import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

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