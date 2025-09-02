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

async function createWallet(body: any) {
  const { walletReference, walletName, customerName, customerEmail, bvn, bvnDateOfBirth } = body ?? {};
  if (!walletReference || !walletName || !customerName || !customerEmail || !bvn || !bvnDateOfBirth)
    return new Response("Missing fields", { status: 400 });

  const token = await getAccessToken();
  const res = await fetch(`${BASE_URL}/api/v1/disbursements/wallet`, {
    method: "POST",
    body: JSON.stringify({
      walletReference,
      walletName,
      customerName,
      customerEmail,
      bvnDetails: { bvn, bvnDateOfBirth },
    }),
    headers: { "Authorization": `Bearer ${token}`, "Content-Type": "application/json" },
  });

  const data = await res.json();
  if (!data.requestSuccessful) return new Response(data.responseMessage || "Create wallet failed", { status: 400 });

  const r = data.responseBody;
  return new Response(JSON.stringify({
    ok: true,
    walletName: r.walletName,
    walletReference: r.walletReference,
    accountNumber: r.accountNumber,
    accountName: r.accountName,
  }), { headers: { "Content-Type": "application/json" } });
}

serve(async (req) => {
  if (req.method !== "POST") return new Response("Only POST", { status: 405 });
  const body = await req.json();
  return await createWallet(body);
});
