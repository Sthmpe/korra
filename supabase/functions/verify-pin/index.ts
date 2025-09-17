// supabase/functions/verify-pin/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import * as bcrypt from "https://deno.land/x/bcrypt@v0.4.1/mod.ts";

serve(async (req: Request) => {
  try {
    const { pin, storedHash } = await req.json();

    if (!pin || !storedHash) {
      return new Response(JSON.stringify({ error: "pin and storedHash required" }), { status: 400 });
    }

    const valid = await bcrypt.compare(pin, storedHash);

    return new Response(JSON.stringify({ valid }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), { status: 500 });
  }
});
