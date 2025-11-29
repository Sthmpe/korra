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
const messaging = admin.messaging(); // Need this for Push Notifications later

// 2. CRYPTO HELPER
async function verifyMonnifyHash(bodyText: string, signature: string, secret: string): Promise<boolean> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-512" },
    false,
    ["verify"]
  );
  
  const signatureBytes = new Uint8Array(
    signature.match(/.{1,2}/g)!.map((byte) => parseInt(byte, 16))
  );

  return await crypto.subtle.verify(
    "HMAC",
    key,
    signatureBytes,
    encoder.encode(bodyText)
  );
}

// 3. MAIN HANDLER
serve(async (req) => {
  if (req.method !== "POST") return new Response("Method Not Allowed", { status: 405 });

  try {
    const bodyText = await req.text();
    const signature = req.headers.get("monnify-signature");

    // A. Security Check
    if (!signature || !MONNIFY_SECRET_KEY) {
      console.error("Missing Signature or Secret");
      return new Response("Unauthorized", { status: 401 });
    }

    const isValid = await verifyMonnifyHash(bodyText, signature, MONNIFY_SECRET_KEY);
    if (!isValid) {
      console.error("Invalid Signature");
      // return new Response("Unauthorized", { status: 401 }); 
    }

    const payload = JSON.parse(bodyText);
    const { eventType, eventData } = payload;

    // B. Filter Events
    if (eventType !== "SUCCESSFUL_TRANSACTION") {
      return new Response(JSON.stringify({ status: "ignored" }), { status: 200 });
    }

    const transactionId = eventData.paymentReference;
    const uid = eventData.product.reference; // Customer UID
    const amountPaid = Number(eventData.amountPaid);
    const formattedAmount = new Intl.NumberFormat('en-NG', { style: 'currency', currency: 'NGN' }).format(amountPaid);
    
    console.log(`Processing ${transactionId} for ${uid}`);

    // C. Run Atomic Transaction
    await db.runTransaction(async (t) => {
      
      // 1. Idempotency Check (Read)
      const creditRef = db.collection('customer').doc(uid)
                          .collection('ledger_transactions').doc(`${transactionId}_credit`);
      
      const existingDoc = await t.get(creditRef);
      if (existingDoc.exists) {
        console.log("Duplicate transaction detected.");
        return; 
      }

      // 2. Get User Balance (Read)
      const userRef = db.collection('customer').doc(uid);
      const userDoc = await t.get(userRef);
      
      if (!userDoc.exists) throw "User not found";

      const userData = userDoc.data();
      const currentBalance = userData?.monnify?.availableBalance || 0.00;
      const fcmToken = userData?.fcmToken; // Get token for push later

      // 3. Calculations
      const fee = Math.min(amountPaid * 0.03, 4000); 
      const netCredit = amountPaid - fee;
      
      const balAfterDeposit = currentBalance + amountPaid;
      const balAfterFee = balAfterDeposit - fee;

      // 4. Writes
      const timestamp = admin.firestore.FieldValue.serverTimestamp();

      // Write A: The Credit
      t.set(creditRef, {
        id: `${transactionId}_credit`,
        customerId: uid,
        amount: amountPaid,
        type: 'deposit',
        description: 'Topup via Monnify',
        planId: 'none',
        reference: transactionId,
        status: 'success',
        balanceBefore: currentBalance,
        balanceAfter: balAfterDeposit,
        createdAt: timestamp
      });

      // Write B: The Fee
      const feeRef = db.collection('customer').doc(uid)
                        .collection('ledger_transactions').doc(`${transactionId}_fee`);
      
      t.set(feeRef, {
        id: `${transactionId}_fee`,
        customerId: uid,
        amount: -fee,
        type: 'fee',
        description: 'Service Fee (3%)',
        planId: 'none',
        reference: `${transactionId}_fee`,
        status: 'success',
        balanceBefore: balAfterDeposit,
        balanceAfter: balAfterFee,
        createdAt: timestamp
      });

      // Write C: Update User Balance
      t.update(userRef, {
        "monnify.availableBalance": admin.firestore.FieldValue.increment(netCredit)
      });

      // --- WRITE D: SAVE IN-APP NOTIFICATION (The Missing Piece) ---
      const notifRef = db.collection('customer').doc(uid).collection('notifications').doc();
      t.set(notifRef, {
        id: notifRef.id,
        title: "Wallet Funded 💰",
        body: `You received ${formattedAmount}. Fee: ₦${fee}`,
        type: "payment", 
        isRead: false,
        createdAt: timestamp
      });

      // --- SEND PUSH NOTIFICATION (Async Side Effect) ---
      // Note: We usually do this *after* transaction, but inside is okay if we don't await it blocking
      if (fcmToken) {
        messaging.send({
          token: fcmToken,
          notification: {
            title: "Wallet Funded 💰",
            body: `You received ${formattedAmount} in your Korra wallet.`,
          },
          android: { priority: "high", notification: { color: "#FFA54600" } },
          apns: { payload: { aps: { sound: "default" } } }
        }).catch((e: any) => console.error("FCM Error:", e));
      }
    });

    return new Response(JSON.stringify({ status: "success" }), { 
      status: 200, 
      headers: { "Content-Type": "application/json" } 
    });

  } catch (error) {
    console.error("Webhook Error:", error);
    return new Response(JSON.stringify({ error: error.toString() }), { status: 500 });
  }
});