// supabase/functions/hash-pin/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import * as bcrypt from "https://deno.land/x/bcrypt@v0.4.1/mod.ts";

serve(async (req: Request) => {
  try {
    const { pin } = await req.json();

    if (!pin) {
      return new Response(JSON.stringify({ error: "Pin required" }), { status: 400 });
    }

    const salt = await bcrypt.genSalt(10);
    const hash = await bcrypt.hash(pin, salt);

    return new Response(JSON.stringify({ hash }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), { status: 500 });
  }
});
