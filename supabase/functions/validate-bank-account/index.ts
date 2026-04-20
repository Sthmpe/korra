import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0"; 

// 1. DEFINE CORS HEADERS
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, firebase-token, x-korra-timestamp, x-korra-signature', 
};

const BASE_URL = Deno.env.get("MONNIFY_BASE_URL")!;
const API_KEY = Deno.env.get("MONNIFY_API_KEY")!;
const SECRET_KEY = Deno.env.get("MONNIFY_SECRET_KEY")!;

// 🔐 Initialize Firebase Admin
const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}

let cachedToken: { value: string; exp: number } | null = null;

async function getAccessToken(): Promise<string> {
    if (cachedToken && cachedToken.exp > Date.now()) return cachedToken.value;

    const basic = btoa(`${API_KEY}:${SECRET_KEY}`);
    const res = await fetch(`${BASE_URL}/api/v1/auth/login`, {
        method: "POST",
        headers: { Authorization: `Basic ${basic}`, "Content-Type": "application/json" },
    });

    const data = await res.json();
    if (!data.requestSuccessful) throw new Error("Auth failed");

    cachedToken = {
        value: data.responseBody.accessToken,
        exp: Date.now() + (data.responseBody.expiresIn * 1000 - 5000),
    };
    return cachedToken.value;
}

// Helper: Returns Data Object or Throws Error
async function validateBankAccount(accountNumber: string, bankCode: string) {
    const token = await getAccessToken();

    const res = await fetch(
        `${BASE_URL}/api/v1/disbursements/account/validate?accountNumber=${accountNumber}&bankCode=${bankCode}`,
        {
            method: "GET",
            headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
        },
    );

    const data = await res.json();
    
    if (!res.ok || !data.requestSuccessful) {
        throw new Error(data.responseMessage || "Validation failed");
    }

    const r = data.responseBody;
    return {
        ok: true,
        accountNumber: r.accountNumber,
        accountName: r.accountName,
        bankCode: r.bankCode,
    };
}

// --- Entry Point ---
serve(async (req) => {
    // A. CORS Pre-flight
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    try {
        if (req.method !== "POST") {
            throw new Error("Only POST allowed");
        }

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
            return new Response(JSON.stringify({ ok: false, message: "Unauthorized: Missing VIP pass." }), {
                status: 401,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            });
        }

        const idToken = authHeader.split('Bearer ')[1];
        try {
            // This mathematically proves the request came from a logged-in user on your Flutter app
            await admin.auth().verifyIdToken(idToken);
        } catch (error) {
            return new Response(JSON.stringify({ ok: false, message: "Unauthorized: Invalid or expired token." }), {
                status: 403,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            });
        }
        
        const body = await req.json();
        const { accountNumber, bankCode } = body;

        if (!accountNumber || !bankCode) {
            return new Response(JSON.stringify({ ok: false, message: "Missing accountNumber or bankCode" }), {
                status: 400,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            });
        }

        // B. Execute Logic
        const result = await validateBankAccount(accountNumber, bankCode);

        // C. Success Response
        return new Response(JSON.stringify(result), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
        });

    } catch (error) {
        // D. Error Handling
        const msg = error instanceof Error ? error.message : String(error);
        
        return new Response(JSON.stringify({ ok: false, message: msg }), {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
    }
});