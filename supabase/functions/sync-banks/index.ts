import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Environment variables
const BASE_URL = Deno.env.get("MONNIFY_BASE_URL")!;
const API_KEY = Deno.env.get("MONNIFY_API_KEY")!;
const SECRET_KEY = Deno.env.get("MONNIFY_SECRET_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Supabase client (service role for writes)
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, { global: { fetch } });

let cachedToken: { value: string; exp: number } | null = null;

// Get Monnify access token
async function getAccessToken(): Promise<string> {
  if (cachedToken && cachedToken.exp > Date.now()) return cachedToken.value;

  const basic = btoa(`${API_KEY}:${SECRET_KEY}`);
  const res = await fetch(`${BASE_URL}/api/v1/auth/login`, {
    method: "POST",
    headers: { Authorization: `Basic ${basic}`, "Content-Type": "application/json" },
  });

  const data = await res.json();
  if (!data.requestSuccessful) throw new Error("Monnify auth failed");

  const token = data.responseBody.accessToken;
  cachedToken = { value: token, exp: Date.now() + (data.responseBody.expiresIn * 1000 - 5000) };
  return token;
}

// Fetch and merge banks with logos
async function syncBanks(save: boolean) {
  const token = await getAccessToken();

  // 1️⃣ Fetch Monnify banks
  const res = await fetch(`${BASE_URL}/api/v1/banks`, {
    headers: { Authorization: `Bearer ${token}`, Accept: "application/json" },
  });
  const data = await res.json();
  if (!data.requestSuccessful) throw new Error("Failed to fetch Monnify banks");

  const monnifyBanks: Array<{ name: string; code: string }> = data.responseBody ?? [];

  // 2️⃣ Fetch bank logos
  const logosRes = await fetch("https://cdn.jsdelivr.net/gh/jsanwo64/Nigeria-Banks-Logo-API/Banks.json");
  const logos: Array<{ name?: string; logo?: string }> = await logosRes.json();

  const normalize = (s: string) => s.toLowerCase().replace(/\s+/g, "");

  // 3️⃣ Merge banks with logos
  const merged = monnifyBanks.map((b) => {
    const match = logos.find((l) => normalize(l.name ?? "") === normalize(b.name));
    return { name: b.name, code: b.code, logo_url: match?.logo ?? "" };
  });

  // 4️⃣ Optionally save to Supabase
  if (save) {
    const { data, error } = await supabase.from("banks").upsert(merged, { onConflict: "code" }).select();
    if (error) throw new Error(error.message);
    return { savedCount: data?.length ?? 0 };
  }

  return merged;
}

// Serve HTTP requests
serve(async (req) => {
  try {
    const url = new URL(req.url);
    const save = url.searchParams.get("save") === "true";
    const result = await syncBanks(save);
    return new Response(JSON.stringify({ ok: true, result }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});
