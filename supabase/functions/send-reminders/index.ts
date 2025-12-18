import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

console.log("[INIT] Starting Reminder Job...");

const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

serve(async (req) => {
  try {
    // 1. SECURITY
    const cronSecret = Deno.env.get('CRON_SECRET');
    const authHeader = req.headers.get('Authorization');
    if (authHeader !== `Bearer ${cronSecret}`) return new Response("Unauthorized", { status: 401 });

    const now = new Date();
    // Normalize "Today" to midnight
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    // 2. QUERY ACTIVE PLANS
    const snapshot = await db.collection('plans')
      .where('status', '==', 'active')
      .get();

    let sentCount = 0;
    const notifications = [];

    snapshot.docs.forEach(doc => {
      const plan = doc.data();
      
      // Calculate Due Date
      const createdDate = plan.createdAt.toDate();
      const durationDays = plan.baseDurationDays || 30; 
      const dueDate = new Date(createdDate);
      dueDate.setDate(createdDate.getDate() + durationDays);

      // Normalize due date to midnight
      const dueMidnight = new Date(dueDate.getFullYear(), dueDate.getMonth(), dueDate.getDate());
      
      // Calculate Difference: Positive = Future (Left), Negative = Past (Overdue)
      const diffTime = dueMidnight.getTime() - today.getTime();
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)); 
      
      let title = "";
      let body = "";
      
      // --- THE 7-DAY WINDOW LOGIC ---

      // 1. BEFORE DUE DATE
      if (diffDays === 3) {
        title = "3 Days Left ⏳";
        body = `Heads up! Your plan for ${plan.productName} is due in 3 days.`;
      } 
      else if (diffDays === 2) {
        title = "2 Days Left ⏳";
        body = `You have 48 hours left to pay for ${plan.productName}. Don't lose your slot!`;
      } 
      else if (diffDays === 1) {
        title = "1 Day Left ⏰";
        body = `This is it! Your payment for ${plan.productName} is due tomorrow.`;
      } 
      
      // 2. DUE DATE
      else if (diffDays === 0) {
        title = "Payment Due Today 🚨";
        body = `Today is the deadline for ${plan.productName}. Pay now to complete your plan.`;
      } 
      
      // 3. OVERDUE
      else if (diffDays === -1) {
        title = "1 Day Overdue ⚠️";
        body = `You missed the date. Please pay for ${plan.productName} now to avoid penalties.`;
      } 
      else if (diffDays === -2) {
        title = "2 Days Overdue ⚠️";
        body = `Your plan is overdue. Your Active Slots are at risk of being frozen.`;
      } 
      else if (diffDays === -3) {
        title = "3 Days Overdue (Final Notice) ⛔";
        body = `Action Required: Pay for ${plan.productName} immediately or your account may be restricted.`;
      } 
      
      // SKIP ALL OTHER DAYS
      else {
        return; 
      }

      // Add to send queue
      notifications.push(
        sendFcm(plan.userId, title, body, { 
          type: "plan_detail", 
          planId: doc.id 
        })
      );
      sentCount++;
    });

    // 3. EXECUTE
    await Promise.all(notifications);
    
    console.log(`[SUCCESS] Sent ${sentCount} reminders.`);
    return new Response(JSON.stringify({ success: true, sent: sentCount }), { 
      headers: { "Content-Type": "application/json" } 
    });

  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});

// --- HELPER: SEND FCM ---
async function sendFcm(uid: string, title: string, body: string, data: any) {
  try {
    const userDoc = await db.collection('customers').doc(uid).get();
    const fcmToken = userDoc.data()?.fcmToken;
    
    if (!fcmToken) return;

    await admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      data: data 
    });
  } catch (e) {
    console.error(`Failed to send to ${uid}`, e);
  }
}