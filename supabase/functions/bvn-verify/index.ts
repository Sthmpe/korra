//bvn-verify/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

// 1. DEFINE CORS HEADERS
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

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

// --- Helper: Convert to Monnify DOB format "03-Oct-1993"
function toMonnifyDate(date: string | Date): string {
  const d = date instanceof Date ? date : new Date(date);
  if (isNaN(d.getTime())) throw new Error("Invalid date");
  const day = String(d.getUTCDate()).padStart(2, "0");
  const monthNames = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
  const month = monthNames[d.getUTCMonth()];
  const year = d.getUTCFullYear();
  return `${day}-${month}-${year}`;
}

// --- BVN Verification ---
async function handleVerifyBVN(body: any) {
  const { bvn, name, dateOfBirth, mobileNo } = body ?? {};
  if (!bvn || !name || !dateOfBirth || !mobileNo) {
    throw new Error("Missing fields");
  }

  const token = await getAccessToken();

  let dob: string;
  try {
    dob = toMonnifyDate(dateOfBirth);
  } catch (e) {
    throw new Error((e as Error).message);
  }

  const res = await fetch(`${BASE_URL}/api/v1/vas/bvn-details-match`, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: JSON.stringify({ bvn, name, dateOfBirth: dob, mobileNo }),
  });

  const data = await res.json();
  if (!res.ok || !data.requestSuccessful) {
    throw new Error(data.responseMessage || "BVN verification failed");
  }

  const r = data.responseBody;
  
  // Return DATA ONLY (let 'serve' handle the Response wrapping)
  return {
    ok: true,
    message: "BVN verification completed",
    bvn: r.bvn,
    nameMatch: r.name?.matchStatus ?? "NO_MATCH",
    nameMatchPercent: r.name?.matchPercentage ?? 0,
    dobMatch: r.dateOfBirth ?? "NO_MATCH",
    mobileMatch: r.mobileNo ?? "NO_MATCH",
  };
}

// --- Entry Point ---
serve(async (req) => {
  // A. CORS Pre-flight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 🔓 NO BOUNCER HERE: Any POST request will process.

    if (req.method !== "POST") {
      throw new Error("Only POST allowed");
    }

    const body = await req.json();
    
    // B. Execute Logic
    const result = await handleVerifyBVN(body);

    // C. Success Response
    return new Response(JSON.stringify(result), { 
      headers: { ...corsHeaders, "Content-Type": "application/json" } 
    });

  } catch (error) {
    // D. Error Handling
    const msg = error instanceof Error ? error.message : String(error);
    
    return new Response(JSON.stringify({ ok: false, message: msg }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});