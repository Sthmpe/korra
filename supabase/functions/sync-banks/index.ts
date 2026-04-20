import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { compareTwoStrings } from "https://esm.sh/string-similarity@4.0.4";

// Environment variables
const BASE_URL = Deno.env.get("MONNIFY_BASE_URL")!;
const API_KEY = Deno.env.get("MONNIFY_API_KEY")!;
const SECRET_KEY = Deno.env.get("MONNIFY_SECRET_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? 'https://yfqgavuvwpnvcggwngjl.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmcWdhdnV2d3BudmNnZ3duZ2psIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NjEyODMzMywiZXhwIjoyMDkxNzA0MzMzfQ.7Rp_7wIza-YrDfXPFA9r0r_VzoAxA9MFjAz-E4HeVtk';

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

// 🚀 UPGRADE 1: Fintech Dictionary (Catching Paycom, Rolez, etc.)
const normalizeBankName = (name: string) => {
  let s = (name || "").toLowerCase();
  
  // Specific Fintech & Bank Overrides
  if (s.includes("opay") || s.includes("paycom")) return "opay";
  if (s.includes("moniepoint") || s.includes("rolez")) return "moniepoint";
  if (s.includes("kuda")) return "kuda";
  if (s.includes("palm") && s.includes("pay")) return "palmpay";
  if (s.includes("guaranty trust") || s.includes("gtb") || s === "gt bank") return "gtb";
  if (s.includes("united bank for africa") || s === "uba") return "uba";
  if (s.includes("first city monument") || s === "fcmb") return "fcmb";
  
  // Strip corporate noise
  s = s.replace(/\b(bank|plc|limited|ltd|microfinance|mfb|company|nigeria|international|digital|services)\b/g, "");
  return s.replace(/[^a-z0-9]/g, "");
};

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
  const logos: Array<{ name?: string; code?: string; logo?: string }> = await logosRes.json();

  // 🚀 UPGRADE 2: Database Memory (Fetch existing logos so we don't overwrite them)
  const existingLogos = new Map<string, string>();
  if (save) {
    const { data: existingBanks } = await supabase.from("banks").select("code, logo_url");
    if (existingBanks) {
      existingBanks.forEach((b) => {
        if (b.logo_url && b.logo_url !== "") {
          existingLogos.set(b.code, b.logo_url);
        }
      });
    }
  }

  // 3️⃣ Merge banks: Monnify is the master record
  const merged = monnifyBanks.map((mb) => {
    let matchedLogoUrl = "";
    const cleanMbName = normalizeBankName(mb.name);

    // Phase 1: Try matching by Code first
    const logoByCode = logos.find((l) => String(l.code) === String(mb.code));
    
    if (logoByCode) {
      const cleanLogoName = normalizeBankName(logoByCode.name || "");
      const codeScore = compareTwoStrings(cleanMbName, cleanLogoName);
      if (codeScore > 0.5) matchedLogoUrl = logoByCode.logo || "";
    }

    // Phase 2: If code failed, full Fuzzy Name Search
    if (!matchedLogoUrl) {
      let highestScore = 0;
      let bestFuzzyMatch = undefined;

      for (const logo of logos) {
        const cleanLogoName = normalizeBankName(logo.name || "");
        const score = compareTwoStrings(cleanMbName, cleanLogoName);
        if (score > highestScore) {
          highestScore = score;
          bestFuzzyMatch = logo;
        }
      }

      if (highestScore > 0.7) {
        matchedLogoUrl = bestFuzzyMatch?.logo || "";
      }
    }

    // Phase 3: THE SAFETY NET 🛟
    // If we STILL don't have a logo, check if Supabase already had one from a previous run!
    if (!matchedLogoUrl && save) {
      matchedLogoUrl = existingLogos.get(mb.code) || "";
    }

    // 🏆 RETURN MONNIFY EXACT DATA + LOGO
    return { 
      name: mb.name, 
      code: mb.code, 
      logo_url: matchedLogoUrl 
    };
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