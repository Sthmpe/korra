import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { compareTwoStrings } from "https://esm.sh/string-similarity@4.0.4";

// 1. DEFINE CORS HEADERS
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-korra-timestamp, x-korra-signature',
};

// 🌍 ENVIRONMENT TOGGLE (Set IS_LIVE=true in Prod, false in Dev)
const IS_LIVE = Deno.env.get("IS_LIVE") === "true";

console.log(`NIN Verification Function starting up in Is_live values::${Deno.env.get("IS_LIVE")} result:${IS_LIVE ? "LIVE" : "SANDBOX"} mode...`);

const BASE_URL = Deno.env.get("MONNIFY_BASE_URL") || (IS_LIVE ? "https://api.monnify.com" : "https://sandbox.monnify.com");
const API_KEY = Deno.env.get("MONNIFY_API_KEY") || "";
const SECRET_KEY = Deno.env.get("MONNIFY_SECRET_KEY") || "";

let cachedToken: { value: string; exp: number } | null = null;

// ==================================================================
// 🧠 ERROR TRANSLATOR
// ==================================================================
function translateKycError(rawError: string, type: string): string {
    const errorStr = (rawError || "").toLowerCase();
    
    if (errorStr.includes("wrong name") || errorStr.includes("does not match")) return rawError; // Pass custom errors cleanly
    if (errorStr.includes("incomplete information")) return rawError; 
    
    if (errorStr.includes("not found") || errorStr.includes("invalid") || errorStr.includes("99")) {
        return `The ${type} number you entered does not exist. Please check for typos.`;
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
// 🚀 HELPER: FUZZY MATCHER & ACCESS TOKEN
// ==================================================================
function isStrongMatch(val1: string, val2: string): boolean {
  if (!val1 || !val2) return false;
  // Requires an 80% similarity to pass (allows for minor typos but blocks completely wrong names)
  return compareTwoStrings(val1.toLowerCase().trim(), val2.toLowerCase().trim()) > 0.8;
}

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

// ==================================================================
// 🛡️ CORE NIN VERIFICATION LOGIC
// ==================================================================
async function verifyNIN(nin: string, appFirst: string, appLast: string, appOther: string, appDob: string, appPhone: string) {
  let data;
  
  if (!IS_LIVE) {
    // 🧪 SANDBOX MODE: Mock Monnify API
    if (nin === "12345678901" || nin === "10987654321" || nin === "11111111111") {
      data = {
        requestSuccessful: true,
        responseMessage: "success",
        responseCode: "0",
        responseBody: {
          nin: nin,
          lastName: appLast, 
          firstName: appFirst,
          middleName: appOther || "CHUKS",
          dateOfBirth: appDob, // Echo exact DOB
          gender: "MALE",
          mobileNumber: appPhone || "2348107248890"
        }
      };
    } else {
      data = { requestSuccessful: false, responseMessage: "NIN not found.", responseCode: "99" };
    }
  } else {
    // 🌍 LIVE MODE
    const token = await getAccessToken();
    const res = await fetch(`${BASE_URL}/api/v1/vas/nin-details`, {
      method: "POST",
      body: JSON.stringify({ nin }),
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    });
    data = await res.json();
  }

  if (!data.requestSuccessful) {
    return { ok: false, message: data.responseMessage || "NIN verification failed" };
  }

  const r = data.responseBody;
  
  // ============================================================
  // ⚖️ THE KORRA KYC BUSINESS RULES
  // ============================================================
  const monnifyFirst = r.firstName || "";
  const monnifyLast = r.lastName || "";
  const monnifyMiddle = r.middleName || "";
  
  // Rule 1 & 2: Name Matching (Fuzzy)
  if (!isStrongMatch(appFirst, monnifyFirst) || !isStrongMatch(appLast, monnifyLast)) {
      return { ok: false, message: "Wrong name. The First and Last name do not match this NIN." };
  }

  if (appOther && appOther.trim().length > 0) {
      if (!isStrongMatch(appOther, monnifyMiddle)) {
          return { ok: false, message: "Wrong name. The middle name provided does not match this NIN." };
      }
  }

  // ============================================================
  // 📅 THE DATE FIX: Handle Flutter ISO String (1996-10-08T00:00...)
  // ============================================================
  
  // 1. Take only the "YYYY-MM-DD" part from Flutter's ISO string
  const cleanAppDobStr = appDob.split('T')[0]; 
  
  // 2. Remove dashes for a pure number comparison
  const finalAppDob = cleanAppDobStr.replace(/[^0-9]/g, ""); // "19961008"
  const finalMonnifyDob = (r.dateOfBirth || "").replace(/[^0-9]/g, ""); // "19961008"

  const isDobCorrect = finalAppDob === finalMonnifyDob;

  // Phone fallback
  const cleanAppPhone = appPhone.replace(/[^0-9]/g, "").slice(-10);
  const cleanMonnifyPhone = (r.mobileNumber || "").replace(/[^0-9]/g, "").slice(-10);
  const isPhoneCorrect = cleanAppPhone === cleanMonnifyPhone;

  if (!isDobCorrect && !isPhoneCorrect) {
      return { ok: false, message: "Incomplete information: Date of birth error or incorrect phone number." };
  }

  // 🏆 SUCCESS!
  return {
    ok: true,
    nin: r.nin,
    firstName: r.firstName,
    middleName: r.middleName,
    lastName: r.lastName,
    dateOfBirth: r.dateOfBirth,
    gender: r.gender,
    mobileNumber: r.mobileNumber,
  };
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 🔐 HMAC ANTI-FORGERY
    const clientTimestamp = req.headers.get('x-korra-timestamp');
    const clientSignature = req.headers.get('x-korra-signature');
    const KORRA_SECRET = "7f8a9b2d4c6e1f3a5b7c9d0e2f4a6b8c1d3e5f7a9b0c2d4e6f8a1b3c5d7e9f0a";

    if (!clientTimestamp || !clientSignature) throw new Error("Unauthorized: Missing security signatures.");

    const now = Date.now();
    const requestTime = parseInt(clientTimestamp, 10);
    if (Math.abs(now - requestTime) > 120000) throw new Error("Unauthorized: Request expired.");

    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey("raw", encoder.encode(KORRA_SECRET), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
    const signatureBuffer = await crypto.subtle.sign("HMAC", key, encoder.encode(clientTimestamp));
    const hashArray = Array.from(new Uint8Array(signatureBuffer));
    const expectedServerSignature = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

    if (clientSignature !== expectedServerSignature) throw new Error("Unauthorized: Cryptographic signature mismatch.");

    if (req.method !== "POST") {
      return new Response("Only POST allowed", { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    // 📦 NEW FLUTTER PAYLOAD EXPECTATIONS
    const { nin, firstName, lastName, otherName, dateOfBirth, mobileNumber } = await req.json();
    
    if (!nin || !firstName || !lastName || !dateOfBirth) {
      return new Response(
        JSON.stringify({ ok: false, message: "NIN, First Name, Last Name, and Date of Birth are required." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Pass the Flutter data into our logic
    const result = await verifyNIN(nin, firstName, lastName, otherName || "", dateOfBirth, mobileNumber || "");
    
    if (result.ok) {
        return new Response(JSON.stringify(result), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
    } else {
        return new Response(JSON.stringify({
            ok: false,
            message: translateKycError(result.message || "", "NIN")
        }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

  } catch (e) {
    return new Response(
      JSON.stringify({ ok: false, message: translateKycError((e as Error).message, "NIN") }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});