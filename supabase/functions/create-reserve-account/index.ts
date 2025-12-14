// supabase/functions/create-reserve-account/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// 1. INITIALIZE FIREBASE ADMIN (Outside the handler for performance)
const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { uid, email, firstName, lastName, bvn, nin } = await req.json()

    // 1. AUTHENTICATE (Basic Auth -> Access Token)
    const BASE_URL = Deno.env.get("MONNIFY_BASE_URL")
    const apiKey = Deno.env.get("MONNIFY_API_KEY")
    const secretKey = Deno.env.get("MONNIFY_SECRET_KEY")
    const contractCode = Deno.env.get("MONNIFY_CONTRACT_CODE")

    // Encode "API_KEY:SECRET_KEY" to Base64
    const base64Auth = btoa(`${apiKey}:${secretKey}`)

    const authResponse = await fetch(`${BASE_URL}/api/v1/auth/login`, {
      method: "POST",
      headers: { "Authorization": `Basic ${base64Auth}` }
    })

    const authData = await authResponse.json()
    if (!authData.requestSuccessful) {
      throw new Error("Monnify Auth Failed")
    }
    const accessToken = authData.responseBody.accessToken

    // 2. CREATE RESERVED ACCOUNT (Using verified V2 Body)
    const requestBody = {
      accountReference: uid, // Links to your user
      accountName: `Korra - ${firstName} ${lastName}`,
      currencyCode: "NGN",
      contractCode: contractCode,
      customerEmail: email,
      customerName: `${firstName} ${lastName}`,
      bvn: bvn,             // CORRECTED: 'bvn' not 'customerBvn'
      nin: nin,             // ADDED: Matches your example
      getAllAvailableBanks: false, // Gets Wema, Moniepoint, etc.
      preferredBanks: [
        "50515"
      ]
      // restrictPaymentSource: false // Optional: Defaults to false
    }

    const createResponse = await fetch(`${BASE_URL}/api/v2/bank-transfer/reserved-accounts`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(requestBody)
    })

    const responseJson = await createResponse.json()

    if (!responseJson.requestSuccessful) {
      console.error("Monnify Error:", responseJson)
      throw new Error(responseJson.responseMessage || "Failed to create account")
    }

    // 3. PARSE RESPONSE
    // Monnify returns an array of accounts. We usually pick index 0.
    const mainAccount = responseJson.responseBody.accounts[0]

    // ============================================================
    // 🆕 NEW STEP: INITIALIZE LEDGER IN FIRESTORE (SERVER SIDE)
    // ============================================================
    
    // 1. Start a Batch
    const batch = db.batch();
    const timestamp = admin.firestore.FieldValue.serverTimestamp();

    // 2. Prepare Ledger Entry
    const ledgerRef = db.collection('customer').doc(uid).collection('ledger_transactions').doc();
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
    batch.set(ledgerRef, initialTx); // Add to batch

    // 3. Prepare Customer Stats Entry
    // Kept separate from stats and profile for security/cleanliness
    const bankingRef = db.collection('customers').doc(uid).collection('banking_details').doc('monnify');
    batch.set(bankingRef, {
      accountReference: responseJson.responseBody.accountReference,
      accountName: mainAccount.accountName,
      accountNumber: mainAccount.accountNumber,
      bankName: mainAccount.bankName,
      bankCode: mainAccount.bankCode,
      createdAt: timestamp
    });

    const statsRef = db.collection('customers').doc(uid).collection('account_stats').doc('main');
    batch.set(statsRef, {
      uid: uid,
      activePlansCount: 0,        // Slot Usage
      completedPlansCount: 0,     // Level Progression
      defaultsCount: 0,           // Risk Score
      cancelledPlansCount: 0,     // Cancellation tracking
      tier: "Starter",            // ✅ Added Tier (Starter, Keeper, Collector, VIP)
      lastUpdated: timestamp
    });

    // 4. Commit both at once
    await batch.commit();

    // ============================================================
    // END NEW STEP
    // ============================================================

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
    })

  } catch (error) {
    return new Response(JSON.stringify({ success: false, error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})