//check_uniqueness/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

// 1. DEFINE CORS HEADERS
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
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