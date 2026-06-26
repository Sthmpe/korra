// process-promo/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-cron-secret, content-type',
};

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');

const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

interface PromoConfig {
    isActive: boolean;
    maxUses: number;
    currentUses: number;
    completedUses: number;
    promoValue: number;
    minItemPrice: number;
    maxDurationDays: number;
    startDate: admin.firestore.FieldValue | admin.firestore.Timestamp | null;
    usedByUids: string[];
}

// --- 📧 PREMIUM PROMO EMAIL TEMPLATE ---
const getPromoActivationTemplate = (storeName: string, promoValueStr: string, minPriceStr: string, maxUses: number, durationDays: number) => `
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Promo Activated</title>
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
      <div class="hero-eyebrow">Campaign Live</div>
      <h1>Sponsored Flash Sale</h1>
      <p class="hero-sub">Your store has been selected for a Korra sponsored promotion.</p>
    </div>
    <div class="body">
      <div class="greeting">
        <p>Hi <strong>${storeName}</strong>,</p>
        <p>Your custom flash sale is officially active! Korra will automatically apply a completion bonus to your customers' plans when they check out.</p>
      </div>
      
      <div class="info-box">
        <div class="box-title">Customer Bonus</div>
        <div class="amount">${promoValueStr}</div>
        <div class="tx-count">Valid for the first ${maxUses} customers</div>
      </div>

      <div class="greeting">
        <p><strong>Campaign Rules:</strong></p>
        <p>• Minimum Item Price: ${minPriceStr}<br>
        • Maximum Plan Duration: ${durationDays} Days<br>
        • Limit: One per customer</p>
      </div>

      <div class="cta-wrap">
        <a href="https://business.korra.com.ng" class="cta-btn">View Dashboard</a>
      </div>
    </div>
    <div class="signoff">
      <p>Please share the good news with your WhatsApp community and social media followers! Once ${maxUses} customers claim the bonus, the promo will automatically close.</p>
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
async function sendPromoEmail(email: string, storeName: string, promoValue: number, minItemPrice: number, maxUses: number, durationDays: number) {
  if (!RESEND_API_KEY || !email) return;

  const promoValueStr = `₦${promoValue.toLocaleString()}`;
  const minPriceStr = `₦${minItemPrice.toLocaleString()}`;

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
        subject: `🚀 Your ${promoValueStr} Sponsored Flash Sale is LIVE!`,
        html: getPromoActivationTemplate(storeName, promoValueStr, minPriceStr, maxUses, durationDays),
        tags: [{ name: 'category', value: 'promo_activation' }],
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
      data: { type: 'promo_active', refId: 'promo_dashboard' }
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
    const payload = await req.json();
    const { 
        action, 
        emails, 
        activate, 
        maxUses = 10, 
        promoValue = 1000, 
        minItemPrice = 7000, 
        maxDurationDays = 14 
    } = payload;

    // =======================================================================
    // 🧹 ACTION: SWEEP_PROMOS (Triggered daily by Cron Job)
    // Payload: { "action": "SWEEP_PROMOS" }
    // =======================================================================
    if (action === 'SWEEP_PROMOS') {
      // Find all currently active promos
      const activePromosSnapshot = await db.collection('promos').where('isActive', '==', true).get();
      
      if (activePromosSnapshot.empty) {
        return new Response(JSON.stringify({ status: "SUCCESS", message: "No active promos to sweep." }), { 
          status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      const batch = db.batch();
      let deactivatedCount = 0;
      const now = Date.now();

      for (const doc of activePromosSnapshot.docs) {
        const promo = doc.data();
        let shouldDeactivate = false;

        // Condition 1: Usage limit reached
        if (promo.currentUses >= promo.maxUses || (promo.usedByUids && promo.usedByUids.length >= promo.maxUses)) {
          shouldDeactivate = true;
          console.log(`Deactivating ${doc.id}: Max uses reached (${promo.currentUses}/${promo.maxUses})`);
        }

        // Condition 2: Time limit reached (30 days)
        if (!shouldDeactivate && promo.startDate) {
          // Cast to Timestamp to access the toDate() method
          const startDateTimestamp = promo.startDate as admin.firestore.Timestamp;
          const startMs = startDateTimestamp.toDate().getTime();
          const daysElapsed = (now - startMs) / (1000 * 3600 * 24);

          if (daysElapsed > 30) {
            shouldDeactivate = true;
            console.log(`Deactivating ${doc.id}: Expired (${daysElapsed.toFixed(1)} days old)`);
          }
        }

        // Apply deactivation to the batch
        if (shouldDeactivate) {
          batch.update(doc.ref, { isActive: false });
          deactivatedCount++;
        }
      }

      if (deactivatedCount > 0) {
        await batch.commit();
      }

      return new Response(JSON.stringify({ 
        status: "SUCCESS", 
        message: `Swept ${activePromosSnapshot.size} promos. Deactivated ${deactivatedCount}.` 
      }), { 
        status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } 
      });
    }

    if (action === 'MANAGE_PROMO') {
      // Set defaults but allow payload to override them for future flexibility
      const maxUses = payload.maxUses;
      const promoValue = payload.promoValue;
      const minItemPrice = payload.minItemPrice;
      const maxDurationDays = payload.maxDurationDays;

      const batch = db.batch();
      const notificationPromises: Promise<void>[] = [];

      for (const email of emails) {
        const vendorSnapshot = await db.collection('vendors').where('personal.email', '==', email).limit(1).get();
        
        if (!vendorSnapshot.empty) {
          const vendorDoc = vendorSnapshot.docs[0];
          const vendorId = vendorDoc.id;
          const vendorData = vendorDoc.data();
          const storeName = vendorData.store?.storeName || "Merchant";
          const fcmToken = vendorData.fcmToken;

          const promoRef = db.collection('promos').doc(vendorId);
          
          if (activate) {
            batch.set(promoRef, {
                isActive: true,
                startDate: admin.firestore.FieldValue.serverTimestamp(),
                maxUses: maxUses,
                promoValue: promoValue,
                minItemPrice: minItemPrice,
                maxDurationDays: maxDurationDays,
                // Do not overwrite currentUses, completedUses, or usedByUids if they exist
            }, { merge: true });

            // Queue up notifications
            notificationPromises.push(
              sendPromoEmail(email, storeName, promoValue, minItemPrice, maxUses, maxDurationDays)
            );
            notificationPromises.push(
              sendPushNotification(
                fcmToken, 
                "🚀 Promo Active!", 
                `Your ₦${promoValue.toLocaleString()} Sponsored Flash Sale is now live. Share with your customers!`
              )
            );
          } else {
            // Deactivate
            batch.set(promoRef, { isActive: false }, { merge: true });
          }
        }
      }

      await batch.commit();
      await Promise.allSettled(notificationPromises);

      return new Response(JSON.stringify({ status: "SUCCESS", message: `Promos ${activate ? 'activated' : 'deactivated'} successfully.` }), { 
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" } 
      });
    }

    return new Response(JSON.stringify({ error: "Invalid action" }), { status: 400, headers: corsHeaders });

  } catch (error) {
    console.error("Endpoint Error:", error);
    return new Response(JSON.stringify({ error: "Internal Server Error" }), { status: 500, headers: corsHeaders });
  }
});