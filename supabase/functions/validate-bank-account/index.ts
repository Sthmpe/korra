import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

// 1. DEFINE CORS HEADERS
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const BASE_URL = Deno.env.get("MONNIFY_BASE_URL")!;
const API_KEY = Deno.env.get("MONNIFY_API_KEY")!;
const SECRET_KEY = Deno.env.get("MONNIFY_SECRET_KEY")!;

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