import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

// 1. DEFINE CORS HEADERS
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
};

// --- 1. FIREBASE INIT ---
const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}
const db = admin.firestore();

// --- 2. MAIN LOGIC ---
serve(async (req) => {
  // A. CORS Pre-flight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // =======================================================================
    // 🌐 GET: FETCH ALL MERCHANTS (Public Directory)
    // =======================================================================
    if (req.method === 'GET') {
      const snapshot = await db.collection('trusted_merchants').orderBy('createdAt', 'desc').get();
      
      const merchants = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));

      return new Response(JSON.stringify({ merchants }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // =======================================================================
    // 🚀 POST: UPLOAD NEW MERCHANT (Admin Only)
    // =======================================================================
    if (req.method === 'POST') {
      const body = await req.json();
      const { adminPassword, merchantData } = body;

      // 🔐 SECURITY CHECK
      if (adminPassword !== "David2026Boss") {
        throw new Error("Unauthorized Access.");
      }

      // Add to Firestore
      const newMerchantRef = db.collection('trusted_merchants').doc();
      await newMerchantRef.set({
        ...merchantData,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      return new Response(JSON.stringify({ 
        status: "SUCCESS", 
        message: "Merchant injected successfully.", 
        id: newMerchantRef.id 
      }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    throw new Error("Method not allowed");

  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error("Function error:", msg);
    return new Response(JSON.stringify({ error: msg }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});