import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

serve(async (req) => {
  try {
    const { customerUid } = await req.json();
    
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
        const userDoc = await t.get(db.collection('customer').doc(customerUid));
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
    const notifRef = db.collection('customer').doc(customerUid).collection('notifications').doc();
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