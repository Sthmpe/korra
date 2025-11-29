import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

// 1. Initialize Firebase Admin
const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*' } });

  try {
    const { type, value, collection } = await req.json();
    
    // Validation
    if (!value || !type) return new Response("Missing data", { status: 400 });

    let query;
    const targetCollection = collection || 'customer'; // Default to customer

    // 2. Construct Query based on Type
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
      return new Response("Invalid type", { status: 400 });
    }

    // 3. Execute Query (Limit 1 for speed)
    const snapshot = await query.limit(1).get();
    const exists = !snapshot.empty;

    // 4. Return ONLY boolean (No data leaked)
    return new Response(JSON.stringify({ exists }), { 
      headers: { "Content-Type": "application/json" } 
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.toString() }), { status: 500 });
  }
});