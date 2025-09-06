// supabase/functions/initiate-transfer/index.ts
import { serve } from "https://deno.land/std/http/server.ts";

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

async function initiateTransfer(body: any) {
    const { amount, reference, narration, destinationBankCode, destinationAccountNumber, currency, sourceAccountNumber } = body ?? {};
    if (!amount || !reference || !narration || !destinationBankCode || !destinationAccountNumber || !currency || !sourceAccountNumber) {
        return new Response(JSON.stringify({ ok: false, message: "Missing fields" }), {
            status: 400,
            headers: { "Content-Type": "application/json" },
        });
    }

    const token = await getAccessToken();

    const res = await fetch(`${BASE_URL}/api/v2/disbursements/single`, {
        method: "POST",
        headers: { "Authorization": `Bearer ${token}`, "Content-Type": "application/json" },
        body: JSON.stringify({
            amount,
            reference,
            narration,
            destinationBankCode,
            destinationAccountNumber,
            currency,
            sourceAccountNumber,
        }),
    });

    const data = await res.json();
    if (!res.ok || !data.requestSuccessful) {
        return new Response(JSON.stringify({ ok: false, message: data.responseMessage || "Transfer failed" }), {
            status: 400,
            headers: { "Content-Type": "application/json" },
        });
    }

    const r = data.responseBody;
    return new Response(
        JSON.stringify({
            ok: true,
            amount: r.amount,
            reference: r.reference,
            status: r.status,
            fee: r.totalFee,
            beneficiary: {
                name: r.destinationAccountName,
                bank: r.destinationBankName,
                accountNumber: r.destinationAccountNumber,
                bankCode: r.destinationBankCode,
            },
            dateCreated: r.dateCreated,
        }),
        { headers: { "Content-Type": "application/json" } },
    );
}

// --- Entry Point ---
serve(async (req) => {
    if (req.method !== "POST") {
        return new Response(JSON.stringify({ ok: false, message: "Only POST allowed" }), {
            status: 405,
            headers: { "Content-Type": "application/json" },
        });
    }
    const body = await req.json();
    return await initiateTransfer(body);
});