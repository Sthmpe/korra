import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

// 1. DEFINE CORS HEADERS
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, firebase-token, x-korra-timestamp, x-korra-signature', 
};

// --- 2. FIREBASE INIT ---
const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}
const db = admin.firestore();

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

    const { type, vendorUid, productId, productIds } = await req.json();

    if (!vendorUid || !type) {
        return new Response(JSON.stringify({ success: false, error: "Missing vendorUid or type" }), { 
            status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" }
        });
    }

    if (vendorUid !== secureUid) {
        throw new Error("Security Violation: You can only delete your own products.");
    }

    // 2. Strict check for Single Delete
    if (type === 'single-delete' && !productId) {
        throw new Error("Missing productId for single delete.");
    }

    // 3. Strict check for Multiple Delete
    if (type === 'multiple-delete' && (!Array.isArray(productIds) || productIds.length === 0)) {
        throw new Error("Missing productIds array for multiple delete.");
    }
    
    // ==========================================================
    // MULTIPLE DELETE (GROUP DELETE)
    // ==========================================================
    if (type === 'multiple-delete') {
      if (!Array.isArray(productIds) || productIds.length === 0) {
         throw new Error("Missing array of Product IDs.");
      }

      console.log(`🗑️ Deleting ${productIds.length} products for vendor ${vendorUid}...`);

      await db.runTransaction(async (t) => {
        const statsRef = db.collection('vendor_stats').doc(vendorUid);
        
        // 1. Get ALL documents at once
        const productRefs = productIds.map(id => db.collection('products').doc(id));
        const productDocs = await t.getAll(...productRefs);

        let totalCapacityToRestore = 0;

        // 2. Loop through them and calculate liability
        productDocs.forEach(doc => {
           if (doc.exists) {
              const data = doc.data();
              const status = data?.status;
              const price = Number(data?.price) || 0;
              const stock = Number(data?.availableStock) || 0;

              // Add to the total liability refund if it was active
              if (status === 'approved') {
                 totalCapacityToRestore += (price * stock);
              }
              
              // Queue the deletion
              t.delete(doc.ref);
           }
        });

        // 3. Restore the combined liability all at once!
        if (totalCapacityToRestore > 0) {
           console.log(`♻️ Restoring a massive ₦${totalCapacityToRestore} to liability limit...`);
           t.update(statsRef, {
             totalLiability: admin.firestore.FieldValue.increment(-totalCapacityToRestore)
           });
        }
      });

      console.log(`✅ Successfully bulk-deleted ${productIds.length} items`);
      return new Response(JSON.stringify({ success: true }), { 
        status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } 
      });
    }

    // ==========================================================
    // DELETE PRODUCT & RESTORE CAPACITY
    // ==========================================================
    if (type === 'single-delete') {
      await db.runTransaction(async (t) => {
        const productRef = db.collection('products').doc(productId);
        const statsRef = db.collection('vendor_stats').doc(vendorUid);

        const productDoc = await t.get(productRef);
        if (!productDoc.exists) throw new Error("Product not found.");

        const productData = productDoc.data();
        
        // 1. Calculate the capacity to restore (e.g., Price * Stock)
        // Adjust this math to match exactly how you calculate liability!
        const price = Number(productData?.price) || 0;
        const stock = Number(productData?.availableStock) || 0;
        const status = productData?.status;
        
        const capacityToRestore = price * stock;

        // 2. If it was active and taking up space, restore the limit
        if (status === 'approved' && capacityToRestore > 0) {
          t.update(statsRef, {
            // Subtracting from totalLiability frees up their available limit
            totalLiability: admin.firestore.FieldValue.increment(-capacityToRestore)
          });
        }

        // 3. Finally, delete the product
        t.delete(productRef);
      });

      return new Response(JSON.stringify({ success: true }), { 
        status: 200, 
        headers: { ...corsHeaders, "Content-Type": "application/json" } 
      });
    }

    throw new Error("Invalid operation type."); // Catch missing/wrong types

  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ success: false, error: msg }), { 
      status: 400, 
      headers: { ...corsHeaders, "Content-Type": "application/json" } 
    });
  }
});