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
    /* Premium Typography and Background */
    body { 
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; 
      background-color: #f4f5f7; 
      padding: 30px 14px; 
      margin: 0; 
    }
    
    /* Sleeker Main Card */
    .container { 
      background: #ffffff; 
      max-width: 600px; 
      margin: 0 auto; 
      border-radius: 8px; 
      box-shadow: 0 2px 10px rgba(0,0,0,0.04); 
      border-top: 3px solid #A54600; /* Thinner, refined accent bar */
      text-align: center; 
    }
    
    .logo-container { 
      padding: 35px 20px 15px; 
    }
    
    /* Scaled-down Typography */
    .content { 
      padding: 0 35px 35px; 
      color: #374151; 
      line-height: 1.6; 
      font-size: 12px; 
    }
    h1 { 
      color: #111827; 
      font-size: 18px; 
      font-weight: 600; 
      margin-bottom: 8px; 
    }
    p { 
      margin-bottom: 18px; 
      color: #4b5563; 
    }

    /* Clean, borderless information cards */
    .info-box { 
      background-color: #f9fafb; 
      border-radius: 6px; 
      padding: 20px; 
      margin: 25px 0; 
      text-align: left; 
    }
    .warning-box { 
      background-color: #fffdfa; 
      border-radius: 6px; 
      padding: 20px; 
      margin: 25px 0; 
      text-align: left; 
    }
    
    /* Adjusted Card Headers */
    .box-title { 
      font-size: 12px; 
      text-transform: uppercase; 
      letter-spacing: 1px; 
      font-weight: 700; 
      text-align: center; 
      margin-top: 0; 
      margin-bottom: 15px; 
    }
    .info-title { color: #6b7280; }
    .warning-title { color: #A54600; }

    /* Custom Bullet Points */
    ul { 
      padding: 0; 
      list-style: none; 
      margin: 0; 
    }
    li { 
      margin-bottom: 14px; 
      font-size: 12px; 
      padding-left: 20px; 
      position: relative; 
    }
    li::before { 
      content: "•"; 
      color: #A54600; 
      font-size: 16px; 
      position: absolute; 
      left: 0; 
      top: -2px; 
    }
    li strong { color: #111827; }

    /* Button */
    .btn { 
      display: inline-block; 
      background: #A54600; 
      color: #ffffff; 
      padding: 14px 28px; 
      text-decoration: none; 
      border-radius: 6px; 
      font-weight: 600; 
      margin-top: 15px; 
      font-size: 14px; 
    }

    /* Footer */
    .footer { 
      text-align: center; 
      font-size: 12px; 
      color: #9ca3af; 
      padding: 25px; 
      background: #fafbfc; 
      border-top: 1px solid #f3f4f6; 
    }
  </style>
</head>
<body>
  <div class="container">
    
    <div class="logo-container">
       <img src="https://ltytmqjpektcgwajfzfm.supabase.co/storage/v1/object/public/open/korra_logo_icon.webp" alt="Korra" height="60">
    </div>

    <div class="content">
      <h1>Welcome to Korra, ${name}! 👋</h1>
      <p>You’ve just joined the smartest way to beat inflation. Lock the price of high-ticket items today, and pay at your own pace.</p>
      
      <div class="info-box">
        <div class="box-title info-title">🚀 How Korra Works</div>
        <ul>
          <li><strong>Find a Merchant/Vendor:</strong> Walk directly into any partner physical store, or check our online directory for suggestions.</li>
          <li><strong>Get a Code:</strong> Chat with the merchant/vendor, agree on a price, and they will generate your Payment Code.</li>
          <li><strong>Lock & Pay:</strong> Enter the code in the app. Payments are processed securely by our partner, <strong>Monnify by Moniepoint</strong>.</li>
        </ul>
      </div>

      <div class="warning-box">
        <div class="box-title warning-title">⚠️ The Golden Rules</div>
        <ul>
          <li><strong>The Price Lock:</strong> The moment you make your first payment, your price is completely frozen. It will not change.</li>
          <li><strong>Store Credit Only:</strong> We do not offer cash refunds. If you cancel a plan or miss a deadline, your money becomes <strong>Store Credit</strong> to be spent only with that specific merchant/vendor.</li>
          <li><strong>Proof of Collection:</strong> Do NOT share your Pickup Code until you are physically holding the item. This code serves as your official proof of collection to prevent future disputes.</li>
          <li><strong>Report Issues:</strong> If you face any challenges or suspicious activity, please report it to our support team immediately.</li>
        </ul>
      </div>

      <p>Looking for a place to start shopping?</p>
      <a href="https://korra.com.ng" class="btn">Explore Merchants/Vendors</a>
    </div>

    <div class="footer">
      © 2026 Korra. Need help? Contact support@korra.com.ng
    </div>
  </div>
</body>
</html>
`;

// 🚀 VENDOR TEMPLATE 
const getVendorTemplate = (name: string) => `
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    /* Premium Typography and Background */
    body { 
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; 
      background-color: #f4f5f7; 
      padding: 30px 14px; 
      margin: 0; 
    }
    
    /* Sleeker Main Card */
    .container { 
      background: #ffffff; 
      max-width: 600px; 
      margin: 0 auto; 
      border-radius: 8px; 
      box-shadow: 0 2px 10px rgba(0,0,0,0.04); 
      border-top: 3px solid #A54600; /* Thinner, refined accent bar */
      text-align: center; 
    }
    
    .logo-container { 
      padding: 35px 20px 15px; 
    }
    
    /* Scaled-down Typography */
    .content { 
      padding: 0 35px 35px; 
      color: #374151; 
      line-height: 1.6; 
      font-size: 12px; 
    }
    h1 { 
      color: #111827; 
      font-size: 18px; 
      font-weight: 600; 
      margin-bottom: 8px; 
    }
    p { 
      margin-bottom: 18px; 
      color: #4b5563; 
    }

    /* Clean, borderless information cards */
    .info-box { 
      background-color: #f9fafb; 
      border-radius: 6px; 
      padding: 20px; 
      margin: 25px 0; 
      text-align: left; 
    }
    .warning-box { 
      background-color: #fffdfa; 
      border-radius: 6px; 
      padding: 20px; 
      margin: 25px 0; 
      text-align: left; 
    }
    
    /* Adjusted Card Headers */
    .box-title { 
      font-size: 12px; 
      text-transform: uppercase; 
      letter-spacing: 1px; 
      font-weight: 700; 
      text-align: center; 
      margin-top: 0; 
      margin-bottom: 15px; 
    }
    .info-title { color: #6b7280; }
    .warning-title { color: #A54600; }

    /* Custom Bullet Points */
    ul { 
      padding: 0; 
      list-style: none; 
      margin: 0; 
    }
    li { 
      margin-bottom: 14px; 
      font-size: 12px; 
      padding-left: 20px; 
      position: relative; 
    }
    li::before { 
      content: "•"; 
      color: #A54600; 
      font-size: 16px; 
      position: absolute; 
      left: 0; 
      top: -2px; 
    }
    li strong { color: #111827; }

    /* Button */
    .btn { 
      display: inline-block; 
      background: #A54600; 
      color: #ffffff; 
      padding: 14px 28px; 
      text-decoration: none; 
      border-radius: 6px; 
      font-weight: 600; 
      margin-top: 15px; 
      font-size: 14px; 
    }

    /* Footer */
    .footer { 
      text-align: center; 
      font-size: 12px; 
      color: #9ca3af; 
      padding: 25px; 
      background: #fafbfc; 
      border-top: 1px solid #f3f4f6; 
    }
  </style>
</head>
<body>
  <div class="container">
    
    <div class="logo-container">
       <img src="https://ltytmqjpektcgwajfzfm.supabase.co/storage/v1/object/public/open/korra_logo_icon.webp" alt="Korra" height="60">
    </div>

    <div class="content">
      <h1>Welcome to Korra Partners, ${name}! 🚀</h1>
      <p>We are thrilled to partner with you. Korra helps you sell more high-ticket items to customers who are ready to buy but need flexible payment options.</p>
      
      <div class="info-box">
        <div class="box-title info-title">💸 Why Merchants Love Korra</div>
        <ul>
          <li><strong>Instant Cash Flow:</strong> Withdraw your funds from your wallet immediately as the customer pays. No waiting until the plan is completed.</li>
          <li><strong>No Cash Refunds:</strong> If a customer defaults or cancels, the money they paid stays with you as Store Credit. They MUST spend it in your shop.</li>
          <li><strong>Secure Payments:</strong> All transactions are processed safely by our partner, <strong>Monnify by Moniepoint</strong>.</li>
        </ul>
      </div>

      <div class="warning-box">
        <div class="box-title warning-title">⚠️ Merchant Golden Rules</div>
        <ul>
          <li><strong>Reserved means SOLD:</strong> The moment a plan starts, you MUST reserve that exact item. Do not sell it to someone else.</li>
          <li><strong>Price Protection:</strong> You cannot increase the price of an active plan. If market prices change or you run out of stock before a plan is created, please call us immediately to reject the request.</li>
          <li><strong>Proof of Collection:</strong> Always collect and verify the customer's Pickup Code before handing over the item. This is your official proof of fulfillment to prevent any future disputes.</li>
          <li><strong>Report Issues:</strong> Do not attempt to cancel plans manually. Contact our support team to handle any issues or disputes.</li>
        </ul>
      </div>

      <p>We will be reaching out shortly to verify your details and list your store on our directory.</p>
      <a href="https://korra.com.ng" class="btn">Thank you for choosing Korra!</a>
    </div>

    <div class="footer">
      © 2026 Korra. Need help? Contact support@korra.com.ng
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