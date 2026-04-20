import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Ensure you have set your Paystack Secret Key in your Supabase environment variables!
const PAYSTACK_SECRET = Deno.env.get('PAYSTACK_SECRET_KEY');

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    if (req.method !== "POST") throw new Error("Only POST allowed");

    const payload = await req.json();
    const action = payload.action; 

    if (!PAYSTACK_SECRET) throw new Error("Missing PAYSTACK_SECRET_KEY in environment variables");

    // ====================================================================
    // 🏦 ACTION 1: FETCH AVAILABLE DVA BANKS
    // Let's see exactly which banks Paystack allows your business to use.
    // ====================================================================
    if (action === 'FETCH_PROVIDERS') {
      console.log("Fetching available DVA providers...");
      const res = await fetch('https://api.paystack.co/dedicated_account/available_providers', {
        method: 'GET',
        headers: { 'Authorization': `Bearer ${PAYSTACK_SECRET}` }
      });
      const data = await res.json();
      
      return new Response(JSON.stringify(data), { 
          status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } 
      });
    }

    // ====================================================================
    // 🚀 ACTION 2: CREATE CUSTOMER & ASSIGN DVA
    // The synchronous 2-step process.
    // ====================================================================
    if (action === 'CREATE_DVA') {
      const { email, first_name, last_name, phone, preferred_bank } = payload;

      if (!email || !first_name || !last_name || !phone) {
        throw new Error("Missing required fields: email, first_name, last_name, phone");
      }

      // STEP 1: CREATE CUSTOMER
      console.log(`👤 Creating Paystack customer for ${email}...`);
      const customerRes = await fetch('https://api.paystack.co/customer', {
        method: 'POST',
        headers: { 
            'Authorization': `Bearer ${PAYSTACK_SECRET}`, 
            'Content-Type': 'application/json' 
        },
        body: JSON.stringify({ email, first_name, last_name, phone })
      });
      
      const customerData = await customerRes.json();
      if (!customerData.status) throw new Error(`Paystack Customer Error: ${customerData.message}`);
      
      const customerCode = customerData.data.customer_code;
      console.log(`✅ Customer Created. Code: ${customerCode}`);

      // STEP 2: CREATE DEDICATED VIRTUAL ACCOUNT
      // If you don't pass a preferred_bank, we default to Wema Bank as it is historically the most stable on Paystack.
      const targetBank = preferred_bank || 'wema-bank'; 
      console.log(`🏦 Assigning ${targetBank} DVA to ${customerCode}...`);
      
      const dvaRes = await fetch('https://api.paystack.co/dedicated_account', {
        method: 'POST',
        headers: { 
            'Authorization': `Bearer ${PAYSTACK_SECRET}`, 
            'Content-Type': 'application/json' 
        },
        body: JSON.stringify({ 
            customer: customerCode, 
            preferred_bank: targetBank 
        })
      });

      const dvaData = await dvaRes.json();
      
      if (!dvaData.status) throw new Error(`Paystack DVA Error: ${dvaData.message}`);
      
      console.log(`✅ DVA Created: ${dvaData.data.account_number}`);

      // Return both payloads so you can inspect them in Postman
      return new Response(JSON.stringify({ 
          success: true, 
          customer: customerData.data,
          dva: dvaData.data 
      }), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    throw new Error("Invalid action. Use 'FETCH_PROVIDERS' or 'CREATE_DVA'");

  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error("🔥 Error:", msg);
    return new Response(JSON.stringify({ success: false, error: msg }), {
      status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" }
    });
  }
});