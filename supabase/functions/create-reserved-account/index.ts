import { serve } from "https://deno.land/std/http/server.ts";

const BASE_URL = Deno.env.get("MONNIFY_BASE_URL")!;
const API_KEY = Deno.env.get("MONNIFY_API_KEY")!;
const SECRET_KEY = Deno.env.get("MONNIFY_SECRET_KEY")!;

let cachedToken: { value: string; exp: number } | null = null;

async function getAccessToken(): Promise<string> {
  if (cachedToken && cachedToken.exp > Date.now()) return cachedToken.value;

  const basic = btoa(`${API_KEY}:${SECRET_KEY}`);
  const res = await fetch(`${BASE_URL}/api/v2/bank-transfer/reserved-accounts`, {
    method: "POST",
    headers: { Authorization: `Basic ${basic}`, "Content-Type": "application/json" },
  });
  const data = await res.json();
  if (!data.requestSuccessful) throw new Error("Auth failed");

  cachedToken = { value: data.responseBody.accessToken, exp: Date.now() + (data.responseBody.expiresIn * 1000 - 5000) };
  return cachedToken.value;
}

async function createReservedAccount(body: any) {
  const { accountReference, accountName, currencyCode, contractCode, customerEmail, customerName, bvn, nin, incomeSplitConfig, metaData } = body ?? {};

  if (!accountReference || !accountName || !currencyCode || !contractCode || !customerEmail || (!bvn && !nin)) {
    return new Response(JSON.stringify({ ok: false, message: "Missing required fields" }), { status: 400, headers: { "Content-Type": "application/json" } });
  }

  const token = await getAccessToken();

  const res = await fetch(`${BASE_URL}/api/v2/bank-transfer/reserved-accounts`, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      accountReference,
      accountName,
      currencyCode,
      contractCode,
      customerEmail,
      customerName,
      bvn,
      nin,
      getAllAvailableBanks: true,
      incomeSplitConfig: incomeSplitConfig ?? [],
      metaData: metaData ?? {},
    }),
  });

  const data = await res.json();
  if (!res.ok || !data.requestSuccessful) {
    return new Response(JSON.stringify({ ok: false, message: data.responseMessage || "Reserved account creation failed" }), { status: 400, headers: { "Content-Type": "application/json" } });
  }

  const r = data.responseBody;
  const firstAccount = Array.isArray(r.accounts) && r.accounts.length > 0 ? r.accounts[0] : null;

  return new Response(JSON.stringify({
    ok: true,
    accountReference: r.accountReference,
    accountName: r.accountName,
    accountNumber: firstAccount?.accountNumber ?? "",
    bankName: firstAccount?.bankName ?? "",
    bankCode: firstAccount?.bankCode ?? "",
    currencyCode: r.currencyCode,
    customerEmail: r.customerEmail,
    status: r.status,
  }), { headers: { "Content-Type": "application/json" } });
}

// --- Entry Point ---
serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ ok: false, message: "Only POST allowed" }), { status: 405, headers: { "Content-Type": "application/json" } });
  }
  const body = await req.json();
  return await createReservedAccount(body);
});
