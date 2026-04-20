//check_uniqueness/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

// 1. DEFINE CORS HEADERS
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-korra-signature, x-korra-timestamp',
};

// 2. Initialize Firebase Admin
const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

serve(async (req) => {
  // 3. HANDLE BROWSER PRE-FLIGHT (CORS)
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
    
    const { type, value, collection } = await req.json();
    
    // Validation
    if (!value || !type) {
      return new Response(JSON.stringify({ error: "Missing data" }), { 
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      });
    }

    let query;
    const targetCollection = collection || 'customer'; // Default to customer

    // 4. Construct Query based on Type
    if (type === 'email') {
      // Check nested field: personal.email
      query = db.collection(targetCollection).where('personal.email', '==', value);
    } else if (type === 'nin') {
      // Check nested field: kyc.nin
      query = db.collection(targetCollection).where('kyc.nin', '==', value);
    } else if (type === 'bvn') {
      // Check nested field: kyc.bvn
      query = db.collection(targetCollection).where('kyc.bvn', '==', value);
    } else {
      return new Response(JSON.stringify({ error: "Invalid type" }), { 
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      });
    }

    // 5. Execute Query (Limit 1 for speed)
    const snapshot = await query.limit(1).get();
    const exists = !snapshot.empty;

    // 6. Return ONLY boolean (No data leaked)
    return new Response(JSON.stringify({ exists }), { 
      headers: { ...corsHeaders, "Content-Type": "application/json" } 
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.toString() }), { 
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" } // ✅ Added headers here too
    });
  }
});