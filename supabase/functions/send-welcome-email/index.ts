import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// 1. DEFINE CORS HEADERS
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');

// --- 🛡️ PREMIUM CUSTOMER TEMPLATE ---
const getCustomerTemplate = (name: string) => `
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Welcome to Korra</title>
<link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #EDE8E1; font-family: 'DM Sans', sans-serif; padding: 24px 8px; min-height: 100vh; }
  .email-wrap { max-width: 480px; margin: 0 auto; }
  
  /* Removed border, kept soft shadow */
  .main-card { background: #FDFAF7; border-radius: 12px; box-shadow: 0 4px 20px rgba(28, 13, 0, 0.05); overflow: hidden; }
  
  .hero { background: #1C0D00; padding: 36px 24px 28px; text-align: center; }
  .hero-eyebrow { display: inline-block; font-size: 10px; font-weight: 600; letter-spacing: 2px; text-transform: uppercase; color: #C27641; margin-bottom: 12px; }
  .hero h1 { font-family: 'DM Serif Display', serif; font-size: 24px; font-weight: 400; color: #FDF6EE; margin-bottom: 8px; line-height: 1.2;}
  .hero h1 em { font-style: italic; color: #E07A3A; }
  .hero-sub { font-size: 13px; color: rgba(253,246,238,0.7); line-height: 1.5; }
  
  /* Tighter padding for mobile feel */
  .body { padding: 32px 24px; }
  .greeting { font-size: 14px; color: #3D2B1A; line-height: 1.6; margin-bottom: 24px; font-weight: 300; }
  .greeting strong { font-weight: 600; color: #1C0D00; }
  
  /* Borderless info boxes */
  .info-box { background: #FDF0E6; border-radius: 8px; padding: 20px 16px; margin-bottom: 24px; }
  .info-box.alert { background: #FFF4F4; } 
  .box-title { font-size: 11px; font-weight: 600; letter-spacing: 1.5px; text-transform: uppercase; margin-bottom: 12px; color: #C27641; }
  .box-title.alert-title { color: #D92D20; }
  
  ul { padding-left: 0; list-style: none; margin: 0; }
  li { font-size: 13px; color: #7C4A25; line-height: 1.6; margin-bottom: 12px; padding-left: 16px; position: relative; }
  .alert li { color: #912018; }
  li::before { content: "•"; color: #A54600; font-size: 18px; position: absolute; left: 0; top: -2px; }
  .alert li::before { color: #D92D20; }
  li strong { font-weight: 600; color: #5C2D0E; display: block; margin-bottom: 2px; }
  .alert li strong { color: #7A271A; }

  .cta-wrap { text-align: center; margin-top: 24px; margin-bottom: 8px; }
  .cta-btn { display: inline-block; background: #A54600; color: #FDF6EE; text-decoration: none; font-size: 14px; font-weight: 600; padding: 14px 40px; border-radius: 50px; }
  
  /* Borderless signoff */
  .signoff { padding: 0 24px 28px; font-size: 13px; color: #5A3E2B; text-align: left; }
  .signoff p { padding-top: 12px; margin-bottom: 20px; line-height: 1.6; }
  .sig-name { font-family: 'DM Serif Display', serif; font-size: 18px; color: #A54600; margin-bottom: 2px; }
  .sig-role { font-size: 12px; color: #B09080; }
  
  .footer { background: #1C0D00; text-align: center; padding: 24px 20px; }
  .footer-row { font-size: 12px; color: rgba(253, 246, 238, 0.6); margin-bottom: 12px; }
  .footer-logo { height: 14px; vertical-align: middle; margin-right: 6px; opacity: 0.5; }
  .footer a { color: #C27641; text-decoration: none; font-weight: 500; }
  
  /* Mobile specific adjustments */
  @media only screen and (max-width: 600px) { 
    body { padding: 16px 8px; } 
    .cta-btn { display: block; width: 100%; padding: 14px 0; } 
  }
</style>
</head>
<body>
<div class="email-wrap">
  <div class="main-card">
    <div class="hero">
      <div class="hero-eyebrow">Welcome</div>
      <h1>Welcome to <em>Korra</em></h1>
      <p class="hero-sub">Pay small small for what you want without pressure.</p>
    </div>
    <div class="body">
      <p class="greeting">
        Hi <strong>${name}</strong>, welcome to Korra, a simple way to get what you want without paying everything upfront. Start small, pay gradually, and stay in control of your money.
      </p>
      
      <div class="info-box">
        <div class="box-title">How Korra Works</div>
        <ul>
          <li><strong>Get a Payment Plan:</strong> Your merchant creates a plan for the item you want.</li>
          <li><strong>Start with a Deposit:</strong> Pay a small amount to begin.</li>
          <li><strong>Pay Small Small:</strong> Continue payments at your own pace until complete.</li>
        </ul>
      </div>

      <div class="info-box alert">
        <div class="box-title alert-title">Important Things to Know</div>
        <ul>
          <li><strong>Your Price is Locked:</strong> Once you start, the price stays the same no sudden increases.</li>
          
          <li><strong>Your Money is Safe:</strong> If you cancel, your payment is not lost. It remains as Store Balance with the merchant, so you can use it for another purchase.</li>
          
          <li><strong>Collect Safely:</strong> Only share your Pickup Code when you are physically collecting your item.</li>
          
          <li><strong>Stay Within Korra:</strong> Always make payments inside Korra. If anything feels wrong, contact us at <strong>support@korra.com.ng</strong>.</li>
        </ul>
      </div>

      <div class="cta-wrap">
        <a href="https://korra.com.ng" class="cta-btn">Start Your First Payment</a>
      </div>
    </div>
    <div class="signoff">
      <p>Need help getting started? We're always here for you at <strong>support@korra.com.ng</strong>.</p>
      <div class="sig-name">The Korra Team</div>
      <div class="sig-role">korra.com.ng</div>
    </div>
    <div class="footer">
      <div class="footer-row">
        <img class="footer-logo" src="https://ltytmqjpektcgwajfzfm.supabase.co/storage/v1/object/public/open/korra_logo_icon.webp" alt="Korra Icon"> 
        © 2026 Korra &nbsp;|&nbsp; <a href="mailto:support@korra.com.ng">support@korra.com.ng</a>
      </div>
    </div>
  </div>
</div>
</body>
</html>
`;

