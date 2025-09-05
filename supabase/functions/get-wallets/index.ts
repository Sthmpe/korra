// supabase/functions/get-wallets/index.ts
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
    headers: {
      Authorization: `Basic ${basic}`,
      "Content-Type": "application/json",
    },
  });
  const data = await res.json();
  if (!data.requestSuccessful) throw new Error("Auth failed");

  cachedToken = {
    value: data.responseBody.accessToken,
    exp: Date.now() + (data.responseBody.expiresIn * 1000 - 5000),
  };
  return cachedToken.value;
}

async function getWallets(query: URLSearchParams) {
  const pageSize = query.get("pageSize") ?? "10";
  const pageNo = query.get("pageNo") ?? "0";

  try {
    const token = await getAccessToken();

    const res = await fetch(
      `${BASE_URL}/api/v1/disbursements/wallet?pageSize=${pageSize}&pageNo=${pageNo}`,
      {
        method: "GET",
        headers: {
          Authorization: `Bearer ${token}`,
          Accept: "application/json",
        },
      },
    );

    const data = await res.json();
    if (!res.ok || !data.requestSuccessful) {
      return new Response(
        JSON.stringify({ ok: false, monnifyError: data }),
        {
          status: res.status,
          headers: { "Content-Type": "application/json" },
        },
      );
    }
    
    // Map the content array to extract full wallet details
    const wallets = data.responseBody?.content.map((wallet: any) => ({
      walletName: wallet.walletName,
      walletReference: wallet.walletReference,
      customerName: wallet.customerName,
      customerEmail: wallet.customerEmail,
      feeBearer: wallet.feeBearer,
      bvnDetails: wallet.bvnDetails,
      accountNumber: wallet.accountNumber,
      accountName: wallet.accountName,
      topUpAccountDetails: wallet.topUpAccountDetails,
    })) ?? [];

    return new Response(
      JSON.stringify({
        ok: true,
        total: data.responseBody?.totalElements ?? wallets.length,
        page: data.responseBody?.pageable?.pageNumber ?? Number(pageNo),
        wallets,
      }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ ok: false, message: error.message }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      },
    );
  }
}

// --- Entry Point ---
serve(async (req) => {
  if (req.method !== "GET") {
    return new Response(
      JSON.stringify({ ok: false, message: "Only GET allowed" }),
      {
        status: 405,
        headers: { "Content-Type": "application/json" },
      },
    );
  }

  const url = new URL(req.url);
  return await getWallets(url.searchParams);
});