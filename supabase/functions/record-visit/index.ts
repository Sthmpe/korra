// record-visit
//
// Increments a store's rolling visit counters in Firestore. The customer app
// cannot write vendor_metrics directly (rules are locked), so it calls here and
// this function (admin SDK) does the increment. Feeds the "Most Visited" badge
// that compute-visibility ranks on a schedule.
//
// Also counts as an "open" on any of that store's currently active campaigns
// (mirrors the Dart Campaign.isActive rule: untimed campaigns are always
// active until deleted, timed ones only while dealEndAt is in the future) —
// visiting the merchant's store counts as a campaign visit.
//
// POST /record-visit   body: { vendorId: string }
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

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { vendorId } = await req.json().catch(() => ({ vendorId: '' }));
    if (!vendorId || typeof vendorId !== 'string') {
      return json({ status: 'ERROR', error: 'vendorId required' }, 400);
    }

    const today = new Date().toISOString().slice(0, 10); // yyyy-MM-dd
    await db.collection('vendor_metrics').doc(vendorId).set(
      {
        visitsTotal: admin.firestore.FieldValue.increment(1),
        daily: { [today]: admin.firestore.FieldValue.increment(1) },
        lastVisitAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    // Bump openCount on every currently active campaign for this store. Cap
    // of 3 campaigns per vendor (enforced at creation) keeps this cheap.
    try {
      const campaignsSnap = await db.collection('campaigns').where('vendorId', '==', vendorId).get();
      const now = Date.now();
      const batch = db.batch();
      let hasWrites = false;
      campaignsSnap.forEach((doc) => {
        const dealEndAt = doc.data()?.dealEndAt?.toDate?.()?.getTime?.();
        const active = typeof dealEndAt === 'number' ? now < dealEndAt : true;
        if (active) {
          batch.update(doc.ref, { openCount: admin.firestore.FieldValue.increment(1) });
          hasWrites = true;
        }
      });
      if (hasWrites) await batch.commit();
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
