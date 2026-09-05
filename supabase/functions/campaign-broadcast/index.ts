// campaign-broadcast
//
// Fans out a merchant's new campaign to their circle — every customer who
// follows the store (customers/{uid}/my_vendors/{vendorId}) gets an in-app
// notification. Customers who muted the store (customers/{uid}.mutedStores
// contains vendorId) are skipped entirely — no in-app, no push.
//
// PUSH CAP (confirmed by David): each customer gets at most 3 pushed campaign
// notifications per calendar day, combined across every store they follow,
// and one of those 3 slots per distinct store — a store that already used its
// slot today can never claim a second one, even if fewer than 3 stores total
// have been used. Tracked at customers/{uid}/campaignPushDaily/{yyyy-MM-dd}.
// Once a customer's slots for a day are gone, further campaigns from any
// store still write the in-app notification, just without a push. This is
// purely per-customer (their own follow list + their own daily slot count) —
// a customer who hasn't saved a store never sees it at all, and one
// customer's used-up slots have no effect on any other customer.
//
// Called by the merchant app right after the campaign doc is created. Same
// Double-Lock security as plan-manager; the Firebase token IS the identity, so
// a merchant can only broadcast for their own store (uid === vendorId).

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, firebase-token, x-korra-timestamp, x-korra-signature',
};

const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();
const messaging = admin.messaging();

const KORRA_SECRET = "7f8a9b2d4c6e1f3a5b7c9d0e2f4a6b8c1d3e5f7a9b0c2d4e6f8a1b3c5d7e9f0a";

