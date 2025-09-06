import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Environment variables are required for the function to work.
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Create a Supabase client with the service role key to bypass RLS for this trusted server-side operation.
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

serve(async (_req) => {
  try {
    // 1. Fetch all records from the 'banks' table.
    // We select only the columns the app needs and order them alphabetically by name.
    const { data: banks, error } = await supabase
      .from("banks")
      .select("name, code, logo_url")
      .order("name", { ascending: true });

    // 2. Handle any potential database errors.
    if (error) {
      throw new Error(error.message);
    }

    // 3. Return the list of banks in a successful response.
    return new Response(JSON.stringify({ ok: true, banks }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (e) {
    // 4. If any error occurs, return a structured error response.
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});