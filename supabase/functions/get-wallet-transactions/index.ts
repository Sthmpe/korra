// supabase/functions/get-wallet-transactions/index.ts
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

async function getWalletTransactions(body: any) {
    const { accountNumber } = body ?? {};
    if (!accountNumber) {
        return new Response(JSON.stringify({ ok: false, message: "Missing accountNumber" }), {
            status: 400,
            headers: { "Content-Type": "application/json" },
        });
    }

    const token = await getAccessToken();
    const res = await fetch(
        `${BASE_URL}/api/v1/disbursements/wallet/transactions?accountNumber=${accountNumber}`,
        { method: "GET", headers: { "Authorization": `Bearer ${token}` } },
    );

    const data = await res.json();
    if (!res.ok || !data.requestSuccessful) {
        return new Response(JSON.stringify({ ok: false, message: data.responseMessage || "Failed to fetch transactions" }), {
            status: 400,
            headers: { "Content-Type": "application/json" },
        });
    }

    // Pick only the transaction list
    const transactions = data.responseBody?.content ?? [];
    return new Response(
        JSON.stringify({
            ok: true,
            transactions: transactions.map((t: any) => ({
                reference: t.walletTransactionReference,
                amount: t.amount,
                type: t.transactionType,
                status: t.status,
                date: t.transactionDate,
                narration: t.narration,
            })),
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
    return await getWalletTransactions(body);
});
