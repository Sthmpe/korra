import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

// 1. DEFINE CORS HEADERS
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-korra-timestamp, x-korra-signature',
};

// 🌍 ENVIRONMENT TOGGLE (Set IS_LIVE=true in Prod, false in Dev)
const IS_LIVE = Deno.env.get("IS_LIVE") === "true";

const BASE_URL = Deno.env.get("MONNIFY_BASE_URL") || (IS_LIVE ? "https://api.monnify.com" : "https://sandbox.monnify.com");
const API_KEY = Deno.env.get("MONNIFY_API_KEY") || "";
const SECRET_KEY = Deno.env.get("MONNIFY_SECRET_KEY") || "";

let cachedToken: { value: string; exp: number } | null = null;

// ==================================================================
// 🧠 ERROR TRANSLATOR (Makes API errors Human-Readable for the UI)
// ==================================================================
function translateKycError(rawError: string, type: string): string {
    const errorStr = (rawError || "").toLowerCase();
    
    if (errorStr.includes("phone number does not match")) return rawError; // Pass custom error cleanly
    if (errorStr.includes("not found") || errorStr.includes("invalid") || errorStr.includes("99")) {
        return `The ${type} number you entered is invalid. Please check for typos.`;
    }
    if (errorStr.includes("match percentage") || errorStr.includes("too low")) {
        return `The name on this ${type} does not match your profile name closely enough.`;
    }
    if (errorStr.includes("timeout") || errorStr.includes("network")) {
        return `The National ${type} database is currently down. Please try again in 10 minutes.`;
    }
    if (errorStr.includes("insufficient funds") || errorStr.includes("balance")) {
        return "Verification temporarily unavailable. Please try again later.";
    }
    
    return `Could not verify ${type}. Please check your details and try again.`;
}

// ==================================================================
// 🚀 REAL MONNIFY HELPERS
// ==================================================================
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

function toMonnifyDate(date: string | Date): string {
  const d = date instanceof Date ? date : new Date(date);
  if (isNaN(d.getTime())) throw new Error("Invalid date");
  const day = String(d.getUTCDate()).padStart(2, "0");
  const monthNames = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
  const month = monthNames[d.getUTCMonth()];
  const year = d.getUTCFullYear();
  return `${day}-${month}-${year}`;
}

// ==================================================================
// 🛡️ CORE BVN VERIFICATION LOGIC
// ==================================================================
async function verifyBVN(bvn: string, name: string, dateOfBirth: string, mobileNo: string) {
  let data;

  if (!IS_LIVE) {
    // 🧪 SANDBOX MODE: Use Mock Logic (Since Monnify BVN is Live-Only)
    if (bvn === "22222222226" || bvn === "99999999999" || bvn === "11111111111") {
      data = {
        requestSuccessful: true,
        responseMessage: "success",
        responseCode: "0",
        responseBody: {
          bvn: "22228945899",
          name: { matchStatus: "FULL_MATCH", matchPercentage: 100 },
          dateOfBirth: "NO_MATCH",
          mobileNo: "FULL_MATCH"
        }
      };
    } else {
      data = { requestSuccessful: false, responseMessage: "Unable to process request. Invalid BVN provided", responseCode: "99" };
    }
  } else {
    // 🌍 LIVE MODE: Call real Monnify API
    const token = await getAccessToken();
    let dob: string;
    try {
      dob = toMonnifyDate(dateOfBirth);
    } catch (e) {
      throw new Error("Invalid Date format provided.");
    }

    const res = await fetch(`${BASE_URL}/api/v1/vas/bvn-details-match`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify({ bvn, name, dateOfBirth: dob, mobileNo }),
    });
    
    data = await res.json();

    // 🚨 HEAVY LOGGING ADDED HERE 🚨
    console.log("==================================================");
    console.log("🎯 MONNIFY LIVE BVN RESPONSE PAYLOAD");
    console.log("==================================================");
    console.log(JSON.stringify(data, null, 2));
    console.log("==================================================");
  }

  // ⚙️ STANDARD PROCESSING
  if (!data.requestSuccessful) {
    return { ok: false, message: data.responseMessage || "BVN verification failed" };
  }

  const r = data.responseBody;
  const matchPercent = r.name?.matchPercentage ?? 0;
  const phoneMatch = r.mobileNo ?? "NO_MATCH";

  // 🛡️ STRICT BUSINESS RULES
  if (matchPercent < 50) {
    // Rule 1: Instant Fail if name is under 50%
    return { ok: false, message: "Name match percentage is too low." };
  } 
  
  if (matchPercent >= 50 && matchPercent < 100) {
    // Rule 2: If Name is between 50-99%, Phone MUST be FULL_MATCH
    if (phoneMatch !== "FULL_MATCH") {
      return { ok: false, message: "Your phone number does not match the BVN record." };
    }
  }
  
  // Rule 3: If Name is 100%, we don't care about phone or DOB, let them pass!

  // 🏆 RETURN EXACT REQUESTED STRUCTURE
  return {
    ok: true,
    bvn: r.bvn,
    nameMatch: r.name?.matchStatus ?? "NO_MATCH",
    nameMatchPercent: matchPercent,
    dobMatch: r.dateOfBirth ?? "NO_MATCH",
    mobileMatch: r.mobileNo ?? "NO_MATCH",
  };
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 🔐 LOCK 1: HMAC ANTI-FORGERY & ANTI-REPLAY
    const clientTimestamp = req.headers.get('x-korra-timestamp');
    const clientSignature = req.headers.get('x-korra-signature');
    const KORRA_SECRET = "7f8a9b2d4c6e1f3a5b7c9d0e2f4a6b8c1d3e5f7a9b0c2d4e6f8a1b3c5d7e9f0a";

    if (!clientTimestamp || !clientSignature) throw new Error("Unauthorized: Missing security signatures.");

    const now = Date.now();
    const requestTime = parseInt(clientTimestamp, 10);
    if (Math.abs(now - requestTime) > 120000) throw new Error("Unauthorized: Request expired (Replay attack blocked).");

    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey("raw", encoder.encode(KORRA_SECRET), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
    const signatureBuffer = await crypto.subtle.sign("HMAC", key, encoder.encode(clientTimestamp));
    const hashArray = Array.from(new Uint8Array(signatureBuffer));
    const expectedServerSignature = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

    if (clientSignature !== expectedServerSignature) throw new Error("Unauthorized: Cryptographic signature mismatch.");

    if (req.method !== "POST") {
      return new Response("Only POST allowed", { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    const { bvn, name, dateOfBirth, mobileNo } = await req.json();
    
    if (!bvn || !name || !dateOfBirth || !mobileNo) {
      return new Response(
        JSON.stringify({ ok: false, message: "bvn, name, dateOfBirth, and mobileNo are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const result = await verifyBVN(bvn, name, dateOfBirth, mobileNo);
    
    if (result.ok) {
        return new Response(JSON.stringify(result), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
    } else {
        return new Response(JSON.stringify({
            ok: false,
            message: translateKycError(result.message || "", "BVN")
        }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

  } catch (e) {
    return new Response(
      JSON.stringify({ ok: false, message: translateKycError((e as Error).message, "BVN") }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});