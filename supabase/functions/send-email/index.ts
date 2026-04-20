import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-korra-timestamp, x-korra-signature',
};

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');
const KORRA_SECRET = "7f8a9b2d4c6e1f3a5b7c9d0e2f4a6b8c1d3e5f7a9b0c2d4e6f8a1b3c5d7e9f0a";

// --- 🛡️ TEMPLATE 1: SENDING THE OTP ---
const getOtpTemplate = (name: string, code: string) => `
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Verify your Email</title>
<link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #EDE8E1; font-family: 'DM Sans', sans-serif; padding: 24px 8px; min-height: 100vh; }
  .email-wrap { max-width: 480px; margin: 0 auto; }
  .main-card { background: #FDFAF7; border-radius: 12px; box-shadow: 0 4px 20px rgba(28, 13, 0, 0.05); overflow: hidden; }
  .hero { background: #1C0D00; padding: 36px 24px 28px; text-align: center; }
  .hero-eyebrow { display: inline-block; font-size: 10px; font-weight: 600; letter-spacing: 2px; text-transform: uppercase; color: #C27641; margin-bottom: 12px; }
  .hero h1 { font-family: 'DM Serif Display', serif; font-size: 24px; font-weight: 400; color: #FDF6EE; margin-bottom: 8px; line-height: 1.2;}
  .body { padding: 32px 24px; }
  .greeting { font-size: 14px; color: #3D2B1A; line-height: 1.6; margin-bottom: 24px; font-weight: 300; }
  .otp-box { background: #FDF0E6; border-radius: 8px; padding: 24px; margin-bottom: 24px; text-align: center; }
  .otp-code { font-size: 36px; font-weight: 600; color: #A54600; letter-spacing: 8px; margin: 0; }
  .signoff { padding: 0 24px 28px; font-size: 13px; color: #5A3E2B; text-align: left; }
  .signoff p { margin-bottom: 20px; line-height: 1.6; }
  .sig-name { font-family: 'DM Serif Display', serif; font-size: 18px; color: #A54600; margin-bottom: 2px; }
  .sig-role { font-size: 12px; color: #B09080; }
  .footer { background: #1C0D00; text-align: center; padding: 24px 20px; }
  .footer-row { font-size: 12px; color: rgba(253, 246, 238, 0.6); margin-bottom: 12px; }
</style>
</head>
<body>
<div class="email-wrap">
  <div class="main-card">
    <div class="hero">
      <div class="hero-eyebrow">Security</div>
      <h1>Verify your Email</h1>
    </div>
    <div class="body">
      <p class="greeting">
        Hi${name ? ' <strong>' + name + '</strong>' : ''}, please use the code below to verify your email address. This code will expire in 10 minutes.
      </p>
      <div class="otp-box">
        <h1 class="otp-code">${code}</h1>
      </div>
      <p class="greeting" style="font-size: 13px; color: #7C4A25;">
        If you didn't request this code, you can safely ignore this email.
      </p>
    </div>
    <div class="signoff">
      <div class="sig-name">The Korra Team</div>
      <div class="sig-role">korra.com.ng</div>
    </div>
    <div class="footer">
      <div class="footer-row">© 2026 Korra &nbsp;|&nbsp; support@korra.com.ng</div>
    </div>
  </div>
</div>
</body>
</html>
`;

