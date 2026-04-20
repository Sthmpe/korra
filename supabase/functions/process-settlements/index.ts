import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

// 1. DEFINE CORS & ENV
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-cron-secret, content-type',
};

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');

// Initialize Firebase
const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

// --- 📧 PREMIUM SETTLEMENT EMAIL TEMPLATE ---
const getSettlementTemplate = (storeName: string, amountStr: string, txCount: number) => `
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Funds Settled</title>
<link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #EDE8E1; font-family: 'DM Sans', sans-serif; padding: 24px 8px; min-height: 100vh; }
  .email-wrap { max-width: 480px; margin: 0 auto; }
  .main-card { background: #FDFAF7; border-radius: 12px; box-shadow: 0 4px 20px rgba(28, 13, 0, 0.05); overflow: hidden; }
  
  .hero { background: #1C0D00; padding: 36px 24px 28px; text-align: center; }
  .hero-eyebrow { display: inline-block; font-size: 10px; font-weight: 600; letter-spacing: 2px; text-transform: uppercase; color: #10B981; margin-bottom: 12px; }
  .hero h1 { font-family: 'DM Sans', sans-serif; font-size: 32px; font-weight: 700; color: #FDF6EE; margin-bottom: 8px; letter-spacing: -1px;}
  .hero-sub { font-size: 14px; color: rgba(253,246,238,0.8); line-height: 1.5; }
  
  .body { padding: 32px 24px; }
  .greeting { font-size: 15px; color: #3D2B1A; line-height: 1.6; margin-bottom: 24px; font-weight: 400; }
  .greeting strong { font-weight: 600; color: #1C0D00; }
  
  .info-box { background: #ECFDF5; border-radius: 8px; padding: 20px; margin-bottom: 24px; text-align: center; }
  .box-title { font-size: 12px; font-weight: 600; letter-spacing: 1px; text-transform: uppercase; margin-bottom: 8px; color: #065F46; }
  .amount { font-size: 28px; font-weight: 700; color: #064E3B; margin-bottom: 8px; letter-spacing: -0.5px; }
  .tx-count { font-size: 13px; color: #047857; font-weight: 500; }
  
  .cta-wrap { text-align: center; margin-top: 32px; margin-bottom: 8px; }
  .cta-btn { display: inline-block; background: #A54600; color: #FDF6EE; text-decoration: none; font-size: 15px; font-weight: 600; padding: 16px 40px; border-radius: 50px; }
  
  .signoff { padding: 0 24px 28px; font-size: 13px; color: #5A3E2B; text-align: left; }
  .signoff p { padding-top: 12px; margin-bottom: 20px; line-height: 1.6; }
  .sig-name { font-family: 'DM Serif Display', serif; font-size: 18px; color: #A54600; margin-bottom: 2px; }
  
  .footer { background: #1C0D00; text-align: center; padding: 24px 20px; }
  .footer-row { font-size: 12px; color: rgba(253, 246, 238, 0.6); margin-bottom: 12px; }
  .footer a { color: #C27641; text-decoration: none; font-weight: 500; }
  
  @media only screen and (max-width: 600px) { 
    body { padding: 16px 8px; } 
    .cta-btn { display: block; width: 100%; padding: 16px 0; } 
  }
</style>
</head>
<body>
<div class="email-wrap">
  <div class="main-card">
    <div class="hero">
      <div class="hero-eyebrow">Settlement Successful</div>
      <h1>${amountStr}</h1>
      <p class="hero-sub">Has been credited to your Korra Wallet.</p>
    </div>
    <div class="body">
      <div class="greeting">
        <p>Hi <strong>${storeName}</strong>,</p>
        <p>Great news! The holding period for your recent sales is complete. The funds have been successfully settled and are now available for payout.</p>
      </div>
      
      <div class="info-box">
        <div class="box-title">Settlement Summary</div>
        <div class="amount">${amountStr}</div>
        <div class="tx-count">From ${txCount} cleared transaction(s)</div>
      </div>

      <div class="cta-wrap">
        <a href="https://business.korra.com.ng" class="cta-btn">Withdraw Funds Now</a>
      </div>
    </div>
    <div class="signoff">
      <p>If you have auto-payouts enabled, this amount will be sent to your bank account on your next scheduled date. Otherwise, you can request a payout immediately from your dashboard.</p>
      <div class="sig-name">The Korra Team</div>
    </div>
    <div class="footer">
      <div class="footer-row">
        © 2026 Korra Business &nbsp;|&nbsp; <a href="mailto:support@korra.com.ng">support@korra.com.ng</a>
      </div>
    </div>
  </div>
</div>
</body>
</html>
`;

