// supabase/functions/nin-verify/index.ts
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
    headers: {
      Authorization: `Basic ${basic}`,
      "Content-Type": "application/json",
    },
  });

  const data = await res.json();
  if (!data.requestSuccessful) throw new Error("Auth failed");

  const token = data.responseBody.accessToken;
  cachedToken = {
    value: token,
    exp: Date.now() + (data.responseBody.expiresIn * 1000 - 5000),
  };
  return token;
}

async function verifyNIN(nin: string) {
  const token = await getAccessToken();

  const res = await fetch(`${BASE_URL}/api/v1/vas/nin-details`, {
    method: "POST",
    body: JSON.stringify({ nin }),
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
  });

  const data = await res.json();

  if (!data.requestSuccessful) {
    return {
      ok: false,
      message: data.responseMessage || "NIN verification failed",
    };
  }

  const r = data.responseBody;
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
  // A. CORS Pre-flight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    if (req.method !== "POST") {
      return new Response("Only POST allowed", { 
        status: 405,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      });
    }

    const { nin } = await req.json();
    if (!nin) {
      return new Response(
        JSON.stringify({ ok: false, message: "nin is required" }),
        { 
          status: 400, 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        },
      );
    }

    const result = await verifyNIN(nin);
    
    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (e) {
    return new Response(
      JSON.stringify({ ok: false, message: (e as Error).message }),
      { 
        status: 500, 
        headers: { ...corsHeaders, "Content-Type": "application/json" } 
      },
    );
  }
});