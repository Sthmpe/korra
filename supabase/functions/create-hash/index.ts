// supabase/functions/create-hash/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

async function hashPin(pin: string): Promise<string> {
  const encoder = new TextEncoder();
  const salt = crypto.getRandomValues(new Uint8Array(16)); // 16-byte salt

  // Import raw PIN as key
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(pin),
    { name: "PBKDF2" },
    false,
    ["deriveBits"]
  );

  // Derive 256-bit hash with PBKDF2
  const derived = await crypto.subtle.deriveBits(
    { name: "PBKDF2", hash: "SHA-256", salt, iterations: 100_000 },
    key,
    256
  );

  // Convert hash -> hex
  const hashArray = Array.from(new Uint8Array(derived));
  const hashHex = hashArray.map(b => b.toString(16).padStart(2, "0")).join("");

  // Return salt:hash
  return `${btoa(String.fromCharCode(...salt))}:${hashHex}`;
}

serve(async (req: Request) => {
  try {
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Only POST allowed" }), { status: 405 });
    }

    const { pin } = await req.json();
    if (!pin) {
      return new Response(JSON.stringify({ error: "Pin required" }), { status: 400 });
    }

    const hash = await hashPin(pin);
    return new Response(JSON.stringify({ hash }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
