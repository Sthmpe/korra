// ai-review-summary
//
// Returns a short AI generated summary of a store's customer reviews, shown in a
// collapsible "AI review summary" box at the top of the customer feedback list.
//
// For now this is a stub: the real summariser is not wired yet, so every call
// responds with { available: false, message: "AI currently unavailable" } and a
// 200 status so the app can render the box gracefully. The client treats any
// non-2xx or thrown error as "service unavailable" too.
//
// POST /ai-review-summary   body: { vendorId: string }
//
// When the real model is added later, keep this same response shape and just
// fill in `summary` + set `available: true`.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

const UNAVAILABLE = {
  available: false,
  summary: null,
  message: 'AI currently unavailable',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // We accept the request but the summariser is not live yet.
    if (req.method !== 'POST') {
      return json(UNAVAILABLE, 200);
    }
    // Body is read to stay forward compatible, but not used yet.
    await req.json().catch(() => ({}));

    // TODO: when the model is wired, fetch the vendor's reviews and return
    // { available: true, summary: "...", message: null }.
    return json(UNAVAILABLE, 200);
  } catch (_e) {
    // Any failure still reads as "service unavailable" on the client.
    return json(UNAVAILABLE, 200);
  }
});
