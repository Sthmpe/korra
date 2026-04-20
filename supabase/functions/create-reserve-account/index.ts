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

const db = admin.firestore();

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
    // If the request is older than 2 minutes (120,000 milliseconds), kill it immediately.
    const now = Date.now();
    const requestTime = parseInt(clientTimestamp, 10);
    if (Math.abs(now - requestTime) > 120000) {
        throw new Error("Unauthorized: Request expired (Replay attack blocked).");
    }

    // 🛑 2. The Math Check (Anti-Forgery)
    // The server recalculates the hash using the exact same logic as Flutter
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
        secureUid = decodedToken.uid; // The absolute truth of who they are
    } catch (error) {
        throw new Error("Unauthorized Access: Token expired or invalid.");
    }

    const { uid, email, firstName, lastName, bvn, nin } = await req.json();

    if (uid !== secureUid) {
        throw new Error("Security Violation: You cannot perform actions for another user.");
    }

    // 1. MONNIFY AUTH
    const BASE_URL = Deno.env.get("MONNIFY_BASE_URL");
    const apiKey = Deno.env.get("MONNIFY_API_KEY");
    const secretKey = Deno.env.get("MONNIFY_SECRET_KEY");
    const contractCode = Deno.env.get("MONNIFY_CONTRACT_CODE");

    const base64Auth = btoa(`${apiKey}:${secretKey}`);

    const authResponse = await fetch(`${BASE_URL}/api/v1/auth/login`, {
      method: "POST",
      headers: { "Authorization": `Basic ${base64Auth}` }
    });

    const authData = await authResponse.json();
    if (!authData.requestSuccessful) {
      throw new Error("Monnify Auth Failed");
    }
    const accessToken = authData.responseBody.accessToken;

    // 2. CREATE RESERVED ACCOUNT
    const requestBody = {
      accountReference: uid,
      accountName: `Korra - ${firstName} ${lastName}`,
      currencyCode: "NGN",
      contractCode: contractCode,
      customerEmail: email,
      customerName: `${firstName} ${lastName}`,
      bvn: bvn,
      nin: nin,
      getAllAvailableBanks: true, 
    };

    const createResponse = await fetch(`${BASE_URL}/api/v2/bank-transfer/reserved-accounts`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(requestBody)
    });

    const responseJson = await createResponse.json();

    if (!responseJson.requestSuccessful) {
      console.error("Monnify Error:", responseJson);
      throw new Error(responseJson.responseMessage || "Failed to create account");
    }

    // 3. PARSE & SAVE TO FIRESTORE
    const mainAccount = responseJson.responseBody.accounts[0];
    const batch = db.batch();
    const timestamp = admin.firestore.FieldValue.serverTimestamp();

    // Ledger Entry
    const ledgerRef = db.collection('customers').doc(uid).collection('ledger_transactions').doc();
    const initialTx = {
      id: ledgerRef.id,
      customerId: uid,
      amount: 0.00,
      type: 'system',
      description: `Account Opened: ${mainAccount.bankName}`,
      planId: 'none',
      reference: `INIT-${ledgerRef.id.substring(0, 8)}`,
      status: 'success',
      balanceBefore: 0.00,
      balanceAfter: 0.00,
      createdAt: timestamp
    };
    batch.set(ledgerRef, initialTx);

    // Banking Details
    const bankingRef = db.collection('customers').doc(uid).collection('banking_details').doc('monnify');
    batch.set(bankingRef, {
      accountReference: responseJson.responseBody.accountReference,
      accountName: mainAccount.accountName,
      accountNumber: mainAccount.accountNumber,
      bankName: mainAccount.bankName,
      bankCode: mainAccount.bankCode,
      createdAt: timestamp
    });

    // Stats
    const statsRef = db.collection('customers').doc(uid).collection('account_stats').doc('main');
    batch.set(statsRef, {
      uid: uid,
      activePlansCount: 0,
      completedPlansCount: 0,
      expiredPlansCount: 0,
      cancelledPlansCount: 0,
      tier: "Starter",
      lastUpdated: timestamp
    });

    await batch.commit();

    // 4. SUCCESS RESPONSE
    return new Response(JSON.stringify({
      success: true,
      data: {
        bankName: mainAccount.bankName,
        accountNumber: mainAccount.accountNumber,
        accountName: mainAccount.accountName,
        accountReference: responseJson.responseBody.accountReference,
        bankCode: mainAccount.bankCode
      }
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error) {
    // 5. ERROR RESPONSE
    return new Response(JSON.stringify({ success: false, error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});