import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

// 1. DEFINE CORS HEADERS
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, firebase-token, x-korra-timestamp, x-korra-signature',
};

// 2. INITIALIZE FIREBASE ADMIN
const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

// 3. MAIN WORKER
serve(async (req) => {
  // A. CORS Pre-flight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // =======================================================================
    // 🔐 LOCK 1: HMAC ANTI-FORGERY & ANTI-REPLAY
    // =======================================================================
    const clientTimestamp = req.headers.get('x-korra-timestamp');
    const clientSignature = req.headers.get('x-korra-signature');
    const KORRA_SECRET = "7f8a9b2d4c6e1f3a5b7c9d0e2f4a6b8c1d3e5f7a9b0c2d4e6f8a1b3c5d7e9f0a";

    if (!clientTimestamp || !clientSignature) {
        throw new Error("Unauthorized: Missing security signatures.");
    }

    // 🛑 1. The Time Check (Anti-Replay)
    const now = Date.now();
    const requestTime = parseInt(clientTimestamp, 10);
    if (Math.abs(now - requestTime) > 120000) {
        throw new Error("Unauthorized: Request expired (Replay attack blocked).");
    }

    // 🛑 2. The Math Check (Anti-Forgery)
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
        "raw",
        encoder.encode(KORRA_SECRET),
        { name: "HMAC", hash: "SHA-256" },
        false,
        ["sign"]
    );

    const signatureBuffer = await crypto.subtle.sign("HMAC", key, encoder.encode(clientTimestamp));
    const hashArray = Array.from(new Uint8Array(signatureBuffer));
    const expectedServerSignature = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

    if (clientSignature !== expectedServerSignature) {
        throw new Error("Unauthorized: Cryptographic signature mismatch.");
    }

    // =======================================================================
    // 🔐 LOCK 2: AUTH TOKEN (Proves WHO the user is)
    // =======================================================================
    const authHeader = req.headers.get('firebase-token');

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        throw new Error("Unauthorized Access: Missing VIP pass.");
    }

    const idToken = authHeader.split('Bearer ')[1];
    let secureUid: string;

    try {
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        secureUid = decodedToken.uid;
    } catch (error) {
        throw new Error("Unauthorized Access: Token expired or invalid.");
    }

    // =======================================================================
    // 3. READ REQUEST BODY
    // =======================================================================
    const { amount, customerName, customerEmail, paymentReference, paymentDescription, redirectUrl } = await req.json();

    // 4. FETCH MONNIFY CREDENTIALS SECURELY FROM ENV
    const BASE_URL = Deno.env.get("MONNIFY_BASE_URL");
    const apiKey = Deno.env.get("MONNIFY_API_KEY");
    const secretKey = Deno.env.get("MONNIFY_SECRET_KEY");
    const contractCode = Deno.env.get("MONNIFY_CONTRACT_CODE");

    if (!BASE_URL || !apiKey || !secretKey || !contractCode) {
        throw new Error("Server Configuration Error: Missing Monnify credentials in Supabase environment.");
    }

    // 5. LOGIN TO MONNIFY FOR BEARER TOKEN
    const base64Auth = btoa(`${apiKey}:${secretKey}`);
    const authResponse = await fetch(`${BASE_URL}/api/v1/auth/login`, {
      method: "POST",
      headers: {
        "Authorization": `Basic ${base64Auth}`,
      },
    });

    if (!authResponse.ok) {
      throw new Error(`Monnify Auth Login Failed: ${authResponse.statusText}`);
    }

    const authData = await authResponse.json();
    const accessToken = authData.responseBody?.accessToken;

    if (!accessToken) {
      throw new Error("Failed to retrieve Monnify Access Token.");
    }

    // 6. INITIALIZE PAYMENT SESSION
    const initResponse = await fetch(`${BASE_URL}/api/v1/merchant/transactions/init-transaction`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        amount,
        customerName,
        customerEmail,
        paymentReference,
        paymentDescription,
        currencyCode: "NGN",
        contractCode,
        redirectUrl,
        paymentMethods: ["CARD", "ACCOUNT_TRANSFER", "USSD"],
      }),
    });

    const initData = await initResponse.json();

    if (!initResponse.ok || !initData.requestSuccessful) {
      throw new Error(`Monnify Payment Init Failed: ${initData.responseMessage || initResponse.statusText}`);
    }

    // 7. RETURN TRANSACTION DETAILS (Including checkoutUrl)
    return new Response(
      JSON.stringify(initData.responseBody),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      }
    );
  }
});
