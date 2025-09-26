// supabase/functions/verify-pin/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

async function verifyPin(pin: string, stored: string): Promise<boolean> {
  const [saltB64, storedHashHex] = stored.split(":");
  if (!saltB64 || !storedHashHex) return false;

  const salt = new Uint8Array(
    atob(saltB64).split("").map(c => c.charCodeAt(0))
  );
  const encoder = new TextEncoder();

  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(pin),
    { name: "PBKDF2" },
    false,
    ["deriveBits"]
  );

  const derived = await crypto.subtle.deriveBits(
    { name: "PBKDF2", hash: "SHA-256", salt, iterations: 100_000 },
    key,
    256
  );

  const hashArray = Array.from(new Uint8Array(derived));
  const hashHex = hashArray.map(b => b.toString(16).padStart(2, "0")).join("");

  return hashHex === storedHashHex;
}

serve(async (req: Request) => {
  try {
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Only POST allowed" }), { status: 405 });
    }

    const { pin, storedHash } = await req.json();
    if (!pin || !storedHash) {
      return new Response(JSON.stringify({ error: "pin and storedHash required" }), { status: 400 });
    }

    const valid = await verifyPin(pin, storedHash);
    return new Response(JSON.stringify({ valid }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