// --- HELPER: SEND EMAIL ---
async function sendSettlementEmail(email: string, storeName: string, amountStr: string, txCount: number) {
  if (!RESEND_API_KEY || !email) return;

  try {
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`
      },
      body: JSON.stringify({
        from: `Korra Business <notifications@korra.com.ng>`, 
        to: [email],
        subject: `Funds Settled: ${amountStr} is ready for payout 🏦`,
        html: getSettlementTemplate(storeName, amountStr, txCount),
        tags: [{ name: 'category', value: 'settlement' }],
      })
    });
    if (!res.ok) console.error("Resend API Error:", await res.text());
  } catch (err) {
    console.error("Failed to send email:", err);
  }
}

// --- HELPER: SEND PUSH NOTIFICATION ---
async function sendPushNotification(fcmToken: any, title: string, body: string) {
  if (!fcmToken) return;
  try {
    const payload = {
      notification: { title, body },
      data: { type: 'settlement', refId: 'batch_settlement' }
    };

    if (Array.isArray(fcmToken) && fcmToken.length > 0) {
      await admin.messaging().sendEachForMulticast({ ...payload, tokens: fcmToken });
    } else if (typeof fcmToken === 'string') {
      await admin.messaging().send({ ...payload, token: fcmToken });
    }
  } catch (err) {
    console.error('FCM Push Error:', err);
  }
}

// --- MAIN HANDLER ---
serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    // 🚀 RUN BATCH SETTLEMENT
    const vendorsSnap = await db.collection('vendors').get();
    let totalVendorsProcessed = 0;
    let totalTransactionsSettled = 0;

    for (const vendorDoc of vendorsSnap.docs) {
      const vendorId = vendorDoc.id;
      const vendorData = vendorDoc.data();

      // Extract Vendor Details for Notifications
      const storeName = vendorData.store?.storeName || "Partner";
      const vendorEmail = vendorData.personal?.email; // 🚀 Extracted from nested map!
      const fcmToken = vendorData.fcmToken || vendorData.fcmTokens;

      const ledgerSnap = await db.collection('vendors')
        .doc(vendorId)
        .collection('ledger_transactions')
        .where('type', '==', 'sale')
        .where('status', '==', 'success')
        .get();

      let vendorTotalCleared = 0;
      let vendorClearedCount = 0;
      const batch = db.batch(); 

      ledgerSnap.docs.forEach(doc => {
        const txData = doc.data();

        if (txData.settlementStatus === 'pending') {
          vendorTotalCleared += (txData.amount || 0);
          vendorClearedCount++;
          batch.update(doc.ref, {
            settlementStatus: 'cleared',
            settledAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
      });

      if (vendorClearedCount > 0) {
        const amountDisplay = `₦${vendorTotalCleared.toLocaleString('en-US')}`;

        // 1. Activity Feed
        const activityRef = db.collection('vendors').doc(vendorId).collection('activity_feed').doc();
        batch.set(activityRef, {
          id: activityRef.id,
          type: 'payment',
          title: 'Funds Settled 🏦',
          body: `${amountDisplay} from ${vendorClearedCount} recent sale(s) has cleared and is now available to withdraw.`,
          ref_id: 'batch_settlement',
          amount_display: `+${amountDisplay}`,
          date: admin.firestore.FieldValue.serverTimestamp(),
          is_read: false
        });

        // 2. Commit Database Batch
        await batch.commit();

        // 3. Send Push Notification
        const pushTitle = "Funds Settled 🏦";
        const pushBody = `${amountDisplay} from ${vendorClearedCount} recent transaction(s) has cleared! You can now request a payout.`;
        await sendPushNotification(fcmToken, pushTitle, pushBody);

        // 4. 🚀 SEND THE EMAIL!
        if (vendorEmail) {
           await sendSettlementEmail(vendorEmail, storeName, amountDisplay, vendorClearedCount);
        }

        totalVendorsProcessed++;
        totalTransactionsSettled += vendorClearedCount;
      }
    }

    return new Response(JSON.stringify({ 
        message: "Settlement process complete.",
        vendorsProcessed: totalVendorsProcessed,
        transactionsSettled: totalTransactionsSettled
    }), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });

  } catch (error: any) {
    console.error("Settlement Cron Error:", error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: corsHeaders });
  }
});