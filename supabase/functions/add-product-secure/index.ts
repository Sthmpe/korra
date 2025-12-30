//add-product-secure/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";
import { crypto } from "https://deno.land/std@0.177.0/crypto/mod.ts";

// 1. DEFINE CORS HEADERS
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// --- 1. FIREBASE INIT ---
const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}
const db = admin.firestore();

// --- 2. HELPER: Generate Code ---
async function generateProductCode(vendorId: string) {
  const vendorPrefix = vendorId.substring(0, 4).toUpperCase();
  const timestamp = Date.now().toString();
  const data = new TextEncoder().encode(vendorId + timestamp);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
  const shortHash = hashHex.substring(0, 7).toUpperCase();
  return `K-${vendorPrefix}-${shortHash}`;
}

// --- 3. MAIN LOGIC ---
serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  
  try {
    const { 
      vendorId, 
      productData 
    } = await req.json();

    if (!vendorId || !productData) {
      return new Response(JSON.stringify({ error: "Missing data" }), { status: 400 });
    }

    // 1. Calculate & Validate Value
    const price = Number(productData.price);
    const stock = Number(productData.availableStock);

    const totalValue = price * stock;

    if (totalValue <= 0) {
      return new Response(JSON.stringify({ error: "Invalid product value" }), { status: 400 });
    }

    // 2. RUN TRANSACTION (Atomic Check & Write)
    const result = await db.runTransaction(async (t) => {
      const statsRef = db.collection('vendor_stats').doc(vendorId);
      const productRef = db.collection('products').doc(); // Auto-ID

      const statsDoc = await t.get(statsRef);
      
      // Default stats if missing
      let maxLimit = 250000.0;
      let maxPlanAmount = 100000.0;
      let currentLiability = 0.0;
      let currentActive = 0.0;

      if (statsDoc.exists) {
        const stats = statsDoc.data();
        maxLimit = Number(stats.maxReservationLimit) || 250000.0;
        maxPlanAmount = Number(stats.maxPlanAmount) || 100000.0; // 👈 Read Dynamic Limit
        currentLiability = Number(stats.totalLiability) || 0.0;
        currentActive = Number(stats.currentActivePlanValue) || 0.0;
      }

      // 🛑 1. SECURITY BLOCK: Dynamic Price Cap
      if (price > maxPlanAmount) {
        throw `Security Violation: Single product price (₦${price.toLocaleString()}) exceeds your account limit (₦${maxPlanAmount.toLocaleString()}).`;
      }

      // 🛑 SERVER-SIDE LIMIT CHECK
      const usedLimit = currentLiability + currentActive;
      const availableLimit = maxLimit - usedLimit;

      if (totalValue > availableLimit) {
        throw `Limit Exceeded. Product value (₦${totalValue.toLocaleString()}) exceeds available limit (₦${availableLimit.toLocaleString()}).`;
      }

      // ✅ GENERATE CODE
      const code = await generateProductCode(vendorId);

      // ✅ PREPARE PRODUCT DATA
      const finalProduct = {
        id: productRef.id,
        vendorId: vendorId,
        storeName: productData.storeName,
        code: code,
        
        name: productData.name,
        description: productData.description,
        category: productData.category,
        images: productData.images,
        
        price: price,
        initialStock: stock,
        availableStock: stock,
        
        status: 'approved', 
        rejectionReason: null,

        // Smart Contract Fields
        modelType: productData.modelType,
        cancellationPolicy: productData.cancellationPolicy,
        extensionsEnabled: productData.extensionsEnabled,
        directDownPayment: productData.directDownPayment || null,

        // Timeline Fields
        baseDuration: productData.baseDuration,
        noticePeriod: productData.noticePeriod,
        totalMaxTime: productData.totalMaxTime,

        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // ✅ UPDATE STATS
      // Adds new inventory value to 'currentActivePlanValue'
      const newActive = currentActive + totalValue;

      t.set(statsRef, {
        currentActivePlanValue: newActive,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      // ✅ SAVE PRODUCT
      t.set(productRef, finalProduct);

      return { productId: productRef.id, code: code };
    });

    return new Response(JSON.stringify({ 
      success: true, 
      data: result 
    }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });

  } catch (error) {
    const msg = error.toString().replace("Error: ", "");
    return new Response(JSON.stringify({ success: false, error: msg }), { 
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" } 
    });
  }
});