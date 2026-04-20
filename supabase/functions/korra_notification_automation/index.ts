// korra_notification_automation
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

// --- 1. FIREBASE INIT ---
const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}
const db = admin.firestore();
const messaging = admin.messaging();

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY') ?? '';

// --- 2. PUSH NOTIFICATION HELPER ---
async function sendPushNotification(customerId: string, name: string, planCount: number) {
  if (!customerId) return;
  
  try {
    const userRef = db.collection('customers').doc(customerId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      console.log(`🔕 User document missing for ID: ${customerId}. Skipping push.`);
      return;
    }

    const title = "Keep your plan active ⚡";

    const body = planCount === 1 
      ? `Hi ${name}, a quick payment today keeps your plan on track. Even small amount counts.`
      : `Hi ${name}, you have ${planCount} active plans. A quick payment keeps everything on track.`;

    // 1. Write to In-App Notifications Feed
    await userRef.collection('notifications').add({
      title: title,
      body: body,
      type: 'reminder',
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      metadata: { category: "payment_reminder", groupedCount: planCount } 
    });

    // 2. Fire the actual device Push Notification
    const fcmToken = userDoc.data()?.fcmToken;
    if (fcmToken) {
      await messaging.send({
        token: fcmToken,
        notification: { title, body },
        data: { type: "reminder" }
      });
      console.log(`✅ Push successfully fired to device for ${name}`);
    } else {
      console.log(`🔕 No FCM Token saved in customer doc for ${name}. In-app notification saved.`);
    }
  } catch (error) {
    console.error(`❌ Push Error for ${name}:`, error);
  }
}

