// view-reengagement
//
// Cron worker for the "Last Viewed" re-engagement push. The customer app logs
// qualifying product views (5+ seconds dwell) to
// customers/{uid}/recent_views/{productId} and, on the FIRST qualifying view,
// drops a marker in view_reengagement_queue/{uid} with notifyAt = view + 24h.
//
// This function runs on a schedule (hourly is plenty) and, for every marker
// that has come due:
//   - reads that customer's recent_views (purchased products were already
//     deleted by the app, so whatever remains is fair game),
//   - keeps views inside the marker's 24h window with dwellMs >= 5000,
//   - picks the LONGEST-dwell product (random among ties),
//   - sends exactly ONE push (+ in-app notification), then deletes the marker.
// A marker with no surviving candidates is simply deleted — no push.
//
// Deploy, then schedule it (same as the other automation crons), e.g.:
//   supabase functions deploy view-reengagement
//   schedule: every 60 minutes

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();
const messaging = admin.messaging();

const MIN_DWELL_MS = 5000;
const WINDOW_MS = 24 * 60 * 60 * 1000;
const BATCH_LIMIT = 200; // markers per run; the hourly cadence drains any backlog

function naira(n: number): string {
  return `₦${Number(n || 0).toLocaleString('en-NG', { maximumFractionDigits: 0 })}`;
}

async function processMarker(markerDoc: FirebaseFirestore.QueryDocumentSnapshot): Promise<'sent' | 'skipped'> {
  const uid = markerDoc.id;
  const marker = markerDoc.data();

  try {
    const windowStart: Date =
      marker.windowStart?.toDate?.() ?? new Date(Date.now() - WINDOW_MS);

    const viewsSnap = await db
      .collection('customers').doc(uid)
      .collection('recent_views')
      .get();

    const candidates = viewsSnap.docs
      .map((d) => d.data())
      .filter((v) => {
        const dwell = Number(v.dwellMs ?? 0);
        if (dwell < MIN_DWELL_MS) return false;
        const viewedAt = v.viewedAt?.toDate?.();
        return viewedAt instanceof Date && viewedAt >= windowStart;
      });

    if (candidates.length === 0) return 'skipped';

    // Longest dwell wins; ties broken randomly per the spec.
    const maxDwell = Math.max(...candidates.map((c) => Number(c.dwellMs ?? 0)));
    const tied = candidates.filter((c) => Number(c.dwellMs ?? 0) === maxDwell);
    const pick = tied[Math.floor(Math.random() * tied.length)];

    const customerDoc = await db.collection('customers').doc(uid).get();
    if (!customerDoc.exists) return 'skipped';

    const productName = (pick.name ?? 'that product').toString();
    const storeName = (pick.storeName ?? 'the store').toString();
    const price = Number(pick.price ?? 0);
    const title = "Still thinking about it? 👀";
    const body = price > 0
      ? `${productName} (${naira(price)}) at ${storeName} is still available. Take another look before it sells out.`
      : `${productName} at ${storeName} is still available. Take another look before it sells out.`;

    await db.collection('customers').doc(uid).collection('notifications').add({
      title,
      body,
      type: 'last_viewed',
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      metadata: {
        productId: pick.productId ?? '',
        vendorId: pick.vendorId ?? '',
        slug: pick.slug ?? '',
        source: 'view_reengagement_cron',
      },
    });

    const fcmToken = customerDoc.data()?.fcmToken;
    if (fcmToken) {
      await messaging.send({
        token: fcmToken,
        notification: { title, body },
        data: {
          type: 'last_viewed',
          productId: (pick.productId ?? '').toString(),
          vendorId: (pick.vendorId ?? '').toString(),
          slug: (pick.slug ?? '').toString(),
        },
      }).catch((e) => console.error(`view-reengagement: FCM failed for ${uid}:`, e));
    }

    return 'sent';
  } catch (e) {
    console.error(`view-reengagement: marker ${uid} failed:`, e);
    return 'skipped';
  }
}

serve(async (_req) => {
  try {
    const dueSnap = await db
      .collection('view_reengagement_queue')
      .where('notifyAt', '<=', admin.firestore.Timestamp.now())
      .limit(BATCH_LIMIT)
      .get();

    let sent = 0;
    for (const markerDoc of dueSnap.docs) {
      const outcome = await processMarker(markerDoc);
      if (outcome === 'sent') sent += 1;
      // Exactly one push per marker: delete regardless of outcome so a
      // failed/empty window never retries into a duplicate later.
      await markerDoc.ref.delete().catch(() => {});
    }

    console.log(`view-reengagement: ${dueSnap.size} due, ${sent} pushed.`);
    return new Response(
      JSON.stringify({ status: 'OK', due: dueSnap.size, sent }),
      { headers: { 'Content-Type': 'application/json' } },
    );
  } catch (e) {
    console.error('view-reengagement failed:', e);
    return new Response(JSON.stringify({ status: 'ERROR' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
