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

// --- 3. MAIN LOGIC ---
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

    const { vendorId, productCode, updateData } = await req.json();

    if (!vendorId || !productCode || !updateData) {
      return new Response(JSON.stringify({ error: "Missing data" }), { 
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      });
    }

    if (vendorId !== secureUid) {
        throw new Error("Security Violation: You cannot perform actions for another user.");
    }

    // 1. Validate Inputs
    const newPrice = Number(updateData.price);
    const newStock = Number(updateData.availableStock);

    // 2. RUN TRANSACTION
    const result = await db.runTransaction(async (t) => {
      // References
      const statsRef = db.collection('vendor_stats').doc(vendorId);
      const productQuery = db.collection('products')
                             .where('vendorId', '==', vendorId)
                             .where('code', '==', productCode)
                             .limit(1);
      
      const productSnap = await t.get(productQuery);
      if (productSnap.empty) throw "Product not found";
      
      const productDoc = productSnap.docs[0];
      const oldData = productDoc.data();
      const statsDoc = await t.get(statsRef);
      let maxPlanAmount = 100000.0;

      if (!statsDoc.exists) throw "Vendor stats not found";
      const stats = statsDoc.data();
      maxPlanAmount = Number(stats.maxPlanAmount) || 100000.0; 

      // 3. Calculate Financial Delta
      const oldTotal = (Number(oldData.price) || 0) * (Number(oldData.availableStock) || 0);
      const newTotal = newPrice * newStock;
      const difference = newTotal - oldTotal; 
      
      if (newPrice > maxPlanAmount) {
        throw `Security Violation: Single product price (₦${newPrice.toLocaleString()}) exceeds your account limit (₦${maxPlanAmount.toLocaleString()}).`;
      }

      // 4. Check Limit (Only if value increased)
      if (difference > 0) {
        const maxLimit = Number(stats.maxReservationLimit) || 250000.0;
        const currentUsed = (Number(stats.totalLiability) || 0) + (Number(stats.currentActivePlanValue) || 0);
        const available = maxLimit - currentUsed;

        if (difference > available) {
          throw `Limit Exceeded. This update requires ₦${difference.toLocaleString()} more limit, but you only have ₦${available.toLocaleString()}.`;
        }
      }

      // 5. Determine New Status
      let newStatus = oldData.status;
      if (oldData.status === 'rejected') {
        newStatus = 'pending';
      } else if (oldData.status === 'outOfStock' && newStock > 0) {
        newStatus = 'approved';
      }

      // 6. Update Stats
      const currentActive = Number(stats.currentActivePlanValue) || 0;
      t.update(statsRef, {
        currentActivePlanValue: currentActive + difference, 
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      });

      // 7. Update Product
      t.update(productDoc.ref, {
        ...updateData,
        status: newStatus,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      return { code: productCode, status: newStatus };
    });

    return new Response(JSON.stringify({ success: true, data: result }), { 
      headers: { ...corsHeaders, "Content-Type": "application/json" } 
    });

  } catch (error) {
    const msg = error.toString().replace("Error: ", "");
    return new Response(JSON.stringify({ success: false, error: msg }), { 
      status: 400, 
      headers: { ...corsHeaders, "Content-Type": "application/json" } 
    });
  }
});