// 🛡️ PREMIUM REMINDER TEMPLATE
const getReminderTemplate = (name: string, planCount: number) => {
  const planLabel = planCount === 1 ? "Active Plan" : "Active Plans";
  const cadenceText = planCount === 1 ? "your reservation plan" : "your reservation plans";

  return `
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Korra – Payment Reminder</title>
<link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

  body {
    background: #EDE8E1;
    font-family: 'DM Sans', sans-serif;
    padding: 32px 12px; /* Slimmer outer padding */
    min-height: 100vh;
  }

  .email-wrap {
    max-width: 500px; /* Slimmer card width */
    margin: 0 auto;
  }

  /* ── MAIN CARD WRAPPER ── */
  .main-card {
    background: #FDFAF7;
    border-radius: 16px; /* Slightly softer corners for a smaller card */
    border: 1px solid #EAE0D5;
    box-shadow: 0 8px 24px rgba(28, 13, 0, 0.04);
    overflow: hidden; 
  }

  /* ── HERO SECTION ── */
  .hero {
    background: #1C0D00;
    padding: 40px 32px 32px; /* Tighter padding */
    text-align: center;
    position: relative;
    overflow: hidden;
  }
  .hero-eyebrow {
    display: inline-block;
    font-family: 'DM Sans', sans-serif;
    font-size: 10px;
    font-weight: 600;
    letter-spacing: 2px;
    text-transform: uppercase;
    color: #C27641;
    margin-bottom: 16px;
    position: relative;
    z-index: 1;
  }
  .hero h1 {
    font-family: 'DM Serif Display', serif;
    font-size: 26px; /* Scaled down from 36px */
    font-weight: 400;
    color: #FDF6EE;
    line-height: 1.2;
    margin-bottom: 10px;
    position: relative;
    z-index: 1;
  }
  .hero h1 em {
    font-style: italic;
    color: #E07A3A;
  }
  .hero-sub {
    font-size: 13px; /* Scaled down */
    color: rgba(253,246,238,0.7);
    line-height: 1.5;
    position: relative;
    z-index: 1;
  }

  /* ── BODY ── */
  .body {
    padding: 36px 32px; /* Tighter padding */
  }

  .greeting {
    font-size: 14px; /* Scaled down */
    color: #3D2B1A;
    line-height: 1.6;
    margin-bottom: 24px;
    font-weight: 300;
  }
  .greeting strong {
    font-weight: 600;
    color: #1C0D00;
  }
  .cadence-text {
    text-transform: capitalize;
  }

  /* ── BALANCE CARD ── */
  .balance-card {
    background: #1C0D00;
    border-radius: 12px;
    padding: 24px 24px; /* Tighter padding */
    margin-bottom: 28px;
    text-align: left; 
  }
  .bal-label {
    font-size: 10px;
    font-weight: 600;
    letter-spacing: 2px;
    text-transform: uppercase;
    color: #C27641;
    margin-bottom: 8px;
  }
  .bal-figure {
    font-family: 'DM Serif Display', serif;
    font-size: 32px; /* Scaled down from 42px */
    color: #FDF6EE;
    letter-spacing: -0.5px;
    line-height: 1;
    margin-bottom: 10px;
  }
  .bal-plan {
    font-size: 12px;
    color: rgba(253,246,238,0.5);
    font-weight: 400;
    margin-bottom: 20px;
  }
  .due-pill {
    display: inline-block;
    background: #A54600;
    color: #FDF6EE;
    font-size: 12px;
    font-weight: 600;
    padding: 8px 20px; /* Slimmer button */
    border-radius: 40px;
    letter-spacing: 0.3px;
    text-decoration: none;
    transition: background 0.2s;
  }
  .due-pill:hover {
    background: #8A3A00;
  }

  /* ── BODY COPY ── */
  .copy {
    font-size: 14px; /* Scaled down */
    color: #5A3E2B;
    line-height: 1.6;
    margin-bottom: 28px;
    font-weight: 300;
  }
  .copy strong {
    font-weight: 600;
    color: #1C0D00;
  }

  /* ── PRICE LOCK ROW ── */
  .lock-row {
    background: #FDF0E6;
    border-radius: 10px;
    padding: 18px 20px; /* Tighter padding */
    margin-bottom: 32px;
    text-align: left;
  }
  .lock-copy {
    font-size: 13px; /* Scaled down */
    color: #7C4A25;
    line-height: 1.5;
    font-weight: 400;
  }
  .lock-copy strong {
    font-weight: 600;
    color: #5C2D0E;
    display: block;
    margin-bottom: 4px;
  }

  /* ── CTA ── */
  .cta-wrap {
    text-align: center;
    margin-bottom: 8px;
  }
  .cta-btn {
    display: inline-block;
    background: #A54600;
    color: #FDF6EE;
    text-decoration: none;
    font-size: 14px; /* Scaled down */
    font-weight: 600;
    padding: 14px 40px; /* Sleeker button */
    border-radius: 50px;
    letter-spacing: 0.3px;
    transition: background 0.2s;
  }
  .cta-btn:hover {
    background: #8A3A00;
  }
  .cta-note {
    text-align: center;
    font-size: 12px;
    color: #B09080;
    margin-top: 12px;
    font-weight: 400;
  }

  /* ── SIGN OFF ── */
  .signoff {
    padding: 0 32px 32px;
    text-align: left;
  }
  .signoff p {
    font-size: 13px; /* Scaled down */
    color: #5A3E2B;
    line-height: 1.6;
    font-weight: 300;
    margin-bottom: 20px;
    padding-top: 28px;
    border-top: 1px solid #EAE0D5;
  }
  .signoff strong { font-weight: 600; color: #1C0D00; }
  .sig-name {
    font-family: 'DM Serif Display', serif;
    font-size: 20px; /* Scaled down */
    color: #A54600;
    margin-bottom: 4px;
  }
  .sig-role {
    font-size: 12px;
    color: #B09080;
    letter-spacing: 0.5px;
  }

  /* ── FOOTER ── */
  .footer {
    background: #1C0D00;
    text-align: center;
    padding: 28px 20px; /* Tighter padding */
  }
  
  .footer-row {
    font-size: 12px; /* Scaled down */
    color: rgba(253, 246, 238, 0.6);
    line-height: 1.5;
    margin-bottom: 12px;
  }
  .footer-logo {
    height: 14px;
    vertical-align: middle;
    margin-right: 6px;
    opacity: 0.5;
  }
  .footer a {
    color: #C27641;
    text-decoration: none;
    font-weight: 500;
  }
  .footer-disclaimer {
    font-size: 11px;
    color: rgba(253, 246, 238, 0.3);
  }

  /* 📱 MOBILE OPTIMIZATION */
  @media only screen and (max-width: 600px) {
    body { padding: 24px 8px; }
    .email-wrap { width: 100%; }
    .hero { padding: 32px 20px 24px; }
    .hero h1 { font-size: 24px; }
    .body { padding: 28px 20px; }
    
    .balance-card { 
      padding: 20px; 
      text-align: center; /* Centers the balance on mobile */
    }
    .bal-figure { font-size: 28px; }
    
    .lock-row { padding: 16px; }
    .signoff { padding: 0 20px 28px; }
    
    .cta-btn { 
      display: block; 
      width: 100%; 
      padding: 14px 0; 
    }
  }
</style>
</head>
<body>

<div class="email-wrap">
  <div class="main-card">
    <div class="hero">
      <div class="hero-eyebrow">Payment Reminder</div>
      <h1>You’re still on track<br><em>keep it going</em></h1>
      <p class="hero-sub">A small payment today keeps your plan active</p>
    </div>

    <div class="body">
      <p class="greeting">
      Hi <strong>${name}</strong>, you’re making great progress on your <strong class="cadence-text">${cadenceText}</strong> plan.

      A quick payment today keeps everything on track even a small amount counts.
      </p>

      <div class="balance-card">
        <div class="bal-label">Your Active Plans</div>
        <div class="bal-figure">${planCount} ${planLabel}</div>
        <div class="bal-plan">Your prices are still locked</div>
        <a href="https://app.korra.com.ng" class="due-pill">Open App</a>
      </div>

      <p class="copy">
        You don’t need to complete everything at once. Just keep your plan active by paying small small.

        The earlier you stay consistent, the faster you complete and collect your item.
      </p>

      <div class="lock-row">
        <div class="lock-copy">
          <strong>Your price stays the same.</strong> 
          As long as your plan remains active, your reserved item and agreed price are secured.
        </div>
      </div>

      <div class="cta-wrap">
        <a href="https://app.korra.com.ng" class="cta-btn">Continue Payment</a>
        <p class="cta-note">Takes less than a minute</p>
      </div>
    </div>

    <div class="signoff">
      <p>
        If you need help or have any questions, we’re here for you at <strong>support@korra.com.ng</strong>.
      </p>
      <p>
        Keep going you’re closer than you think.
      </p>
      <div class="sig-name">The Korra Team</div>
      <div class="sig-role">app.korra.com.ng</div>
    </div>

    <div class="footer">
      <div class="footer-row">
        <img class="footer-logo" src="https://ltytmqjpektcgwajfzfm.supabase.co/storage/v1/object/public/open/korra_logo_icon.webp" alt="Korra Icon"> 
        © 2026 Korra &nbsp;|&nbsp; <a href="mailto:support@korra.com.ng">support@korra.com.ng</a>
      </div>
      <div class="footer-disclaimer">
        You are receiving this because you have an active reservation plan.
      </div>
    </div>
  </div>

</div>

</body>
</html>
`;
};

