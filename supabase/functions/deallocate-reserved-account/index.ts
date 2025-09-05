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

async function deallocateReservedAccount(accountReference: string) {
  if (!accountReference) {
    return new Response(JSON.stringify({ ok: false, message: "Missing accountReference" }), { status: 400, headers: { "Content-Type": "application/json" } });
  }

  const token = await getAccessToken();

  const res = await fetch(`${BASE_URL}/api/v1/bank-transfer/reserved-accounts/reference/${accountReference}`, {
    method: "DELETE",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
  });

  const data = await res.json();
  if (!res.ok || !data.requestSuccessful) {
    return new Response(JSON.stringify({ ok: false, message: data.responseMessage || "Failed to deallocate reserved account" }), { status: 400, headers: { "Content-Type": "application/json" } });
  }

  return new Response(JSON.stringify({
    ok: true,
    accountReference: data.responseBody.accountReference,
    status: "DEALLOCATED"
  }), { headers: { "Content-Type": "application/json" } });
}

// --- Entry Point ---
serve(async (req) => {
  if (req.method !== "DELETE") {
    return new Response(JSON.stringify({ ok: false, message: "Only DELETE allowed" }), { status: 405, headers: { "Content-Type": "application/json" } });
  }
  const body = await req.json();
  return await deallocateReservedAccount(body.accountReference);
});
