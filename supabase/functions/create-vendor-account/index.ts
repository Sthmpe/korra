// supabase/functions/create-vendor-account/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, firebase-token, x-korra-timestamp, x-korra-signature', 
};

// Initialize Firebase Admin
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

    const { uid, email, firstName, lastName, storeName } = await req.json()

    if (uid !== secureUid) {
        throw new Error("Security Violation: You cannot perform actions for another user.");
    }

    // ============================================================
    // 🆕 SECURE VENDOR INITIALIZATION
    // ============================================================
    const batch = db.batch();
    const timestamp = admin.firestore.FieldValue.serverTimestamp();

    // 1. Initialize CASH LEDGER (Assets - Real Money)
    const ledgerRef = db.collection('vendors').doc(uid).collection('ledger_transactions').doc();
    batch.set(ledgerRef, {
      id: ledgerRef.id,
      userId: uid,
      amount: 0.00,
      type: 'system',
      description: 'Vendor Account Created',
      reference: `INIT-CSH-${ledgerRef.id.substring(0, 8)}`,
      status: 'success',
      balanceBefore: 0.00,
      balanceAfter: 0.00,
      createdAt: timestamp,
      releaseDate: null, 
      orderId: null
    });

    // 2. Initialize LIABILITY LEDGER (Store Credit Owed)
    // Tracks store credits issued to customers upon cancellation
    const liabilityRef = db.collection('vendors').doc(uid).collection('liabilities').doc();
    batch.set(liabilityRef, {
      id: liabilityRef.id,
      userId: uid,
      amount: 0.00,
      type: 'system',
      description: 'Liability Ledger Initialized',
      reference: `INIT-LIAB-${liabilityRef.id.substring(0, 8)}`,
      createdAt: timestamp
    });

    // 3. Initialize VENDOR STATS & LIMITS (Tier 1 Default)
    const statsRef = db.collection('vendor_stats').doc(uid);
    batch.set(statsRef, {
      uid: uid,
      
      // Financial Stats
      totalSalesVolume: 0.00,
      totalEarnings: 0.00,
      activeLocks: 0.00,
      totalLiability: 0.00,        // Total Store Credit currently owed
      currentActivePlanValue: 0.00,// Total value of running plans (for limit calc)
      reputationScore: 100, 
      
      // RISK CONTROLS (Tier 1 Defaults)
      tier: 1,                     // Default Tier
      isVerified: false,           // Needs phone call
      maxPlanAmount: 100000.00,    // Max Price per Item (100k)
      maxReservationLimit: 250000.00, // Total Capacity (250k)
      
      lastUpdated: timestamp
    });

    // 4. 🆕 Initialize COMPLIANCE DOC (New Collection)
    const complianceRef = db.collection('vendor_compliance').doc(uid);
    batch.set(complianceRef, {
      uid: uid,
      
      // ✅ TRAFFIC LIGHT STATUS (Starts Red)
      status: 'verification_pending', 
      reason: 'New Account',
      publicMessage: 'To protect your funds, we need to verify your identity before enabling withdrawals.',
      
      // ✅ OPERATIONAL FLAGS
      blockPayments: false, // If true, the customer app strictly blocks new payments
      
      // ✅ LIVENESS / IDENTITY
      livenessCheckPassed: false,
      livenessBypass: true, // ✅ Default to TRUE (Bypass ON)
      livenessMatchPercentage: 0.0,
      lastCheckDate: null,

      // ✅ COMPLIANCE METRICS (For admin tracking)
      metrics: {
        restrictionCount: 0,      // How many times we blocked them
        resolutionCount: 0,       // How many times they fixed an issue
        falseComplaintCount: 0    // How many times a customer lied about them
      },

      // ✅ HISTORY LOGS (Ready for future implementation)
      complaints: [], // Will hold maps: { date, type, customerId, resolved }
      reviews: [],    // Will hold maps: { date, rating, customerId, isGood }

      updatedAt: timestamp
    });

    // 5. Create Empty Payout Details Doc
    const payoutRef = db.collection('vendors').doc(uid).collection('settings').doc('payout_details');
    batch.set(payoutRef, {
      bankName: null,
      accountNumber: null,
      accountName: null,
      bankCode: null,
      updatedAt: timestamp
    });

    // 6. 🆕 Send WELCOME Notification (In-App)
    const notifRef = db.collection('vendors').doc(uid).collection('notifications').doc();
    batch.set(notifRef, {
      id: notifRef.id,
      title: "Welcome to Korra Business! 🚀",
      body: "Your vendor account is active. Complete your verification to start accepting payments.",
      type: "system",
      isRead: false,
      createdAt: timestamp
    });

    await batch.commit();
    // ============================================================

    return new Response(JSON.stringify({
      success: true,
      message: "Vendor account initialized successfully"
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