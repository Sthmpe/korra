import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// 1. DEFINE CORS HEADERS
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');

// --- EMAIL TEMPLATES ---

// 🛡️ UPDATED CUSTOMER TEMPLATE
const getCustomerTemplate = (name: string) => `
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: sans-serif; background-color: #f6f7fb; padding: 20px; }
    .container { background: #ffffff; max-width: 600px; margin: 0 auto; border-radius: 12px; padding: 0; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
    .header { background-color: #A54600; padding: 20px; text-align: center; }
    .content { padding: 30px; color: #333; }
    h1 { color: #A54600; font-size: 20px; }
    .warning-box { background-color: #fff4e5; border-left: 5px solid #ff9800; padding: 15px; margin: 20px 0; font-size: 13px; color: #663c00; }
    .btn { display: inline-block; background: #A54600; color: #fff; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold; margin-top: 20px; }
    .footer { text-align: center; font-size: 11px; color: #aaa; padding: 20px; background: #fafafa; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
       <img src="https://ltytmqjpektcgwajfzfm.supabase.co/storage/v1/object/public/open/korra_logo_white.png" alt="Korra" height="30">
    </div>
    <div class="content">
      <h1>Welcome to Korra, ${name}! 👋</h1>
      <p>You are now part of the smartest way to shop. With Korra, you can reserve items, pay small-small, and pick up when you're ready.</p>
      
      <div class="warning-box">
        <strong>🛡️ SAFETY FIRST: AVOID SCAMS</strong>
        <p>Your safety is our priority. Please follow these rules:</p>
        <ul>
          <li><strong>Verify Your Vendor:</strong> Ensure you are transacting with a reliable vendor, not just a random person. If a deal looks too good to be true, be careful.</li>
          <li><strong>Protect Your PIN:</strong> Do NOT share your Pickup Code until your order is physically confirmed and inspected. This code confirms order fulfilment.</li>
          <li><strong>Report Suspicious Activity:</strong> If a vendor asks for payment outside the app, report them immediately.</li>
        </ul>
      </div>

      <p>Ready to start your first plan?</p>
      <a href="#" class="btn">Start Shopping</a>
    </div>
    <div class="footer">
      © 2025 Korra. Need help? Contact support@korra.com.ng
    </div>
  </div>
</body>
</html>
`;

// 🚀 VENDOR TEMPLATE (Kept same as before)
const getVendorTemplate = (name: string) => `
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: sans-serif; background-color: #f6f7fb; padding: 20px; }
    .container { background: #ffffff; max-width: 600px; margin: 0 auto; border-radius: 12px; padding: 0; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
    .header { background-color: #004d40; padding: 20px; text-align: center; } 
    .content { padding: 30px; color: #333; }
    h1 { color: #004d40; font-size: 20px; }
    .tips-box { background-color: #e0f2f1; border-left: 5px solid #009688; padding: 15px; margin: 20px 0; font-size: 13px; color: #004d40; }
    .btn { display: inline-block; background: #004d40; color: #fff; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold; margin-top: 20px; }
    .footer { text-align: center; font-size: 11px; color: #aaa; padding: 20px; background: #fafafa; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
       <img src="https://ltytmqjpektcgwajfzfm.supabase.co/storage/v1/object/public/open/korra_logo_white.png" alt="Korra Business" height="30">
    </div>
    <div class="content">
      <h1>Welcome to Korra Business, ${name}! 🚀</h1>
      <p>Your store is now live. Korra helps you secure sales faster by allowing customers to pay in installments while you keep the stock.</p>
      
      <div class="tips-box">
        <strong>📈 HOW TO SUCCEED & BUILD TRUST</strong>
        <ul>
          <li><strong>Real Photos Only:</strong> Customers trust vendors who upload clear, original photos of products.</li>
          <li><strong>Be Responsive:</strong> Answer customer questions quickly to build your reputation.</li>
          <li><strong>No Scams:</strong> We have a zero-tolerance policy. If you are reported for fake products, your wallet will be locked immediately.</li>
        </ul>
      </div>

      <p>Upload your first product now and start selling!</p>
      <a href="#" class="btn">Go to Dashboard</a>
    </div>
    <div class="footer">
      © 2025 Korra. Need help? Contact support@korra.com.ng
    </div>
  </div>
</body>
</html>
`;


serve(async (req) => {
  // A. CORS Pre-flight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { name, email, userType } = await req.json(); // userType: 'customer' | 'vendor'

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
        from: `${fromName} <hello@mail.korra.com.ng>`, 
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