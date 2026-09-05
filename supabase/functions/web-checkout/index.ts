// web-checkout
//
// Guest outright purchases on the public storefront (korra.com.ng), no
// account required. Three actions:
//
//   init             -> validates the cart server-side (prices, stock,
//                       compliance), computes the fee from the merchant's
//                       absorbOutrightFee setting (3.5% capped at ₦7,500),
//                       creates the `orders` doc with paymentStatus 'awaiting'
//                       and returns the amount + reference for the Monnify
//                       inline SDK. NOTHING touches the merchant ledger or
//                       stock here; that happens only when monnify-webhook
//                       verifies the payment (metaData.purchaseType ==
//                       'web_outright').
//   status           -> polled by the confirmation screen. Requires the order
//                       reference as an access token. Returns paymentStatus
//                       and, once paid, the merchant's contact.
//   notify-delivered -> called by the MERCHANT APP (HMAC-guarded like other
//                       app endpoints) after marking a webPurchase order
//                       delivered; emails the guest once (deliveredEmailSent
//                       flag makes it idempotent).
//
// Guests are identified by name/email/phone only. Their record lives in the
// order doc (+ web_purchases dispute archive on confirmation); no customer
// account is created or linked, by design.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";
import {
  orderDeliveredEmail,
  sendOrderEmail,
  WebOrderEmailData,
} from "../_shared/web_order_emails.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-korra-timestamp, x-korra-signature',
};

const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

// ----- Fee economics: identical to outright-checkout -----
const OUTRIGHT_FEE_RATE = 0.035;
const MAX_FEE = 7500;

