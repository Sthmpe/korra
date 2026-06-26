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
async function sendPushNotification(customerId: string, name: string, planCount: number, pushTitle: string, pushBody: string) {
  if (!customerId) return;
  
  try {
    const userRef = db.collection('customers').doc(customerId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      console.log(`🔕 User document missing for ID: ${customerId}. Skipping push.`);
      return;
    }

    // 1. Write to In-App Notifications Feed
    await userRef.collection('notifications').add({
      title: pushTitle,
      body: pushBody,
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
        notification: { title: pushTitle, body: pushBody },
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
const getReminderTemplate = (name: string, planCount: number, heroHeadline: string, balFigure: string, balSubtext: string) => {
  const planLabel = planCount === 1 ? "reserved item" : "reserved items";

  return `
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Korra – Milestone Alert</title>
<link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

  body {
    background: #EDE8E1;
    font-family: 'DM Sans', sans-serif;
    padding: 32px 12px;
    min-height: 100vh;
  }

  .email-wrap {
    max-width: 500px;
    margin: 0 auto;
  }

  /* ── MAIN CARD WRAPPER ── */
  .main-card {
    background: #FDFAF7;
    border-radius: 16px;
    box-shadow: 0 8px 30px rgba(28, 13, 0, 0.06);
    overflow: hidden; 
  }

  /* ── HERO SECTION ── */
  .hero {
    background: #1C0D00;
    padding: 40px 32px 32px;
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
    font-size: 26px;
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
    font-size: 13px;
    color: rgba(253,246,238,0.7);
    line-height: 1.5;
    position: relative;
    z-index: 1;
  }

  /* ── BODY ── */
  .body {
    padding: 36px 32px;
  }

  .greeting {
    font-size: 14px;
    color: #3D2B1A;
    line-height: 1.6;
    margin-bottom: 24px;
    font-weight: 300;
  }
  .greeting strong {
    font-weight: 600;
    color: #1C0D00;
  }

  /* ── BALANCE CARD ── */
  .balance-card {
    background: #1C0D00;
    border-radius: 12px;
    padding: 24px 24px;
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
    font-size: 32px;
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
    padding: 8px 20px;
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
    font-size: 14px;
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
    padding: 18px 20px;
    margin-bottom: 32px;
    text-align: left;
  }
  .lock-copy {
    font-size: 13px;
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
    font-size: 14px;
    font-weight: 600;
    padding: 14px 40px;
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
    font-size: 13px;
    color: #5A3E2B;
    line-height: 1.6;
    font-weight: 300;
    margin-bottom: 20px;
    padding-top: 28px;
  }
  .signoff strong { font-weight: 600; color: #1C0D00; }
  .sig-name {
    font-family: 'DM Serif Display', serif;
    font-size: 20px;
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
    padding: 28px 20px;
  }
  
  .footer-row {
    font-size: 12px;
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
      text-align: center; 
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
      <div class="hero-eyebrow">Milestone Alert</div>
      <h1>${heroHeadline}</h1>
      <p class="hero-sub">Add to your progress today to unlock your items</p>
    </div>

    <div class="body">
      <p class="greeting">
      Hi <strong>${name}</strong>, you're making great progress.

      Every bit counts—add to your progress today to keep your streak alive.
      </p>

      <div class="balance-card">
        <div class="bal-label">Total Progress</div>
        <div class="bal-figure">${balFigure}</div>
        <div class="bal-plan">${balSubtext} &bull; ${planCount} ${planLabel}</div>
        <a href="https://app.korra.com.ng" class="due-pill">Open App</a>
      </div>

      <p class="copy">
        You don't need to complete everything at once. Just keep your momentum going by dropping small amounts.

        The earlier you stay consistent, the faster you unlock your items.
      </p>

      <div class="lock-row">
        <div class="lock-copy">
          <strong>Your price stays the same.</strong> 
          As long as your momentum continues, your reserved items and agreed prices are secured.
        </div>
      </div>

      <div class="cta-wrap">
        <a href="https://app.korra.com.ng" class="cta-btn">Add to Progress</a>
        <p class="cta-note">Takes less than a minute</p>
      </div>
    </div>

    <div class="signoff">
      <p>
        If you need help or have any questions, we're here for you at <strong>support@korra.com.ng</strong>.
      </p>
      <p>
        Keep going you're closer than you think.
      </p>
      <div class="sig-name">The Korra Team</div>
      <div class="sig-role">app.korra.com.ng</div>
    </div>

    <div class="footer">
      <div class="footer-row">
        <img class="footer-logo" src="https://ltytmqjpektcgwajfzfm.supabase.co/storage/v1/object/public/open/korra_logo_icon.webp" alt="Korra Icon"> 
        &copy; 2026 Korra &nbsp;|&nbsp; <a href="mailto:support@korra.com.ng">support@korra.com.ng</a>
      </div>
      <div class="footer-disclaimer">
        You are receiving this because you have active reserved items.
      </div>
    </div>
  </div>

</div>

</body>
</html>
`;
};


// ============================================================
// SAFE AWAIT — catches errors without breaking other channels
// Returns [error, data] — if error has value it failed, if data has value it succeeded
// ============================================================
async function safeAwait<T>(promise: Promise<T>) {
  try {
    const data = await promise;
    return [null, data] as const;
  } catch (error) {
    return [error, null] as const;
  }
}

// ============================================================
// SEND WHATSAPP VIA RENDER (BAILEYS)
// Posts customer data to the Render server which uses Korra
// to craft a natural AI message and send to customer's WhatsApp
// ============================================================
const RENDER_URL = Deno.env.get('RENDER_URL') ?? '';
const RENDER_SECRET = Deno.env.get('RENDER_SECRET') ?? '';

async function sendBaileysWhatsApp(phone: string, name: string, progressPercentage: number, planCount: number, pushBody: string) {
  if (!phone || phone === 'No Phone') throw new Error('No phone number available');
  if (!RENDER_URL) throw new Error('RENDER_URL not set');

  const res = await fetch(`${RENDER_URL}/send-reminder`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-secret-key': RENDER_SECRET
    },
    body: JSON.stringify({ phone, name, progressPercentage, planCount, pushBody })
  });

  if (!res.ok) {
    const errData = await res.json().catch(() => ({}));
    throw new Error(`Render responded with ${res.status}: ${JSON.stringify(errData)}`);
  }

  return await res.json();
}

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
          totalAmount: 0,       // sum of all plan totalAmount fields
          totalAmountPaid: 0,   // sum of all plan amountPaid fields
          plans: []
        });
      }

      // Add this plan's data to the customer's cart
      const customerRecord = groupedCustomers.get(customerId);
      customerRecord.totalOutstandingBalance += plan.outstandingLoanAmount;
      customerRecord.totalAmount += plan.totalAmount || 0;
      customerRecord.totalAmountPaid += plan.amountPaid || 0;
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
    // Using Promise.allSettled — all customers processed concurrently.
    // One customer failing does NOT stop others from being notified.
    const customersArray = [...groupedCustomers.values()];

    const results = await Promise.allSettled(
      customersArray.map(async (data) => {
        const { customerId, name, email, phone, totalOutstandingBalance, totalAmount, totalAmountPaid, plans } = data;
        const planCount = plans.length;

        console.log(`\n⚙️ --- Processing Customer: ${name} (${planCount} plans) ---`);

        // 🎯 Calculate progress percentage
        const progressPercentage = totalAmount > 0
          ? Math.min(100, Math.round((totalAmountPaid / totalAmount) * 100))
          : 0;
        const remainingPercentage = 100 - progressPercentage;

        // 🎯 3-Phase Milestone Logic
        let pushTitle = "";
        let pushBody = "";
        let heroHeadline = "";
        let balFigure = "";
        let balSubtext = "";

        if (progressPercentage < 40) {
          // 🟢 Phase 1: The Start
          pushTitle = "Great start! 🎯";
          pushBody = `Hi ${name}, you've already unlocked ${progressPercentage}% of your target. Add to your progress today to keep that momentum going!`;
          heroHeadline = `You've unlocked ${progressPercentage}%<br><em>keep your momentum</em>`;
          balFigure = `${progressPercentage}% Unlocked`;
          balSubtext = "You are making solid progress";
        } else if (progressPercentage <= 60) {
          // 🟡 Phase 2: The Middle
          pushTitle = "Halfway there! ⚖️";
          pushBody = `Hi ${name}, you are ${progressPercentage}% of the way there! Add to your progress today and cross that halfway mark.`;
          heroHeadline = `You are ${progressPercentage}% there<br><em>keep pushing forward</em>`;
          balFigure = `${progressPercentage}% Unlocked`;
          balSubtext = "You are crossing the halfway mark";
        } else {
          // 🔴 Phase 3: The Finish Line
          pushTitle = "Almost there! 🏁";
          pushBody = `Hi ${name}, you are just ${remainingPercentage}% away from unlocking your items! Add to your progress today to close the gap.`;
          heroHeadline = `Only ${remainingPercentage}% left<br><em>finish strong</em>`;
          balFigure = `Only ${remainingPercentage}% Remaining`;
          balSubtext = "You are so close to the finish line";
        }

        console.log(`📊 Progress: ${progressPercentage}% | Phase: ${progressPercentage < 40 ? 'Start' : progressPercentage <= 60 ? 'Middle' : 'Finish'}`);

        let channelStatus = "";

        // 🛡️ A. PUSH NOTIFICATION BLOCK
        const [pushErr] = await safeAwait(
          sendPushNotification(customerId, name, planCount, pushTitle, pushBody)
        );
        if (pushErr) {
          console.error(`❌ Push crashed for ${name}:`, pushErr);
          channelStatus += "Push: ❌ | ";
        } else {
          channelStatus += "Push: ✅ | ";
        }

        // 🛡️ B. EMAIL BLOCK
        if (email) {
          const [emailErr] = await safeAwait(
            fetch('https://api.resend.com/emails', {
              method: 'POST',
              headers: { 
                'Authorization': `Bearer ${RESEND_API_KEY}`, 
                'Content-Type': 'application/json' 
              },
              body: JSON.stringify({
                from: 'Korra <notifications@korra.com.ng>',
                to: [email],
                subject: planCount === 1 ? `KORRA PAYMENT REMINDER` : `Action Required: Multiple Korra Payments Due`,
                html: getReminderTemplate(name, planCount, heroHeadline, balFigure, balSubtext),
                tags: [{ name: 'category', value: 'reminder' }]
              })
            }).then(async (res) => {
              const data = await res.json();
              if (!res.ok) throw new Error(`Resend error: ${JSON.stringify(data)}`);
              console.log(`✅ RESEND SUCCESS [Customer: ${email}]: Email ID ${data.id}`);
              return data;
            })
          );
          if (emailErr) {
            console.error(`❌ Email crashed for ${name}:`, emailErr);
            channelStatus += "Email: ❌ | ";
          } else {
            channelStatus += "Email: ✅ | ";
          }
        } else {
          console.warn(`⚠️ Missing email for ${name}. Skipped Resend Email.`);
          channelStatus += "Email: ⚠️ No email | ";
        }

        // 🛡️ C. WHATSAPP BLOCK
        if (phone && phone !== 'No Phone') {
          const [waErr] = await safeAwait(
            sendBaileysWhatsApp(phone, name, progressPercentage, planCount, pushBody)
          );
          if (waErr) {
            console.error(`❌ WhatsApp crashed for ${name}:`, waErr);
            channelStatus += "WhatsApp: ❌";
          } else {
            channelStatus += "WhatsApp: ✅";
          }
        } else {
          channelStatus += "WhatsApp: ⚠️ No phone";
        }

        console.log(`📋 Channel Status for ${name}: ${channelStatus}`);

        // D. Return report line with channel status
        return `Name: ${name}\nCustomerID: ${customerId}\nPhone: ${phone}\nTotal Active Plans: ${planCount}\nTotal Outstanding: ₦${totalOutstandingBalance}\nProgress: ${progressPercentage}%\nChannels: ${channelStatus}\nSTATUS: ✅ SUCCESS\n---------------------------\n`;
      })
    );

    // 🚀 4. AUDIT RESULTS
    let successCount = 0;
    const failedCustomers: { name: string; id: string; error: any }[] = [];

    results.forEach((result, index) => {
      const currentCustomer = customersArray[index];
      if (result.status === 'fulfilled') {
        successCount++;
        whatsappReportString += result.value;
      } else {
        failedCustomers.push({
          name: currentCustomer.name,
          id: currentCustomer.customerId,
          error: result.reason
        });
        whatsappReportString += `Name: ${currentCustomer.name}\nCustomerID: ${currentCustomer.customerId}\nSTATUS: ⚠️ FAILED TO PROCESS\n---------------------------\n`;
      }
    });

    // 🚀 5. THE BATCH LOG
    console.log(`\n🏁 Processing Complete! Success: ${successCount} | Failed: ${failedCustomers.length}`);

    if (failedCustomers.length > 0) {
      console.error(`🚨 BATCH FAILURE ALERT: ${failedCustomers.length} notifications failed to send.`, JSON.stringify(failedCustomers, null, 2));
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