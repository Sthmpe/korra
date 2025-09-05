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

async function getReservedAccountTransactions(accountReference: string, page = 0, size = 10) {
  if (!accountReference) {
    return new Response(JSON.stringify({ ok: false, message: "Missing accountReference" }), { status: 400, headers: { "Content-Type": "application/json" } });
  }

  const token = await getAccessToken();
  const url = `${BASE_URL}/api/v1/bank-transfer/reserved-accounts/transactions?accountReference=${accountReference}&page=${page}&size=${size}`;
  
  const res = await fetch(url, {
    method: "GET",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
  });

  const data = await res.json();
  if (!res.ok || !data.requestSuccessful) {
    return new Response(JSON.stringify({ ok: false, message: data.responseMessage || "Failed to fetch transactions" }), { status: 400, headers: { "Content-Type": "application/json" } });
  }

  // Extract only transaction content array
  const transactions = data.responseBody?.content ?? [];

  return new Response(JSON.stringify({ ok: true, transactions }), { headers: { "Content-Type": "application/json" } });
}

// --- Entry Point ---
serve(async (req) => {
  if (req.method !== "GET") {
    return new Response(JSON.stringify({ ok: false, message: "Only GET allowed" }), { status: 405, headers: { "Content-Type": "application/json" } });
  }

  const url = new URL(req.url);
  const accountReference = url.searchParams.get("accountReference") ?? "";
  const page = parseInt(url.searchParams.get("page") ?? "0", 10);
  const size = parseInt(url.searchParams.get("size") ?? "10", 10);

  return await getReservedAccountTransactions(accountReference, page, size);
});
