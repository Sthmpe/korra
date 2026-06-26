import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import admin from "npm:firebase-admin@11.11.0";

// 1. DEFINE CORS & ENV
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-cron-secret, content-type',
};

const RESEND_API_KEY       = Deno.env.get('RESEND_API_KEY');
const MONNIFY_BASE_URL     = Deno.env.get("MONNIFY_BASE_URL") || "";
const MONNIFY_API_KEY      = Deno.env.get("MONNIFY_API_KEY") ?? "";
const MONNIFY_SECRET_KEY   = Deno.env.get("MONNIFY_SECRET_KEY") ?? "";
const MONNIFY_WALLET_ACCOUNT = Deno.env.get("MONNIFY_WALLET_ACCOUNT") ?? "";

// Minimum balance required before auto-payout fires
const AUTO_PAYOUT_THRESHOLD = 10_000;
// EMTL fee threshold (same rule as manual payout)
const EMTL_THRESHOLD = 10_000;
const GOVT_LEVY      = 50;

// Initialize Firebase
const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
if (admin.apps.length === 0) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

// ---------------------------------------------------------------------------
// HELPER: MONNIFY AUTH
// ---------------------------------------------------------------------------
async function getMonnifyToken(): Promise<string> {
  const authString = btoa(`${MONNIFY_API_KEY}:${MONNIFY_SECRET_KEY}`);
  const response = await fetch(`${MONNIFY_BASE_URL}/api/v1/auth/login`, {
    method: "POST",
    headers: { "Authorization": `Basic ${authString}` }
  });
  const data = await response.json();
  if (!data.requestSuccessful) throw new Error("Failed to authenticate with Monnify");
  return data.responseBody.accessToken;
}

// ---------------------------------------------------------------------------
// HELPER: SETTLEMENT EMAIL TEMPLATES
// Two variants:
// Variant A — below threshold or no bank account → funds in Korra wallet
// Variant B — above threshold AND bank account set up → funds sent to bank
// ---------------------------------------------------------------------------
const getSettlementWalletTemplate = (storeName: string, amountStr: string, txCount: number) => `
<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Funds Settled</title>
<link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<style>
  *,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
  body{background:#EDE8E1;font-family:'DM Sans',sans-serif;padding:24px 8px;min-height:100vh}
  .email-wrap{max-width:480px;margin:0 auto}
  .main-card{background:#FDFAF7;border-radius:12px;box-shadow:0 4px 20px rgba(28,13,0,.05);overflow:hidden}
  .hero{background:#1C0D00;padding:36px 24px 28px;text-align:center}
  .hero-eyebrow{display:inline-block;font-size:10px;font-weight:600;letter-spacing:2px;text-transform:uppercase;color:#10B981;margin-bottom:12px}
  .hero h1{font-family:'DM Sans',sans-serif;font-size:32px;font-weight:700;color:#FDF6EE;margin-bottom:8px;letter-spacing:-1px}
  .hero-sub{font-size:14px;color:rgba(253,246,238,0.8);line-height:1.5}
  .body{padding:32px 24px}
  .greeting{font-size:15px;color:#3D2B1A;line-height:1.6;margin-bottom:24px}
  .greeting strong{font-weight:600;color:#1C0D00}
  .info-box{background:#ECFDF5;border-radius:8px;padding:20px;margin-bottom:24px;text-align:center}
  .box-title{font-size:12px;font-weight:600;letter-spacing:1px;text-transform:uppercase;margin-bottom:8px;color:#065F46}
  .amount{font-size:28px;font-weight:700;color:#064E3B;margin-bottom:8px;letter-spacing:-0.5px}
  .tx-count{font-size:13px;color:#047857;font-weight:500}
  .tip-box{background:#FFF7ED;border-radius:8px;padding:16px;margin-bottom:24px;font-size:13px;color:#7A3B00;line-height:1.6}
  .tip-box strong{font-weight:600}
  .cta-wrap{text-align:center;margin-top:32px;margin-bottom:8px}
  .cta-btn{display:inline-block;background:#A54600;color:#FDF6EE;text-decoration:none;font-size:15px;font-weight:600;padding:16px 40px;border-radius:50px}
  .signoff{padding:0 24px 28px;font-size:13px;color:#5A3E2B}
  .signoff p{padding-top:12px;margin-bottom:20px;line-height:1.6}
  .sig-name{font-family:'DM Serif Display',serif;font-size:18px;color:#A54600;margin-bottom:2px}
  .footer{background:#1C0D00;text-align:center;padding:24px 20px}
  .footer-row{font-size:12px;color:rgba(253,246,238,0.6);margin-bottom:12px}
  .footer a{color:#C27641;text-decoration:none;font-weight:500}
  @media only screen and (max-width:600px){body{padding:16px 8px}.cta-btn{display:block;width:100%;padding:16px 0}}
</style></head><body>
<div class="email-wrap"><div class="main-card">
  <div class="hero">
    <div class="hero-eyebrow">Settlement Successful</div>
    <h1>${amountStr}</h1>
    <p class="hero-sub">Credited to your Korra Wallet — ready to withdraw.</p>
  </div>
  <div class="body">
    <div class="greeting">
      <p>Hi <strong>${storeName}</strong>,</p>
      <p>Your recent sales have cleared the holding period. The funds are now sitting in your Korra Wallet and are ready for you to withdraw at any time.</p>
    </div>
    <div class="info-box">
      <div class="box-title">Settlement Summary</div>
      <div class="amount">${amountStr}</div>
      <div class="tx-count">From ${txCount} cleared transaction(s)</div>
    </div>
    <div class="tip-box">
      💡 <strong>Tip:</strong> Want funds sent directly to your bank account automatically? Set up an <strong>Auto-Payout Account</strong> in your Korra dashboard and we'll handle it for you.
    </div>
    <div class="cta-wrap">
      <a href="https://business.korra.com.ng" class="cta-btn">Withdraw Funds Now</a>
    </div>
  </div>
  <div class="signoff">
    <p>If you have any questions about your settlement, don't hesitate to reach out to our support team.</p>
    <div class="sig-name">The Korra Team</div>
  </div>
  <div class="footer">
    <div class="footer-row">© 2026 Korra Business &nbsp;|&nbsp; <a href="mailto:support@korra.com.ng">support@korra.com.ng</a></div>
  </div>
</div></div></body></html>`;

