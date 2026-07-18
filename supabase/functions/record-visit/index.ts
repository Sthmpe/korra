// record-visit
//
// Two distinct visit pipelines, deliberately kept separate:
//
// APP (default) — body: { vendorId, customerId? }
//   - Increments vendor_metrics rolling counters (feeds the "Most Visited"
//     badge that compute-visibility ranks). In-app/customer-network only.
//     DEDUPED per customer per calendar day via a marker doc at
//     vendor_metrics/{vendorId}/visitors/{customerId}_{yyyy-MM-dd}; without a
//     customerId nothing is counted.
//   - Counts an "open" on each currently active, non-archived campaign,
//     DEDUPED per customer per calendar day: a marker doc at
//     campaigns/{id}/opens/{customerId}_{yyyy-MM-dd} is create()d — if it
//     already exists the open was already counted today. Fresh markers
//     increment openCount and dailyOpens.{date}. No customerId → no campaign
//     open (we can't dedupe what we can't identify).
//
// WEB — body: { vendorId, source: 'web', sessionKey }
//   - Feeds the merchant's separate "Web Activity" stat ONLY. Never touches
//     vendor_metrics or campaigns (page views aren't campaign opens and web
//     traffic must not inflate Most Visited).
//   - Session-based dedupe: marker at web_activity/{vendorId}/sessions/
//     {sessionKey}_{yyyy-MM-dd} — same browser session counts once per day.
//     Reasonable-effort dedupe, not a uniqueness claim.
//   - Obvious bot traffic excluded by user-agent.
//
// Fire-and-forget from the client: a failed count must never block the store.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

const BOT_UA =
  /bot|crawl|spider|slurp|preview|headless|lighthouse|python|curl|wget|facebookexternalhit|whatsapp|telegram|discord|embedly|quora|pinterest|vkshare|snapchat|w3c_validator/i;

async function handleWebVisit(vendorId: string, sessionKey: string, userAgent: string) {
  if (BOT_UA.test(userAgent || '')) return; // bots don't count
  const key = (sessionKey || '').replace(/[^a-zA-Z0-9_-]/g, '').slice(0, 64);
  if (key.length < 8) return; // no usable session id → don't count at all

  const today = new Date().toISOString().slice(0, 10);
  const activityRef = db.collection('web_activity').doc(vendorId);

  // create() throws ALREADY_EXISTS when this session already counted today —
  // that's the dedupe.
  try {
    await activityRef.collection('sessions').doc(`${key}_${today}`).create({
      at: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (_alreadyCounted) {
    return;
  }

  await activityRef.set(
    {
      total: admin.firestore.FieldValue.increment(1),
      daily: { [today]: admin.firestore.FieldValue.increment(1) },
      lastVisitAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

async function bumpCampaignOpens(vendorId: string, customerId: string) {
  const campaignsSnap = await db.collection('campaigns').where('vendorId', '==', vendorId).get();
  const now = Date.now();
  const today = new Date().toISOString().slice(0, 10);

  await Promise.all(campaignsSnap.docs.map(async (doc) => {
    const data = doc.data();
    if (data?.archived === true) return;
    const dealEndAt = data?.dealEndAt?.toDate?.()?.getTime?.();
    const active = typeof dealEndAt === 'number' ? now < dealEndAt : true;
    if (!active) return;

    // One open per customer per calendar day: the marker's create() fails
    // with ALREADY_EXISTS on a repeat open, and we simply skip the count.
    try {
      await doc.ref.collection('opens').doc(`${customerId}_${today}`).create({
        at: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (_alreadyCounted) {
      return;
    }

    await doc.ref.update({
      openCount: admin.firestore.FieldValue.increment(1),
      [`dailyOpens.${today}`]: admin.firestore.FieldValue.increment(1),
    });
  }));
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const body = await req.json().catch(() => ({}));
    const vendorId = body?.vendorId;
    if (!vendorId || typeof vendorId !== 'string') {
      return json({ status: 'ERROR', error: 'vendorId required' }, 400);
    }

    // ---- WEB pipeline: Web Activity only, nothing else ----
    if (body?.source === 'web') {
      await handleWebVisit(
        vendorId,
        (body?.sessionKey ?? '').toString(),
        req.headers.get('user-agent') ?? '',
      );
      return json({ status: 'OK' });
    }

    // ---- APP pipeline: Most Visited metrics + deduped campaign opens ----
    const today = new Date().toISOString().slice(0, 10); // yyyy-MM-dd
    const customerId = (body?.customerId ?? '').toString().trim().replace(/[^a-zA-Z0-9_-]/g, '').slice(0, 64);

    // One counted visit per customer per store per calendar day — same
    // marker-doc dedupe as campaign opens, so relaunching the app (the client
    // set only dedupes per session) can't inflate "Most Visited". No
    // customerId → no count: we can't dedupe what we can't identify, and the
    // customer app always sends the signed-in uid.
    if (customerId) {
      let firstVisitToday = true;
      try {
        await db
          .collection('vendor_metrics')
          .doc(vendorId)
          .collection('visitors')
          .doc(`${customerId}_${today}`)
          .create({ at: admin.firestore.FieldValue.serverTimestamp() });
      } catch (_alreadyCounted) {
        firstVisitToday = false;
      }

      if (firstVisitToday) {
        await db.collection('vendor_metrics').doc(vendorId).set(
          {
            visitsTotal: admin.firestore.FieldValue.increment(1),
            daily: { [today]: admin.firestore.FieldValue.increment(1) },
            lastVisitAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }
    }

    try {
      if (customerId) await bumpCampaignOpens(vendorId, customerId);
    } catch (e) {
      // Never let campaign-open tracking block the visit count above.
      console.error('record-visit: campaign openCount bump failed:', e);
    }

    return json({ status: 'OK' });
  } catch (e) {
    // Never surface an error that could block the storefront; log server-side.
    console.error('record-visit failed:', e);
    return json({ status: 'ERROR' }, 200);
  }
});
