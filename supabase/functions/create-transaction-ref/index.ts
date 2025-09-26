// supabase/functions/create-transaction-ref/index.ts
import { serve } from "https://deno.land/std/http/server.ts";
import { v4 as uuid } from "https://deno.land/std/uuid/mod.ts";

serve(async (req: Request) => {
  try {
    const { type, userId } = await req.json();

    if (!type || !userId) {
      return new Response(
        JSON.stringify({ error: "type and userId required" }),
        { status: 400 }
      );
    }

    // Generate prefix based on type
    const prefix = type.toUpperCase(); // e.g. PAYOUT / LAYAWAY
    const ref = `${prefix}-${uuid.generate()}`;

    return new Response(
      JSON.stringify({ reference: ref }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: e.message }),
      { status: 500 }
    );
  }
});