function to2DP(num: number): number {
  if (num === 0) return 0;
  return Math.ceil(Number((num * 100).toFixed(4))) / 100;
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

// =========================================================================
// ACTION: init
// =========================================================================
async function handleInit(body: any) {
  const { vendorId, items, customer } = body;

  if (!vendorId || typeof vendorId !== 'string') throw "Missing store.";
  if (!Array.isArray(items) || items.length === 0) throw "Your cart is empty.";
  if (items.length > 25) throw "Too many items in one checkout.";
  for (const it of items) {
    if (!it?.productId || typeof it.productId !== 'string') throw "Invalid cart item.";
    const qty = Number(it.quantity);
    if (!Number.isInteger(qty) || qty <= 0 || qty > 99) throw "Invalid item quantity.";
    // Optional variant line ("XL / Red"): must be a short string when sent.
    if (it.variantLabel != null &&
        (typeof it.variantLabel !== 'string' || it.variantLabel.length > 40)) {
      throw "Invalid item option.";
    }
  }

  const name = (customer?.name ?? '').toString().trim();
  const email = (customer?.email ?? '').toString().trim().toLowerCase();
  const phone = (customer?.phone ?? '').toString().trim();
  if (name.length < 2 || name.length > 80) throw "Please enter your full name.";
  if (!EMAIL_RE.test(email) || email.length > 120) throw "Please enter a valid email address.";
  const phoneDigits = phone.replace(/[^0-9+]/g, '');
  if (phoneDigits.length < 7 || phoneDigits.length > 16) throw "Please enter a valid phone number.";

  // --- Vendor + compliance (same gate as app checkout) ---
  const [vendorDoc, complianceDoc] = await Promise.all([
    db.collection('vendors').doc(vendorId).get(),
    db.collection('vendor_compliance').doc(vendorId).get(),
  ]);
  if (!vendorDoc.exists) throw "Store not found.";
  if (complianceDoc.exists) {
    const comp = complianceDoc.data()!;
    if (comp.blockPayments === true || comp.status === 'suspended' || comp.status === 'banned') {
      throw "This store cannot accept payments right now due to a compliance issue.";
    }
  }
  const vendorData = vendorDoc.data()!;
  const storeMap = vendorData.store ?? {};
  const storeName = storeMap.storeName ?? 'Merchant Store';
  const absorbOutrightFee = storeMap.absorbOutrightFee === true;

  // --- Products: server-side prices, never the client's ---
  const productDocs = await Promise.all(
    items.map((it: any) => db.collection('products').doc(it.productId).get()),
  );

  // Active campaigns (max 3 per vendor): a product's campaignTag is only
  // snapshotted onto the order if its owning campaign is live right now
  // (untimed campaigns live until deleted; timed ones only while dealEndAt
  // is in the future — an expired countdown leaves a stale tag behind).
  const campaignsSnap = await db.collection('campaigns').where('vendorId', '==', vendorId).get();
  const activeCampaigns = campaignsSnap.docs.filter((d) => {
    const c = d.data();
    if (c.archived === true) return false; // soft-deleted → history only
    const end = c.dealEndAt?.toDate?.()?.getTime?.();
    return typeof end === 'number' ? Date.now() < end : true;
  });
  // Tag for display + owning campaign id for attribution (id stays internal).
  const activePromo = (productId: string, tag: any): { tag: string; campaignId: string } | null => {
    const t = (tag ?? '').toString().trim();
    if (!t) return null;
    const owner = activeCampaigns.find((d) => {
      const c = d.data();
      return Array.isArray(c.productIds) && c.productIds.includes(productId);
    });
    return owner ? { tag: t, campaignId: owner.id } : null;
  };

  let subtotal = 0;
  const orderItems: any[] = [];
  const promotions: string[] = []; // unique active campaign tags, snapshotted
  const promotionCampaignIds: string[] = []; // internal: attribution only
  for (let i = 0; i < items.length; i++) {
    const doc = productDocs[i];
    const qty = Number(items[i].quantity);
    if (!doc.exists) throw "One of the items is no longer available.";
    const p = doc.data()!;
    if (p.vendorId !== vendorId) throw "Cart items must all belong to this store.";
    if (p.status !== 'approved') throw `"${p.name}" is no longer available.`;

    const stock = Number(p.availableStock ?? 0);
    if (stock < qty) throw `Only ${stock} left of "${p.name}". Please adjust your cart.`;

    // --- VARIANT VALIDATION (per-variant stock). Stock is NOT decremented
    // here — the order is only pending until the Monnify webhook confirms
    // payment and deducts the exact variantLabel stamped on each item. ---
    const productVariants: { label: string; stock: number }[] =
      Array.isArray(p.variants)
        ? p.variants.map((v: any) => ({
            label: String(v?.label ?? ''),
            stock: Math.floor(Number(v?.stock ?? 0)),
          }))
        : [];
    const requestedLabel = (items[i].variantLabel ?? '').toString().trim();
    let chosenVariant: string | null = null;
    if (productVariants.length > 0) {
      if (!requestedLabel) throw `Please choose an option for "${p.name}".`;
      const match = productVariants.find((v) => v.label === requestedLabel);
      if (!match) throw `Option "${requestedLabel}" of "${p.name}" is no longer available.`;
      // Cumulative across lines of the same product in this cart.
      const alreadyRequested = items
        .slice(0, i)
        .filter((x: any) => x.productId === doc.id &&
            (x.variantLabel ?? '').toString().trim() === requestedLabel)
        .reduce((acc: number, x: any) => acc + Number(x.quantity), 0);
      if (alreadyRequested + qty > match.stock) {
        throw `Only ${match.stock} left of "${p.name}" (${requestedLabel}). Please adjust your cart.`;
      }
      chosenVariant = requestedLabel;
    }

    // Only honor the discount when the product's owning campaign is still live
    // (untimed, or timed and not yet past). An expired/archived/deleted
    // campaign that left a stale discountedPrice behind is charged at full
    // price — the discount and its tag lapse together.
    const promo = activePromo(doc.id, p.campaignTag);
    const unitPrice = to2DP(
      (promo != null && p.discountedPrice != null && Number(p.discountedPrice) > 0)
        ? Number(p.discountedPrice)
        : Number(p.price ?? 0),
    );
    if (unitPrice <= 0) throw `"${p.name}" has an invalid price.`;

    subtotal = to2DP(subtotal + unitPrice * qty);
    if (promo && !promotions.includes(promo.tag)) promotions.push(promo.tag);
    if (promo && !promotionCampaignIds.includes(promo.campaignId)) {
      promotionCampaignIds.push(promo.campaignId);
    }
    orderItems.push({
      productId: doc.id,
      title: p.name ?? 'Product',
      imageUrl: Array.isArray(p.images) && p.images.length > 0 ? p.images[0] : '',
      quantity: qty,
      unitPrice,
      ...(promo ? { promotion: promo.tag } : {}),
      ...(chosenVariant ? { variantLabel: chosenVariant } : {}),
    });
  }

  let feeAmount = to2DP(subtotal * OUTRIGHT_FEE_RATE);
  if (feeAmount > MAX_FEE) feeAmount = MAX_FEE;
  const amountCharged = absorbOutrightFee ? subtotal : to2DP(subtotal + feeAmount);

  // --- The pending order: visible to the merchant, off their books ---
  const orderRef = db.collection('orders').doc();
  const reference = `WEB-${orderRef.id.substring(0, 5)}-${Date.now().toString().slice(-4)}`;
  const summaryTitle = orderItems.length === 1
    ? orderItems[0].title
    : `${orderItems[0].title} +${orderItems.length - 1} more`;

  await orderRef.set({
    vendorId,
    customerId: '',
    customerName: name,
    customerPhone: phoneDigits,
    customerEmail: email,
    customerAddress: '',
    totalAmount: subtotal,
    feeAmount,
    feePaidBy: absorbOutrightFee ? 'merchant' : 'customer',
    amountCharged,
    creditUsed: 0,
    walletUsed: 0,
    status: 'pending',
    paymentStatus: 'awaiting', // webhook flips to 'paid'
    webPurchase: true,
    source: 'web',
    reference,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    items: orderItems,
    // Snapshot at time of purchase — kept even if the campaign later
    // expires or is deleted (copied, not referenced live). The campaign IDs
    // are internal attribution; the webhook increments campaign purchases
    // only when the payment actually confirms.
    ...(promotions.length > 0 ? { promotions } : {}),
    ...(promotionCampaignIds.length > 0 ? { promotionCampaignIds } : {}),
  });

  return json({
    status: "SUCCESS",
    orderId: orderRef.id,
    reference,
    amount: amountCharged,
    subtotal,
    feeAmount,
    feePaidBy: absorbOutrightFee ? 'merchant' : 'customer',
    storeName,
    summaryTitle,
  });
}

// =========================================================================
// ACTION: cancel — customer closed the Monnify overlay without paying.
// Reference acts as the access token; only an order still awaiting payment
// can be cancelled this way. If the payment somehow lands afterwards, the
// webhook restores the order to pending when it marks it paid.
// =========================================================================
async function handleCancel(body: any) {
  const { orderId, reference } = body;
  if (!orderId || !reference) throw "Missing order details.";

  const orderRef = db.collection('orders').doc(orderId);
  const orderDoc = await orderRef.get();
  if (!orderDoc.exists) throw "Order not found.";
  const order = orderDoc.data()!;
  if (order.reference !== reference || order.webPurchase !== true) throw "Order not found.";

  if (order.paymentStatus !== 'awaiting') {
    return json({ status: "SKIPPED", reason: "order not awaiting payment" });
  }

  await orderRef.update({
    status: 'cancelled',
    paymentStatus: 'abandoned',
    cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return json({ status: "SUCCESS" });
}

// =========================================================================
// ACTION: status
// =========================================================================
async function handleStatus(body: any) {
  const { orderId, reference } = body;
  if (!orderId || !reference) throw "Missing order details.";

  const orderDoc = await db.collection('orders').doc(orderId).get();
  if (!orderDoc.exists) throw "Order not found.";
  const order = orderDoc.data()!;

  // The reference doubles as the guest's access token for this order.
  if (order.reference !== reference || order.webPurchase !== true) {
    throw "Order not found.";
  }

  const paymentStatus = order.paymentStatus ?? 'awaiting';
  const base = {
    status: "SUCCESS",
    orderId: orderDoc.id,
    orderIdShort: orderDoc.id.substring(0, 8).toUpperCase(),
    paymentStatus,
    orderStatus: order.status ?? 'pending',
  };

  if (paymentStatus !== 'paid') return json(base);

  // Paid: hand the guest the merchant contact for the WhatsApp handoff.
  const vendorDoc = await db.collection('vendors').doc(order.vendorId).get();
  const vData = vendorDoc.exists ? vendorDoc.data()! : {};
  const storeMap = vData.store ?? {};
  return json({
    ...base,
    merchant: {
      name: storeMap.storeName ?? 'Merchant Store',
      phone: storeMap.contactPhone ?? vData.personal?.phone ?? '',
    },
  });
}

// =========================================================================
// ACTION: notify-delivered (merchant app only, HMAC-guarded)
// =========================================================================
async function handleNotifyDelivered(req: Request, body: any) {
  // Same HMAC scheme as the app's other endpoints.
  const clientTimestamp = req.headers.get('x-korra-timestamp');
  const clientSignature = req.headers.get('x-korra-signature');
  const KORRA_SECRET = "7f8a9b2d4c6e1f3a5b7c9d0e2f4a6b8c1d3e5f7a9b0c2d4e6f8a1b3c5d7e9f0a";
  if (!clientTimestamp || !clientSignature) throw "Unauthorized: Missing security signatures.";
  if (Math.abs(Date.now() - parseInt(clientTimestamp, 10)) > 120000) throw "Unauthorized: Request expired.";
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw", encoder.encode(KORRA_SECRET), { name: "HMAC", hash: "SHA-256" }, false, ["sign"],
  );
  const sigBuf = await crypto.subtle.sign("HMAC", key, encoder.encode(clientTimestamp));
  const expected = Array.from(new Uint8Array(sigBuf)).map((b) => b.toString(16).padStart(2, '0')).join('');
  if (clientSignature !== expected) throw "Unauthorized: Signature mismatch.";

  const { orderId } = body;
  if (!orderId) throw "Missing orderId.";

  const orderRef = db.collection('orders').doc(orderId);
  const orderDoc = await orderRef.get();
  if (!orderDoc.exists) throw "Order not found.";
  const order = orderDoc.data()!;

  if (order.webPurchase !== true) return json({ status: "SKIPPED", reason: "not a web purchase" });
  if (order.status !== 'delivered') return json({ status: "SKIPPED", reason: "order not delivered" });
  if (order.deliveredEmailSent === true) return json({ status: "SKIPPED", reason: "already sent" });
  if (!order.customerEmail) return json({ status: "SKIPPED", reason: "no email on order" });

  const vendorDoc = await db.collection('vendors').doc(order.vendorId).get();
  const vData = vendorDoc.exists ? vendorDoc.data()! : {};
  const storeMap = vData.store ?? {};

  const emailData: WebOrderEmailData = {
    customerName: order.customerName ?? 'there',
    customerEmail: order.customerEmail,
    orderIdShort: orderDoc.id.substring(0, 8).toUpperCase(),
    orderId: orderDoc.id,
    storeName: storeMap.storeName ?? 'the store',
    merchantPhone: storeMap.contactPhone ?? vData.personal?.phone ?? '',
    items: order.items ?? [],
    subtotal: Number(order.totalAmount ?? 0),
    feeAmount: Number(order.feeAmount ?? 0),
    feePaidBy: order.feePaidBy ?? 'customer',
    amountCharged: Number(order.amountCharged ?? 0),
  };

  const { subject, html } = orderDeliveredEmail(emailData);
  await sendOrderEmail(emailData.customerEmail, subject, html);
  await orderRef.update({ deliveredEmailSent: true });

  return json({ status: "SUCCESS" });
}

// =========================================================================
serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    if (req.method !== 'POST') throw "Only POST allowed.";
    const body = await req.json();
    const action = body?.action;

    if (action === 'init') return await handleInit(body);
    if (action === 'status') return await handleStatus(body);
    if (action === 'cancel') return await handleCancel(body);
    if (action === 'notify-delivered') return await handleNotifyDelivered(req, body);

    throw "Unknown action.";
  } catch (error) {
    const message = typeof error === 'string' ? error : (error as Error)?.message ?? "Request failed.";
    console.error("web-checkout error:", error);
    return json({ status: "ERROR", error: message }, 400);
  }
});
