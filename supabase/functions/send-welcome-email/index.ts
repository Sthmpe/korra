import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const RESEND_API_KEY = 're_LA73tLsT_6btk6w4uhXQsZsksraJxLuMU'; // Replace with your Resend API key

const handler = async (request: Request): Promise<Response> => {
  try {
    const { name, email } = await request.json();

    if (!name || !email) {
      return new Response(JSON.stringify({ error: "Missing name or email" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Inject name into HTML properly
    const htmlContent = `
      <!doctype html>
      <html lang="en" xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <meta charset="utf-8">
        <meta name="x-apple-disable-message-reformatting">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Welcome to Korra</title>
        <style>
          body, table, td, a { 
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Roboto", Helvetica, Arial, sans-serif !important; 
            margin:0; 
            padding:0; 
          }
          img { border:0; outline:none; text-decoration:none; display:block; }
          table { border-collapse: collapse !important; }
          .preheader { display:none; max-height:0; overflow:hidden; mso-hide:all; opacity:0; }
          @media (max-width: 600px){
            .container { width:100% !important; margin:0 !important; }
            .hero-text { font-size:12px !important; line-height:18px !important; }
            h1 { font-size:14px !important; line-height:20px !important; }
            .feature-text { font-size:11px !important; line-height:16px !important; }
          }
        </style>
      </head>
      <body style="background-color:#f6f7fb; margin:0; padding:0;">

        <!-- Hidden preview -->
        <div class="preheader">Welcome to Korra, the smart way to layaway for vendors and customers.</div>

        <table role="presentation" width="100%" bgcolor="#f6f7fb" cellpadding="0" cellspacing="0">
          <tr>
            <td align="center" style="padding:40px 12px;">

              <!-- Card -->
              <table role="presentation" class="container" width="600" style="max-width:600px; width:100%; background:#ffffff; border-radius:16px; overflow:hidden; box-shadow:0 8px 32px rgba(0,0,0,0.08);">

                <!-- Top bar -->
                <tr><td style="background:#A54600; height:6px;"></td></tr>

                <!-- Logo -->
                <tr>
                  <td align="center" style="padding:24px 0;">
                    <img src="https://ltytmqjpektcgwajfzfm.supabase.co/storage/v1/object/public/open/Untitled%20design.webp" alt="Korra Logo" width="120" height="100">
                  </td>
                </tr>

                <!-- Hero / Greeting -->
                <tr>
                  <td style="padding:0 24px 24px 24px; text-align:center;">
                    <h1 style="margin:0; font-size:16px; line-height:22px; color:#0f172a;">
                      Hi ${name}, Welcome to Korra! 👋
                    </h1>
                    <p class="hero-text" style="margin:12px 0 0 0; color:#334155; font-size:12px; line-height:18px;">
                      You’re officially part of the Korra community! Manage flexible reserve plans, track orders, and grow your business or savings effortlessly — whether you're a vendor or a customer.
                    </p>
                  </td>
                </tr>

                <!-- Features -->
                <tr>
                  <td style="padding:20px 24px;">
                    <table role="presentation" width="100%">
                      <tr>
                        <td width="24" valign="top" style="font-size:16px; line-height:22px;">💡</td>
                        <td class="feature-text" style="color:#334155; font-size:11px; line-height:16px;">Flexible reserve plans for all users.</td>
                      </tr>
                      <tr><td height="8"></td><td></td></tr>
                      <tr>
                        <td width="24" valign="top" style="font-size:16px; line-height:22px;">🔒</td>
                        <td class="feature-text" style="color:#334155; font-size:11px; line-height:16px;">Secure wallets and seamless payment management.</td>
                      </tr>
                      <tr><td height="8"></td><td></td></tr>
                      <tr>
                        <td width="24" valign="top" style="font-size:16px; line-height:22px;">⚡</td>
                        <td class="feature-text" style="color:#334155; font-size:11px; line-height:16px;">Track payments and orders quickly with ease.</td>
                      </tr>
                    </table>
                  </td>
                </tr>

                <!-- CTA -->
                <tr>
                  <td align="center" style="padding:20px;">
                    <a href="#" style="background:#A54600; color:#ffffff; font-weight:bold; font-size:13px; padding:10px 20px; border-radius:10px; text-decoration:none; display:inline-block; box-shadow:0 4px 12px rgba(165,70,0,0.25);">
                      Continue in the app
                    </a>
                  </td>
                </tr>

                <!-- Support -->
                <tr>
                  <td style="padding:0 24px 20px 24px; text-align:center;">
                    <p style="margin:0; color:#64748b; font-size:11px; line-height:16px;">
                      Need help? <a href="mailto:support@korra.com" style="color:#A54600; text-decoration:underline;">Contact Support</a> or call us at <strong>09152540533</strong>.
                    </p>
                  </td>
                </tr>

                <!-- Footer -->
                <tr>
                  <td style="padding:12px 24px 20px 24px; background:#f9f9f9; border-top:1px solid #e0e0e0; text-align:center;">
                    <p style="margin:0; color:#94a3b8; font-size:10px; line-height:14px;">
                      © 2025 Korra. All rights reserved.<br>
                      You’re receiving this email because an account was created with this address.
                    </p>
                  </td>
                </tr>

              </table>
              <!-- /Card -->
            </td>
          </tr>
        </table>
      </body>
      </html>
    `;

    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`
      },
      body: JSON.stringify({
        // 👇 UPDATE THIS LINE
        from: 'Korra Team <hello@mail.korra.com.ng>', 
        to: [email],
        subject: 'Welcome to Korra!',
        html: htmlContent,
        tags: [
          {
            name: 'category',
            value: 'welcome',
          },
        ],
      })
    });
    const data = await res.json();

    if (!res.ok) {
      console.error("Resend API error:", data);
      return new Response(JSON.stringify({ error: data }), {
        status: res.status,
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ success: true, data }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });

  } catch (err) {
    console.error("Function error:", err);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
};

serve(handler);
