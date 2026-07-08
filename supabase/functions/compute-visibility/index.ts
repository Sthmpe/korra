// compute-visibility
//
// Scheduled job (cron). Recomputes the marketplace badges shown on stores:
//   - Most Visited  → from real storefront visits (vendor_metrics, written by
//                     the app when a customer opens a store)
//   - Top Seller    → from vendor earnings (vendor_stats.totalEarnings)
//   - Highlighted   → NOT touched here; set when a merchant buys a highlight.
//
// Writes vendor_visibility/{vendorId} with merge:true so isHighlighted and any
// other fields survive. Non-qualifying stores are reset to 0 so a badge that
// was earned last week disappears when the store falls out of the ranking.
//
// Auth: Authorization: Bearer <CRON_SECRET> (same as the other cron workers).

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type',
};

const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

// How many stores can hold each badge, and the floor to qualify.
const TOP_N = 20;
const MIN_VISITS = 10;   // rolling 30-day visits
const MIN_EARNINGS = 1;  // any real earnings

// Sum the last 30 days of the per-day visit map (falls back to visitsTotal).
function rollingVisits(data: any): number {
  const daily = data?.daily || {};
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - 30);

  let sum = 0;
  let counted = false;
  for (const key of Object.keys(daily)) {
    const d = new Date(key);
    if (!isNaN(d.getTime()) && d >= cutoff) {
      sum += Number(daily[key] || 0);
      counted = true;
    }
  }
  if (counted) return sum;
  return Number(data?.visitsTotal || 0);
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const cronSecret = Deno.env.get('CRON_SECRET');
    const authHeader = req.headers.get('Authorization');
    if (authHeader !== `Bearer ${cronSecret}`) {
      return new Response("Unauthorized", { status: 401, headers: corsHeaders });
    }

    // 1. Load signals (two collection scans).
    const [metricsSnap, statsSnap] = await Promise.all([
      db.collection('vendor_metrics').get(),
      db.collection('vendor_stats').get(),
    ]);

    const visits = new Map<string, number>(); // vendorId -> rolling visits
    for (const doc of metricsSnap.docs) {
      visits.set(doc.id, rollingVisits(doc.data()));
    }

    const earnings = new Map<string, number>(); // vendorId -> total earnings
    for (const doc of statsSnap.docs) {
      earnings.set(doc.id, Number(doc.data()?.totalEarnings || 0));
    }

    // 2. Rank. Qualifiers = top N above the floor.
    const topVisited = [...visits.entries()]
      .filter(([, v]) => v >= MIN_VISITS)
      .sort((a, b) => b[1] - a[1])
      .slice(0, TOP_N);

    const topSellers = [...earnings.entries()]
      .filter(([, v]) => v >= MIN_EARNINGS)
      .sort((a, b) => b[1] - a[1])
      .slice(0, TOP_N);

    const mostVisitedCount = new Map(topVisited); // reach number to display
    const topSellerRank = new Set(topSellers.map(([id]) => id));

    // 3. Every store we have any signal for gets rewritten (so lost badges
    //    clear). The displayed "circles" number is the reach proxy:
    //      mostVisitedCircles = rolling visits, topSellerCircles = follower reach.
    const allIds = new Set<string>([...visits.keys(), ...earnings.keys()]);

    let updated = 0;
    let batch = db.batch();
    let ops = 0;

    for (const id of allIds) {
      const isMostVisited = mostVisitedCount.has(id);
      const isTopSeller = topSellerRank.has(id);

      batch.set(
        db.collection('vendor_visibility').doc(id),
        {
          mostVisitedCircles: isMostVisited ? mostVisitedCount.get(id) : 0,
          topSellerCircles: isTopSeller ? (visits.get(id) || 1) : 0,
          visibilityUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      updated++;
      ops++;

      // Firestore batches cap at 500 writes.
      if (ops >= 400) {
        await batch.commit();
        batch = db.batch();
        ops = 0;
      }
    }
    if (ops > 0) await batch.commit();

    return new Response(
      JSON.stringify({
        status: "SUCCESS",
        storesProcessed: updated,
        mostVisited: topVisited.length,
        topSellers: topSellers.length,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("❌ compute-visibility error:", error);
    return new Response(
      JSON.stringify({ status: "ERROR", error: (error as Error)?.message ?? String(error) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
