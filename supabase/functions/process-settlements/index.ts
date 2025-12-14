import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

// --- 1. FIREBASE INIT ---
console.log("[DEBUG] Starting Function Initialization...");

try {
  const serviceAccountRaw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
  if (!serviceAccountRaw) {
    console.error("[CRITICAL] FIREBASE_SERVICE_ACCOUNT is missing in env vars");
  } else {
    // Attempt parse to check validity
    const serviceAccount = JSON.parse(serviceAccountRaw);
    console.log(`[DEBUG] Firebase Config Found for project: ${serviceAccount.project_id}`);
    
    if (admin.apps.length === 0) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log("[DEBUG] Firebase App Initialized Successfully");
    }
  }
} catch (err) {
  console.error("[CRITICAL] Failed to initialize Firebase:", err.message);
}

const db = admin.firestore();

// --- 2. MAIN LOGIC ---
serve(async (req) => {
  const requestMethod = req.method;
  console.log(`[DEBUG] Received ${requestMethod} request`);

  try {
    // --- A. SECURITY CHECK ---
    const cronSecret = Deno.env.get('CRON_SECRET');
    const authHeader = req.headers.get('Authorization');

    // Debugging Secrets (Check logs to see what matches)
    console.log(`[DEBUG] Server CRON_SECRET exists: ${!!cronSecret}`);
    console.log(`[DEBUG] Received Authorization Header: ${authHeader}`);

    // 1. Server Config Check
    if (!cronSecret) {
      console.error("[ERROR] CRON_SECRET is not set in Supabase Secrets.");
      return new Response(JSON.stringify({ error: "Server Misconfiguration: Missing CRON_SECRET" }), { 
        status: 500,
        headers: { "Content-Type": "application/json" }
      });
    }

    // 2. Auth Check
    const expectedHeader = `Bearer ${cronSecret}`;
    if (authHeader !== expectedHeader) {
      console.warn("[WARN] Auth Mismatch!");
      console.warn(`[WARN] Expected: ${expectedHeader}`);
      console.warn(`[WARN] Received: ${authHeader}`);
      return new Response(JSON.stringify({ error: "Unauthorized: Secret mismatch" }), { 
        status: 401,
        headers: { "Content-Type": "application/json" }
      });
    }

    console.log("[DEBUG] Authentication Successful. Proceeding to DB...");

    const now = admin.firestore.Timestamp.now();
    console.log(`[DEBUG] Current Server Time: ${now.toDate().toISOString()}`);

    // --- B. QUERY ---
    // Log the query attempt
    console.log("[DEBUG] Querying 'ledger_transactions' where status='locked' AND releaseDate <= now...");

    const snapshot = await db.collectionGroup('ledger_transactions')
      .where('status', '==', 'locked')
      .where('releaseDate', '<=', now)
      .limit(500)
      .get();

    console.log(`[DEBUG] Query Complete. Found ${snapshot.size} documents to release.`);

    if (snapshot.empty) {
      return new Response(JSON.stringify({ 
        success: true, 
        message: "No funds to release", 
        processed: 0 
      }), { 
        headers: { "Content-Type": "application/json" } 
      });
    }

    // --- C. BATCH UPDATES ---
    console.log("[DEBUG] Starting Batch Write...");
    const batch = db.batch();
    
    snapshot.docs.forEach(doc => {
      const data = doc.data();
      const vendorId = doc.ref.parent.parent!.id; 
      
      console.log(`[DEBUG] releasing doc: ${doc.id} for vendor: ${vendorId}, amount: ${data.amount}`);

      // 1. Update Ledger
      batch.update(doc.ref, { 
        status: 'available',
        releasedAt: now,
        updatedAt: now 
      });

      // 2. Create Notification
      const notifRef = db.collection('vendors').doc(vendorId).collection('notifications').doc();
      batch.set(notifRef, {
        title: "Funds Released 🔓",
        body: `₦${(data.amount || 0).toLocaleString()} is now available for withdrawal.`,
        type: "fund_release",
        isRead: false,
        createdAt: now,
        refId: doc.id
      });
    });

    // --- D. COMMIT ---
    await batch.commit();
    console.log("[DEBUG] Batch Commit Successful.");

    return new Response(JSON.stringify({ 
      success: true, 
      releasedCount: snapshot.size 
    }), { 
      headers: { "Content-Type": "application/json" } 
    });

  } catch (error) {
    // Catch-all for crashes
    console.error("[CRITICAL EXCEPTION]", error);
    return new Response(JSON.stringify({ 
      success: false, 
      error: error.message,
      stack: error.stack 
    }), { 
      status: 500,
      headers: { "Content-Type": "application/json" } 
    });
  }
});