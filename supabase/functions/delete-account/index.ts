import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

// 1. INIT FIREBASE
const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();
const auth = admin.auth();

// 2. MONNIFY CONFIG
const MONNIFY_BASE_URL = "https://sandbox.monnify.com"; // Change to Live for prod
const MONNIFY_API_KEY = Deno.env.get("MONNIFY_API_KEY");
const MONNIFY_SECRET = Deno.env.get("MONNIFY_SECRET_KEY");

// Helper: Get Monnify Access Token
async function getMonnifyToken() {
  const authString = btoa(`${MONNIFY_API_KEY}:${MONNIFY_SECRET}`);
  const res = await fetch(`${MONNIFY_BASE_URL}/api/v1/auth/login`, {
    method: "POST",
    headers: { "Authorization": `Basic ${authString}` }
  });
  const data = await res.json();
  if (!data.requestSuccessful) throw "Monnify Auth Failed";
  return data.responseBody.accessToken;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*' } });

  try {
    const { customerUid } = await req.json();
    if (!customerUid) throw "User ID required";

    // --- GATE 1: CHECK ACTIVE PLANS ---
    // We check for ANY plan that is not 'completed' or 'cancelled'.
    // This catches 'active', 'overdue', 'pending_approval'.
    const activePlansQuery = await db.collection("plans")
      .where("customerId", "==", customerUid)
      .where("status", "in", ["active", "overdue", "pending_approval"])
      .get();

    if (!activePlansQuery.empty) {
      // 🛑 BLOCK DELETION
      return new Response(
        JSON.stringify({ success: false, error: "You cannot delete your account while you have active or overdue plans. Please complete or cancel them first." }), 
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // --- GATE 2: GET WALLET REFERENCE ---
    const userDoc = await db.collection("customer").doc(customerUid).get();
    if (!userDoc.exists) throw "User profile not found";
    
    const userData = userDoc.data();
    const walletRef = userData?.monnify?.walletReference;

    // --- STEP 3: DEALLOCATE MONNIFY ACCOUNT ---
    if (walletRef) {
      try {
        const token = await getMonnifyToken();
        const deleteUrl = `${MONNIFY_BASE_URL}/api/v1/bank-transfer/reserved-accounts/reference/${walletRef}`;
        
        const monnifyRes = await fetch(deleteUrl, {
          method: "DELETE",
          headers: { "Authorization": `Bearer ${token}` }
        });
        
        const monnifyData = await monnifyRes.json();
        // We log but don't stop if Monnify fails (maybe account already deleted)
        console.log("Monnify Deallocation:", monnifyData); 
      } catch (e) {
        console.error("Monnify Error (Non-fatal):", e);
      }
    }

    // --- STEP 4: WIPE FIRESTORE DATA ---
    // We use a Batch to ensure atomicity where possible
    const batch = db.batch();
    
    // A. Delete Main Profile
    const userRef = db.collection("customer").doc(customerUid);
    batch.delete(userRef);

    // B. Delete Limits Profile
    const limitRef = db.collection("customer_limits").doc(customerUid);
    batch.delete(limitRef);

    // C. (Optional) Delete Subcollections? 
    // Firestore doesn't recursively delete subcollections (like 'ledger_transactions').
    // For a true wipe, you'd need to query and delete them, but for MVP, 
    // removing the parent reference acts as a "Soft Delete" since queries rely on UID.
    
    await batch.commit();

    // --- STEP 5: DELETE AUTH USER ---
    await auth.deleteUser(customerUid);

    console.log(`✅ Account Deleted: ${customerUid}`);

    return new Response(
      JSON.stringify({ success: true, message: "Account deleted successfully" }), 
      { headers: { "Content-Type": "application/json" } }
    );

  } catch (err) {
    return new Response(
      JSON.stringify({ success: false, error: err.toString() }), 
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});