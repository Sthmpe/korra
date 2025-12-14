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

// 2. CRYPTO HELPER (HMAC-SHA512)
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
      return new Response("Unauthorized", { status: 401 }); 
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
      const fcmToken = userData?.fcmToken; // Get token for push

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

      // Write D: SAVE IN-APP NOTIFICATION
      const notifRef = db.collection('customer').doc(uid).collection('notifications').doc();
      t.set(notifRef, {
        id: notifRef.id,
        title: "Wallet Funded 💰",
        body: `You received ${formattedAmount}. Fee: ₦${fee}`,
        type: "payment", 
        isRead: false,
        createdAt: timestamp
      });

      // 5. SEND PUSH NOTIFICATION (Async Side Effect)
      if (fcmToken) {
        // We deliberately catch errors here so the Transaction doesn't fail just because Push failed
        messaging.send({
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
              defaultSound: true,
              defaultVibrateTimings: true,
              color: "#A54600", // ✅ FIXED: 6-digit Hex (Removed FF alpha)
              icon: "ic_launcher"
            }
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                contentAvailable: true,
              }
            }
          }
        }).catch((e: any) => console.error("FCM Error (Transaction still succeeded):", e));
      }
      
      // 1. CHECK FOR ACTIVE PLANS (The Gatekeeper)
      // We check if there are any plans that are NOT 'completed' or 'cancelled'.
      // We use a query inside the transaction or right before it.
      const activePlansQuery = await t.get(
        db.collection('plans')
          .where('customerId', '==', uid)
          .where('status', 'in', ['active', 'overdue', 'pending_approval'])
          .limit(1)
      );

      // 2. EXECUTE LIMIT LOGIC ONLY IF CLEAN
      if (activePlansQuery.empty) {
         // 1. Get Old Limit Values
         const totalLimit = limitDoc.exists ? (limitDoc.data().totalCreditLimit || 15000) : 15000;
         const activeDebt = limitDoc.exists ? (limitDoc.data().activeDebt || 0) : 0;
         
         // 2. Calculate "Old Reservation Limit" (Purchasing Power)
         const oldReservationLimit = Math.max(0, totalLimit - activeDebt);

         // 3. Formula: (New Wallet Balance * 1.25) + (0.25 * Old Res Limit)
         // Use balAfterFee because that's the actual cash they have now
         const partA = balAfterFee * 1.25;
         const partB = oldReservationLimit * 0.25;
         const newReservationLimit = partA + partB;

         // 4. Calculate New Total Limit (Add Debt back)
         let newTotalLimit = newReservationLimit + activeDebt;

         // Cap at 100k (as requested)
         if (newTotalLimit > 100000) newTotalLimit = 100000;

         // 5. Update if Increased
         if (newTotalLimit > totalLimit) {
            t.update(limitRef, {
                totalCreditLimit: newTotalLimit,
                lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
                limitReason: 'wallet_fund_boost_v5'
            });

            // 6. Limit Notification
            const boostAmount = newReservationLimit - oldReservationLimit;
            const formattedBoost = new Intl.NumberFormat('en-NG', { style: 'currency', currency: 'NGN' }).format(boostAmount);
            const formattedTotal = new Intl.NumberFormat('en-NG', { style: 'currency', currency: 'NGN' }).format(newReservationLimit);

            const limitNotifRef = db.collection('customer').doc(uid).collection('notifications').doc();
            t.set(limitNotifRef, {
                id: limitNotifRef.id,
                title: "Purchasing Power Increased! 🚀",
                body: `Your reservation limit increased by +${formattedBoost}. You can now reserve items up to ${formattedTotal}.`,
                type: "system", // Shows standard/brand color
                isRead: false,
                createdAt: timestamp
            });

            // 7. Limit Push
            if (fcmToken) {
               messaging.send({
                  token: fcmToken,
                  data: {
                    type: "system",
                    title: "Limit Increased! 🚀",
                    body: `Your purchasing power is now ${formattedTotal}.`,
                    uid: uid,
                    notifId: limitNotifRef.id
                  },
                  android: { priority: "high" },
                  apns: { payload: { aps: { contentAvailable: true } } }
               }).catch((e: any) => console.error("Limit Push Error:", e));
            }
         }
      } else {
         console.log("User has active plans. Limit increase skipped.");
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