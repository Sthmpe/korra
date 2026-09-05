// Shared email templates + sender for guest web purchases.
// Visual language matches send-email (DM Serif Display + DM Sans, dark hero,
// warm cream card) so every Korra email reads as one brand.
// Guests have no app: email is their ONLY record, so the receipt carries
// everything they need including the merchant's contact.

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');

export interface WebOrderEmailData {
  customerName: string;
  customerEmail: string;
  orderIdShort: string; // first 8 chars, uppercased
  orderId: string;
  storeName: string;
  merchantPhone: string; // raw, may be empty
  items: { title: string; quantity: number; unitPrice: number }[];
  subtotal: number;
  feeAmount: number;
  feePaidBy: string; // 'merchant' | 'customer'
  amountCharged: number;
}

function naira(n: number): string {
  return `₦${Number(n || 0).toLocaleString('en-NG', { maximumFractionDigits: 2 })}`;
}

// Nigerian local numbers (0xxxxxxxxxx) become international for wa.me.
export function waNumber(phone: string): string {
  const digits = (phone || '').replace(/[^0-9]/g, '');
  if (digits.length === 11 && digits.startsWith('0')) return `234${digits.substring(1)}`;
  return digits;
}

const baseStyles = `
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #EDE8E1; font-family: 'DM Sans', sans-serif; padding: 24px 8px; min-height: 100vh; }
  .email-wrap { max-width: 480px; margin: 0 auto; }
  .main-card { background: #FDFAF7; border-radius: 12px; box-shadow: 0 4px 20px rgba(28, 13, 0, 0.05); overflow: hidden; }
  .hero { background: #1C0D00; padding: 36px 24px 28px; text-align: center; }
  .hero-eyebrow { display: inline-block; font-size: 10px; font-weight: 600; letter-spacing: 2px; text-transform: uppercase; color: #C27641; margin-bottom: 12px; }
  .hero h1 { font-family: 'DM Serif Display', serif; font-size: 24px; font-weight: 400; color: #FDF6EE; margin-bottom: 8px; line-height: 1.2; }
  .body { padding: 32px 24px; }
  .greeting { font-size: 14px; color: #3D2B1A; line-height: 1.6; margin-bottom: 24px; font-weight: 300; }
  .order-box { background: #FDF0E6; border-radius: 8px; padding: 24px; margin-bottom: 24px; text-align: center; }
  .order-label { font-size: 10px; font-weight: 600; letter-spacing: 2px; text-transform: uppercase; color: #7C4A25; margin-bottom: 8px; }
  .order-code { font-size: 30px; font-weight: 600; color: #A54600; letter-spacing: 4px; margin: 0; font-family: 'DM Sans', sans-serif; }
  .items-table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
  .items-table td { padding: 10px 0; font-size: 13px; color: #3D2B1A; border-bottom: 1px solid #F0E6DC; }
  .items-table .qty { color: #B09080; font-size: 12px; }
  .items-table .price { text-align: right; font-weight: 600; }
  .totals td { padding: 8px 0; font-size: 13px; color: #5A3E2B; }
  .totals .grand td { font-size: 15px; font-weight: 600; color: #1C0D00; padding-top: 14px; }
  .cta-btn { display: inline-block; background: #A54600; color: #FDF6EE !important; text-decoration: none; font-size: 14px; font-weight: 600; padding: 14px 28px; border-radius: 999px; margin: 4px 6px; }
  .cta-btn.secondary { background: #FDF0E6; color: #A54600 !important; }
  .note { font-size: 12.5px; color: #7C4A25; line-height: 1.6; background: #FDF0E6; border-radius: 8px; padding: 14px 16px; margin-top: 20px; }
  .signoff { padding: 0 24px 28px; font-size: 13px; color: #5A3E2B; text-align: left; }
  .sig-name { font-family: 'DM Serif Display', serif; font-size: 18px; color: #A54600; margin-bottom: 2px; }
  .sig-role { font-size: 12px; color: #B09080; }
  .footer { background: #1C0D00; text-align: center; padding: 24px 20px; }
  .footer-row { font-size: 12px; color: rgba(253, 246, 238, 0.6); margin-bottom: 12px; }
`;

function shell(title: string, eyebrow: string, eyebrowColor: string, heroTitle: string, bodyHtml: string): string {
  return `
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${title}</title>
<link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<style>${baseStyles}
  .hero-eyebrow { color: ${eyebrowColor}; }
</style>
</head>
<body>
<div class="email-wrap">
  <div class="main-card">
    <div class="hero">
      <div class="hero-eyebrow">${eyebrow}</div>
      <h1>${heroTitle}</h1>
    </div>
    <div class="body">
      ${bodyHtml}
    </div>
    <div class="signoff">
      <div class="sig-name">The Korra Team</div>
      <div class="sig-role">korra.com.ng</div>
    </div>
    <div class="footer">
      <div class="footer-row">© 2026 Korra &nbsp;|&nbsp; support@korra.com.ng</div>
    </div>
  </div>
</div>
</body>
</html>`;
}