const getSettlementAutoPayoutTemplate = (
  storeName: string,
  amountStr: string,
  txCount: number,
  bankName: string,
  maskedAccount: string,
) => `
<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Funds Settled — Auto-Payout Queued</title>
<link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<style>
  *,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
  body{background:#EDE8E1;font-family:'DM Sans',sans-serif;padding:24px 8px;min-height:100vh}
  .email-wrap{max-width:480px;margin:0 auto}
  .main-card{background:#FDFAF7;border-radius:12px;box-shadow:0 4px 20px rgba(28,13,0,.05);overflow:hidden}
  .hero{background:#1C0D00;padding:36px 24px 28px;text-align:center}
  .hero-eyebrow{display:inline-block;font-size:10px;font-weight:600;letter-spacing:2px;text-transform:uppercase;color:#10B981;margin-bottom:12px}
  .hero h1{font-family:'DM Sans',sans-serif;font-size:32px;font-weight:700;color:#FDF6EE;margin-bottom:8px;letter-spacing:-1px}
  .hero-sub{font-size:14px;color:rgba(253,246,238,0.8);line-height:1.5}
  .body{padding:32px 24px}
  .greeting{font-size:15px;color:#3D2B1A;line-height:1.6;margin-bottom:24px}
  .greeting strong{font-weight:600;color:#1C0D00}
  .info-box{background:#ECFDF5;border-radius:8px;padding:20px;margin-bottom:16px;text-align:center}
  .box-title{font-size:12px;font-weight:600;letter-spacing:1px;text-transform:uppercase;margin-bottom:8px;color:#065F46}
  .amount{font-size:28px;font-weight:700;color:#064E3B;margin-bottom:8px;letter-spacing:-0.5px}
  .tx-count{font-size:13px;color:#047857;font-weight:500}
  .dest-box{background:#F2F4F7;border-radius:8px;padding:16px;margin-bottom:24px}
  .dest-row{display:flex;justify-content:space-between;font-size:13px;padding:4px 0}
  .dest-label{color:#667085;font-weight:500}
  .dest-value{color:#101828;font-weight:600}
  .signoff{padding:0 24px 28px;font-size:13px;color:#5A3E2B}
  .signoff p{padding-top:12px;margin-bottom:20px;line-height:1.6}
  .sig-name{font-family:'DM Serif Display',serif;font-size:18px;color:#A54600;margin-bottom:2px}
  .footer{background:#1C0D00;text-align:center;padding:24px 20px}
  .footer-row{font-size:12px;color:rgba(253,246,238,0.6);margin-bottom:12px}
  .footer a{color:#C27641;text-decoration:none;font-weight:500}
  @media only screen and (max-width:600px){body{padding:16px 8px}}
</style></head><body>
<div class="email-wrap"><div class="main-card">
  <div class="hero">
    <div class="hero-eyebrow">Settlement + Auto-Payout</div>
    <h1>${amountStr}</h1>
    <p class="hero-sub">Settled & being sent to your bank account.</p>
  </div>
  <div class="body">
    <div class="greeting">
      <p>Hi <strong>${storeName}</strong>,</p>
      <p>Your funds have cleared and your auto-payout has been triggered. The amount below is on its way to your linked bank account.</p>
    </div>
    <div class="info-box">
      <div class="box-title">Settlement Summary</div>
      <div class="amount">${amountStr}</div>
      <div class="tx-count">From ${txCount} cleared transaction(s)</div>
    </div>
    <div class="dest-box">
      <div class="dest-row"><span class="dest-label">Sending to</span><span class="dest-value">${bankName}</span></div>
      <div class="dest-row"><span class="dest-label">Account</span><span class="dest-value">${maskedAccount}</span></div>
    </div>
  </div>
  <div class="signoff">
    <p>If you did not set up this auto-payout or believe this is an error, please contact our support team immediately.</p>
    <div class="sig-name">The Korra Team</div>
  </div>
  <div class="footer">
    <div class="footer-row">© 2026 Korra Business &nbsp;|&nbsp; <a href="mailto:support@korra.com.ng">support@korra.com.ng</a></div>
  </div>
</div></div></body></html>`;

