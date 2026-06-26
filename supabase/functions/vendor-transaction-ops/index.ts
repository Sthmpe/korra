import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

// 1. DEFINE CORS HEADERS
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, firebase-token, x-korra-signature, x-korra-timestamp',
};

// --- CONFIGURATION ---
const MONNIFY_BASE_URL =  Deno.env.get("MONNIFY_BASE_URL") || ""; // Switch to Live for Prod
const MONNIFY_API_KEY = Deno.env.get("MONNIFY_API_KEY") ?? "";
const MONNIFY_SECRET_KEY = Deno.env.get("MONNIFY_SECRET_KEY") ?? "";
const MONNIFY_WALLET_ACCOUNT = Deno.env.get("MONNIFY_WALLET_ACCOUNT") ?? "";

// Initialize Firebase
const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

// --- HELPER: MONNIFY AUTH ---
async function getMonnifyToken() {
  const authString = btoa(`${MONNIFY_API_KEY}:${MONNIFY_SECRET_KEY}`);
  const response = await fetch(`${MONNIFY_BASE_URL}/api/v1/auth/login`, {
    method: "POST",
    headers: { "Authorization": `Basic ${authString}` }
  });
  const data = await response.json();
  if (!data.requestSuccessful) throw new Error("Failed to authenticate with Payment Gateway");
  return data.responseBody.accessToken;
}

// --- HELPER: CRYPTO ---
async function hashPin(pin: string, salt: Uint8Array | null = null): Promise<string> {
  const encoder = new TextEncoder();
  const finalSalt = salt || crypto.getRandomValues(new Uint8Array(16));
  const key = await crypto.subtle.importKey("raw", encoder.encode(pin), { name: "PBKDF2" }, false, ["deriveBits"]);
  const derived = await crypto.subtle.deriveBits({ name: "PBKDF2", hash: "SHA-256", salt: finalSalt, iterations: 100_000 }, key, 256);
  const hashHex = Array.from(new Uint8Array(derived)).map(b => b.toString(16).padStart(2, "0")).join("");
  return `${btoa(String.fromCharCode(...finalSalt))}:${hashHex}`;
}

async function verifyPin(inputPin: string, storedHash: string): Promise<boolean> {
  const [saltB64, originalHash] = storedHash.split(':');
  const saltStr = atob(saltB64);
  const salt = new Uint8Array(saltStr.length);
  for (let i = 0; i < saltStr.length; i++) salt[i] = saltStr.charCodeAt(i);
  const newHashFull = await hashPin(inputPin, salt);
  const [, newHash] = newHashFull.split(':');
  return newHash === originalHash;
}

// --- HELPER: SEND PREMIUM NOTIFICATION ---
async function sendNotification(
  uid: string, 
  title: string, 
  body: string, 
  type: string, 
  amountDisplay: string = "", 
  refId: string = ""
) {
  // 1. Save to your original notifications collection
  await db.collection('vendors').doc(uid).collection('notifications').add({
    title: title,
    body: body,
    type: type,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // 2. Save to the new Activity Feed collection
  const activityRef = db.collection('vendors').doc(uid).collection('activity_feed').doc();
  await activityRef.set({
    id: activityRef.id,
    type: type, // Maps to your VendorActivityType
    title: title,
    body: body,
    ref_id: refId,
    amount_display: amountDisplay,
    date: admin.firestore.FieldValue.serverTimestamp(),
    is_read: false
  });

  // 3. Send FCM Push Notification to the Device
  try {
    const vendorDoc = await db.collection('vendors').doc(uid).get();
    const vendorData = vendorDoc.data();
    
    // Look for the FCM token (handles both string and array formats)
    const fcmToken = vendorData?.fcmToken || vendorData?.fcmTokens;

    if (fcmToken) {
      const payload = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: type,
          refId: refId,
        }
      };

      if (Array.isArray(fcmToken) && fcmToken.length > 0) {
        await admin.messaging().sendEachForMulticast({ ...payload, tokens: fcmToken });
      } else if (typeof fcmToken === 'string') {
        await admin.messaging().send({ ...payload, token: fcmToken });
      }
    }
  } catch (err) {
    console.error('FCM Push Notification Error:', err);
  }
}

