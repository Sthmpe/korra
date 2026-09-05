// store-api
//
// Public read-only endpoint for the storefront WEBSITE (korra.com.ng/store).
// The website never touches Firestore directly — it calls here, and this
// function (admin SDK, server-side) returns the store payload as JSON. That
// keeps Firestore security rules fully locked; the site can only read, and all
// changes still happen in the app.
//
// GET /store-api?slug={slug}                     → store + visibility + reviews + first page of products
// GET /store-api?slug={slug}&cursor={id}         → next page of products (pagination)
// GET /store-api?slug={slug}&productId={id}      → store + single product (product-level SSR page/OG)
// GET /store-api?action=slugs                    → all store slugs (for the sitemap)
// GET /store-api?action=product-urls             → all { slug, productId } pairs (for the sitemap)
// GET /store-api?action=store-stats              → per-store { slug, rating, reviewCount } (for the reviews sitemap gate)
//
// Called with the Supabase anon key (public-safe). No per-user auth.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
};

const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

const PAGE_SIZE = 24;
const BLOCKED = new Set(['suspended', 'banned', 'restricted']);

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// Only the public fields the website needs — never leak private vendor data.
function publicStore(id: string, data: any) {
  const store = data?.store || {};
  const location = data?.location || {};
  const socials = data?.socials || {};
  const personal = data?.personal || {};
  return {
    id,
    name: store.storeName || 'Merchant Store',
    description: store.description || '',
    logoUrl: store.logoUrl || '',
    coverUrl: store.coverUrl || '',
    slug: store.slug || id,
    walkIn: [location.address, location.city, location.state]
      .map((s: any) => (s || '').toString().trim())
      .filter(Boolean)
      .join(', '),
    phone: store.contactPhone || personal.phone || '',
    whatsapp: socials.whatsappGroup || '',
    // Guest checkout: true -> merchant absorbs the 3.5% fee (no fee line
    // shown); false -> customer pays it on top. Display only; web-checkout
    // recomputes the authoritative amounts server-side.
    absorbOutrightFee: store.absorbOutrightFee === true,
    instagram: socials.instagram || '',
    tiktok: socials.tiktok || '',
  };
}

function publicProduct(id: string, p: any) {
  // A timed campaign stamps campaignEndsAt on the product. Once it passes, the
  // tag and discount have lapsed, so we drop them here — a single gate that
  // covers every site surface (store page, product page, modal, cart display)
  // with no dependency on the merchant-side sweep cleaning the field. Untimed
  // campaigns have no end time and stay until the merchant deletes them.
  const endsAt = p.campaignEndsAt?.toDate?.()?.getTime?.() ?? null;
  const promoActive = endsAt == null || endsAt > Date.now();
  return {
    id,
    code: p.code || '',
    name: p.name || 'Product',
    description: p.description || '',
    price: Number(p.price || 0),
    discountedPrice: promoActive ? Number(p.discountedPrice || 0) : 0,
    images: Array.isArray(p.images) ? p.images.slice(0, 6) : [],
    category: p.category || '',
    availableStock: Number(p.availableStock || 0),
    allowReservation: p.allowReservation !== false,
    modelType: p.modelType || '',
    isFeatured: p.isFeatured === true,
    campaignTag: promoActive ? (p.campaignTag || null) : null,
    // Optional flat variants (label + per-variant stock); [] for products
    // without variants. availableStock above is always the summed total.
    variants: Array.isArray(p.variants)
      ? p.variants.map((v: any) => ({
          label: String(v?.label ?? ''),
          stock: Math.floor(Number(v?.stock ?? 0)),
        }))
      : [],
  };
}