function itemsHtml(d: WebOrderEmailData): string {
  const rows = d.items
    .map(
      (it) => `
      <tr>
        <td>${it.title} <span class="qty">x${it.quantity}</span></td>
        <td class="price">${naira(it.unitPrice * it.quantity)}</td>
      </tr>`,
    )
    .join('');

  const feeRow =
    d.feePaidBy === 'customer' && d.feeAmount > 0
      ? `<tr><td>Processing fee</td><td class="price">${naira(d.feeAmount)}</td></tr>`
      : '';

  return `
    <table class="items-table">${rows}</table>
    <table class="items-table totals" style="border:none">
      <tr><td>Subtotal</td><td class="price">${naira(d.subtotal)}</td></tr>
      ${feeRow}
      <tr class="grand"><td>Total paid</td><td class="price">${naira(d.amountCharged)}</td></tr>
    </table>`;
}

function contactButtons(d: WebOrderEmailData): string {
  const wa = waNumber(d.merchantPhone);
  const msg = encodeURIComponent(
    `Hello ${d.storeName}, I just placed Korra order ${d.orderIdShort} on your store. Please confirm my order.`,
  );
  const waBtn = wa
    ? `<a class="cta-btn" href="https://wa.me/${wa}?text=${msg}">Message ${d.storeName} on WhatsApp</a>`
    : '';
  const telBtn = d.merchantPhone
    ? `<a class="cta-btn secondary" href="tel:${d.merchantPhone}">Call ${d.merchantPhone}</a>`
    : '';
  if (!waBtn && !telBtn) return '';
  return `<div style="text-align:center; margin: 8px 0 4px;">${waBtn}${telBtn}</div>`;
}

export function orderConfirmedEmail(d: WebOrderEmailData): { subject: string; html: string } {
  const body = `
    <p class="greeting">
      Hi <strong>${d.customerName}</strong>, your payment to <strong>${d.storeName}</strong> is confirmed.
      Keep this email safe. Your Order ID below is your reference for this purchase.
    </p>
    <div class="order-box">
      <div class="order-label">Your Order ID</div>
      <h1 class="order-code">${d.orderIdShort}</h1>
    </div>
    ${itemsHtml(d)}
    ${contactButtons(d)}
    <div class="note">
      Delivery is arranged directly between you and ${d.storeName}. Share your Order ID with them
      so they can find your order instantly. Korra confirms payments and settles the merchant;
      we do not handle delivery.
    </div>`;
  return {
    subject: `Payment confirmed. Your ${d.storeName} order ${d.orderIdShort}`,
    html: shell('Payment Confirmed', 'Order Confirmed', '#4CAF50', 'Payment Confirmed', body),
  };
}

export function orderDeliveredEmail(d: WebOrderEmailData): { subject: string; html: string } {
  const body = `
    <p class="greeting">
      Hi <strong>${d.customerName}</strong>, good news. <strong>${d.storeName}</strong> has marked your
      order <strong>${d.orderIdShort}</strong> as delivered.
    </p>
    ${itemsHtml(d)}
    <div class="note">
      If you have not received this order, contact ${d.storeName} directly with your Order ID.
    </div>
    ${contactButtons(d)}`;
  return {
    subject: `${d.storeName} marked your order ${d.orderIdShort} as delivered`,
    html: shell('Order Delivered', 'Delivered', '#4CAF50', 'Order Delivered', body),
  };
}

export function orderFailedEmail(d: WebOrderEmailData): { subject: string; html: string } {
  const body = `
    <p class="greeting">
      Hi <strong>${d.customerName}</strong>, unfortunately your payment for order
      <strong>${d.orderIdShort}</strong> at <strong>${d.storeName}</strong> was not successful,
      so the order has been cancelled.
    </p>
    <div class="note">
      If you were debited, the amount is reversed automatically by your bank or payment provider,
      usually within 24 hours. You can place the order again at any time.
    </div>`;
  return {
    subject: `Payment not completed for order ${d.orderIdShort}`,
    html: shell('Payment Failed', 'Payment Issue', '#D92D20', 'Payment Not Completed', body),
  };
}

export async function sendOrderEmail(to: string, subject: string, html: string): Promise<void> {
  if (!RESEND_API_KEY) {
    console.error('RESEND_API_KEY missing; order email skipped');
    return;
  }
  try {
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: 'Korra Orders <orders@korra.com.ng>',
        to: [to],
        subject,
        html,
      }),
    });
    if (!res.ok) {
      const data = await res.json().catch(() => ({}));
      console.error('Resend order email failed:', data);
    }
  } catch (e) {
    console.error('Resend order email error:', e);
  }
}
