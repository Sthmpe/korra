import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

// 1. DEFINE CORS HEADERS
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, firebase-token, x-korra-timestamp, x-korra-signature',
};

const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

serve(async (req) => {
  // A. CORS Pre-flight
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

    const { customerUid } = await req.json();

    if (customerUid !== secureUid) {
        throw new Error("Security Violation: You cannot perform actions for another user.");
    }
    
    // 1. CHECK FOR ACTIVE PLANS
    const activePlans = await db.collection('plans')
      .where('customerId', '==', customerUid)
      .where('status', 'in', ['active', 'overdue', 'pending_approval'])
      .get();

    if (!activePlans.empty) {
      return new Response(JSON.stringify({ success: false, message: "Cannot upgrade limit while you have active plans." }), { headers: { "Content-Type": "application/json" } });
    }

    await db.runTransaction(async (t) => {
        // 2. GET DATA
        const userDoc = await t.get(db.collection('customers').doc(customerUid));
        const limitRef = db.collection('customer_limits').doc(customerUid);
        const limitDoc = await t.get(limitRef);

        const walletBalance = userDoc.data()?.monnify?.availableBalance || 0;
        const totalLimit = limitDoc.data()?.totalCreditLimit || 15000;
        const activeDebt = limitDoc.data()?.activeDebt || 0;

        // 3. MATH
        const oldReservationLimit = Math.max(0, totalLimit - activeDebt);
        
        // Formula: (Wallet * 1.25) + (0.25 * Old Res)
        const newReservationLimit = (walletBalance * 1.25) + (oldReservationLimit * 0.25);
        
        let newTotalLimit = newReservationLimit + activeDebt;
        if (newTotalLimit > 100000) newTotalLimit = 100000;

        // 4. UPDATE IF INCREASED
        if (newTotalLimit > totalLimit) {
            t.update(limitRef, {
                totalCreditLimit: newTotalLimit,
                lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
                limitReason: 'manual_recalculation'
            });
        }
    });

    // B. Save Notification
    const notifRef = db.collection('customers').doc(customerUid).collection('notifications').doc();
    t.set(notifRef, {
      id: notifRef.id,
      title: "Limit Recalculated 🚀",
      body: `Success! Your reservation limit has increased by +${formattedBoost}. You can now reserve items up to ${formattedTotal}.`,
      type: "system",
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // C. Send Push (Side Effect)
    if (fcmToken) {
      messaging.send({
        token: fcmToken,
        notification: {
          title: "Limit Increased! 🚀",
          body: `Your purchasing power is now ${formattedTotal}.`,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "korra_high_importance_channel",
            priority: "max",
            defaultSound: true,
            defaultVibrateTimings: true,
            color: "#A54600",
            icon: "ic_launcher"
          }
        },
        apns: { payload: { aps: { sound: "default" } } }
      }).catch((e: any) => console.error("FCM Error:", e));
    }

    return new Response(JSON.stringify({ success: true, message: "Limit recalculated successfully." }), { headers: { "Content-Type": "application/json" } });

  } catch (e) {
    return new Response(JSON.stringify({ error: e.toString() }), { status: 500 });
  }
});