// Active/upcoming flash deals (timed campaigns) for a store, so the website can
// show the same live countdown badges as the app.
async function fetchDeals(vendorId: string) {
  const snap = await db.collection('campaigns').where('vendorId', '==', vendorId).get();
  const now = Date.now();
  const deals: any[] = [];
  snap.forEach((doc) => {
    const c = doc.data();
    if (c.archived === true) return; // soft-deleted → history only
    const start = c.dealStartAt?.toDate?.()?.getTime?.() ?? null;
    const end = c.dealEndAt?.toDate?.()?.getTime?.() ?? null;
    if (start == null || end == null) return; // untimed campaign → no countdown
    if (end <= now) return; // window closed
    deals.push({
      productIds: Array.isArray(c.productIds) ? c.productIds : [],
      startAt: start,
      endAt: end,
      title: c.title || '',
      tag: c.tag || '',
      discountType: c.discountType || 'none',
      discountValue: Number(c.discountValue || 0),
    });
  });
  return deals;
}

// vendorId → slug for every vendor that has a slug, fully paginated.
async function allVendorSlugs(): Promise<Map<string, string>> {
  const slugById = new Map<string, string>();
  let last: string | null = null;
  while (true) {
    let q = db
      .collection('vendors')
      .select('store.slug')
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(1000);
    if (last) q = q.startAfter(last);
    const snap = await q.get();
    snap.docs.forEach((d) => {
      const slug = d.data()?.store?.slug;
      if (typeof slug === 'string' && slug.length > 0) slugById.set(d.id, slug);
    });
    if (snap.size < 1000) break;
    last = snap.docs[snap.size - 1].id;
  }
  return slugById;
}

async function resolveVendor(slug: string) {
  const bySlug = await db
    .collection('vendors')
    .where('store.slug', '==', slug)
    .limit(1)
    .get();
  if (!bySlug.empty) return bySlug.docs[0];

  const byId = await db.collection('vendors').doc(slug).get();
  return byId.exists ? byId : null;
}

async function reviewSummary(vendorId: string) {
  const empty = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
  const snap = await db.collection('vendors').doc(vendorId).collection('reviews').get();
  if (snap.empty) return { average: 0, count: 0, recent: [], distribution: empty };
  let sum = 0;
  const distribution: Record<number, number> = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
  const all: any[] = [];
  snap.forEach((d) => {
    const r = d.data();
    const rating = Number(r?.rating || 0);
    sum += rating;
    const bucket = Math.min(5, Math.max(1, Math.round(rating)));
    distribution[bucket] = (distribution[bucket] || 0) + 1;
    all.push({
      name: r?.customerName || 'Anonymous Buyer',
      rating,
      comment: (r?.comment || r?.review || '').toString(),
      createdAt: r?.createdAt?.toDate?.()?.getTime?.() ?? 0,
    });
  });
  // Newest first, all reviews (with or without a written comment), capped.
  const recent = all.sort((a, b) => b.createdAt - a.createdAt).slice(0, 20);
  return { average: sum / snap.size, count: snap.size, recent, distribution };
}

