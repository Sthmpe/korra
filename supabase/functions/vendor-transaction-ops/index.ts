import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

// --- CONFIGURATION ---
const MONNIFY_BASE_URL = "https://sandbox.monnify.com"; // Switch to Live for Prod
const MONNIFY_API_KEY = Deno.env.get("MONNIFY_API_KEY") ?? "";
const MONNIFY_SECRET_KEY = Deno.env.get("MONNIFY_SECRET_KEY") ?? "";
const MONNIFY_WALLET_ACCOUNT = Deno.env.get("MONNIFY_WALLET_ACCOUNT") ?? "";

// Initialize Firebase
const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

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
async function sendNotification(uid: string, title: string, body: string, type: string) {
  // 1. Write to In-App Notification Collection
  await db.collection('vendors').doc(uid).collection('notifications').add({
    title: title,
    body: body,
    type: type,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    // 'priority': 'high' // Flag for your UI to show gold border or special icon
  });

  // 2. (Optional) Trigger Push Notification / Email via FCM or Extension
  // If you have the "Trigger Email" extension installed on the 'mail' collection:
  /*
  await db.collection('mail').add({
    to: [userEmail],
    message: {
      subject: title,
      html: `<h1>${title}</h1><p>${body}</p>`,
    }
  });
  */
}

// --- MAIN HANDLER ---
serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { type, uid, pin, amount, destination } = await req.json();

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
      return new Response(JSON.stringify({ success: true }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    // ====================================================
    // 2. TRANSFER (PAYOUT)
    // ====================================================
    if (type === 'transfer') {
      if (!amount || amount <= 0) throw new Error("Invalid amount");
      if (!destination || !destination.bankCode || !destination.accountNumber) throw new Error("Invalid destination");

      // --- STEP A: VERIFY PIN ---
      const pinDoc = await db.collection('vendors').doc(uid).collection('security').doc('transaction_pin').get();
      if (!pinDoc.exists) throw new Error("PIN not set. Please create a transaction PIN.");
      
      const isValid = await verifyPin(pin, pinDoc.data().hash);
      if (!isValid) throw new Error("Incorrect PIN");

      // --- STEP B: ATOMIC LEDGER CHECK & DEDUCT (THE 2ND CHECK) ---
      const payoutRef = `PAYOUT-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
      
      await db.runTransaction(async (t) => {
        const statsRef = db.collection('vendor_stats').doc(uid);
        const statsDoc = await t.get(statsRef);
        
        // Calculate Liquid Cash: (Total Earnings) - (Locked in Vault) - (Already Paid Out)
        // This ensures they cannot withdraw locked funds or overdraw.
        const earnings = statsDoc.data()?.totalEarnings || 0;
        const locked = statsDoc.data()?.activeLocks || 0;
        const paidOut = statsDoc.data()?.totalPayouts || 0;
        const currentBalance = earnings - locked - paidOut;

        // THE CHECK
        if (currentBalance < amount) {
          throw new Error(`Insufficient funds. Available: ₦${currentBalance.toLocaleString()}`);
        }

        // Deduct Money (Create Record)
        const ledgerRef = db.collection('vendors').doc(uid).collection('ledger_transactions').doc();
        t.set(ledgerRef, {
          amount: -amount, // Negative
          type: 'payout',
          status: 'pending_monnify', 
          reference: payoutRef,
          description: `Withdrawal to ${destination.accountName}`,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          balanceBefore: currentBalance,
          balanceAfter: currentBalance - amount,
          metadata: {
            destinationBank: destination.bankCode,
            destinationAccount: destination.accountNumber
          }
        });

        // Update Stats (Optimistic)
        t.update(statsRef, {
          totalPayouts: admin.firestore.FieldValue.increment(amount)
        });
      });

      // --- STEP C: CALL MONNIFY ---
      try {
        const token = await getMonnifyToken();
        
        const monnifyPayload = {
          amount: amount,
          reference: payoutRef,
          narration: "Korra Payout",
          destinationBankCode: destination.bankCode,
          destinationAccountNumber: destination.accountNumber,
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

        const result = await response.json();

        // --- STEP D: HANDLE RESULT & NOTIFY ---
        let finalStatus = 'failed';
        let note = 'Transaction failed';

        // 1. SUCCESS CASE
        if (result.requestSuccessful && result.responseBody?.status === 'SUCCESS') {
          finalStatus = 'success';
          note = 'Payout successful';

          // ✅ SEND PREMIUM NOTIFICATION
          await sendNotification(
            uid,
            "Payout Successful 💸",
            `Your withdrawal of ₦${amount.toLocaleString()} to ${destination.accountName} was successful.`,
            "payout_success"
          );
        } 
        // 2. PENDING CASE
        else if (result.requestSuccessful && result.responseBody?.status === 'PENDING') {
          finalStatus = 'pending';
          note = 'Processing by bank';
          
          await sendNotification(
            uid,
            "Payout Processing ⏳",
            `Your withdrawal of ₦${amount.toLocaleString()} is being processed by the bank.`,
            "payout_pending"
          );
        } 
        // 3. FAILURE CASE (REFUND)
        else {
          finalStatus = 'failed';
          note = result.responseMessage || 'Gateway error';
          
          // Refund the Ledger
          await db.runTransaction(async (t) => {
             const ledgerRef = db.collection('vendors').doc(uid).collection('ledger_transactions').doc();
             t.set(ledgerRef, {
               amount: amount, // Positive
               type: 'refund',
               status: 'success',
               reference: `REFUND-${payoutRef}`,
               description: `Refund for failed payout`,
               createdAt: admin.firestore.FieldValue.serverTimestamp()
             });
             t.update(db.collection('vendor_stats').doc(uid), {
                totalPayouts: admin.firestore.FieldValue.increment(-amount)
             });
          });

          await sendNotification(
            uid,
            "Payout Failed ❌",
            `Your withdrawal of ₦${amount.toLocaleString()} failed. The funds have been returned to your wallet.`,
            "payout_failed"
          );
        }

        // Update Ledger Status
        const q = await db.collection('vendors').doc(uid).collection('ledger_transactions').where('reference', '==', payoutRef).get();
        if (!q.empty) {
          await q.docs[0].ref.update({ status: finalStatus, gatewayResponse: note });
        }

        return new Response(JSON.stringify({ 
          success: finalStatus !== 'failed',
          status: finalStatus,
          reference: payoutRef,
          message: note
        }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });

      } catch (monnifyError) {
        // If Monnify network fails, we keep it as 'pending_monnify' so a cron job can check it later.
        // We do NOT refund automatically here to avoid double-crediting if the money actually moved.
        throw new Error(`Gateway Error: ${monnifyError.message}`);
      }
    }

    throw new Error("Invalid operation");

  } catch (e) {
    return new Response(JSON.stringify({ success: false, error: e.message }), { 
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" } 
    });
  }
});