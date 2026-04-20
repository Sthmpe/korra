import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0"; 

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, firebase-token, x-korra-timestamp, x-korra-signature',
};

const PAYSTACK_SECRET = Deno.env.get('PAYSTACK_SECRET_KEY')!;
const KORRA_SECRET = Deno.env.get('KORRA_HMAC_SECRET') || "7f8a9b2d4c6e1f3a5b7c9d0e2f4a6b8c1d3e5f7a9b0c2d4e6f8a1b3c5d7e9f0a";

// Initialize Firebase Admin for token verification
const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    if (req.method !== "POST") throw new Error("Only POST allowed");

    // =======================================================================
    // 🔐 LOCK 1: HMAC ANTI-FORGERY
    // =======================================================================
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

    // =======================================================================
    // 🔐 LOCK 2: FIREBASE AUTH
    // =======================================================================
    const authHeader = req.headers.get('firebase-token');
    if (!authHeader || !authHeader.startsWith('Bearer ')) throw new Error("Unauthorized: Missing User Token.");
    
    const idToken = authHeader.split('Bearer ')[1];
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const secureUid = decodedToken.uid;

    // =======================================================================
    // 🚀 BUSINESS LOGIC: PAYSTACK DVA CREATION (CUSTOMER)
    // =======================================================================
    const { uid, email, firstName, lastName, phone } = await req.json();

    if (uid !== secureUid) throw new Error("Security Violation: UID mismatch.");

    console.log(`👤 Creating Paystack customer for ${email}...`);

    // STEP 1: CREATE PAYSTACK CUSTOMER
    const customerRes = await fetch('https://api.paystack.co/customer', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${PAYSTACK_SECRET}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, first_name: firstName, last_name: lastName, phone })
    });
    
    const customerData = await customerRes.json();
    if (!customerData.status) throw new Error(`Paystack Customer Error: ${customerData.message}`);
    
    const customerCode = customerData.data.customer_code;
    const customerId = customerData.data.id;

    // 🚀 SMART ENVIRONMENT DETECTION
    const isTestMode = PAYSTACK_SECRET.startsWith('sk_test_');
    let targetBank = isTestMode ? 'test-bank' : 'wema-bank';

    console.log(`🏦 Assigning ${targetBank} DVA to Customer ${customerCode}...`);

    // STEP 2: CREATE DEDICATED VIRTUAL ACCOUNT
    let dvaRes = await fetch('https://api.paystack.co/dedicated_account', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${PAYSTACK_SECRET}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ customer: customerCode, preferred_bank: targetBank })
    });

    let dvaData = await dvaRes.json();

    // FALLBACK FOR LIVE MODE: If Titan fails, try Wema
    if (!dvaData.status && !isTestMode) {
      console.log(`⚠️ Titan failed (${dvaData.message}). Falling back to wema-bank...`);
      targetBank = 'wema-bank';
      dvaRes = await fetch('https://api.paystack.co/dedicated_account', {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${PAYSTACK_SECRET}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ customer: customerCode, preferred_bank: targetBank })
      });
      dvaData = await dvaRes.json();
    }

    // FALLBACK FOR TEST MODE: Auto-assign if test-bank fails
    if (!dvaData.status && isTestMode) {
      dvaRes = await fetch('https://api.paystack.co/dedicated_account', {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${PAYSTACK_SECRET}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ customer: customerCode })
      });
      dvaData = await dvaRes.json();
    }

    if (!dvaData.status) throw new Error(`Paystack DVA Error: ${dvaData.message}`);

    console.log(`✅ Successfully generated DVA: ${dvaData.data.account_number}`);

    return new Response(JSON.stringify({ 
      success: true, 
      data: {
        paystackCustomerId: customerId,
        paystackCustomerCode: customerCode,
        accountNumber: dvaData.data.account_number,
        accountName: dvaData.data.account_name,
        bankName: dvaData.data.bank.name,
        bankSlug: dvaData.data.bank.slug,
      }
    }), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });

  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    console.error("🔥 Edge Function Error:", msg);
    return new Response(JSON.stringify({ success: false, error: msg }), {
      status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" }
    });
  }
});