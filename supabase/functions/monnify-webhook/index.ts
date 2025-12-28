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

    // B. Filter Events
    if (eventType !== "SUCCESSFUL_TRANSACTION") {
      return new Response(JSON.stringify({ status: "ignored" }), { status: 200 });
    }

    const transactionId = eventData.paymentReference;
    const uid = eventData.product.reference; 
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

    // --- D. SEND PUSH NOTIFICATION (Outside Transaction) ---
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
          .catch((e: any) => console.error("❌ FCM Failed:", e));
       } else {
          console.error("⚠️ Push Skipped: No FCM Token found for user.");
       }
    }

    return new Response(JSON.stringify({ status: "success" }), { 
      status: 200, 
      headers: { "Content-Type": "application/json" } 
    });

  } catch (error) {
    console.error("Webhook Error:", error);
    return new Response(JSON.stringify({ error: error.toString() }), { status: 500 });
  }
});