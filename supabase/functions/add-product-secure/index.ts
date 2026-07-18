//add-product-secure/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";
import { crypto } from "https://deno.land/std@0.177.0/crypto/mod.ts";

// 1. DEFINE CORS HEADERS
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, firebase-token, x-korra-timestamp, x-korra-signature', 
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

// --- 2b. HELPER: Sanitize optional flat variants ---
// [{label, stock}] with unique non-empty labels and non-negative integer
// stock. Returns null when the product has no variants. Throws on bad input
// so a malformed payload can never write inconsistent stock.
function sanitizeVariants(raw: unknown): { label: string; stock: number }[] | null {
  if (!Array.isArray(raw) || raw.length === 0) return null;
  if (raw.length > 30) throw "Too many variants (max 30).";
  const seen = new Set<string>();
  const out: { label: string; stock: number }[] = [];
  for (const v of raw) {
    const label = String((v as any)?.label ?? '').trim().slice(0, 40);
    const stock = Math.floor(Number((v as any)?.stock));
    if (!label) throw "Variant label cannot be empty.";
    if (!Number.isFinite(stock) || stock < 0) throw `Invalid stock for variant "${label}".`;
    const key = label.toLowerCase();
    if (seen.has(key)) throw `Duplicate variant label: "${label}".`;
    seen.add(key);
    out.push({ label, stock });
  }
  return out;
}

// --- 3. MAIN LOGIC ---
serve(async (req) => {
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

    const { 
      vendorId, 
      productData 
    } = await req.json();

    if (vendorId !== secureUid) {
        throw new Error("Security Violation: You cannot perform actions for another user.");
    }

    if (!vendorId || !productData) {
      return new Response(JSON.stringify({ error: "Missing data" }), { status: 400 });
    }

    // 1. Calculate & Validate Value
    const price = Number(productData.price);
    // Variants (optional): the server-side sum is the ONLY source of truth
    // for total stock when variants exist; the client's flat number is ignored.
    const variants = sanitizeVariants(productData.variants);
    const stock = variants
      ? variants.reduce((acc, v) => acc + v.stock, 0)
      : Number(productData.availableStock);

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
        ...(variants ? { variants } : {}),

        status: 'approved',
        rejectionReason: null,

        isPremium: productData.isPremium || false,

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