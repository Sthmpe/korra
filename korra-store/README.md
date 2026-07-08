# Korra Store Website

Public, SEO-indexable storefront pages for Korra merchants. Serves the
per-merchant store pages that the app's share links and Android App Links point
to.

**Scope: this app owns ONLY `/store/*`.** The existing Korra landing page keeps
the apex (`korra.com.ng/`). Deploy this behind a reverse proxy / rewrite so
`korra.com.ng/store/*` → this app, and `/` stays on the landing.

- `korra.com.ng/store/{slug}` — a merchant's public storefront (SSR, indexable)
- `korra.com.ng/store` — redirects to `/` (the existing landing; no slug = no store)
- `korra.com.ng/.well-known/assetlinks.json` — Android App Links verification
- `korra.com.ng/sitemap.xml`, `/robots.txt` — SEO

Built with **Next.js (App Router)** — React with server-side rendering, which is
what makes the store pages crawlable/indexable (a plain client-only React SPA
would not be). Data is read from Firestore via its public REST API (no SDK
bundle); the page mirrors the app storefront (cover, glass logo, Top Seller /
Most Visited / Highlighted badges, rating, walk-in location, contact chips,
featured strip, product grid) from the same `vendors`, `products`,
`vendor_visibility` and reviews the app uses.

## Browse-first, pay-in-app

The website is for **browsing + SEO** — anyone can view a store and its products
with no login. The Korra hand-off happens only at **pay intent**: the "Reserve
on Korra" button opens the app (Android App Link → Play Store fallback) or the
customer web app (iOS/desktop), where sign-up + checkout live. There is no web
checkout here by design.

## Setup

```bash
cd korra-store
cp .env.example .env.local   # values already default to Korra PROD
npm install
npm run dev                  # http://localhost:3000
```

Try `http://localhost:3000/store/<a-real-slug>` with a slug that exists in
Firestore (or a raw vendor uid — the resolver falls back to uid like the app).

## Environment

See `.env.example`. The Firebase web API key + project id are public (reads are
gated by Firestore security rules). If a store page shows no products, the
Firestore rules likely block unauthenticated reads — allow public reads of
`approved` products and the `vendors` store profile.

## Deploy

Any Node host (Vercel recommended). Point the `korra.com.ng` apex domain here.
The subdomains stay separate: `app.korra.com.ng` (customer PWA) and
`business.korra.com.ng` (merchant PWA) — the site links out to those, it does
not host them.

## ⚠️ Android App Links — finish the assetlinks fingerprint

`public/.well-known/assetlinks.json` currently has a placeholder fingerprint.
For Android to auto-verify `korra.com.ng/store/*` and open the customer app,
replace `REPLACE_WITH_RELEASE_SIGNING_SHA256_FINGERPRINT` with the **release
signing certificate SHA-256** for the customer app:

```bash
keytool -list -v -keystore <release-keystore> -alias <alias>
# copy the SHA-256, keep the colons, e.g. AB:CD:12:...
```

Package names are already set: `com.korra.shop.live` (live) and `com.korra.shop`
(dev). iOS is intentionally excluded — iOS/desktop visitors are sent to the
customer web app (`app.korra.com.ng`) by the "Continue in Korra" button.

## Notes

- No secrets in this repo. The service uses only the public Firebase web config.
- Store pages revalidate every 5 min (ISR) so merchant edits appear without a
  redeploy.
- Suspended/banned stores (per `vendor_compliance`) render an "unavailable"
  notice and nothing else — matching the in-app suspension gate.