// --- 🎉 TEMPLATE 2: GENERIC SUCCESS MESSAGE ---
const getSuccessTemplate = (name: string) => `
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Email Verified</title>
<link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #EDE8E1; font-family: 'DM Sans', sans-serif; padding: 24px 8px; min-height: 100vh; }
  .email-wrap { max-width: 480px; margin: 0 auto; }
  .main-card { background: #FDFAF7; border-radius: 12px; box-shadow: 0 4px 20px rgba(28, 13, 0, 0.05); overflow: hidden; }
  .hero { background: #1C0D00; padding: 36px 24px 28px; text-align: center; }
  .hero-eyebrow { display: inline-block; font-size: 10px; font-weight: 600; letter-spacing: 2px; text-transform: uppercase; color: #4CAF50; margin-bottom: 12px; }
  .hero h1 { font-family: 'DM Serif Display', serif; font-size: 24px; font-weight: 400; color: #FDF6EE; margin-bottom: 8px; line-height: 1.2;}
  .body { padding: 32px 24px; }
  .greeting { font-size: 14px; color: #3D2B1A; line-height: 1.6; margin-bottom: 24px; font-weight: 300; }
  .signoff { padding: 0 24px 28px; font-size: 13px; color: #5A3E2B; text-align: left; }
  .signoff p { margin-bottom: 20px; line-height: 1.6; }
  .sig-name { font-family: 'DM Serif Display', serif; font-size: 18px; color: #A54600; margin-bottom: 2px; }
  .sig-role { font-size: 12px; color: #B09080; }
  .footer { background: #1C0D00; text-align: center; padding: 24px 20px; }
  .footer-row { font-size: 12px; color: rgba(253, 246, 238, 0.6); margin-bottom: 12px; }
</style>
</head>
<body>
<div class="email-wrap">
  <div class="main-card">
    <div class="hero">
      <div class="hero-eyebrow">Success</div>
      <h1>Email Verified</h1>
    </div>
    <div class="body">
      <p class="greeting">
        Hi${name ? ' <strong>' + name + '</strong>' : ''}, your email address has been successfully verified! 
      </p>
      <p class="greeting">
        You can continue setting up your profile on the Korra app.
      </p>
    </div>
    <div class="signoff">
      <div class="sig-name">The Korra Team</div>
      <div class="sig-role">korra.com.ng</div>
    </div>
    <div class="footer">
      <div class="footer-row">© 2026 Korra &nbsp;|&nbsp; support@korra.com.ng</div>
    </div>
  </div>
</div>
</body>
</html>
`;

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    if (req.method !== "POST") throw new Error("Only POST allowed");

    // --- HMAC VERIFICATION ---
    const clientTimestamp = req.headers.get('x-korra-timestamp');
    const clientSignature = req.headers.get('x-korra-signature');

    if (!clientTimestamp || !clientSignature) throw new Error("Unauthorized: Missing app signatures.");

    const now = Date.now();
    if (Math.abs(now - parseInt(clientTimestamp, 10)) > 120000) throw new Error("Unauthorized: Request expired.");

    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey("raw", encoder.encode(KORRA_SECRET), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
    const signatureBuffer = await crypto.subtle.sign("HMAC", key, encoder.encode(clientTimestamp));
    const expectedServerSignature = Array.from(new Uint8Array(signatureBuffer)).map(b => b.toString(16).padStart(2, '0')).join('');

    if (clientSignature !== expectedServerSignature) throw new Error("Unauthorized: App signature mismatch.");

    // --- PAYLOAD ROUTING ---
    if (!RESEND_API_KEY) throw new Error("Missing RESEND_API_KEY");

    // type is either 'send' or 'verified'
    const { type, name, email, code } = await req.json(); 

    if (!type || !email) throw new Error("Missing type or email");

    let subject = '';
    let htmlContent = '';

    if (type === 'send') {
      if (!code) throw new Error("Missing code for OTP email");
      subject = 'Your Korra Verification Code';
      htmlContent = getOtpTemplate(name || '', code);
    } 
    else if (type === 'verified') {
      subject = 'Email Verified Successfully 🎉';
      htmlContent = getSuccessTemplate(name || '');
    } 
    else {
      throw new Error("Invalid email type. Use 'send' or 'verified'.");
    }

    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`
      },
      body: JSON.stringify({
        from: 'Korra Security <security@korra.com.ng>', 
        to: [email],
        subject: subject,
        html: htmlContent,
      })
    });
    
    const data = await res.json();
    if (!res.ok) throw new Error(data.message || "Resend API error");

    return new Response(JSON.stringify({ success: true, data }), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });

  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error("Function error:", msg);
    return new Response(JSON.stringify({ error: msg }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
});