async function fetchProductsPage(vendorId: string, cursorId: string | null) {
  let q = db
    .collection('products')
    .where('vendorId', '==', vendorId)
    .where('status', '==', 'approved')
    // Order by document id — equality filters + __name__ need no custom index.
    .orderBy(admin.firestore.FieldPath.documentId())
    .limit(PAGE_SIZE);

  if (cursorId) q = q.startAfter(cursorId);

  const snap = await q.get();
  const products = snap.docs.map((d) => publicProduct(d.id, d.data()));
  const nextCursor = snap.size === PAGE_SIZE ? snap.docs[snap.docs.length - 1].id : null;
  return { products, nextCursor };
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'GET') return json({ error: 'Method not allowed' }, 405);

  try {
    const url = new URL(req.url);
    const action = url.searchParams.get('action');

    // Sitemap helper — all slugs.
    if (action === 'slugs') {
      const slugById = await allVendorSlugs();
      return json({ slugs: [...slugById.values()] });
    }

    // Sitemap helper — EVERY approved product's { slug, productId }, so
    // individual product pages (/store/{slug}/p/{id}) are discoverable by
    // crawlers. Fully paginated (no cap): the website chunks the result into
    // 50k-URL sitemap files, so scale is handled there, not here.
    if (action === 'product-urls') {
      const slugById = await allVendorSlugs();

      const urls: { slug: string; productId: string }[] = [];
      let last: string | null = null;
      while (true) {
        let q = db
          .collection('products')
          .where('status', '==', 'approved')
          .select('vendorId')
          .orderBy(admin.firestore.FieldPath.documentId())
          .limit(1000);
        if (last) q = q.startAfter(last);
        const snap = await q.get();
        snap.docs.forEach((d) => {
          const vendorId = d.data()?.vendorId;
          const slug = typeof vendorId === 'string' ? slugById.get(vendorId) : undefined;
          if (slug) urls.push({ slug, productId: d.id });
        });
        if (snap.size < 1000) break;
        last = snap.docs[snap.size - 1].id;
      }

      return json({ urls });
    }

    // Sitemap helper — each store's review average and count, so the website
    // can decide which /store/{slug}/reviews pages are worth indexing.
    if (action === 'store-stats') {
      const slugById = await allVendorSlugs();
      const entries = [...slugById.entries()]; // [vendorId, slug]
      const stores: { slug: string; rating: number; reviewCount: number }[] = [];
      // Small parallel batches — one reviews read per vendor.
      for (let i = 0; i < entries.length; i += 10) {
        const batch = entries.slice(i, i + 10);
        const results = await Promise.all(
          batch.map(async ([vendorId, slug]) => {
            const snap = await db
              .collection('vendors').doc(vendorId)
              .collection('reviews').select('rating').get();
            let sum = 0;
            snap.forEach((d) => { sum += Number(d.data()?.rating || 0); });
            return {
              slug,
              rating: snap.size > 0 ? sum / snap.size : 0,
              reviewCount: snap.size,
            };
          }),
        );
        stores.push(...results);
      }
      return json({ stores });
    }

    const slug = url.searchParams.get('slug');
    if (!slug) return json({ error: 'Missing slug' }, 400);

    const vendorDoc = await resolveVendor(slug);
    if (!vendorDoc) return json({ error: 'not_found' }, 404);

    const vendorId = vendorDoc.id;
    const cursor = url.searchParams.get('cursor');
    const productId = url.searchParams.get('productId');

    // Pagination request — just the next page of products.
    if (cursor) {
      const page = await fetchProductsPage(vendorId, cursor);
      return json(page);
    }

    // Single-product request — for the product-level SSR page and its OG tags.
    if (productId) {
      const productDoc = await db.collection('products').doc(productId).get();
      if (!productDoc.exists || productDoc.data()?.vendorId !== vendorId) {
        return json({ error: 'product_not_found' }, 404);
      }
      return json({
        store: publicStore(vendorId, vendorDoc.data()),
        product: publicProduct(productDoc.id, productDoc.data()),
      });
    }

    // Full first load.
    const [complianceDoc, visibilityDoc, reviews, firstPage, deals] = await Promise.all([
      db.collection('vendor_compliance').doc(vendorId).get(),
      db.collection('vendor_visibility').doc(vendorId).get(),
      reviewSummary(vendorId),
      fetchProductsPage(vendorId, null),
      fetchDeals(vendorId),
    ]);

    const compliance = complianceDoc.exists ? complianceDoc.data() : null;
    const blocked = compliance && BLOCKED.has((compliance.status || '').toString());

    const visibility = visibilityDoc.exists ? visibilityDoc.data() : {};

    return json({
      store: publicStore(vendorId, vendorDoc.data()),
      blocked: !!blocked,
      blockedMessage: blocked ? (compliance?.publicMessage || null) : null,
      visibility: {
        topSellerCircles: Number(visibility?.topSellerCircles || 0),
        mostVisitedCircles: Number(visibility?.mostVisitedCircles || 0),
        isHighlighted: visibility?.isHighlighted === true,
      },
      reviews,
      deals,
      products: firstPage.products,
      nextCursor: firstPage.nextCursor,
    });
  } catch (error) {
    console.error("❌ store-api error:", error);
    return json({ error: (error as Error)?.message ?? String(error) }, 500);
  }
});