serve(async (req) => {
  console.log("🚀 KORRA NOTIFICATION CRON TRIGGERED");
  
  try {
    const today = new Date(new Date().toLocaleString("en-US", { timeZone: "Africa/Lagos" }));
    const dayOfWeek = today.getDay(); // 0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat
    const isTuesdayOrSaturday = (dayOfWeek === 2 || dayOfWeek === 6);
    const weekNumber = Math.ceil(Math.floor((today.getTime() - new Date(today.getFullYear(), 0, 1).getTime()) / (24 * 60 * 60 * 1000)) / 7);
    const isBiWeeklyRun = isTuesdayOrSaturday && (weekNumber % 2 === 0);

    const cadencesToProcess = ['daily'];
    if (isTuesdayOrSaturday) {
      cadencesToProcess.push('weekly');
      if (isBiWeeklyRun) cadencesToProcess.push('monthly', 'flexible');
    }

    console.log("🔍 Querying Firestore for active plans...");
    const plansSnapshot = await db.collection('plans')
      .where('status', '==', 'active')
      .where('outstandingLoanAmount', '>', 0)
      .where('cadenceType', 'in', cadencesToProcess)
      .get();

    if (plansSnapshot.empty) {
      return new Response(JSON.stringify({ message: "No active plans to process today." }), { headers: { "Content-Type": "application/json" } });
    }

    // 🚀 1. THE BATCHING LOGIC (Group by Customer)
    const groupedCustomers = new Map();

    for (const doc of plansSnapshot.docs) {
      const plan = doc.data();
      const email = plan.customerEmail;
      const customerId = plan.customerId || plan.customerUid || email; // Fallback for old data
      
      if (!customerId) continue; // Safety check

      if (!groupedCustomers.has(customerId)) {
        groupedCustomers.set(customerId, {
          customerId: customerId,
          name: plan.customerName || "Customer",
          email: email,
          phone: plan.customerPhone || "No Phone",
          totalOutstandingBalance: 0,
          plans: [] // We keep track of their specific plans here
        });
      }

      // Add this plan's data to the customer's cart
      const customerRecord = groupedCustomers.get(customerId);
      customerRecord.totalOutstandingBalance += plan.outstandingLoanAmount;
      customerRecord.plans.push({
        planId: doc.id,
        cadence: plan.cadenceType,
        amountDue: plan.outstandingLoanAmount
      });
    }

    console.log(`✅ Aggregated ${plansSnapshot.size} plans into ${groupedCustomers.size} unique customers.`);

    let whatsappReportString = `📱 Korra WhatsApp Digest for ${today.toDateString()}\n`;
    whatsappReportString += `Included Cadences: ${cadencesToProcess.join(', ').toUpperCase()}\n\n`;

    // 🚀 2. SEND THE CONSOLIDATED NOTIFICATIONS
    for (const [customerId, data] of groupedCustomers.entries()) {
      const { name, email, phone, totalOutstandingBalance, plans } = data;
      const planCount = plans.length;

      console.log(`\n⚙️ --- Processing Customer: ${name} (${planCount} plans) ---`);

      // A. Send ONE Consolidated Push Notification
      await sendPushNotification(customerId, name, planCount);

      // B. Send ONE Consolidated Email
      if (email) {
        console.log(`✉️ Sending Batched Resend Email to ${email}...`);
        const userEmailRes = await fetch('https://api.resend.com/emails', {
          method: 'POST',
          headers: { 
            'Authorization': `Bearer ${RESEND_API_KEY}`, 
            'Content-Type': 'application/json' 
          },
          body: JSON.stringify({
            from: 'Korra <notifications@korra.com.ng>',
            to: [email],
            subject: planCount === 1 ? `KORRA PAYMENT REMINDER` : `Action Required: Multiple Korra Payments Due`,
            html: getReminderTemplate(name, planCount),
            tags: [{ name: 'category', value: 'reminder' }]
          })
        });

        const userEmailData = await userEmailRes.json();
        if (!userEmailRes.ok) {
          console.error(`❌ RESEND ERROR [Customer: ${email}]:`, JSON.stringify(userEmailData));
        } else {
          console.log(`✅ RESEND SUCCESS [Customer: ${email}]: Email ID ${userEmailData.id}`);
        }
      } else {
        console.warn(`⚠️ Missing email for ${name}. Skipped Resend Email.`);
      }

      // C. Append to WhatsApp Report (Shows the aggregate)
      whatsappReportString += `Name: ${name}\nCustomerID: ${customerId}\nPhone: ${phone}\nTotal Active Plans: ${planCount}\nTotal Outstanding: ₦${totalOutstandingBalance}\n---------------------------\n`;
    }

    // 6. EMAIL THE ADMIN
    if (isTuesdayOrSaturday) {
      console.log("\n✉️ Sending Admin WhatsApp Digest to roidealsinc@gmail.com...");
      const adminEmailRes = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: { 
          'Authorization': `Bearer ${RESEND_API_KEY}`, 
          'Content-Type': 'application/json' 
        },
        body: JSON.stringify({
          from: 'Korra System <system@korra.com.ng>',
          to: ['roidealsinc@gmail.com'], 
          subject: `📋 Korra WhatsApp Blast List - ${today.toDateString()}`,
          text: whatsappReportString
        })
      });
      
      const adminEmailData = await adminEmailRes.json();
      if (!adminEmailRes.ok) {
        console.error(`❌ RESEND ERROR [Admin]:`, JSON.stringify(adminEmailData));
      } else {
        console.log(`✅ RESEND SUCCESS [Admin]: Email ID ${adminEmailData.id}`);
      }
    } else {
      console.log("\n⏭️ Not Tuesday or Saturday. Skipping Admin Digest.");
    }

    return new Response(JSON.stringify({ 
      success: true, 
      totalPlansProcessed: plansSnapshot.size,
      uniqueCustomersMessaged: groupedCustomers.size 
    }), { headers: { "Content-Type": "application/json" } });

  } catch (error: any) {
    console.error("🔥 FATAL CRON ERROR:", error.message, error.stack);
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});