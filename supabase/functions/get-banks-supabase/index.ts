import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Admin Client (For Database Access)
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? 'https://yfqgavuvwpnvcggwngjl.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmcWdhdnV2d3BudmNnZ3duZ2psIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NjEyODMzMywiZXhwIjoyMDkxNzA0MzMzfQ.7Rp_7wIza-YrDfXPFA9r0r_VzoAxA9MFjAz-E4HeVtk';

// Create a Supabase client with the service role key to bypass RLS for this trusted server-side operation.
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

serve(async (req) => {
  // A. Handle Browser Pre-flight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

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
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (e) {
    // D. Error Handling
    const msg = e instanceof Error ? e.message : String(e);
    return new Response(JSON.stringify({ error: msg }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 401, // Unauthorized
    });
  }
});