async function sendSettlementEmail(
  email: string,
  storeName: string,
  amountStr: string,
  txCount: number,
  autoPayoutAccount?: { bankName: string; maskedAccount: string } | null,
) {
  if (!RESEND_API_KEY || !email) return;
  try {
    const hasAutoPayout = !!autoPayoutAccount;
    const subject = hasAutoPayout
      ? `Funds Settled & Auto-Payout Triggered: ${amountStr} 💸`
      : `Funds Settled: ${amountStr} is in your Korra Wallet 🏦`;
    const html = hasAutoPayout
      ? getSettlementAutoPayoutTemplate(storeName, amountStr, txCount, autoPayoutAccount!.bankName, autoPayoutAccount!.maskedAccount)
      : getSettlementWalletTemplate(storeName, amountStr, txCount);

    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${RESEND_API_KEY}` },
      body: JSON.stringify({
        from: `Korra Business <notifications@korra.com.ng>`,
        to: [email],
        subject,
        html,
        tags: [{ name: 'category', value: 'settlement' }],
      })
    });
    if (!res.ok) console.error("Resend API Error:", await res.text());
  } catch (err) {
    console.error("Failed to send settlement email:", err);
  }
}

// ---------------------------------------------------------------------------
// HELPER: AUTO-PAYOUT EMAIL
// ---------------------------------------------------------------------------
async function sendAutoPayoutEmail(
  email: string,
  storeName: string,
  amountStr: string,
  bankName: string,
  maskedAccount: string,
  reference: string,
) {
  if (!RESEND_API_KEY || !email) return;
  const html = `
<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Auto-Payout Sent</title>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;600;700&display=swap" rel="stylesheet">
<style>
  *{box-sizing:border-box;margin:0;padding:0}
  body{background:#EDE8E1;font-family:'DM Sans',sans-serif;padding:24px 8px}
  .wrap{max-width:480px;margin:0 auto}
  .card{background:#FDFAF7;border-radius:12px;overflow:hidden;box-shadow:0 4px 20px rgba(28,13,0,.05)}
  .hero{background:#064E3B;padding:36px 24px 28px;text-align:center}
  .eyebrow{font-size:10px;font-weight:600;letter-spacing:2px;text-transform:uppercase;color:#6EE7B7;margin-bottom:12px;display:block}
  .hero h1{font-size:32px;font-weight:700;color:#ECFDF5;letter-spacing:-1px;margin-bottom:6px}
  .hero p{font-size:14px;color:rgba(236,253,245,.8)}
  .body{padding:32px 24px}
  .row{display:flex;justify-content:space-between;padding:12px 0;border-bottom:1px solid #F0EBE4;font-size:14px}
  .row:last-child{border-bottom:none}
  .label{color:#6B5744;font-weight:500}
  .value{color:#1C0D00;font-weight:600;text-align:right}
  .ref{font-size:11px;color:#9E7F62;margin-top:4px;text-align:right}
  .footer{background:#1C0D00;text-align:center;padding:20px}
  .footer p{font-size:12px;color:rgba(253,246,238,.6)}
  .footer a{color:#C27641;text-decoration:none;font-weight:500}
</style></head><body>
<div class="wrap"><div class="card">
  <div class="hero">
    <span class="eyebrow">Auto-Payout Sent</span>
    <h1>${amountStr}</h1>
    <p>Sent to your linked bank account</p>
  </div>
  <div class="body">
    <div class="row"><span class="label">Store</span><span class="value">${storeName}</span></div>
    <div class="row"><span class="label">Bank</span><span class="value">${bankName}</span></div>
    <div class="row"><span class="label">Account</span><span class="value">${maskedAccount}<div class="ref">Ref: ${reference}</div></span></div>
    <div class="row"><span class="label">Amount</span><span class="value">${amountStr}</span></div>
  </div>
  <div class="footer"><p>© 2026 Korra Business &nbsp;|&nbsp; <a href="mailto:support@korra.com.ng">support@korra.com.ng</a></p></div>
</div></div>
</body></html>`;

  try {
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${RESEND_API_KEY}` },
      body: JSON.stringify({
        from: `Korra Business <notifications@korra.com.ng>`,
        to: [email],
        subject: `Auto-Payout Sent: ${amountStr} is on its way 💸`,
        html,
        tags: [{ name: 'category', value: 'auto_payout' }],
      })
    });
    if (!res.ok) console.error("Resend Auto-Payout Email Error:", await res.text());
  } catch (err) {
    console.error("Failed to send auto-payout email:", err);
  }
}

// ---------------------------------------------------------------------------
// HELPER: PUSH NOTIFICATION
// ---------------------------------------------------------------------------
async function sendPushNotification(fcmToken: any, title: string, body: string) {
  if (!fcmToken) return;
  try {
    const payload = {
      notification: { title, body },
      data: { type: 'settlement', refId: 'batch_settlement' }
    };
    if (Array.isArray(fcmToken) && fcmToken.length > 0) {
      await admin.messaging().sendEachForMulticast({ ...payload, tokens: fcmToken });
    } else if (typeof fcmToken === 'string') {
      await admin.messaging().send({ ...payload, token: fcmToken });
    }
  } catch (err) {
    console.error('FCM Push Error:', err);
  }
}

// ---------------------------------------------------------------------------
// HELPER: AUTO-PAYOUT FOR ONE VENDOR
// ---------------------------------------------------------------------------
async function runAutoPayoutForVendor(
  vendorId: string,
  storeName: string,
  vendorEmail: string | undefined,
  fcmToken: any,
  settledAmount: number,
) {
  try {
    const autoDoc = await db
      .collection('vendors').doc(vendorId)
      .collection('settings').doc('auto_payout_details')
      .get();

    if (!autoDoc.exists) return;

    const auto = autoDoc.data()!;
    const bankCode      = auto['bankCode']      as string | undefined;
    const accountNumber = auto['accountNumber'] as string | undefined;
    const accountName   = auto['accountName']   as string | undefined;
    const bankName      = auto['bankName']      as string | undefined;

    if (!bankCode || !accountNumber || !accountName) return;

    const balance = settledAmount;

    // Threshold check — only auto-payout if settled amount >= ₦10,000
    if (balance < AUTO_PAYOUT_THRESHOLD) return;

    const fee            = balance >= EMTL_THRESHOLD ? GOVT_LEVY : 0;
    const payoutAmount   = balance - fee;
    const totalDeduction = balance;

    const timeStr   = Date.now().toString(36).toUpperCase();
    const userSlice = vendorId.slice(-4).toUpperCase();
    const payoutRef = `AUTOPAYOUT-${timeStr}-${userSlice}`;

    await db.runTransaction(async (t) => {
      const statsRef  = db.collection('vendor_stats').doc(vendorId);
      const freshSnap = await t.get(statsRef);

      const freshBalance = settledAmount;

      if (freshBalance < AUTO_PAYOUT_THRESHOLD) {
        throw new Error('Settled amount below threshold inside transaction — skip');
      }

      const ledgerRef = db
        .collection('vendors').doc(vendorId)
        .collection('ledger_transactions').doc();

      t.set(ledgerRef, {
        amount:           -payoutAmount,
        type:             'auto_payout',
        status:           'pending_monnify',
        settlementStatus: 'cleared',
        reference:         payoutRef,
        description:      `Auto-payout to ${accountName}`,
        createdAt:         admin.firestore.FieldValue.serverTimestamp(),
        balanceBefore:     freshBalance,
        balanceAfter:      freshBalance - payoutAmount,
        metadata: {
          destinationBank:    bankCode,
          destinationAccount: accountNumber,
          destinationName:    accountName,
        }
      });

      if (fee > 0) {
        const feeRef = db
          .collection('vendors').doc(vendorId)
          .collection('ledger_transactions').doc();

        t.set(feeRef, {
          amount:       -fee,
          type:         'fee',
          status:       'success',
          reference:    `FEE-${payoutRef}`,
          description:  'EMTL Government Levy (Auto-Payout)',
          createdAt:    admin.firestore.FieldValue.serverTimestamp(),
          balanceBefore: freshBalance - payoutAmount,
          balanceAfter:  freshBalance - totalDeduction,
        });
      }

      t.update(statsRef, {
        totalPayouts: admin.firestore.FieldValue.increment(totalDeduction),
      });

      const mappingRef = db.collection('monnify_mappings').doc(payoutRef);
      t.set(mappingRef, {
        vendorUid: vendorId,
        type:      'auto_payout',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    const token = await getMonnifyToken();
    const monnifyRes = await fetch(`${MONNIFY_BASE_URL}/api/v2/disbursements/single`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type':  'application/json',
      },
      body: JSON.stringify({
        amount:                   payoutAmount,
        reference:                payoutRef,
        narration:                'Korra Auto-Payout',
        destinationBankCode:      bankCode,
        destinationAccountNumber: accountNumber,
        destinationAccountName:   accountName,
        currency:                 'NGN',
        sourceAccountNumber:      MONNIFY_WALLET_ACCOUNT,
        async:                    false,
      }),
    });

    const monnifyData = await monnifyRes.json();
    console.log(`📤 Auto-payout submitted ${payoutRef} → Monnify raw status: ${monnifyData.responseBody?.status ?? 'unknown'}`);

    const amountStr     = `₦${payoutAmount.toLocaleString('en-US')}`;
    const maskedAccount = `•••• ${accountNumber.slice(-4)}`;

    const actRef = db
      .collection('vendors').doc(vendorId)
      .collection('activity_feed').doc();
    await actRef.set({
      id:             actRef.id,
      type:           'payout_pending',
      title:          'Auto-Payout In Progress ⏳',
      body:           `${amountStr} is being sent to your ${bankName} account (${maskedAccount}). We'll notify you once confirmed.`,
      ref_id:         payoutRef,
      amount_display: `-${amountStr}`,
      date:           admin.firestore.FieldValue.serverTimestamp(),
      is_read:        false,
    });

    await sendPushNotification(
      fcmToken,
      'Auto-Payout In Progress ⏳',
      `${amountStr} is being sent to your ${bankName} account. You will be notified once confirmed.`,
    );

    if (vendorEmail) {
      await sendAutoPayoutEmail(vendorEmail, storeName, amountStr, bankName ?? '', maskedAccount, payoutRef);
    }

    console.log(`✅ Auto-payout ${payoutRef} submitted → ${vendorId} → ${amountStr}`);

  } catch (err: any) {
    if (!err.message?.includes('threshold')) {
      console.error(`❌ Auto-payout failed for vendor ${vendorId}:`, err.message);
    }
  }
}

// ---------------------------------------------------------------------------
// MAIN HANDLER
// ---------------------------------------------------------------------------
serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const vendorsSnap = await db.collection('vendors').get();
    let totalVendorsProcessed     = 0;
    let totalTransactionsSettled  = 0;
    let totalAutoPayoutsTriggered = 0;

    for (const vendorDoc of vendorsSnap.docs) {
      const vendorId   = vendorDoc.id;
      const vendorData = vendorDoc.data();

      const storeName   = vendorData.store?.storeName || "Partner";
      const vendorEmail = vendorData.personal?.email as string | undefined;
      const fcmToken    = vendorData.fcmToken || vendorData.fcmTokens;

      // ── STEP 1: SETTLEMENT ────────────────────────────────────────────────
      const salesSnap = await db
        .collection('vendors').doc(vendorId)
        .collection('ledger_transactions')
        .where('type', '==', 'sale')
        .where('status', '==', 'success')
        .get();

      const promosSnap = await db
        .collection('vendors').doc(vendorId)
        .collection('ledger_transactions')
        .where('type', '==', 'promo_credit')
        .where('status', '==', 'success')
        .get();

      const allPendingDocs = [...salesSnap.docs, ...promosSnap.docs];

      let vendorTotalCleared = 0;
      let vendorClearedCount = 0;
      const batch = db.batch();

      allPendingDocs.forEach(doc => {
        const txData = doc.data();
        if (txData.settlementStatus === 'pending') {
          vendorTotalCleared += (txData.amount || 0);
          vendorClearedCount++;
          batch.update(doc.ref, {
            settlementStatus: 'cleared',
            settledAt:        admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      });

      if (vendorClearedCount > 0) {
        const amountDisplay = `₦${vendorTotalCleared.toLocaleString('en-US')}`;

        const activityRef = db
          .collection('vendors').doc(vendorId)
          .collection('activity_feed').doc();
        batch.set(activityRef, {
          id:             activityRef.id,
          type:           'payment',
          title:          'Funds Settled 🏦',
          body:           `${amountDisplay} from ${vendorClearedCount} recent sale(s) has cleared and is now available to withdraw.`,
          ref_id:         'batch_settlement',
          amount_display: `+${amountDisplay}`,
          date:           admin.firestore.FieldValue.serverTimestamp(),
          is_read:        false,
        });

        await batch.commit();

        await sendPushNotification(
          fcmToken,
          "Funds Settled 🏦",
          `${amountDisplay} from ${vendorClearedCount} recent transaction(s) has cleared! You can now request a payout.`,
        );

        // ── STEP 2: AUTO-PAYOUT ───────────────────────────────────────────────
        const autoPayoutDoc = await db
          .collection('vendors').doc(vendorId)
          .collection('settings').doc('auto_payout_details')
          .get();

        // ✅ BUG FIX: Only set autoPayoutInfo if amount meets threshold
        // Below ₦10,000 → wallet email (no bank transfer, regardless of account setup)
        // At or above ₦10,000 with bank account → auto-payout email + bank transfer
        let autoPayoutInfo: { bankName: string; maskedAccount: string } | null = null;
        if (autoPayoutDoc.exists && vendorTotalCleared >= AUTO_PAYOUT_THRESHOLD) {
          const autoData = autoPayoutDoc.data()!;
          const accNum   = autoData['accountNumber'] as string ?? '';
          autoPayoutInfo = {
            bankName:      autoData['bankName'] as string ?? '',
            maskedAccount: accNum.length >= 4 ? `•••• ${accNum.slice(-4)}` : accNum,
          };
        }

        if (vendorEmail) {
          await sendSettlementEmail(vendorEmail, storeName, amountDisplay, vendorClearedCount, autoPayoutInfo);
        }

        totalVendorsProcessed++;
        totalTransactionsSettled += vendorClearedCount;

        if (autoPayoutDoc.exists && vendorTotalCleared >= AUTO_PAYOUT_THRESHOLD) {
          await runAutoPayoutForVendor(vendorId, storeName, vendorEmail, fcmToken, vendorTotalCleared);
          totalAutoPayoutsTriggered++;
        }
      }
    }

    return new Response(JSON.stringify({
      message:               "Settlement + auto-payout process complete.",
      vendorsProcessed:       totalVendorsProcessed,
      transactionsSettled:    totalTransactionsSettled,
      autoPayoutsTriggered:   totalAutoPayoutsTriggered,
    }), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });

  } catch (error: any) {
    console.error("Settlement Cron Error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: corsHeaders,
    });
  }
});