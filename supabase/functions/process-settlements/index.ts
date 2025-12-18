import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

// --- 1. FIREBASE INIT ---
console.log("[INIT] Starting Function...");

try {
  const serviceAccountRaw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
  if (!serviceAccountRaw) {
    console.error("[CRITICAL] FIREBASE_SERVICE_ACCOUNT is missing");
  } else {
    const serviceAccount = JSON.parse(serviceAccountRaw);
    if (admin.apps.length === 0) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log(`[INIT] Connected to project: ${serviceAccount.project_id}`);
    }
  }
} catch (err) {
  console.error("[CRITICAL] Firebase Init Failed:", err.message);
}

const db = admin.firestore();

// --- 2. MAIN LOGIC ---
serve(async (req) => {
  try {
    // --- A. SECURITY CHECK ---
    const cronSecret = Deno.env.get('CRON_SECRET');
    const authHeader = req.headers.get('Authorization');

    if (!cronSecret) {
      return new Response(JSON.stringify({ error: "Server Misconfiguration: Missing CRON_SECRET" }), { status: 500 });
    }

    if (authHeader !== `Bearer ${cronSecret}`) {
      console.warn(`[WARN] Unauthorized access attempt.`);
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }

    // --- B. QUERY ---
    const now = admin.firestore.Timestamp.now();
    
    // ⚠️ BATCH LIMIT FIX: 
    // We do 2 writes per doc (Update Ledger + Create Notif).
    // Firestore limit is 500 writes. So we must limit query to 250 max.
    // We use 200 to be safe.
    const snapshot = await db.collectionGroup('ledger_transactions')
      .where('status', '==', 'locked')
      .where('releaseDate', '<=', now)
      .limit(200) 
      .get();

    if (snapshot.empty) {
      console.log("[INFO] No locked funds due for release.");
      return new Response(JSON.stringify({ success: true, processed: 0 }), { 
        headers: { "Content-Type": "application/json" } 
      });
    }

    console.log(`[INFO] Found ${snapshot.size} transactions to release.`);

    // --- C. BATCH UPDATES ---
    const batch = db.batch();
    
    snapshot.docs.forEach(doc => {
      const data = doc.data();
      // Locate the vendor ID from the path: vendors/{vendorId}/ledger_transactions/{docId}
      const vendorId = doc.ref.parent.parent!.id; 

      // 1. Update Ledger Status
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
      
      // OPTIONAL: If you track 'activeLocks' in vendor_stats, you would decrement it here.
      // However, updating stats for multiple vendors in one batch is complex.
      // Ideally, your 'Liquid Cash' logic should calculate 'locked' by querying the ledger directly 
      // or using a cloud function trigger on the ledger update.
    });

    // --- D. COMMIT ---
    await batch.commit();
    console.log(`[SUCCESS] Released ${snapshot.size} transactions.`);

    return new Response(JSON.stringify({ 
      success: true, 
      releasedCount: snapshot.size 
    }), { 
      headers: { "Content-Type": "application/json" } 
    });

  } catch (error) {
    console.error("[CRITICAL EXCEPTION]", error);
    return new Response(JSON.stringify({ success: false, error: error.message }), { 
      status: 500,
      headers: { "Content-Type": "application/json" } 
    });
  }
});