// --- MAIN HANDLER ---
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
        secureUid = decodedToken.uid;
    } catch (error) {
        throw new Error("Unauthorized Access: Token expired or invalid.");
    }

    const { type, uid, pin, amount, destination } = await req.json();

    if (uid !== secureUid) {
        throw new Error("Security Violation: You cannot perform actions for another user.");
    }

    if (!uid || !pin) throw new Error("Missing UID or PIN");

    // ====================================================
    // 1. PIN CREATION
    // ====================================================
    if (type === 'create_pin') {
      const secureHash = await hashPin(pin);
      await db.collection('vendors').doc(uid).collection('security').doc('transaction_pin').set({
        hash: secureHash,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return new Response(JSON.stringify({ success: true }), { 
        headers: { ...corsHeaders, "Content-Type": "application/json" } 
      });
    }

    // ====================================================
    // 2. VERIFY PIN ONLY
    // Used by: Payout Settings screen to gate account changes.
    // Checks the PIN is correct but does nothing else —
    // Flutter then writes autoPayoutBankDetails to Firestore directly.
    // ====================================================
    if (type === 'verify_pin') {
      const pinDoc = await db
        .collection('vendors')
        .doc(uid)
        .collection('security')
        .doc('transaction_pin')
        .get();
 
      if (!pinDoc.exists) throw new Error("PIN not set. Please create a transaction PIN first.");
 
      const isValid = await verifyPin(pin, pinDoc.data().hash);
      if (!isValid) throw new Error("Incorrect PIN. Please try again.");
 
      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
 
    // ====================================================
    // 3. TRANSFER (PAYOUT)
    // ====================================================
    if (type === 'transfer') {
      // 🚀 HARD BLOCK: Minimum 1000
      if (!amount || amount < 1000) throw new Error("Minimum withdrawal amount is ₦1,000");
      if (!destination || !destination.bankCode || !destination.accountNumber) throw new Error("Invalid destination");

      // --- CALCULATE EMTL FEE ---
      const EMTL_THRESHOLD = 10000;  // ₦10,000 (Govt Rule)
      const GOVT_LEVY = 50;          // ₦50 (Govt Rule)
      
      const fee = amount >= EMTL_THRESHOLD ? GOVT_LEVY : 0;
      const totalDeduction = amount + fee; // The exact total coming out of their Korra Wallet

      // --- STEP A: VERIFY PIN ---
      const pinDoc = await db.collection('vendors').doc(uid).collection('security').doc('transaction_pin').get();
      if (!pinDoc.exists) throw new Error("PIN not set. Please create a transaction PIN.");
      
      const isValid = await verifyPin(pin, pinDoc.data().hash);
      if (!isValid) throw new Error("Incorrect PIN");

      // --- STEP B: ATOMIC LEDGER CHECK & DEDUCT (THE 2ND CHECK) ---
      // 1. Convert timestamp to a short string of letters and numbers (e.g., "LTT8F140")
      const timeStr = Date.now().toString(36).toUpperCase(); 

      // 2. Grab just the last 4 characters of the vendor's UID (e.g., "EYT2")
      const userSlice = uid.slice(-4).toUpperCase(); 

      // 3. Combine them for a beautiful, bulletproof reference: "PAYOUT-LTT8F140-EYT2"
      const payoutRef = `PAYOUT-${timeStr}-${userSlice}`;
      
      await db.runTransaction(async (t) => {
        const statsRef = db.collection('vendor_stats').doc(uid);
        const statsDoc = await t.get(statsRef);
        
        // Calculate Liquid Cash
        const earnings = statsDoc.data()?.totalEarnings || 0;
        const locked = statsDoc.data()?.activeLocks || 0;
        const paidOut = statsDoc.data()?.totalPayouts || 0;
        const currentBalance = earnings - locked - paidOut;

        // THE CHECK
        if (currentBalance < totalDeduction) {
          if (fee > 0) {
            throw new Error(`Insufficient funds. You need ₦${totalDeduction.toLocaleString()} to cover the withdrawal + ₦50 Govt Levy.`);
          }
          throw new Error(`Insufficient funds. Available: ₦${currentBalance.toLocaleString()}`);
        }

        // Deduct Payout Amount
        const ledgerRef = db.collection('vendors').doc(uid).collection('ledger_transactions').doc();
        t.set(ledgerRef, {
          amount: -amount, // Negative
          type: 'payout',
          status: 'pending_monnify', 
          settlementStatus: 'cleared',
          reference: payoutRef,
          description: `Withdrawal to ${destination.accountName}`,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          balanceBefore: currentBalance,
          balanceAfter: currentBalance - amount,
          metadata: {
            destinationBank: destination.bankCode,
            destinationAccount: destination.accountNumber,
            destinationName: destination.accountName
          }
        });

        // 🚀 DEDUCT EMTL FEE (As a separate, clean ledger record)
        if (fee > 0) {
          const feeRef = db.collection('vendors').doc(uid).collection('ledger_transactions').doc();
          t.set(feeRef, {
            amount: -fee,
            type: 'fee',
            status: 'success', // Fees are final
            reference: `FEE-${payoutRef}`,
            description: `EMTL Government Levy`,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            balanceBefore: currentBalance - amount,
            balanceAfter: currentBalance - totalDeduction,
          });

          await sendNotification(
            uid,
            "EMTL Levy Deducted",
            "A ₦50 Government Levy was applied to your withdrawal.",
            "system",           // type
            "-₦50",             // amountDisplay
            `FEE-${payoutRef}`  // refId
          );
        }

        // Update Stats (Optimistic) - We add the total deduction so it lowers their balance correctly
        t.update(statsRef, {
          totalPayouts: admin.firestore.FieldValue.increment(totalDeduction)
        });

        // Create a mapping for this payout reference to the vendor UID (for easy lookups when Monnify calls us back)
        const mappingRef = db.collection('monnify_mappings').doc(payoutRef);
        t.set(mappingRef, {
            vendorUid: uid,
            type: 'payout',
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
      });

      // --- STEP C: CALL MONNIFY ---
      try {
        let result: any;

        const token = await getMonnifyToken();
        const monnifyPayload = {
          amount: amount,
          reference: payoutRef,
          narration: "Korra Payout",
          destinationBankCode: destination.bankCode,
          destinationAccountNumber: destination.accountNumber,
          destinationAccountName: destination.accountName,
          currency: "NGN",
          sourceAccountNumber: MONNIFY_WALLET_ACCOUNT, 
          async: false 
        };

        const response = await fetch(`${MONNIFY_BASE_URL}/api/v2/disbursements/single`, {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${token}`,
            "Content-Type": "application/json"
          },
          body: JSON.stringify(monnifyPayload)
        });

        result = await response.json();




        // --- STEP D: SUBMIT ONLY ---
        // Webhook (monnify-webhook) is the single source of truth for everything.
        // SUCCESSFUL_DISBURSEMENT → webhook marks success + notifies merchant
        // FAILED_DISBURSEMENT     → webhook runs refund saga + notifies merchant
        // We just log what Monnify returned and return pending to Flutter.
        console.log(`📤 Payout submitted ${payoutRef} → Monnify status: ${result.responseBody?.status ?? 'unknown'}`);

        await sendNotification(
          uid,
          "Payout In Progress ⏳",
          `Your withdrawal of ₦${amount.toLocaleString()} to ${destination.accountName} is being processed.`,
          "payout_pending",
          `-₦${amount.toLocaleString()}`,
          payoutRef
        );

        return new Response(JSON.stringify({ 
          success: true,
          status: 'pending',
          reference: payoutRef,
          message: 'Payout submitted. You will be notified once confirmed.',
        }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });

      } catch (gatewayError) {
        // If network fails, keep it as 'pending_monnify'
        const errMsg = gatewayError instanceof Error ? gatewayError.message : String(gatewayError);
        throw new Error(`Gateway Error: ${errMsg}`);
      }
    }

    throw new Error("Invalid operation");

  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return new Response(JSON.stringify({ success: false, error: msg }), { 
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" } 
    });
  }
});