// --- 🚀 PREMIUM VENDOR TEMPLATE ---
const getVendorTemplate = (name: string) => `
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Welcome to Korra Partners</title>
<link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #EDE8E1; font-family: 'DM Sans', sans-serif; padding: 24px 8px; min-height: 100vh; }
  .email-wrap { max-width: 480px; margin: 0 auto; }
  
  /* Borderless, soft shadow */
  .main-card { background: #FDFAF7; border-radius: 12px; box-shadow: 0 4px 20px rgba(28, 13, 0, 0.05); overflow: hidden; }
  
  .hero { background: #1C0D00; padding: 36px 24px 28px; text-align: center; }
  .hero-eyebrow { display: inline-block; font-size: 10px; font-weight: 600; letter-spacing: 2px; text-transform: uppercase; color: #C27641; margin-bottom: 12px; }
  .hero h1 { font-family: 'DM Serif Display', serif; font-size: 24px; font-weight: 400; color: #FDF6EE; margin-bottom: 8px; line-height: 1.2;}
  .hero h1 em { font-style: italic; color: #E07A3A; }
  .hero-sub { font-size: 13px; color: rgba(253,246,238,0.7); line-height: 1.5; }
  
  /* Tighter padding */
  .body { padding: 32px 24px; }
  .greeting { font-size: 14px; color: #3D2B1A; line-height: 1.6; margin-bottom: 24px; font-weight: 300; }
  .greeting strong { font-weight: 600; color: #1C0D00; }
  
  /* Borderless info boxes */
  .info-box { background: #FDF0E6; border-radius: 8px; padding: 20px 16px; margin-bottom: 24px; }
  .info-box.alert { background: #FFF4F4; }
  .box-title { font-size: 11px; font-weight: 600; letter-spacing: 1.5px; text-transform: uppercase; margin-bottom: 12px; color: #C27641; }
  .box-title.alert-title { color: #D92D20; }
  
  ul { padding-left: 0; list-style: none; margin: 0; }
  li { font-size: 13px; color: #7C4A25; line-height: 1.6; margin-bottom: 12px; padding-left: 16px; position: relative; }
  .alert li { color: #912018; }
  li::before { content: "•"; color: #A54600; font-size: 18px; position: absolute; left: 0; top: -2px; }
  .alert li::before { color: #D92D20; }
  li strong { font-weight: 600; color: #5C2D0E; display: block; margin-bottom: 2px; }
  .alert li strong { color: #7A271A; }

  .cta-wrap { text-align: center; margin-top: 24px; margin-bottom: 8px; }
  .cta-btn { display: inline-block; background: #A54600; color: #FDF6EE; text-decoration: none; font-size: 14px; font-weight: 600; padding: 14px 40px; border-radius: 50px; }
  
  /* Clean signoff */
  .signoff { padding: 0 24px 28px; font-size: 13px; color: #5A3E2B; text-align: left; }
  .signoff p { padding-top: 12px; margin-bottom: 20px; line-height: 1.6; }
  .sig-name { font-family: 'DM Serif Display', serif; font-size: 18px; color: #A54600; margin-bottom: 2px; }
  .sig-role { font-size: 12px; color: #B09080; }
  
  .footer { background: #1C0D00; text-align: center; padding: 24px 20px; }
  .footer-row { font-size: 12px; color: rgba(253, 246, 238, 0.6); margin-bottom: 12px; }
  .footer-logo { height: 14px; vertical-align: middle; margin-right: 6px; opacity: 0.5; }
  .footer a { color: #C27641; text-decoration: none; font-weight: 500; }
  
  @media only screen and (max-width: 600px) { 
    body { padding: 16px 8px; } 
    .cta-btn { display: block; width: 100%; padding: 14px 0; } 
  }
</style>
</head>
<body>
<div class="email-wrap">
  <div class="main-card">
    <div class="hero">
      <div class="hero-eyebrow">Partner Network</div>
      <h1>Welcome to <em>Korra</em></h1>
      <p class="hero-sub">Close more sales without the stress of tracking payments.</p>
    </div>
    <div class="body">
      <div class="greeting">
        <p>Hi <strong>${name}</strong>, welcome to Korra.</p>
        <p>Now you can close more sales by allowing customers to pay in parts while Korra handles the tracking for you.</p>
      </div>
      
      <div class="info-box">
        <div class="box-title">Why Merchants Use Korra</div>
        <ul>
          <li><strong>More Closed Sales:</strong> Customers who can’t pay upfront can start paying immediately.</li>
          
          <li><strong>Less Stress:</strong> No more tracking payments manually across chats and notes.</li>
          
          <li><strong>Payments Stay With You:</strong> If a customer cancels, their payments remain as Store Balance with your business.</li>
        </ul>
      </div>

      <div class="info-box alert">
        <div class="box-title alert-title">Important Guidelines</div>
        <ul>
          <li><strong>Reserve the Item:</strong> Once a plan starts, keep the item for that customer.</li>
          
          <li><strong>Keep Prices Consistent:</strong> Do not change the agreed price after payment has started.</li>
          
          <li><strong>Verify Before Release:</strong> Always confirm full payment before handing over the item.</li>
          
          <li><strong>Use Korra for Payments:</strong> Keep all transactions within Korra for clarity and protection.</li>
        </ul>
      </div>

      <div class="cta-wrap">
        <a href="https://business.korra.com.ng" class="cta-btn">Open Dashboard</a>
      </div>
    </div>
    <div class="signoff">
      <p>We will be reaching out shortly to verify your details and list your store.</p>
      <p>Need help? We're here to support you at <strong>support@korra.com.ng</strong>.</p>
      <div class="sig-name">The Korra Team</div>
      <div class="sig-role">business.korra.com.ng</div>
    </div>
    <div class="footer">
      <div class="footer-row">
        <img class="footer-logo" src="https://ltytmqjpektcgwajfzfm.supabase.co/storage/v1/object/public/open/korra_logo_icon.webp" alt="Korra Icon"> 
        © 2026 Korra &nbsp;|&nbsp; <a href="mailto:support@korra.com.ng">support@korra.com.ng</a>
      </div>
    </div>
  </div>
</div>
</body>
</html>
`;

