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

// Helper to convert date to Monnify format "03-Oct-1993"
function toMonnifyDate(date: string | Date): string {
  const d = date instanceof Date ? date : new Date(date);
  if (isNaN(d.getTime())) throw new Error("Invalid date");
  const day = String(d.getUTCDate()).padStart(2, "0");
  const monthNames = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
  const month = monthNames[d.getUTCMonth()];
  const year = d.getUTCFullYear();
  return `${day}-${month}-${year}`;
}

async function verifyBVN(body: any) {
  const { bvn, name, dateOfBirth, mobileNo } = body ?? {};
  if (!bvn || !name || !dateOfBirth || !mobileNo) return new Response("Missing fields", { status: 400 });

  const token = await getAccessToken();

  // Convert dateOfBirth to Monnify format
  let dob: string;
  try {
    dob = toMonnifyDate(dateOfBirth);
  } catch (e) {
    return new Response((e as Error).message, { status: 400 });
  }

  const res = await fetch(`${BASE_URL}/api/v1/vas/bvn-details-match`, {
    method: "POST",
    body: JSON.stringify({ bvn, name, dateOfBirth: dob, mobileNo }),
    headers: { "Authorization": `Bearer ${token}`, "Content-Type": "application/json" },
  });
  const data = await res.json();
  if (!data.requestSuccessful) return new Response(data.responseMessage || "BVN failed", { status: 400 });

  const matchPercent = data.responseBody?.name?.matchPercentage ?? 0;
  if (matchPercent < 50) return new Response(`Name match too low: ${matchPercent}%`, { status: 422 });

  return new Response(JSON.stringify({ ok: true, result: data.responseBody }), { headers: { "Content-Type": "application/json" } });
}

serve(async (req) => {
  if (req.method !== "POST") return new Response("Only POST", { status: 405 });
  const body = await req.json();
  return await verifyBVN(body);
});
