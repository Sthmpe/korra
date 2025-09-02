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
  const token = data.responseBody.accessToken;
  cachedToken = { value: token, exp: Date.now() + (data.responseBody.expiresIn * 1000 - 5000) };
  return token;
}

serve(async (req) => {
  if (req.method !== "GET") return new Response("Only GET", { status: 405 });
  const url = new URL(req.url);
  const accountNumber = url.searchParams.get("accountNumber");
  if (!accountNumber) return new Response("accountNumber required", { status: 400 });

  const token = await getAccessToken();
  const res = await fetch(`${BASE_URL}/api/v1/disbursements/wallet/balance?accountNumber=${accountNumber}`, {
    method: "GET",
    headers: { "Authorization": `Bearer ${token}`, "Accept": "application/json" },
  });

  const data = await res.json();
  if (!data.requestSuccessful) return new Response(data.responseMessage || "Failed to fetch balance", { status: 400 });

  return new Response(JSON.stringify({ ok: true, availableBalance: data.responseBody?.availableBalance }), { headers: { "Content-Type": "application/json" } });
});