// ============================================================
// SAFE AWAIT — catches errors without breaking other channels
// Returns [error, data] — if error has value it failed
// ============================================================
async function safeAwait<T>(promise: Promise<T>) {
  try {
    const data = await promise;
    return [null, data] as const;
  } catch (error) {
    return [error, null] as const;
  }
}

serve(async (req) => {
  // A. CORS Pre-flight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { name, email, phone, userType } = await req.json(); // userType: 'customer' | 'vendor'

    if (!RESEND_API_KEY) {
      throw new Error("Missing RESEND_API_KEY environment variable");
    }

    if (!name || !email) {
      return new Response(JSON.stringify({ error: "Missing name or email" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 1. Select Template based on User Type
    const isVendor = userType === 'vendor';
    const subject = isVendor ? 'Welcome to Korra Business! 🚀' : 'Welcome to Korra! + Safety Tips 🛡️';
    const htmlContent = isVendor ? getVendorTemplate(name) : getCustomerTemplate(name);
    const fromName = isVendor ? 'Korra Business Team' : 'Korra Team';

    // 2. Send Email via Resend
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`
      },
      body: JSON.stringify({
        from: `${fromName} <notifications@korra.com.ng>`, 
        to: [email],
        subject: subject,
        html: htmlContent,
        tags: [{ name: 'category', value: 'welcome' }],
      })
    });
    
    const data = await res.json();

    if (!res.ok) {
      console.error("Resend API error:", data);
      return new Response(JSON.stringify({ error: data }), {
        status: res.status,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 3. Send WhatsApp welcome via Render
    // We await just to confirm Render received it — not to wait for WhatsApp to finish.
    // Render returns 200 immediately, then handles WhatsApp in its own background async.
    const RENDER_URL = Deno.env.get('RENDER_URL') ?? '';
    const RENDER_SECRET = Deno.env.get('RENDER_SECRET') ?? '';

    if (phone && RENDER_URL) {
      const [renderErr] = await safeAwait(
        fetch(`${RENDER_URL}/send-welcome`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-secret-key': RENDER_SECRET
          },
          body: JSON.stringify({ phone, name, userType })
        }).then(async (waRes) => {
          if (!waRes.ok) throw new Error(`Render responded ${waRes.status}`);
          return waRes.json();
        })
      );

      if (renderErr) {
        console.error(`❌ Render did not receive welcome for ${name}:`, renderErr.message);
      } else {
        console.log(`✅ Render received welcome request for ${name} — WhatsApp sending in background`);
      }
    } else if (!phone) {
      console.log(`⚠️ No phone for ${name} — skipping WhatsApp welcome.`);
    } else {
      console.log('⚠️ RENDER_URL not set — skipping WhatsApp welcome.');
    }

    // 4. Return success immediately — email is done, WhatsApp is handled in background
    return new Response(JSON.stringify({ success: true, data }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error("Function error:", msg);
    return new Response(JSON.stringify({ error: msg }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