function chunk<T>(arr: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

// Customer-side push cap: max 3 pushes/day, one per DISTINCT store — never
// two slots to the same store even if it broadcasts twice. Tracked per
// customer at customers/{uid}/campaignPushDaily/{yyyy-MM-dd}.vendorIds.
// The in-app notification is unaffected by this cap; it always gets written.
async function claimPushSlot(customerId: string, vendorId: string, today: string): Promise<boolean> {
  const ref = db
    .collection('customers')
    .doc(customerId)
    .collection('campaignPushDaily')
    .doc(today);

  return db.runTransaction(async (t) => {
    const snap = await t.get(ref);
    const vendorIds: string[] = snap.exists ? (snap.data()?.vendorIds ?? []) : [];
    if (vendorIds.includes(vendorId)) return false; // this store already used its slot today
    if (vendorIds.length >= 3) return false; // all 3 slots already claimed by other stores
    t.set(
      ref,
      { vendorIds: [...vendorIds, vendorId], updatedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true },
    );
    return true;
  });
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // --- LOCK 1: HMAC anti-forgery / anti-replay ---
    const clientTimestamp = req.headers.get('x-korra-timestamp');
    const clientSignature = req.headers.get('x-korra-signature');
    if (!clientTimestamp || !clientSignature) throw new Error("Unauthorized: Missing security signatures.");

    if (Math.abs(Date.now() - parseInt(clientTimestamp, 10)) > 120000) {
      throw new Error("Unauthorized: Request expired.");
    }
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      "raw", encoder.encode(KORRA_SECRET), { name: "HMAC", hash: "SHA-256" }, false, ["sign"],
    );
    const sigBuf = await crypto.subtle.sign("HMAC", key, encoder.encode(clientTimestamp));
    const expected = Array.from(new Uint8Array(sigBuf)).map((b) => b.toString(16).padStart(2, '0')).join('');
    if (clientSignature !== expected) throw new Error("Unauthorized: Signature mismatch.");

    // --- LOCK 2: Firebase token → identity ---
    const authHeader = req.headers.get('firebase-token');
    if (!authHeader || !authHeader.startsWith('Bearer ')) throw new Error("Unauthorized: Missing token.");
    let uid: string;
    try {
      uid = (await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1])).uid;
    } catch (_e) {
      throw new Error("Unauthorized: Invalid token.");
    }

    const { vendorId, campaignId, title, body, imageUrl } = await req.json();
    if (!vendorId || typeof vendorId !== 'string') throw "Missing store.";
    // A merchant may only broadcast for their own store.
    if (uid !== vendorId) throw "You can only broadcast campaigns for your own store.";
    if (!title || !body) throw "Campaign title and message are required.";

    const storeDoc = await db.collection('vendors').doc(vendorId).get();
    const storeName = storeDoc.data()?.store?.storeName ?? 'A store you follow';

    // 1. Followers = customers with this store in my_vendors.
    const followersSnap = await db
      .collectionGroup('my_vendors')
      .where('vendorId', '==', vendorId)
      .get();

    const followerIds = followersSnap.docs
      .map((d) => d.ref.parent.parent?.id)
      .filter((id): id is string => !!id);

    if (followerIds.length === 0) {
      return new Response(
        JSON.stringify({ status: "SUCCESS", reached: 0, muted: 0, followers: 0 }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // 2. Load each follower's mutedStores + fcmToken (chunked getAll).
    let reached = 0;
    let muted = 0;
    let capped = 0; // in-app only: this customer's 3 daily push slots are taken
    const tokens: string[] = [];
    const today = new Date().toISOString().slice(0, 10); // yyyy-MM-dd

    for (const ids of chunk(followerIds, 200)) {
      const refs = ids.map((id) => db.collection('customers').doc(id));
      const docs = await db.getAll(...refs);

      const eligible = docs.filter((doc) => {
        if (!doc.exists) return false;
        const mutedStores: string[] = Array.isArray(doc.data()?.mutedStores) ? doc.data()!.mutedStores : [];
        return !mutedStores.includes(vendorId);
      });
      muted += docs.length - eligible.length;

      // Push-slot claims are per-customer transactions, so resolve them
      // before batching the in-app writes below.
      const canPush = await Promise.all(
        eligible.map((doc) => claimPushSlot(doc.id, vendorId, today)),
      );

      let writeBatch = db.batch();
      let ops = 0;

      for (let i = 0; i < eligible.length; i++) {
        const doc = eligible[i];
        const data = doc.data()!;

        // In-app notification. vendorId in metadata keeps it mute-filterable
        // client-side too, matching KorraNotification parsing. Always written,
        // regardless of the customer's push cap.
        const notifRef = doc.ref.collection('notifications').doc();
        writeBatch.set(notifRef, {
          title,
          body,
          type: 'campaign',
          isRead: false,
          vendorId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          metadata: {
            vendorId,
            campaignId: campaignId ?? null,
            storeName,
            image: imageUrl ?? null,
          },
        });
        ops++;
        reached++;

        if (canPush[i]) {
          if (typeof data.fcmToken === 'string' && data.fcmToken.length > 0) {
            tokens.push(data.fcmToken);
          }
        } else {
          capped++;
        }

        if (ops >= 400) {
          await writeBatch.commit();
          writeBatch = db.batch();
          ops = 0;
        }
      }
      if (ops > 0) await writeBatch.commit();
    }

    // 3. Device pushes (multicast, 500 tokens per call). The image rides in
    // `data.image` — the app's foreground handler downloads it for the
    // BigPictureStyle — and in `android.notification.imageUrl` so background
    // and terminated pushes also render the picture in the system tray.
    let pushed = 0;
    for (const group of chunk(tokens, 500)) {
      try {
        const resp = await messaging.sendEachForMulticast({
          tokens: group,
          notification: { title, body },
          android: imageUrl ? { notification: { imageUrl } } : undefined,
          data: {
            type: 'campaign',
            vendorId,
            campaignId: campaignId ?? '',
            image: imageUrl ?? '',
          },
        });
        pushed += resp.successCount;
      } catch (e) {
        console.error("campaign push chunk failed:", e);
      }
    }

    return new Response(
      JSON.stringify({
        status: "SUCCESS",
        followers: followerIds.length,
        reached,
        muted,
        capped,
        pushed,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error) {
    const message = typeof error === 'string' ? error : (error as Error)?.message ?? "Broadcast failed.";
    console.error("❌ campaign-broadcast error:", error);
    return new Response(
      JSON.stringify({ status: "ERROR", error: message }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
