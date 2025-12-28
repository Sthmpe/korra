// supabase/functions/create-vendor-account/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

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
    const { uid, email, firstName, lastName, storeName } = await req.json()

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
      livenessCheckPassed: false,
      livenessBypass: true, // ✅ Default to TRUE (Bypass ON)
      livenessMatchPercentage: 0.0,
      lastCheckDate: null,
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