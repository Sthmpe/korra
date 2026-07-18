# 🚀 Korra — Session Handover Document
> **Date:** 3 July 2026  
> **Purpose:** Complete technical handover so any developer (or AI session) can pick up exactly where we left off without asking "what did we do?" ever again.

> [!NOTE]
> **Terminology (as of 3 July 2026):** The vendor "Reservations" tab has been renamed to **"Orders"**. All references to "Fulfilled/Fulfill" in the vendor UI are now **"Delivered/Deliver"**. The `plans` Firestore collection is for **layaway/installment orders only**. A separate `orders` collection (TBD) will handle outright purchases. The `isOutright` getter has been removed from the `Reservation` model.

> [!WARNING]
> Only focus on the active conversation, `SESSION_HANDOVER.md`, and the `implementation_plan.md` artifact. Ignore all other `.md` files in the root directory (such as `BATCH1_SCAN.md` or `MONNIFY_MIGRATION.md`) as they are outdated reference files.

> [!IMPORTANT]
> **CRITICAL AGENT RULES:**
> 1. **BACKGROUND TASKS & MCP:** Do NOT run any background tasks or MCP server tools (including `analyze_files` or `flutter analyze` terminal commands) without asking the user first.
> 2. **WIDGET DECOMPOSITION:** Always split and decompose large widget trees into separate files in their respective `/widgets/` directory. Do not write inline method widgets or put large complex widget blocks inside a single page file. Keep page files lean (under 500 lines) and optimized for memory/performance.
> 3. **SCOPE LIMITS:** Focus strictly on this active conversation, `SESSION_HANDOVER.md`, and the `implementation_plan.md` artifact. Avoid looking at or editing other `.md` files (like `BATCH1_SCAN.md` or `MONNIFY_MIGRATION.md`). Keep UI styles and business logic 100% identical. Never assume code is wrong; ask the user first.

---

## 1. What Is Korra?

Korra is a **buy-now-pay-later (BNPL) / layaway mobile app** built in Flutter. It operates as a **two-sided marketplace**:

- **Customers** browse vendor product links, create a savings/instalment plan for an item, pay in chunks, and receive the item after full or milestone payment.
- **Vendors (Merchants)** list products, generate shareable product links, receive plan reservations, track active plans, manage payouts, and monitor their dashboard stats.

**The core loop:**
1. Vendor lists a product → gets a unique `K-XXXX-XXXXXXX` product code.
2. Customer pastes the link → app fetches the product → Risk Engine calculates minimum down payment.
3. Customer pays down payment → plan is created → vendor sees the reservation.
4. Customer pays instalments → vendor gets paid out on T+1 settlement.

---

## 2. Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter (Dart) — Multi-flavor (customer + vendor APKs from one codebase) |
| **State Management** | BLoC + Cubit (`flutter_bloc ^9.1.1`) |
| **Auth** | Firebase Auth (email/password + Google Sign-In) |
| **Primary Database** | Cloud Firestore (users, plans, products, reservations) |
| **Backend / Edge Functions** | Supabase Edge Functions (TypeScript) |
| **Payment Gateway** | Monnify |
| **Analytics** | Firebase Analytics (`firebase_analytics ^12.4.3`) |
| **Push Notifications** | Firebase Cloud Messaging (`firebase_messaging ^16.0.4`) |
| **Storage** | Firebase Storage (product images) + Supabase Storage |
| **Risk Engine** | Custom Supabase Edge Function (`plan.ts`) — computes min down payment, issues `secureToken` JWT |
| **Routing** | GetX (`get ^4.7.2`) |
| **Responsive Sizing** | `flutter_screenutil ^5.9.3` |

---

## 3. Project Structure

```
lib/
├── bootstrap.dart          # App init (Firebase, dotenv, etc.)
├── main_customer.dart      # Entry point for Customer flavor
├── main_vendor.dart        # Entry point for Vendor flavor
├── korra_app.dart          # Root app widget (flavored routing)
├── config/
│   ├── constants/          # PrefsKeys, app constants
│   └── utils/              # KorraException, currency formatters, validators
├── data/
│   ├── models/             # Dart model classes
│   │   ├── customer/       # plans.dart, payment_receipt_data.dart
│   │   └── vendor/         # reservation.dart, vendor_stat.dart, payout/
│   └── repository/         # All data access abstraction
│       ├── customer/       # CustomerRepository, PlansRepository, VerificationRepo
│       └── vendors/        # VendorRepository, ProductRepository, TransferRepo, etc.
├── logic/
│   ├── bloc/               # All BLoC state machines (see §4)
│   │   ├── auth/           # role_login, signup_customer, signup_vendor, forgot_password
│   │   ├── customer/       # plans, kyc, link, home, profile, change_password
│   │   └── vendor/         # home, product, payout, reservation, profile, image
│   ├── cubit/              # Simple state holders
│   ├── core/net/           # NetCubit (connectivity monitoring)
│   ├── services/           # Background services
│   └── korra_risk_engine/  # Risk engine logic (mirrors edge function)
├── presentation/
│   ├── auth/               # Login, signup, forgot password screens
│   ├── customer/           # Customer-side UI (home, plans, KYC, profile)
│   └── vendor/             # Vendor-side UI (dashboard, products, reservations, payout)
├── flavors/                # Flavor config (customer vs vendor)
└── app_secrets.dart        # API keys loader (reads from .env)
```

---

## 4. BLoC Architecture — Complete Map

### Auth BLoCs

| File | Events | Key States |
|---|---|---|
| `role_login_bloc.dart` | `RoleSelected`, `EmailChanged`, `PasswordChanged`, `SubmitPressed`, `GoogleLoginPressed`, `BiometricsPressed` | `LoginStatus.idle/submitting/success/failure`, `isNewUser`, `role` |
| `signup_customer_bloc.dart` | `SignupCustomerSubmitPressed`, field change events | `SignupStatus.loading/success/failure`, multi-page (`pageIndex`) |
| `signup_vendor_bloc.dart` | `SignupVendorSubmitPressed`, store/personal/social events | `SignupStatus.loading/success/failure`, multi-page |
| `forgot_password_bloc.dart` | `FPEmailChanged`, `FPSubmit` | `FPStatus.editing/submitting/sent/error` |

### Customer BLoCs

| File | Events | Key States |
|---|---|---|
| `create_plan_bloc.dart` | `LoadPlanPreview`, `ConfirmPlanCreation` | `CreatePlanStatus.*`, `secureToken`, `riskEngineUpfront`, tier data |
| `pay_plan_bloc.dart` | `PayInstallmentConfirmed` | `PayPlanStatus.*`, `receiptData` |
| `plan_action_bloc.dart` | `PayInstallmentRequested`, `CancelPlanRequested` | `PlanActionStatus.*` |
| `plan_action_cubit.dart` | `convertToStoreCredit()`, `extendPlan()` | `PlanActionInitial/Loading/Success/Error` |
| `customer_kyc_bloc.dart` | `VerifyBvnClicked`, `VerifyNinClicked`, `SavePhoneClicked` | BVN/NIN verification states |
| `link_bloc.dart` | `LinkSubmitted`, `LinkValidated` | `LinkStatus.validating/valid/invalid/loadingProduct/loaded/failed` |
| `home_bloc.dart` | `HomeStarted`, `PasteLinkSubmitted`, `WalletBalanceUpdated` | `HomeStatus.*` |
| `change_password_bloc.dart` | `ChangePasswordSubmitted` | `ChangePassStatus.*` |

### Vendor BLoCs

| File | Events | Key States |
|---|---|---|
| `vendor_home_bloc.dart` | `VendorHomeStarted`, `VendorLedgerUpdated`, `VendorStatsUpdated` | Wallet balance, locked funds, withdrawable, upcoming releases |
| `vendor_products_bloc.dart` | `VendorProductsAdd/Edit/Delete/DeleteMultiple`, pagination, filter/search | `ProductFlow.idle/delete`, `isSubmitting`, `success`, `items[]` |
| `payout_bloc.dart` | `PayoutStarted`, `WithdrawClicked`, `PinSubmitted`, `NewPinCreated`, BVN/NIN events | `PayoutStatus.*`, `PayoutStep.input/verifyPin/createPin/processing/completed` |
| `reservations_bloc.dart` | `ResStarted`, `ResRefresh`, `ResChangeFilter`, `ResLoadMore`, `ResMarkFulfilled` | Paginated reservations, `VerificationStatus`, tab counts |

---

## 5. Firebase Analytics — What We Added This Session

`firebase_analytics ^12.4.3` was already in `pubspec.yaml`. We instrumented events across all BLoCs using `FirebaseAnalytics.instance.logEvent(name: '...', parameters: {...})`.

### Auth Events
| Event | File | Parameters |
|---|---|---|
| `login_success` | `role_login_bloc.dart` | `role`, `method` (email/google) |
| `login_failed` | `role_login_bloc.dart` | `method`, `error_code` |
| `sign_up` | `signup_customer_bloc.dart` | `method`, `role: customer` |
| `sign_up` | `signup_vendor_bloc.dart` | `method`, `role: vendor` |
| `signup_failed` | both signup blocs | `role`, `error_message` |

### Plan Events (Customer)
| Event | File | Parameters |
|---|---|---|
| `plan_preview_loaded` | `create_plan_bloc.dart` | `product_id`, `product_price`, `min_downpayment`, `has_active_plans` |
| `plan_created` ⭐ | `create_plan_bloc.dart` | `product_id`, `value` (price), `vendor_id`, `downpayment`, `loan_amount`, `duration_days` |
| `plan_creation_failed` | `create_plan_bloc.dart` | `error_message` |
| `installment_paid` | `pay_plan_bloc.dart`, `plan_action_bloc.dart` | `plan_id`, `amount` |
| `installment_payment_failed` | `pay_plan_bloc.dart` | `plan_id`, `amount`, `error_message` |
| `plan_cancelled` | `plan_action_bloc.dart` | `plan_id`, `reason` |
| `plan_converted_to_store_credit` | `plan_action_cubit.dart` | `plan_id` |
| `plan_extended` | `plan_action_cubit.dart` | `plan_id` |

### KYC Events
| Event | File | Parameters |
|---|---|---|
| `kyc_bvn_verified` | `customer_kyc_bloc.dart` | `customer_uid` |
| `kyc_nin_verified` | `customer_kyc_bloc.dart` | `customer_uid` |

### Vendor Events
| Event | File | Parameters |
|---|---|---|
| `product_added` | `vendor_products_bloc.dart` | `vendor_id`, `product_name`, `price`, `category` |
| `product_deleted` | `vendor_products_bloc.dart` | `vendor_id`, `product_id` |
| `products_deleted_bulk` | `vendor_products_bloc.dart` | `vendor_id`, `count` |
| `payout_initiated` | `payout_bloc.dart` | `amount`, `vendor_id`, `bank_code` |
| `payout_failed` | `payout_bloc.dart` | `amount`, `error_message` |

> The `plan_created` event intentionally mirrors the GA4 standard `purchase` event schema — use `value` for price so Firebase dashboards can auto-aggregate revenue.

---

## 6. The Risk Engine (CRITICAL — Read This)

The Risk Engine runs as a **Supabase Edge Function** (`plan.ts` in root), **not in Flutter**.

**Flow:**
1. `LoadPlanPreview` event → `repo.fetchPlanPreview()` → calls Supabase Edge Function
2. Edge Function returns `{ minDownPayment: double, secureToken: string }`
3. `secureToken` is a **JWT handshake token** stored in `CreatePlanState.secureToken`
4. `ConfirmPlanCreation` event → `repo.createPlanSecurely()` sends Plan data + `secureToken`
5. Edge Function validates token server-side → rejects if tampered → prevents price manipulation

**Fallback Tier Logic (used when merchant has no custom settings):**

| Price Range | Duration | Notice | Extension |
|---|---|---|---|
| ≤ ₦50,000 | 14 days | 3 days | None |
| ≤ ₦200,000 | 21 days | 3 days | 5 days |
| ≤ ₦500,000 | 30 days | 3 days | 7 days |
| ≤ ₦750,000 | 60 days | 3 days | 7 days |
| > ₦750,000 | 90 days | 3 days | 7 days |

Merchants can **override** tier logic by setting `merchantDurationDays`, `extensionDays`, `noticeDays` on their product listing.

---

## 7. Multi-Flavor Setup

One codebase → two APKs:

| Flavor | Entry Point | APK Name | Target |
|---|---|---|---|
| `customer` | `main_customer.dart` | `app-customer-release.apk` | End users |
| `merchant` | `main_vendor.dart` | `app-merchant-release.apk` | Merchants |

**Build & Run commands:**

*   **Local Debug (Mobile)**:
    ```bash
    # Customer
    flutter run --flavor customer -t lib/main_customer.dart --dart-define=IS_LIVE=false
    
    # Vendor (Merchant)
    flutter run --flavor merchant -t lib/main_vendor.dart --dart-define=IS_LIVE=false
    ```

*   **Local Debug (Web)**:
    ```bash
    # Customer
    flutter run -d chrome -t lib/main_customer.dart --dart-define=IS_LIVE=false
    
    # Vendor (Merchant)
    flutter run -d chrome -t lib/main_vendor.dart --dart-define=IS_LIVE=false
    ```

*   **Production Release (APKs)**:
    ```bash
    # Customer
    flutter build apk --flavor customer -t lib/main_customer.dart --release --dart-define=IS_LIVE=true
    
    # Vendor (Merchant)
    flutter build apk --flavor merchant -t lib/main_vendor.dart --release --dart-define=IS_LIVE=true
    ```

*   **Production Release (Split APKs - Reduced Size)**:
    ```bash
    # Customer
    flutter build apk --flavor customer -t lib/main_customer.dart --release --split-per-abi --dart-define=IS_LIVE=true
    
    # Vendor (Merchant)
    flutter build apk --flavor merchant -t lib/main_vendor.dart --release --split-per-abi --dart-define=IS_LIVE=true
    ```

*   **Production Release (App Bundle - AAB for Play Store)**:
    ```bash
    # Customer
    flutter build appbundle --flavor customer -t lib/main_customer.dart --release --dart-define=IS_LIVE=true
    
    # Vendor (Merchant)
    flutter build appbundle --flavor merchant -t lib/main_vendor.dart --release --dart-define=IS_LIVE=true
    ```

*   **Production Release (Web)**:
    ```bash
    # Customer
    flutter build web --release -t lib/main_customer.dart --dart-define=IS_LIVE=true --no-tree-shake-icons
    
    # Vendor (Merchant)
    flutter build web --release -t lib/main_vendor.dart --dart-define=IS_LIVE=true --no-tree-shake-icons
    ```

*   **Static Analysis**:
    ```bash
    flutter analyze lib/
    ```

---

## 8. Environment / Secrets

Files: `.env`, `.env.prod`, `.env.local` — loaded via `flutter_dotenv`.

> ⚠️ These are in the repo. Don't push to a public repo without rotating keys.

Firebase config: `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` — standard Firebase setup.

---

## 9. What Works (Production-Ready)

✅ Email + Google Sign-In (Firebase Auth) for both roles  
✅ Role isolation — accounts are cross-checked, vendor can't log in as customer  
✅ Multi-step vendor signup (3 steps: Personal → Store Details → Socials + T&C)  
✅ Multi-step customer signup (2 steps: Personal → Review)  
✅ Product creation by vendors (image upload to Firebase Storage)  
✅ Product link generation (`K-XXXX-XXXXXXX` codes)  
✅ Link validation + product fetch by customers  
✅ Risk Engine — min down payment via Supabase Edge Function  
✅ Plan creation with secureToken JWT handshake  
✅ Instalment payments from customer wallet  
✅ Plan cancellation → funds go to Store Balance  
✅ Store Credit / Store Balance system  
✅ Plan extension (when merchant allows it)  
✅ Vendor real-time ledger (stream-based, fires `VendorLedgerUpdated`)  
✅ T+1 settlement logic (locked funds release next day)  
✅ Payout to bank via Monnify  
✅ Transaction PIN for vendor withdrawals  
✅ BVN/NIN verification via Supabase  
✅ Vendor reservations with pagination + bulk fulfilment marking  
✅ Product pagination (load-more, 10 items at a time)  
✅ Push notifications (FCM setup complete, restructured as a singleton service to prevent double init)  
✅ Firebase Analytics across all BLoCs (added this session)  
✅ Design system tokens partially implemented (KorraColors, KorraSizes, KorraPaddings, Gaps, KorraIcons)
✅ Startup optimization via LazyIndexedStack in customer and vendor shell interfaces

---

## 10. Known Issues / Technical Debt

### 🔴 CRITICAL
* No critical issues. Paystack workaround has been completely removed as dead code; Monnify integration is fully active.

### 🟡 IMPORTANT
* **Phase 2.2 — Split `VendorRepository` and `CustomerRepository`**: Further decompose these God classes into focused repositories (e.g. `VendorAuthRepository`, `VendorProductRepository`, etc.).
* **Phase 3.5 — Fix `StreamBuilder` in `VendorHomePage` AppBar**: Wrap only the notification badge `Container` rather than rebuilding the full AppBar on notification count updates.

### 🟢 MINOR
* Biometric auth in `role_login_bloc.dart` is a **mock** (fake delays + success). Not wired to `local_auth`.
* `home_bloc.dart` `_onStarted` has empty stub — load logic not implemented.
* `dart:math` imported but unused in `vendor_products_bloc.dart` — remove to fix lint.

---

## 11. Database Schema (Firestore)

See `DATABASE_SCHEMA.md` for full schema. Quick reference:

**Collections:**
- `customers/{uid}` — personal data, KYC flags, wallet reference
- `vendors/{uid}` — personal data, store info, KYC, settings, payout details
- `plans/{planId}` — full plan lifecycle (see `Plan` model in `lib/data/models/customer/plans.dart`)
- `products/{productCode}` — product listings
- `reservations/{reservationId}` — plan-product link for vendor view
- `ledger/{vendorId}/entries/{entryId}` — vendor transaction ledger (real-time streamed)

Security rules: see `firebase_rule.txt` in project root.

---

## 12. Supabase Edge Functions

| Root File | Purpose |
|---|---|
| `plan.ts` | Risk engine: min down payment, `secureToken`, create/pay plans |
| `monnify-webhook.ts` | Monnify webhook handler (when live) |
| `vendor-transaction-ops.ts` | Vendor payout processing (Monnify) |
| `process-settlements.ts` | T+1 settlement — releases locked funds |

---

## 13. Git Branches

- **`clean-architecture`** — active development branch, all current work is here
- `main` — not used directly, don't push to it

---

## 14. How to Run the Project

```bash
# 1. Install dependencies
flutter pub get

# 2. Run customer app (debug - mobile)
flutter run --flavor customer -t lib/main_customer.dart --dart-define=IS_LIVE=false

# 3. Run customer app (debug - web)
flutter run -d chrome -t lib/main_customer.dart --dart-define=IS_LIVE=false

# 4. Run vendor app (debug - mobile)
flutter run --flavor merchant -t lib/main_vendor.dart --dart-define=IS_LIVE=false

# 5. Run vendor app (debug - web)
flutter run -d chrome -t lib/main_vendor.dart --dart-define=IS_LIVE=false

# 6. Build release APKs (production)
flutter build apk --flavor customer -t lib/main_customer.dart --release --dart-define=IS_LIVE=true
flutter build apk --flavor merchant -t lib/main_vendor.dart --release --dart-define=IS_LIVE=true

# 7. Build release split-APKs (production - split by ABI)
flutter build apk --flavor customer -t lib/main_customer.dart --release --split-per-abi --dart-define=IS_LIVE=true
flutter build apk --flavor merchant -t lib/main_vendor.dart --release --split-per-abi --dart-define=IS_LIVE=true

# 8. Build release App Bundles (production - AAB)
flutter build appbundle --flavor customer -t lib/main_customer.dart --release --dart-define=IS_LIVE=true
flutter build appbundle --flavor merchant -t lib/main_vendor.dart --release --dart-define=IS_LIVE=true

# 9. Build release Web app (production)
flutter build web --release -t lib/main_customer.dart --dart-define=IS_LIVE=true --no-tree-shake-icons
flutter build web --release -t lib/main_vendor.dart --dart-define=IS_LIVE=true --no-tree-shake-icons

# 10. Analyze for issues
flutter analyze lib/
```

`.env` and `.env.prod` are already in the project root. `flutter_dotenv` loads them automatically.

---

## 15. Key Refactoring Rules (from `REFACTOR_RULES.md`)

1. **Never hardcode** colors, sizes, or strings — use design system tokens
2. **BLoC for all async state** — no `setState` in screens
3. **Repository pattern** — BLoCs never talk directly to Firestore/Supabase
4. **KorraException** for user-facing error messages — never expose raw SDK error strings
5. **secureToken handshake** — all financial operations must go through server-validated token flow

---

## 16. Compacted History — 3–5 July 2026 (all rounds summarized; full details live in git history)

> This section replaces the old round-by-round log, which had grown past 1,000 lines. Nothing pending was dropped — see §17 for the live backlog. Future sessions: append SHORT dated updates below §18; when the file gets long again, re-compact the same way.

### 3 July — Foundation & vendor-side session
- **Terminology**: vendor "Reservations" tab → **"Orders"**; "Fulfilled/Fulfill" → **"Delivered/Deliver"**. `plans/` collection = layaway/installments ONLY; `orders/` collection = outright purchases (model: `OutrightOrder`, multi-item). `isOutright` getter removed from `Reservation`.
- Firebase Analytics instrumented across all BLoCs (see §5). `plan_created` mirrors GA4 `purchase` schema.
- Perf/architecture pass: `LazyIndexedStack` in both shells; `NotificationService` → GetX singleton; GoogleFonts family cached in `KorraTextStyles.inter`; repositories exposed via root `RepositoryProvider` and all screens converted to `context.read<...>()` (no repo constructor params anywhere); repos split into extension files; R8 full mode; routes split into `common_pages.dart` / `customer_pages.dart` / `vendor_pages.dart` for tree-shaking; unused assets moved to `unused_assets/`, `lottie` removed.
- Massive widget decomposition: create-plan, plan-details (1,372 → ~340 lines), add/edit product, KYC shared fields (`lib/presentation/shared/widgets/kyc/`), vendor home, profile pages. **Standing rule: keep page files lean, decompose to `/widgets/`.**
- `KorraHeader` back action uses native `Navigator.pop(context)`; header supports an expanding in-title search mode (used by vendor Orders page).
- **Vendor Orders page**: horizontal `PageView` — panel 0 Reservations (`plans/`), panel 1 Outright Orders (`orders/`), switched by `orders_panel_switcher.dart`; `OutrightOrdersRepository` + `OutrightOrdersBloc`; detail sheets with delivery actions.
- **Storefront fee policy**: reservations = 3.5% fee always on customer (non-configurable). Outright = merchant toggle `vendors/{uid}/store.absorbOutrightFee` (customer pays 3.5% capped ₦7,500, or merchant absorbs). Checkout/payout wiring for this is still backend TODO.
- **Merchant marketing suite**: `vendor_visibility/{vendorId}` model (`topSellerCircles`, `mostVisitedCircles`, `isHighlighted`), campaigns CRUD (`campaigns` collection, 24h active, max 3, banner photo required, tag/caption char limits), reach cards, highlighted-store promo. Vendor Reviews tab streams `vendors/{uid}/reviews`.
- **Customer storefront v1** (Plan E): `/store/:slug` named route, Stores tab added to shell (`Home, Plans, Stores, Profile`), masonry grid (`SliverMasonryGrid`), featured products (`isFeatured`/`campaignTag`/`discountedPrice` on product model + merchant switches), product details sheet, per-store Firestore carts (later replaced by local CartService), category circles, price sort.
- ⚠️ **Firestore rules must be deployed from `firebase_rule.txt`** whenever new paths are added (my_vendors, carts, orders, reviews, campaigns, vendor_visibility) — otherwise PERMISSION_DENIED.

### 4 July — Premium storefront overhaul (Rounds 1–4)
- **Design language locked** (see `design.md` + deals_page.dart): borderless floating white cards on `KorraColors.surface`, 16–24r radii, `Colors.black.withValues(alpha: 0.05)` shadows (blur ~14, offset 0,5), Inter w800 headers, tinted chips, generous whitespace. **David dislikes border lines — avoid `Border.all` unless truly the best option.**
- `StorefrontLazyImage`: blur placeholder + brand progress line + `memCacheWidth` downsizing + `Image.network` fallback on cache errors. Used everywhere images render.
- Product cards: gallery cycling ONLY while hovered (web) or touch-held (mobile, raw `Listener` + live hit-testing — David rejected idle autoplay); lift on press; sold-out veil; low-stock chip. Split into `storefront_product_card.dart` + `storefront_card_image.dart`.
- Parallax collapsing `SliverAppBar` with dark-brand glass logo card (`storefront_sliver_app_bar.dart`); glass icon buttons; custom positioned collapse title.
- Stores tab: gradient hero header w/ floating search (`store_hero_header.dart`, faded watermark icons), rebuilt `discover_store_list_item.dart` (gradient-ring logo, 3 product thumbs, Visit Store CTA).
- Details sheet + cart sheet premium rebuilds; **checkout confirm dialog**; purchase history sheet merges `plans` (RESERVATION chip) + `orders` (OUTRIGHT chip) streams.
- **Freeze fixes applied** (from the Round 3 static investigation): plan-details `_dismissTopSheetIfAny` (pop only a covering sheet, never blind-pop) + `_showSnackbarSafely` (defer Get.snackbar past the transition); profile page stream cached + `listenWhen` on message/status; storefront pin listener cancelled in dispose. Findings #5 (NetCubit rebuilds) & #6 (global GestureDetector) were fixed 5 July / still open respectively.
- **Demo marketplace** (`lib/data/demo/` — `DemoMarketplace.enabled` master switch, ids prefixed `demo`, in-memory ONLY, never written to Firebase): 30 named stores + deterministic products/campaigns/reviews/visibility/network. To remove demo mode: delete `lib/data/demo/` and the `DemoMarketplace.enabled` call sites (grep it). Never complete a demo reservation (would write a real plan).
- **Hot Deals strip** on Stores tab (campaigns <24h joined to already-streamed vendors, tags only — no campaign titles) + shared `KorraCampaignTags` (config/constants/campaign_tags.dart; flash-like tags get solid bolt chip; merchant sheet uses same presets).
- **Cart**: `CartService` persists to SharedPreferences (`korra_saved_carts_v2`, 7-day expiry); store balance ALWAYS applied first, wallet covers the rest; insufficient → black "Fund Wallet" CTA → bank details; `SignalBadgeDot` pulses on the Stores nav tab and cart-pending stores rank first with "In your cart" pill. Checkout is still UI-only (no orders write).

### 5 July — Device-QA fixes + Reviews/Badges (Rounds 5–8)
- **🚨 CRITICAL NAV RULE (cost us three bugs): EVERY navigation in this app must be a NAMED GetX route (`Get.toNamed`).** Anonymous `Get.to(() => Page())` throws "Null check operator used on a null value" (GetX 4.x + getPages). Raw `Navigator.push(MaterialPageRoute)` corrupts GetX gesture bookkeeping under Android predictive back → `'_userGesturesInProgress > 0'` assertion → wedged navigator → app renders but ignores ALL taps. Routes added: `Routes.customerDeals` (`/customer/deals`), `Routes.customerStoreReviews` (`/customer/store-reviews`).
- **🚨 STREAM RULE**: never build a Firestore `.snapshots()` inline in `build` — every setState recreates it and the StreamBuilder blanks to `waiting`. Cache in state (see `_productStreamFor` in storefront_screen.dart, which also retains `_lastProductDocs` during page loads).
- **🚨 BUTTON RULE**: the global theme sets ElevatedButton `minimumSize: Size.fromHeight(54)` → min width infinity. Any ElevatedButton inside a Row MUST override `minimumSize: Size.zero` (+ `tapTargetSize: shrinkWrap`) or it crashes with "BoxConstraints forces an infinite width".
- RenderFlex overflows on his phone taught: never fixed `.h` heights around width-driven content — use `AspectRatio`, `Expanded`, `mainAxisSize.min`. Featured-strip product cards use `fixedHeight`/`expand` flags so the image flexes and price/name never clip.
- Hot Deals strip = snapping `PageView` carousel (viewportFraction 0.72, 3.2s timer, loops to start, pauses on touch AND when route not current). Deals page paginated 6/page; Stores tab = lazy CustomScrollView slivers 10/page; storefront feed paginates 20/page. `RepaintBoundary` on carousel/deal/store cards.
- **Storefront Filter & Sort sheet** (`storefront_filter_sheet.dart`): sort chips, campaign-deals-only toggle, customer-typed ₦ min/max (David explicitly chose NOT to auto-compute store min/max — avoids full catalog load).
- **Ratings & Reviews**: always-visible rating line in storefront header → `StoreReviewsScreen` (summary card w/ distribution bars, 10/page, tolerant mapper: `comment` OR legacy `review`, num ratings). **Review composer** (`storefront_review_composer.dart`): purchase-gated (limit-1 checks on `orders` then `plans` by customerId+vendorId; demo always eligible), stars REQUIRED / comment OPTIONAL, one review per customer (doc id = uid at `vendors/{id}/reviews/{uid}`, set-merge), existing review shows "Do you want to change your review?" and edit mode blanks the old comment. Demo reviews save session-only via `DemoMarketplace.saveMyDemoReview`.
- **Badges**: `store_badge.dart` — Top Seller (gold crown) / Most Visited (blue eye) / Highlighted (purple star); earned ALWAYS ranks above paid Highlighted; no customer-facing numbers; no badge → render nothing (absence ≠ penalty). Streams `vendor_visibility/{vendorId}`; demo via `visibilityFor`. Rendered in storefront header.
- **"Recommended From Your Stores"** rail on Stores tab: STRICT boundary — only merchants in `customers/{uid}/my_vendors`, never discovery; only badge-holders shown, ranked earned-first; memoized visibility fetch. Real subscription/per-network computation drops into `badgesFromVisibility` later without UI rework.
- David hand-edited store_badge.dart + storefront_reviews_section.dart to remove chip/card borders — intentional, keep.

---

## 17. 📌 LIVE TODO BACKLOG (everything still open as of 5 July 2026)

1. **Cart checkout backend**: real `orders` collection write (multi-item per `OutrightOrder`), server-side wallet + store-credit deduction (store balance first), `availableStock` decrement, honour `absorbOutrightFee`. Current confirm flow only clears the local cart.
2. **Customer outright order details view** — purchase-history order entries have no tap destination.
3. **Flash Deals countdown strip** on the storefront feed (`KorraCampaignTags.flashLike` already exists; countdown UI remains). Temu-style urgency.
4. **Server-side product search** once catalogs outgrow client-side page filtering.
5. **Firestore rules + composite index** for the customer-side `orders` query (customerId + vendorId).
6. **Freeze finding #6**: global translucent `GestureDetector` in korra_app.dart (redundant gesture-arena work). (#5 NetCubit was fixed 5 July — see §18.)
7. **Customer READ rules** for `campaigns` (Hot Deals strip degrades to demo-only if denied).
8. **Demo cleanup** when demo phase ends: delete `lib/data/demo/` + `DemoMarketplace.enabled` call sites.
9. **Server-side deals pagination** if `campaigns` grows well beyond ~30 active docs.
10. **Customer WRITE rule** for `vendors/{id}/reviews/{uid}` (+ ideally server-side purchase validation) so real review submits work.
11. **Real badge computation**: per-customer-network Top Seller / Most Visited + real Highlighted subscription check — both drop into `badgesFromVisibility`/`StoreBadgesRow` without UI changes.
12. ~~Premium redesign: Plan Details~~ — ✅ DONE 5 July (see §18).
13. **Premium redesign: customer Home page** (`lib/presentation/customer/home/`) in the deals_page design language; while in there, fix the Home tab rebuilding its plan carousel on every route change (ties to finding #6 + `Skipped 55–74 frames`).
14. **Customer READ rules** for `vendor_visibility` and `vendors/{id}/reviews` (both degrade gracefully if denied).
15. `flutter analyze` has not been run across these sessions (standing rule: ask David first).

---

## 18. Dated Updates (append below; keep entries SHORT)

### 5 July 2026 — Round 9 (Freeze root-cause fix + Plan Details premium redesign + handover compacted)

**A. Navigation freezes (storefront / reviews / hot deals back) — root cause fixed at the platform level:**
- [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml): `android:enableOnBackInvokedCallback` **true → false**. Android 13+ predictive back (`WindowOnBackDispatcher`) is fundamentally incompatible with GetX 4.x gesture bookkeeping — it was wedging the navigator on back gestures regardless of how routes were pushed. Only the predictive-back preview animation is lost. **Full rebuild (not hot reload) required for manifest changes.**
- [net_cubit.dart](lib/logic/core/net/net_cubit.dart): connectivity listener no longer emits `checking` while state is `online` — every OS connectivity blip was rebuilding the ENTIRE app shell (the offline gate's BlocBuilder wraps the navigator). Probes now run silently when online; the "Reconnecting…" banner still shows when actually offline/recovering. (This closes freeze finding #5.)

**B. Plan Details premium redesign (backlog #12 — DONE):** deals_page design language, NO border lines anywhere, all sections in small widget files:
- NEW [plan_detail_product_header.dart](lib/presentation/customer/plans/widgets/plan_detail_product_header.dart): floating 24r white card — image carousel (AspectRatio 4/3, dots pill), VendorHeader, title, brand-colored price, tinted model chip. Owns its own image-index state so swiping images no longer rebuilds the whole screen (was a setState on the screen).
- [plan_details_screen.dart](lib/presentation/customer/plans/widgets/plan_details_screen.dart): slimmed to composition only (carousel/header builders removed), bg `KorraColors.surface`, 16.h card rhythm. All logic (stream, cubit, sheets, guarded pops) unchanged.
- [plan_detail_financial_card.dart](lib/presentation/customer/plans/widgets/plan_detail_financial_card.dart): border → soft shadow; "Ownership Progress" w800 header + tinted % pill; Paid/Remaining columns; extension hint only when relevant.
- [plan_detail_timeline_card.dart](lib/presentation/customer/plans/widgets/plan_detail_timeline_card.dart): fake border removed; tinted card + white circular icon bubble.
- [plan_detail_next_payment_card.dart](lib/presentation/customer/plans/widgets/plan_detail_next_payment_card.dart): soft shadow, brandLight icon bubble. Logic untouched.
- [plan_detail_info_grid.dart](lib/presentation/customer/plans/widgets/plan_detail_info_grid.dart): outer border + row divider borders removed → shadow card, "Plan Information" header, spacing-separated rows.
- [plan_detail_status_banner.dart](lib/presentation/customer/plans/widgets/plan_detail_status_banner.dart): edge-to-edge bars → floating tinted 20r cards w/ icon bubble (overdue banner included).
- [plan_detail_sticky_action.dart](lib/presentation/customer/plans/widgets/plan_detail_sticky_action.dart): rounded top corners 24r.

**C. Handover compacted** per David: rounds 3–8 summarized into §16, live backlog consolidated into §17. Future updates go here, short.

**Standing rules recap (do not break):** named GetX routes only; cache Firestore streams; ElevatedButton in a Row must override minimumSize; no border lines in UI unless truly best; small widget files; demo data never touches Firebase; ask before `flutter analyze`/background tasks; never assume existing code is wrong — ask David.

### 5 July 2026 — Round 9b (Plans page crash fix + premium redesign)

**A. `ProviderNotFoundException: Could not find Provider<LinkBloc>` on the Plans FAB — FIXED:** the `LinkBloc` was created by a `BlocProvider` inside `build`, but the FAB/bottom-sheet read it through the page's own `context`, which sits ABOVE that provider. [plans_page.dart](lib/presentation/customer/plans/plans_page.dart) now owns the bloc as a state field (`_linkBloc`, created in initState, closed in dispose); the `BlocListener` uses `bloc: _linkBloc` and the New Plan sheet gets `BlocProvider.value(value: _linkBloc)`. **Rule: never create a bloc in `build` and read it from the same build's context.**

**B. Plans page premium redesign (no border lines):** bg → `KorraColors.surface`; FAB → extended "New Plan" pill; [plan_card.dart](lib/presentation/customer/plans/widgets/plan_card.dart) border → 20r + 0.05 shadow, vendor initial in brand-tinted square, AutoPay chip borderless tinted pill, pending banner border removed, "View" OutlinedButton → soft grey tonal FilledButton; [segmented_tabs.dart](lib/presentation/customer/plans/widgets/segmented_tabs.dart) → floating white shadow pill on surface (border removed, chip animation 5ms → 200ms easeOut); [empty_state_card.dart](lib/presentation/customer/plans/widgets/empty_state_card.dart) → white shadow card with brand-tinted icon bubble; [plan_skeleton_card.dart](lib/presentation/customer/plans/widgets/plan_skeleton_card.dart) → borderless shadow card. All filtering/sorting/pagination logic untouched.

### 5 July 2026 — Round 9c (Home page premium redesign + shared balance-hide toggle)

**A. Shared balance visibility (wallet card ↔ Bank Details):** NEW [balance_visibility.dart](lib/logic/services/balance_visibility.dart) — a persisted (`SharedPreferences`, key `korra_balance_visible`) `ValueNotifier<bool>`. [customer_wallet_card.dart](lib/presentation/customer/home/widgets/customer_wallet_card.dart) eye toggle now flips this global (visuals unchanged per David), and [bank_details_screen.dart](lib/presentation/customer/profile/bank_details_screen.dart) CURRENT BALANCE got its own eye icon bound to the same notifier — hide in one place hides in the other, both show `₦ ••••`, state survives restarts.

**B. Home page redesign (wallet card intentionally untouched):** bg → `KorraColors.surface`; "Start a new plan" LinkInput + its inline validation/loading feedback now live inside one floating white card (feedback extracted to `_buildLinkStatus()`); empty-plans card → white shadow card with brand-tinted icon bubble (border removed); [activity_tile_pro.dart](lib/presentation/customer/home/widgets/activity_tile_pro.dart) bubbles → floating shadow cards (ghost borders removed, shadow deepens when expanded), tap-to-expand actions KEPT (David likes them) with a new rotating chevron affordance next to the timestamp, secondary action buttons → borderless brand-tinted tonal; [activity_timeline.dart](lib/presentation/customer/home/widgets/activity_timeline.dart) empty state → proper white card. Backlog #13 partially addressed (visual redesign done); the Home-tab rebuild-on-navigation perf item (finding #6 GestureDetector) is still open.

### 5 July 2026 — Round 9d (Home redesign REVERTED per David; balance sync kept)

David preferred his previous Home design. Reverted from Round 9c: Home bg back to white, LinkInput + inline link feedback back out of the floating card (feedback stays extracted as `_buildLinkStatus()` — visually identical to before), activity tiles back to their original ghost-border bubbles / OutlinedButton secondary action / no chevron, timeline empty state back to plain text. KEPT: the empty-reserve-plans card redesign (he approved it), the shared BalanceVisibility toggle (wallet ↔ Bank Details, persisted), and the Bank Details eye icon — but the balance there is now a plain left-aligned Text (the AnimatedSwitcher was centering the amount; that was the "shifted to center" bug he reported). **Design note: David wants Home kept as HIS design — don't restyle it again without being asked.**

### 5 July 2026 — Round 9e (Profile cleanup + Level Up Slots redesign + logout loading)

**System-back freeze:** manifest already has `enableOnBackInvokedCallback="false"` (Round 9). ⚠️ A manifest change only applies after a FULL rebuild/reinstall (`flutter run` fresh build) — hot reload/restart does NOT apply it. David still saw the freeze; most likely tested pre-rebuild. If it persists after a real reinstall, capture logcat at the freeze moment.

**Profile page** ([profile_page.dart](lib/presentation/customer/profile/profile_page.dart)):
- Identity card: **My QR + Share removed**, Edit Profile is the single action ([identity_header_card.dart](lib/presentation/customer/profile/widgets/identity_header_card.dart) — onMyQr/onShare params deleted).
- **Statements & receipts moved directly under Bank Details** in the wallet section.
- **Change password row removed** (accounts use Google sign-in). Route/screen still exist, just unlinked.
- **Logout now shows a blocking "Signing out…" dialog** (PopScope canPop:false) until the bloc finishes: success → `Get.offAllNamed` clears everything incl. the dialog; failure → guarded `_dismissLoadingDialogIfAny` (isCurrent check, never blind-pops) + error snackbar (`errorMessage ?? message`).

**Level Up Slots screen** ([limit_upgrade_screen.dart](lib/presentation/customer/profile/limit_upgrade_screen.dart)) — premium rewrite, same tier logic (Starter 3 / Keeper 5@3 / Collector 10@10 / VIP ∞@25):
- Carousel height is now `Expanded` (old fixed 460.h risked RenderFlex overflows on David's phone), real `AnimatedScale`/`AnimatedOpacity` on page change (old Tween had begin==end → never animated), page dots added.
- Cards: gradient header w/ badge + tier name, ∞ shown for 999 slots, tinted status pills, 999-radius progress bar, no border lines; action bar rounded-top w/ shadow.
- **Upgrade flow de-risked:** the old `showDialog` + double `Navigator.pop(context)` across an await (our known navigator-wedge pattern) replaced by an inline button spinner (`_upgrading`) + single guarded pop with mounted checks.

### Round 9f — 5 July 2026 (merchant campaign timer + storefront location + vendor profile)
- **Deal Countdown Timer (merchant)**: `CampaignTimerSection` (new widget) in CreateCampaignSheet — toggle + start/end pickers (date+time, defaults now→+24h, max 30 days out). Independent of tag/discount. Validated in `_submitCampaign` (both set, end>start, end not past). Saved as `dealStartAt`/`dealEndAt` Timestamps.
- **Campaign model**: `dealStartAt`/`dealEndAt` + `hasTimer`/`timerRunning`/`timerUpcoming`; `isActive` now respects `dealEndAt` (timed deals outlive the 24h default).
- **Customer countdown**: new `DealCountdownBadge` (1s ticker, tabular figures; "STARTS IN…" dark pill / red "…LEFT" pill; renders nothing when closed/untimed). On `HotDealCard` (bottom-left) + `StoreDeal.timedCampaign` helper (running beats upcoming, newest first). Deals page card also prints the window "Sat 5 Jul, 3:00 PM → …".
- **Storefront location**: new `StorefrontLocationRow` — borderless brandLight "Walk-in store" chip, tap expands address INLINE below (AnimatedSize, no sheet). Only when merchant provided an address. `StorefrontHeader` got `address` param; storefront_screen composes it from `location.{address,city,state}`.
- **Vendor Edit Profile**: new `EditVendorProfileScreen` (route `Routes.vendorEditProfile`, registered in vendor_pages, arguments {'vendor': Vendor}). Locked personal fields (owner name/email/phone/store name) + editable Store Settings: description (200 chars), address, city, state → dot-path Firestore update on vendors/{uid}. Vendor model got `store.description` field.
- **Vendor profile page**: Change password row REMOVED (Google sign-in). Edit → edit screen. Share ACTIVE (Share.share store link `https://korra.com.ng/store/{slug}`; slug fetched one-off, uid fallback). My QR ACTIVE → new `StoreQrSheet` bottom sheet (qr_flutter, encodes store link).
- TODO: store slug generation/claim flow still pending ("we will on later" — link currently falls back to uid for merchants without a slug).

### Round 9g — 5 July 2026 (payout hide-balance, outright multi-select, storefront settings polish)
- **Payout/withdraw screen**: `PayoutBalanceCard` now hides the amount — eye toggle on the gradient card, wired to the SAME shared `BalanceVisibility` ValueNotifier the customer wallet/bank-details use (hidden = "₦ ••••••", letterSpacing 3).
- **Outright orders multi-select (UI ONLY — backend NOT connected, per David)**: `OutrightOrdersState.selectedIds` + `OutrightToggleSelection`/`OutrightSelectAll`/`OutrightClearSelection` events + bloc handlers; `OutrightOrderTile` got isSelected/isSelectionMode/onLongPress (green check circle, F0FDF4 fill — mirrors reservation tile); list wires long-press→select, tap toggles in selection mode; reservations_page shows a second dark bulk pill on tab 1 (`_buildOutrightBulkMenu`) — "Yes, Deliver" currently clears selection + info snackbar "coming soon — no orders were updated". TODO: connect bulk outright delivery write (reservation bulk `ResMarkFulfilled` remains fully functional).
- **Storefront settings** (`storefront_settings.dart`): slug link domain fixed korra.shop → **korra.com.ng** (matches profile Share/QR); old logo-gated "Share Store Link" text replaced by borderless pill row under the slug field — brandLight **Share Store** + grey **View Store** (url_launcher, external browser). Twitter field → **TikTok** (`socials.tiktok`); `saveStorefrontSettings` repo param twitter→tiktok.
- **Customer storefront chips**: now only WhatsApp, Instagram, TikTok, Call Us — Twitter and Email chips REMOVED (`StorefrontHeader` params email/twitter → tiktok).

### Round 10 — 5 July 2026 (PLAN — follow this list if picking up mid-round)
David's batch, in his required order. Update this section as each lands (mark DONE + notes).

1. **Mute store (customer)** — mute toggle on the customer storefront. Muted = no notifications from that store in the customer's notification feed. Storage: `customers/{uid}.mutedStores` array of vendorIds (arrayUnion/arrayRemove) so future server-side campaign fan-out can check it too. Client: filter the notification stream against `mutedStores` (notifications must carry `vendorId` in metadata to be filterable — system/payment notifications are never filtered).
2. **Suspended-store blocker (customer storefront)** — reuse the `vendor_compliance/{vendorId}` check from create-plan/pay (status `suspended`/`banned` blocks). Blocked store: customer sees only the first screen — scrolling locked, all interactions absorbed, premium overlay card: "This store is currently unavailable… suspended or restricted due to a policy/compliance issue. Contact the merchant if you believe this is an error." Only Back works.
3. **Demo data cleanup (BEFORE app links, per David)** — delete `lib/data/demo/` and strip every `DemoMarketplace` reference in customer app (storefront_screen, storefront_header, store_page, hot_deals_strip, store_badge, recommended_stores_section, store_reviews_screen, storefront_cart_sheet) + anything demo in settings, both flavors.
4. **Supabase backend: outright checkout** — NEW edge function (own folder under `supabase/functions/`) for the customer outright (pay-in-full) cart purchase. DB = Firebase, Supabase = edge functions only, Supabase bucket = images only. Fee rule: check merchant flag `store.absorbOutrightFee` — true: merchant absorbs fee (deduct from vendor credit), false: customer pays fee on top. Apply the platform rounding rule. Record payments/receipts the same shape as `plan-manager` (REFERENCE ONLY — do NOT edit plan-manager). Wire the function call into the customer repository/cart checkout. Do NOT touch other functions.
5. **App links** — Android `intent-filter` (autoVerify) + iOS associated domains for `https://korra.com.ng/store/{slug}` → open the app on the storefront screen; assetlinks.json / apple-app-site-association served by the store website.
6. **Store website (React)** — NEW root directory: SEO-indexable per-slug store pages at `korra.com.ng/store/{slug}`; bare `/store` redirects to the landing page. Reads vendors/products from Firebase. Also serves the app-link association files.

**Round 10 progress:**
- (1) Mute store DONE — bell GlassIconButton in storefront app bar (left of cart); `customers/{uid}.mutedStores` arrayUnion/arrayRemove; `KorraNotification.vendorId` (top-level or metadata.vendorId); notification feed + unread badge count both skip muted vendors (`streamMutedStores` added to notification_repository). Server fan-out (future campaign notifications) must also check `mutedStores`.
- (2) Suspension blocker DONE — new [storefront_suspended_overlay.dart](lib/presentation/customer/storefront/widgets/storefront_suspended_overlay.dart); storefront fetches `vendor_compliance/{vendorId}` once; status suspended/banned/restricted → scroll locked (NeverScrollable), AbsorbPointer over everything, blurred dark overlay + white card w/ publicMessage fallback copy + "Go back". 
- (3) Demo cleanup DONE — `lib/data/demo/` deleted; DemoMarketplace stripped from storefront_screen, storefront_header, storefront_cart_sheet, store_reviews_screen, store_badge, recommended_stores_section, hot_deals_strip, store_page (+ unused `previews` plumbing in discover_store_list_item); vendor seeders removed ("Seed Demo Reviews & Orders", "Seed Demo Campaigns" + generators). KEPT: the "Clear Demo Data" banners in vendor reviews/campaigns — they only appear while `isMock` docs exist in Firestore, so David can purge leftovers, then they never show again.
- (4) Outright checkout backend DONE — NEW edge function [supabase/functions/outright-checkout/index.ts](supabase/functions/outright-checkout/index.ts). Same Double-Lock (HMAC timestamp + Firebase token) as plan-manager; identity is the TOKEN, never a body uid. Server re-reads product prices (client only sends productId+quantity), checks stock, checks `vendor_compliance` (suspended/banned/blockPayments → throw same message as plan pay), reads `store.absorbOutrightFee`:
    - absorb=true → merchant absorbs the fee (customer pays subtotal; fee comes out of vendorNet)
    - absorb=false → customer pays subtotal + fee (3.5%, cap ₦7,500)
    Rounding: reuses plan-manager's `to2DP` (charges round up) / `to2DP_Floor` (balances round down). Store balance consumed first, wallet covers rest. Writes: decrements stock, creates `orders/{id}` (status 'pending', the shape the vendor Outright Orders screen reads), customer `ledger_transactions` with full `receiptData` (same shape as installment receipts → existing receipt UI works), wallet decrement, `my_vendors` + vendor `customer_balances` store-credit mirrors, vendor `ledger_transactions` sale + `liabilities` redemption, `company_ledger`/`company_wallet` fee, vendor `activity_feed` + `monthly_stats`. Notifications: customer confirmation has NO vendorId in metadata (so a store mute never hides a payment confirmation); vendor gets a "New Outright Order" push. NOTE: did NOT touch plan-manager (reference only, per David).
    Wiring: NEW [outright_checkout_repository.dart](lib/data/repository/customer/outright_checkout_repository.dart) extension `checkoutOutright({vendorId, items})` (exported from customer_repository.dart), returns `PaymentReceiptData`. [storefront_cart_sheet.dart](lib/presentation/customer/storefront/widgets/storefront_cart_sheet.dart) `_checkoutCart` now snapshots the cart, calls the function, and only clears the local cart on success (was a stub that cleared + fake snackbar). ⚠️ DEPLOY: `supabase functions deploy outright-checkout` — the function is NOT deployed yet.
- (5) App Links (ANDROID ONLY — iOS intentionally excluded) DONE:
    - iOS decision (David): NO iOS universal links. The store website detects iOS and redirects to the web app instead (customer → app.korra.com.ng, merchant → business.korra.com.ng). Do not add iOS associated-domains.
    - Dart: NEW [deep_link_service.dart](lib/logic/services/deep_link_service.dart) using `app_links` (added to pubspec). Handles cold-start + warm links; accepts hosts korra.com.ng / www / app.korra.com.ng; routes `/store/{slug}` via `Get.toNamed('/store/$slug')`; bare `/store` ignored (website sends those to landing). Started in [main_customer.dart](lib/main_customer.dart) via post-frame callback (navigator must exist first). Customer app only — merchant app does not register storefront links.
    - Android manifest: main manifest already had an `${appLinkHost}` autoVerify filter (customer=app.korra.com.ng, merchant=business.korra.com.ng). NEW customer-flavor manifest [android/app/src/customer/AndroidManifest.xml](android/app/src/customer/AndroidManifest.xml) merges an extra autoVerify filter onto `.MainActivity` for host `korra.com.ng`/`www.korra.com.ng` pathPrefix `/store`.
    - ⚠️ TODO for David: `https://korra.com.ng/.well-known/assetlinks.json` must list the CUSTOMER app's package (`com.korra.shop` dev / `com.korra.shop.live` live) + release signing SHA-256. The website ships a placeholder assetlinks.json (see store site) — replace the fingerprint with `keytool -list -v -keystore <release-keystore>` output before autoVerify will pass.
- (6) Store website (React/Next.js) DONE — NEW root dir [korra-store/](korra-store/). Chose **Next.js App Router** (React + SSR) because SEO indexing of dynamic `/store/{slug}` pages requires server rendering; a plain client React SPA would not be crawlable. Data read from Firestore **REST API** (no SDK bundle) using the public web config (project korra-prod-63687) — reads gated by Firestore rules.
    - Routes: `/` landing; `/store` → 307 redirect to `/` (David's "bare /store = landing" rule, in next.config.js); `/store/[slug]` SSR store page (resolves vendor by `store.slug`, falls back to uid like the app) with `generateMetadata` (title/desc/canonical/OG/Twitter) + JSON-LD `Store`/`Offer` schema + product grid (approved products, discount-aware pricing). Suspended/banned/restricted stores (via `vendor_compliance`) render an "unavailable" notice only — mirrors the in-app gate. `not-found.js`, `robots.js`, `sitemap.js` (lists all store slugs) for SEO. ISR revalidate 300s so merchant edits show without redeploy.
    - App-link plumbing: `public/.well-known/assetlinks.json` (served at `/.well-known/assetlinks.json`) with packages `com.korra.shop.live` + `com.korra.shop` — ⚠️ SHA-256 fingerprint is a PLACEHOLDER, David must paste the release-signing SHA256 (see korra-store/README.md). iOS/desktop: the "Continue in Korra" button ([OpenInApp.js](korra-store/app/store/[slug]/OpenInApp.js)) detects platform — Android tries the App Link then Play Store fallback; iOS/desktop redirect to app.korra.com.ng (NO iOS universal link, per David).
    - ⚠️ Build not run here (sandbox had no network for `npm install`). David: `cd korra-store && npm install && npm run build`. Structure + non-JSX modules syntax-verified; assetlinks.json validated.

**Round 10 — all six tasks landed. Remaining follow-ups for David:**
1. Deploy edge function: `supabase functions deploy outright-checkout`.
2. Firestore rules: allow public unauthenticated reads for the website (approved `products` + `vendors` store profile + `vendor_compliance`), and confirm `customers/{uid}.mutedStores` is writable by the owner.
3. assetlinks.json: replace the placeholder SHA-256 with the real release fingerprint, then host korra-store at the korra.com.ng apex.
4. `flutter pub get` already run (app_links added); do a full rebuild for the new Android customer-flavor manifest (App Links) + run the app.
5. Server-side campaign fan-out (future) must check `mutedStores` before notifying.

### Round 10b — 5 July 2026 (corrections + visibility/campaign backends)
David corrections after review:
- **Website is browse-first, pay-in-app.** The earlier "redirect to app" CTA was wrong. Browsing a store + products on the website is fully open (no login). The app/web-app hand-off happens ONLY at pay intent (reserve/checkout). Fixed: store page CTA is "Reserve on Korra" ([OpenInApp.js](korra-store/app/store/[slug]/OpenInApp.js)); Android → App Link then Play Store; iOS/desktop → app.korra.com.ng. No web checkout by design.
- **Store site owns ONLY /store/\*.** David already has a live landing at the apex. Deleted the landing page I'd made (`korra-store/app/page.js`); bare `/store` still redirects to `/` (the existing landing via reverse proxy). README updated with the proxy/rewrite requirement.
- **Store page reskinned to match the app**: cover + glass logo card, Top Seller/Most Visited/Highlighted badges (from `vendor_visibility`), rating line (from reviews), walk-in location, contact chips (WhatsApp/Instagram/TikTok/Call), featured strip + product grid, JSON-LD now includes aggregateRating. New firestore helpers: `fetchVisibility`, `fetchReviewSummary` (subcollection runQuery via parentPath).

**Backend — Top Seller / Most Visited (were demo-only, now real):**
- The badges read `vendor_visibility/{id}` (`topSellerCircles`/`mostVisitedCircles`/`isHighlighted`); values were ONLY ever written by the deleted demo seeder → would be 0 for everyone now.
- App: NEW visit tracking — [storefront_screen.dart](lib/presentation/customer/storefront/storefront_screen.dart) `_recordVisit()` increments `vendor_metrics/{vendorId}` (`visitsTotal`, `daily.{yyyy-MM-dd}`, `lastVisitAt`), once per store per app session (static `_countedVisits` set), fire-and-forget.
- NEW scheduled fn [supabase/functions/compute-visibility/index.ts](supabase/functions/compute-visibility/index.ts): cron (Bearer CRON_SECRET). Ranks stores by rolling-30d visits (`vendor_metrics`) → Most Visited, and by `vendor_stats.totalEarnings` → Top Seller (top 20 each, min thresholds), writes `vendor_visibility` merge:true (preserves isHighlighted), resets non-qualifiers to 0 so lost badges clear. ⚠️ Needs: a Firestore collectionGroup index is NOT required here (plain collection scans); schedule it (e.g. hourly) via your cron; `totalEarnings` is all-time (note: refine to a rolling window later if you want recency).
- Highlighted badge: left to the existing merchant highlight promo to set `isHighlighted` (not touched here).

**Backend — Campaign delivery (was client-only Hot Deals):**
- `createCampaign` only wrote a `campaigns` doc; nothing notified followers.
- NEW fn [supabase/functions/campaign-broadcast/index.ts](supabase/functions/campaign-broadcast/index.ts): Double-Lock (HMAC + Firebase token); merchant can only broadcast their own store (uid===vendorId). Finds followers via `collectionGroup('my_vendors').where('vendorId','==',vendorId)`, loads each customer (chunked getAll), SKIPS anyone with the store in `mutedStores`, writes an in-app notification (type 'campaign', vendorId in top-level + metadata so it's mute-filterable client-side) and fires a multicast FCM push (500/chunk). Returns {followers, reached, muted, pushed}.
- Wired: [vendor_campaigns_repository.dart](lib/data/repository/vendors/vendor_campaigns_repository.dart) `createCampaign` now creates the doc then `unawaited(_broadcastCampaign(...))` — fire-and-forget with double-lock invoke; a broadcast failure never surfaces as "campaign failed".
- ⚠️ Needs: a Firestore **collectionGroup index on `my_vendors.vendorId`** (Firestore will print the create-index link on first call). Deploy `campaign-broadcast`.

**Round 10b deploy checklist for David:**
1. `supabase functions deploy compute-visibility campaign-broadcast` (+ outright-checkout from 10a).
2. Schedule `compute-visibility` on your cron (Bearer CRON_SECRET), e.g. hourly.
3. Create the collectionGroup index for `my_vendors.vendorId` (link appears on first campaign-broadcast call, or add to firestore.indexes.json).
4. Firestore rules: allow owner writes to `customers/{uid}.mutedStores`; allow `vendor_metrics/{id}` increment writes by signed-in customers; keep public reads for the website (vendors/products/vendor_visibility/reviews/vendor_compliance).
5. Deploy korra-store behind a proxy so korra.com.ng/store/* hits it and / stays on the existing landing.

### Round 10c — 5 July 2026 (website goes through Supabase, not Firestore; responsive + animation)
- **Data path changed per David**: the website no longer reads Firestore directly. NEW public edge fn [supabase/functions/store-api/index.ts](supabase/functions/store-api/index.ts) (admin SDK, GET, called with the Supabase anon key). Returns a locked-down public payload: `{ store{name,desc,logo,cover,walkIn,phone,socials}, blocked, blockedMessage, visibility{topSeller,mostVisited,highlighted}, reviews{average,count}, products[], nextCursor }`. Actions: `?slug=` (full load), `?slug=&cursor=` (next products page — orderBy documentId, no custom index needed), `?action=slugs` (sitemap). This keeps Firestore rules FULLY LOCKED — no public read exposure at all; the site can only read, changes happen in the app.
- **Website rewired**: deleted `lib/firestore.js`; NEW [lib/api.js](korra-store/lib/api.js) calls store-api. `lib/config.js` now holds SUPABASE_URL + anon key (defaults to your project). Store page does ONE `fetchStore(slug)`. Lazy pagination via NEW client [ProductGrid.js](korra-store/app/store/[slug]/ProductGrid.js) → NEW server route [app/api/products/route.js](korra-store/app/api/products/route.js) (keeps the key server-side) → store-api cursor. Sitemap uses api.js.
- **Responsive + app-like motion**: cover/logo/grid scale from small phones (2-col, shorter cover, hidden CTA copy) to desktop (300px cover, wider cards); product cards fade/rise in on mount with staggered delay, hover lift + image zoom, spinner on infinite-scroll; `prefers-reduced-motion` respected.
- **DEPLOY**: `supabase functions deploy store-api`. Website `.env.local` needs SUPABASE_URL + SUPABASE_ANON_KEY (already in .env.example). Firestore public-read rules are NO LONGER needed for the site (admin SDK reads server-side) — you can keep rules locked.

**PENDING (needs David) — "carry selected product" + finish the thought:**
- David wants: tapping a product on the website opens the app ON THAT product, and if not signed in the app blocks with sign-in then RESUMES to that product (state maintained). Status: the app already maintains state for product→plan after login (`_navigateToProductPlan` redirects to login with redirectArgs → customerCreatePlan). Still TODO: (a) website product cards deep-link to `/store/{slug}?product={id}`; (b) DeepLinkService parse `product` query param; (c) StorefrontScreen accept an initialProductId and auto-open that product sheet after load. NOT built yet — confirm exact UX (does a product tap on the web jump straight to the app, or show details on the web first?) before building, since it touches GetX nav (freeze-sensitive). David's message ended mid-sentence ("and also…") — more requirements pending.

### Round 10d — 5 July 2026 (website = full app-parity storefront: cart, product details, installment+outright, flash deals)
David clarified: the website is NOT reservation-only and must LOOK/FUNCTION like the app storefront (same layout, flash deals, icons, colors, Inter typography), desktop just re-laid-out with the same premium feel. Flow: browse (open) → tap product → details → **Add to Cart** OR **Pay Installment**; installment hands to app create-plan; cart → checkout with store-balance/wallet **masked** → **Proceed to Payment / outright** hands to app. Payment ALWAYS happens in the app.

**store-api extended**: `publicProduct` now returns code, description, availableStock, allowReservation, modelType, up to 6 images; full load also returns `deals` = active/upcoming timed campaigns ({productIds, startAt, endAt, discountType, discountValue, title, tag}) so the site shows the same flash-deal countdowns as the app.

**Website rebuilt to app parity** (all new under korra-store/):
- Typography: Inter via `next/font/google` (matches GoogleFonts.inter). Colors/brand unchanged.
- [components/Icons.js](korra-store/components/Icons.js) — inline-SVG Iconsax-style set.
- [components/DealCountdown.js](korra-store/components/DealCountdown.js) — 1s ticker flash-deal badge (running red / upcoming dark), tabular figures — mirrors app DealCountdownBadge.
- [components/Storefront.js](korra-store/components/Storefront.js) (client) — filter bar (search + category chips + price sort), featured strip, product grid w/ discount % + deal badges, infinite scroll (via /api/products), floating cart FAB with live count, opens the two modals. Deal→product mapping (running beats upcoming).
- [components/ProductModal.js](korra-store/components/ProductModal.js) — image gallery + thumbs, price/discount, stock, quantity stepper, **Add to Cart** (web cart) + **Pay Installment** (→ `handoffToApp(action:'installment', productId)`).
- [components/CartModal.js](korra-store/components/CartModal.js) — cart items w/ qty steppers, **masked** Store Balance + Wallet rows ("₦ ••••••" — those live in the app/account), subtotal + "fee calculated in app", **Proceed to Payment** (→ `handoffToApp(action:'outright', cartIds)`).
- [lib/cart.js](korra-store/lib/cart.js) — localStorage web cart (mirrors app CartService: add/updateQty/remove/clear + pub/sub).
- [lib/handoff.js](korra-store/lib/handoff.js) — platform hand-off: Android → App Link (`/store/{slug}?product=&cart=&action=`) w/ Play Store fallback; iOS/desktop → customer web app w/ same params. Payment never happens on the site.
- [page.js](korra-store/app/store/[slug]/page.js) still SSRs the header (cover, logo, badges, rating, walk-in, chips) + JSON-LD for SEO; the client `<Storefront>` hydrates on top (its initial render is server-rendered too, so products are in the crawlable HTML). Deleted the old OpenInApp.js + ProductGrid.js.
- CSS: added filter bar, card discount/deal badges, cart FAB, bottom-sheet modals, qty steppers, masked rows, and desktop layout (@900px centered premium column, larger cover/cards, centered modals; @1200px max-width).

**App side — receives the deep-link intent** (carry state):
- [storefront_screen.dart](lib/presentation/customer/storefront/storefront_screen.dart): new `initialProductId`; on open it fetches `products/{id}` and auto-opens that product's details sheet (post-frame, guarded once) — shopper resumes exactly where they were on the web. Sign-in + post-login return to create-plan is ALREADY handled by the existing `_navigateToProductPlan` redirect flow, so "block with sign-in then maintain state" works end to end for installment.
- [customer_pages.dart](lib/config/routes/customer_pages.dart): storefront route reads `Get.parameters['product']`.
- [deep_link_service.dart](lib/logic/services/deep_link_service.dart): parses `?product=` and `?action=` and forwards them to the route.

**Still TODO (app side, noted — not blocking the site):**
- Outright web cart → app: the hand-off passes `?cart=id1,id2` but the app does NOT yet prefill its cart from that param (opens the store page). If you want the exact cart to carry over, add cart-prefill in StorefrontScreen from `Get.parameters['cart']`. For now the shopper re-confirms items in the app.
- `?action=installment` opens the product sheet (user taps Pay Installment); it does not auto-jump straight into create-plan. Fine per "it takes them to the app", but could be auto-triggered later.

**Deploy/test (Round 10d):** `supabase functions deploy store-api` (redeploy — deals added). Then `cd korra-store && npm install && npm run dev`, open `/store/{slug}`: browse, open a product, add to cart, open cart (balances masked), Proceed to Payment / Pay Installment → hand-off. `next/font` fetches Inter at build (needs network on your machine). Full Flutter rebuild to pick up the deep-link product param.

### Round 11 — 6 July 2026 (merchant: outright bulk delivery + selection gating + combined home KPIs)
David: reservations selection is the reference (unchanged). Fixes are outright-only + KPI redesign.
- **Outright selection gating** ([outright_order_list.dart](lib/presentation/vendor/reservation/widgets/outright_order_list.dart)): only **New (pending) + Ready-to-Deliver** orders are selectable. Delivered/cancelled can't be long-pressed or toggled (`canSelect = item.isPending || item.isReadyToDeliver`). Tapping an ineligible order in selection mode does nothing; outside selection mode it opens details. Bulk-menu **Select All** now selects only eligible visible orders (reservations_page.dart).
- **Outright bulk delivery CONNECTED** (was stubbed "coming soon"). NEW `OutrightBulkMarkDelivered(ids)` event + `_onBulkMarkDelivered` handler in the outright bloc — loops the existing `repo.markOutrightOrderDelivered(id)` (same backend write as single delivery), sets `deliveryStatus.loading` (FAB shows spinner, tap disabled), then clears selection + `OutrightOrdersRefresh`. Confirm dialog now fires the real event + "Marking N order(s) as delivered…" snackbar.
- **Home KPIs now reservations + outright** ([vendor_kpi_block.dart](lib/presentation/vendor/home/widgets/vendor_kpi_block.dart) + [vendor_home_body.dart](lib/presentation/vendor/home/vendor_home_body.dart)): 4 tiles — **Ready to Deliver** = reservation `readyForPickup` + outright `readyToDeliver` (combined, both fully paid); **New Orders** = outright `pending`; **Ongoing** = reservation `ongoing`; **New Reservations** = reservation `newRes`. Home body nests `streamCounts` (reservation) + `streamOutrightCounts` (outright). Navigation: Ready/Ongoing/New Reservations → reservations panel (panel 0) at the right tab; New Orders → **outright panel** (panel 1) at the New tab.
- **ReservationsPage** gained `initialPanel` (0 reservations / 1 outright) + `initialOutrightFilter`; route [vendor_pages.dart](lib/config/routes/vendor_pages.dart) passes `panel` + `outrightFilter` args so a KPI can deep-link straight into the outright panel/tab.

### Round 12 — 6 July 2026 (reservations select-render fix + website app-parity redesign)
- **Reservations bulk-select was invisible** (long-press showed the FAB but tiles didn't turn green/checked): [reservations_panel.dart](lib/presentation/vendor/reservation/widgets/reservations_panel.dart) `buildWhen` didn't watch `selectedIds` (the outright panel already did). Added `if (!identical(previous.selectedIds, current.selectedIds)) return true;`. Toggle creates a fresh Set so identity check fires. FIXED.
- **Website redesigned to match the app storefront** (korra-store/):
  - Header: sticky **StoreBar** shows the STORE logo + **store name** (not "Korra") so the name stays fixed on scroll, plus a small Korra attribution mark. Logo copied from `assets/images/korra_logo_icon.webp` → `korra-store/public/korra-logo.webp`. Footer "Powered by Korra".
  - Typography: Inter via `next/font` exposed as `--font-inter`; base font reduced (`html{font-size:15px}` mobile / 16px desktop) — fonts were too big.
  - Desktop padding tightened (container 28px sides, smaller section gaps) and **product grid is uniform** (`display:grid`, aspect-ratio:1 images) while **mobile stays staggered masonry** (`column-count:2`, natural image heights) — per David.
  - New sections mirroring the app: **⚡ Flash Deals** horizontal strip (products with a running timed campaign + live countdown), **★ Featured** strip, **Shop by Collection** circular category icons, **Filter & Sort** row, and a **Ratings & Reviews** section (store-api now returns `reviews.recent` — top 6 commented reviews).
  - **Walk-in store** is now tap-to-expand inline ([WalkIn.js](korra-store/components/WalkIn.js)) like the app.
  - Product cards: hover **cycles the image gallery** + lifts, a **quick-add (+)** button reveals on hover (always visible on touch), discount %, sold-out veil, low-stock nudge, deal countdown — matching StorefrontProductCard. No pin (per David).
  - store-api extended: product fields (code/description/stock/etc.), active `deals`, and `reviews.recent`. ⚠️ Redeploy `store-api`.
  - ⚠️ Not run here (no network): `cd korra-store && npm install && npm run build`. `next/font` fetches Inter at build.

### Round 13 — 6 July 2026 (SEO/OG polish + checkout "how it works")
- **Per-store SEO/OG finalised** ([app/store/[slug]/page.js](korra-store/app/store/[slug]/page.js) `generateMetadata`):
  - Title → **`{Store Name} · Shop on Korra`** (set as `title.absolute` so the layout's `%s · Korra` template doesn't double up).
  - Meta description (Google) → merchant's own description, else **`Discover {Store Name}'s products on Korra.`**
  - OG/Twitter share description → merchant's own description, else **`Discover amazing deals on {Store Name} — powered by Korra.`**
  - **OG image now always present**: merchant `coverUrl` → `logoUrl` → **branded fallback** `OG_FALLBACK_IMAGE`. Twitter card forced to `summary_large_image`. So every shared store link previews with an image.
  - Fallback image `korra_logo_icon_og.jpeg` moved from repo root → [korra-store/public/](korra-store/public/); exposed as absolute `${SITE_URL}/korra_logo_icon_og.jpeg` via new `OG_FALLBACK_IMAGE` in [lib/config.js](korra-store/lib/config.js). JSON-LD `image` uses the same fallback chain.
  - (Already in place, unchanged: canonical URL, `robots index,follow` + auto-noindex for suspended stores, JSON-LD `Store`+`Offer`+`AggregateRating`, `sitemap.xml`, `robots.txt`.)
- **Header/footer simplified** (page.js): removed the small Korra mark from the sticky StoreBar (header now = store logo + store name only); footer trimmed to just **"Powered by Korra"** + logo. Removed now-unused `.storebar-korra` CSS.
- **"How Korra installment works" on the product details** ([ProductModal.js](korra-store/components/ProductModal.js)): a collapsible behind a **`!` circle** toggle, shown **only when the product offers Pay Installment** (`canReserve`) — not in the cart. 3 steps (Reserve → Pay at your pace → Get your item, using the real `{store name}` passed via new `storeName` prop from [Storefront.js](korra-store/components/Storefront.js)) + note that unfinished/closed plans convert paid funds to store balance for future use with that store. New `.hiw*` styles in [globals.css](korra-store/app/globals.css).
- ⚠️ Still: redeploy `store-api`, and `cd korra-store && npm install && npm run build` on a networked machine.

### Round 14 - 6 July 2026 (big batch: webstore polish, app parity, campaigns, AI review, delete store, share)
David asked for one large batch. No em dashes anywhere (snackbars, code, this file). Working through in order, checking items off as done.

WEBSTORE (korra-store, Next.js):
- [x] 14.1 Fix DealCountdown hydration mismatch (server rendered time vs client time differed, e.g. "23:31:58 LEFT" vs "23:31:56 LEFT"). Gate the ticking render behind a mounted flag so SSR and first client paint agree.
- [x] 14.2 Removed the "+" quick-add button from product cards ([Storefront.js](korra-store/components/Storefront.js), dropped the `Plus` import and `onAdd` plumbing).
- [x] 14.3 Flash Deals and Featured stay as HORIZONTAL rails (David clarified: keep horizontal, just show fewer). Capped at 4 items; "View all" shows only when there are more than 4 and scrolls back to the full product grid. Emojis removed from the titles ("Flash Deals" / "Featured").
- [x] 14.4 Removed the store name from the sticky header ([page.js](korra-store/app/store/[slug]/page.js) StoreBar now shows only the logo + Open app).
- [x] 14.5 Flash timer legibility: `.deal-badge` font 10px to 12px, tighter icon/text alignment (`line-height:1`, svg nudge), Timer icon 12 to 13. Countdown direction was already correct; the visible "going up" was the hydration bug in 14.1.
- [x] 14.6 Reviews now mirror the app: the rating line in the store header (under the cover) is tappable and links to a new web-only reviews page [app/store/[slug]/reviews/page.js](korra-store/app/store/[slug]/reviews/page.js) (rating summary + recent reviews, "Back to store"). Removed the old bottom-of-page Reviews block and the Reviews.js usage. NOTE: store-api only returns the 6 most recent reviews, so the reviews page shows those with a "showing most recent" note; add a paged reviews action to store-api later for the full list.
- [x] 14.7 Filter and sort now matches the app: a "Filter & Sort" label plus a Filters pill (Sliders icon + active count badge) that opens a bottom sheet with Sort by price (Recommended / Low to High / High to Low) and a "Show deals only" toggle. Grid respects both.
- [x] 14.x Cart fix: the close button was covering the item-count badge. Added right padding to `.cart-head` so the count clears the close button.
- [x] 14.6b Reviews page rebuilt: now shows the average, star row, and a per-star RATING BARS distribution, plus the recent reviews list (with or without a written comment). Reduced the big top padding under the app bar. The store name is sticky at the top of the reviews page. store-api `reviewSummary` now returns `distribution` (per-star counts) and includes all recent reviews (not just commented ones). IMPORTANT: reviews were "not showing" because the deployed store-api predates `reviews.recent` and only returned commented reviews. MUST redeploy store-api for the reviews page to populate.
- [x] 14.3b Rail cards (Flash Deals / Featured) no longer show the "Only N left" low-stock line (kept only on the main grid cards). Hover image switch already works on rail cards when a product has 2+ images.
- [x] 14.7b Filters pill: removed the border it showed in the active state (now just the brand tint fill).
- [x] 14.4b David asked for the store name back in the sticky header after all (undoing part of 14.4). [page.js](korra-store/app/store/[slug]/page.js) StoreBar: added `<h1 className="storebar-name">{store.name}</h1>` back next to the logo. Made it the page's H1 (semantic, good for SEO) since the big name below the cover is now gone.
- [x] 14.4c Removed the big `h1.store-name` that sat above the reviews link under the cover photo (now redundant with the sticky header name). `store-head-text` now holds just the rating/reviews link.
- [x] 14.6c Fixed reviews page store name shifted to the right: `.reviews-bar` (back button + name) was inheriting `justify-content: space-between` from the shared `.storebar-inner` class with only 2 children, which shoved the name to the far right. Added `justify-content: flex-start` on `.reviews-bar` to override it.
- [x] 14.3c Flash Deals / Featured rail cap raised from 4 to 6 (`STRIP_MAX = 6` in [Storefront.js](korra-store/components/Storefront.js)); "View all" only shows past 6.
- [x] 14.8 Pagination confirmed present: IntersectionObserver sentinel + `/api/products?slug=&cursor=` -> store-api `nextCursor`. Works.
- [x] 14.9 / 14.20 Per-product SSR page + share, done on both web and app. New route [app/store/[slug]/p/[productId]/page.js](korra-store/app/store/[slug]/p/[productId]/page.js): its own `generateMetadata` (title, description, canonical, OG/Twitter image from the product's own photo, falling back to store cover/logo/branded default), a `Product` JSON-LD block, and renders `Storefront` with `initialProductId`/`initialProductData` so the product modal auto-opens on load. [store-api](supabase/functions/store-api/index.ts) gained `GET ?slug=&productId=` returning `{ store, product }` for a single item (NEEDS DEPLOY). [Storefront.js](korra-store/components/Storefront.js) seeds `modalProduct` from that on mount. [ProductModal.js](korra-store/components/ProductModal.js) got a Share icon button (Web Share API, falls back to clipboard copy with a small toast) linking to `productUrl(slug, productId)` (new helper in [lib/config.js](korra-store/lib/config.js)).
  App side: [StorefrontProductDetailsSheet](lib/presentation/customer/storefront/widgets/storefront_product_details_sheet.dart) got a share icon overlaid on the image carousel (only when `storeSlug` is passed in), using `share_plus` to share `https://korra.com.ng/store/{slug}/p/{productId}`. [storefront_screen.dart](lib/presentation/customer/storefront/storefront_screen.dart) now passes `storeSlug: widget.storeSlug` into the sheet. [DeepLinkService](lib/logic/services/deep_link_service.dart) updated to also parse that `/p/{id}` path form (previously only understood `?product=`) so tapping a shared product link on a phone with the app installed opens straight to that product; no AndroidManifest change needed since the existing intent-filter matches the whole host with no path restriction.
- [x] 14.10 Search bar moved ABOVE the Flash Deals / Featured strips (own `.searchbar-top` block; collections + sort stay in the filter bar below).

MERCHANT APP:
- [x] 14.11 Campaigns tab enabled on the merchant web app. [products_page.dart](lib/presentation/vendor/product/products_page.dart) previously hid both Reviews and Campaigns behind `if (!kIsWeb)`; Campaigns is now shown on web too (Reviews stays app-only for now). Reworked `_tabController` length and the header-title lookup into a single `_tabTitles` list so the title stays correct regardless of which tabs are actually present. While enabling this, found and fixed a real web crash: the campaign banner photo preview used `Image.file(File(xfile.path))`, which throws on web since an `XFile`'s path there is a blob URL, not a real file path (same issue [image_upload_box.dart](lib/presentation/vendor/product/widgets/image_upload_box.dart) already works around for product photos). [create_campaign_sheet.dart](lib/presentation/vendor/product/widgets/campaigns/create_campaign_sheet.dart) now branches `kIsWeb ? Image.network(path) : Image.file(File(path))` for that preview; the actual upload (`repo.uploadToSupabase`) already handled both platforms correctly.
- [x] 14.12 Campaign price preview in [create_campaign_sheet.dart](lib/presentation/vendor/product/widgets/campaigns/create_campaign_sheet.dart) now renders ONE representative product's before/after price plus a "Same discount applies to the other N selected products" note, instead of one row per selected product. Added a `_zeroPriceProducts` getter and a red warning banner (covers both percentage and flat-amount discount types) listing any selected product whose price would round down to ₦0, so the merchant is warned before launching.
- [x] 14.13 Campaign banner photo picker preview height fixed from 110.h to 120.h in [create_campaign_sheet.dart](lib/presentation/vendor/product/widgets/campaigns/create_campaign_sheet.dart), matching the banner height [CampaignCard](lib/presentation/vendor/product/widgets/campaigns/campaign_card.dart) actually renders at (120.h) in the Campaigns tab, so the picker preview isn't misleading about the final crop.

CUSTOMER APP:
- [x] 14.14 Fixed "Visit count failed ... permission-denied". The app wrote `vendor_metrics` directly (rules locked). Now it calls a new [record-visit](supabase/functions/record-visit/index.ts) edge function (admin SDK increments visitsTotal + daily[today] + lastVisitAt). [storefront_screen.dart](lib/presentation/customer/storefront/storefront_screen.dart) `_recordVisit` now invokes the function (try/catch, fire-and-forget) instead of the Firestore write. NEEDS DEPLOY of record-visit (this is also 14.25).
- [x] 14.15 Campaign notification image fixed (concrete, verified bug): the app's foreground FCM handler ([notification_service.dart](lib/logic/services/notification_service.dart) `_setupInteractedMessage`) reads `message.data['image']` to build the BigPictureStyle, but `campaign-broadcast` never sent that key, only stored `metadata.image` in the Firestore doc for the in-app list. Fixed [campaign-broadcast](supabase/functions/campaign-broadcast/index.ts): push payload now includes `data.image` and `android.notification.imageUrl` (rich image on background/terminated pushes too). Also [KorraNotification](lib/data/models/customer/korra_notification.dart) never parsed `metadata.image` at all, so the in-app Notifications list couldn't show it either — added an `imageUrl` field, and [notification_screen.dart](lib/presentation/customer/home/notification_screen.dart) now renders the real campaign photo as the tile thumbnail (falls back to an icon on load error), plus a proper `campaign` icon/color case. NEEDS DEPLOY of campaign-broadcast.
  NOTE on "campaign not showing in app": traced [hot_deals_strip.dart](lib/presentation/customer/store/widgets/hot_deals_strip.dart) — it only renders on the Stores tab (not Home), requires the campaign's vendor to be present in the already-loaded `vendorsById` map (all non-banned vendors, so should be fine) and requires `campaign.isActive` (untimed campaigns expire 24h after `sentAt`; timed ones need `dealEndAt` in the future). No concrete bug found beyond that; flagging as an architecture note rather than a fix — if it keeps happening, check that the campaign's `sentAt`/`dealStartAt`/`dealEndAt` are actually set correctly at creation time in the merchant app.
- [x] 14.16 Campaign countdown timer added in-app, reusing the existing [DealCountdownBadge](lib/presentation/customer/store/widgets/deal_countdown_badge.dart) (already built for Hot Deals cards). [storefront_screen.dart](lib/presentation/customer/storefront/storefront_screen.dart) now streams this store's `campaigns` (`_campaignsStreamFor`), builds a productId to Campaign `dealMap` (`_buildDealMap`, running beats upcoming), and passes the matching deal to: (a) [StorefrontCardImage](lib/presentation/customer/storefront/widgets/storefront_card_image.dart) via a new `deal` prop on [StorefrontProductCard](lib/presentation/customer/storefront/widgets/storefront_product_card.dart), shown bottom-left on both the Featured strip and the masonry grid; (b) [StorefrontProductDetailsSheet](lib/presentation/customer/storefront/widgets/storefront_product_details_sheet.dart) via a new `deal` prop, shown under the price block. `_showProductDetailsSheet` gained an optional 3rd `Campaign? deal` param.
- [x] 14.17 AI review summary box wired into the customer feedback screen. New [AiReviewSummaryBox](lib/presentation/customer/storefront/widgets/ai_review_summary_box.dart) widget calls the `ai-review-summary` function on mount, shows a loading state then either the summary or "AI currently unavailable", is collapsible (chevron toggle) and closeable (X dismisses it for that screen visit). Added as the first header item in [store_reviews_screen.dart](lib/presentation/customer/storefront/store_reviews_screen.dart) `_buildBody`, above the review composer and rating summary card. NEEDS DEPLOY of ai-review-summary (14.24) to actually return data instead of erroring silently to "unavailable".
- [x] 14.18 Radio style indicator (the existing broadcasting [SignalBadgeDot](lib/presentation/shared/widgets/signal_badge_dot.dart) ripple, previously cart-only) now also fires for a live campaign. [store_page.dart](lib/presentation/customer/store/store_page.dart) added a `_campaignsStream` (last 100 campaigns) and computes `activeCampaignVendorIds` from `Campaign.isActive`; wrapped the existing cart `ValueListenableBuilder` in a `StreamBuilder` for it. [DiscoverStoreListItem](lib/presentation/customer/store/widgets/discover_store_list_item.dart) gained a `hasActiveCampaign` flag: shows the same dot as an unfinished cart, plus a distinct "Live deal" pill (cart's "In your cart" pill still wins if both apply on the same store).
- [x] 14.19 Delete store added to the existing "My Merchants" list ([my_vendors_screen.dart](lib/presentation/customer/profile/my_vendors_screen.dart), the customer's directory of stores they've interacted with). `_VendorCard` became a `StatefulWidget` with a trash icon on each card. Tap checks, in order: store balance > 0 blocks with a reason dialog (Close only, no delete option); an active plan (`plans` where `customerId`+`vendorId`+`status == active`) blocks the same way; otherwise a confirm dialog warns it permanently removes the store and can't be undone, then deletes the `customers/{uid}/my_vendors/{vendorId}` doc and removes the card from the list via a new `onDeleted` callback plumbed from `MyVendorsScreen`.
- [x] 14.20 Done together with 14.9 above.
- [x] 14.21 Search bar moved above the Featured strip in the app's per-store storefront too. Extracted the search field out of [StorefrontFilterBar](lib/presentation/customer/storefront/widgets/storefront_filter_bar.dart) into a standalone `StorefrontSearchField` widget; `StorefrontFilterBar` gained a `hideSearch` flag. [storefront_screen.dart](lib/presentation/customer/storefront/storefront_screen.dart) `_buildProductSlivers` now renders `StorefrontSearchField` first, then Featured, then `StorefrontFilterBar(hideSearch: true)` (collections + sort) right before the grid — same split as the website.
- [x] 14.22 Level Up Slots made more gamified, no new dependencies. [limit_upgrade_screen.dart](lib/presentation/customer/profile/limit_upgrade_screen.dart): tier progress bars now animate their fill in on render (`TweenAnimationBuilder`, "charging up" instead of static), the two header stats tick up from 0 on load, swiping tiers gives a light haptic (`HapticFeedback.selectionClick`), a tier the customer already qualifies for but hasn't claimed now shows a distinct "READY TO UPGRADE" pill in the tier's color instead of the same muted "UNLOCKED" state as an already-passed tier, and a successful upgrade fires a heavier haptic plus a brief home-grown confetti burst (new `_ConfettiBurst`/`_ConfettiPainter`, a `CustomPainter` shower of fading circles) rendered inline in the same screen's `Stack` before the existing single `Navigator.pop`, so the known navigator-wedge risk from popping across an await stays avoided.
- [x] 14.23 Em dash sweep done. Cross referenced every file using `showAppSnackbar`/`SnackBar`/`ScaffoldMessenger` against every file containing an em dash and found one real snackbar hit: the mute/unmute message in [storefront_screen.dart](lib/presentation/customer/storefront/storefront_screen.dart) `_toggleMute` ("Muted, you won't get notifications..."), fixed with periods. Also swept other user-facing (non-comment) strings with em dashes found the same way: the insufficient-funds banner in [storefront_cart_balances.dart](lib/presentation/customer/storefront/widgets/storefront_cart_balances.dart), the empty-deals message in [deals_page.dart](lib/presentation/customer/store/deals_page.dart), and the product share caption in [share_link_sheet.dart](lib/presentation/vendor/product/widgets/share_link_sheet.dart). Left the single `"—"` empty-value placeholder in [edit_vendor_profile_screen.dart](lib/presentation/vendor/profile/edit_vendor_profile_screen.dart) alone since it is a dash-as-placeholder UI convention, not prose. Remaining em dashes across the codebase are all inside `//`/`///` code comments, out of scope for this task.

SUPABASE:
- [x] 14.24 AI review summarizer edge function created at [supabase/functions/ai-review-summary/index.ts](supabase/functions/ai-review-summary/index.ts). Stub returns `{ available:false, summary:null, message:"AI currently unavailable" }` (200 so the box renders gracefully; client treats any non-2xx/throw as unavailable too). Keep the same response shape when the real model lands. NEEDS DEPLOY. App wiring is 14.17.
- [x] 14.25 Storefront visit tracking function created: [record-visit](supabase/functions/record-visit/index.ts). NEEDS DEPLOY.
- [x] 14.26 campaign-broadcast now carries the campaign image end to end (push `data.image` + `android.notification.imageUrl`, plus the existing Firestore `metadata.image` for in-app). Done together with 14.15. NEEDS DEPLOY.

FULL DEPLOYMENT GUIDE (updated 8 July 2026 — confirmed: korra.com.ng landing page is on Vercel already).
Every URL below (Play Store link, CUSTOMER_WEBAPP, MERCHANT_WEBAPP, ANDROID_PLAY_URL) is an env var / `lib/config.js` constant, not hardcoded — swapping any of them later (e.g. plugging in the real Play Store listing once it's live) is a config change, never a code change, on either the app or the website.

--- PART A: korra.com.ng root (landing) + /store/* -> korra-store ---
Both projects are on Vercel, so this is a rewrite, not a DNS change.
1. Deploy korra-store as its own Vercel project: `cd korra-store && vercel --prod` (or connect the GitHub repo in the Vercel dashboard). Set its env vars in that project's Vercel settings: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `NEXT_PUBLIC_SITE_URL=https://korra.com.ng`. It'll get a URL like `korra-store.vercel.app` — confirm it works standalone first (`korra-store.vercel.app/store/david-store`).
2. In the LANDING PAGE's Vercel project (the one already serving korra.com.ng), add a `vercel.json` at its root (or merge into an existing one):
   ```json
   {
     "rewrites": [
       { "source": "/store", "destination": "https://korra-store.vercel.app/store" },
       { "source": "/store/:path*", "destination": "https://korra-store.vercel.app/store/:path*" }
     ]
   }
   ```
   Redeploy the landing project for this to take effect. Everything else on korra.com.ng (the homepage, any other landing routes) is untouched — only `/store` and `/store/*` proxy out.
3. Sitemap/robots: do NOT blanket-proxy `/sitemap.xml` or `/robots.txt` to the store app — that would replace the landing page's own sitemap. Instead add one more rewrite so the store's sitemap is reachable under its own name: `{ "source": "/store-sitemap.xml", "destination": "https://korra-store.vercel.app/sitemap.xml" }`, then add a second `Sitemap:` line to the landing page's own `robots.txt` pointing at `https://korra.com.ng/store-sitemap.xml`. If the landing page currently has NO sitemap/robots.txt of its own, simpler: just proxy `/sitemap.xml` and `/robots.txt` straight to the store app instead.
4. `.well-known/assetlinks.json` and `.well-known/apple-app-site-association` (Android App Links / iOS Universal Links verification) MUST be served from the domain root (`korra.com.ng/.well-known/...`), which is the LANDING project, not korra-store (proxying `/store/*` doesn't cover `/.well-known/*`). Copy the two files already in this repo at `web/.well-known/assetlinks.json` and `web/.well-known/apple-app-site-association` into the landing project's `public/.well-known/` folder verbatim and redeploy it. (There's also a stale copy at `korra-store/public/.well-known/assetlinks.json` from an earlier attempt — harmless since it's unreachable at the root once `/store/*` is the only proxied path, but fine to leave or delete.)
5. Verify: load `korra.com.ng/store/david-store` (should render the storefront, not "Store not found"), `korra.com.ng/store-sitemap.xml` (or `/sitemap.xml` if you went the simple route), `korra.com.ng/.well-known/assetlinks.json`, and paste a store URL into the Facebook Sharing Debugger + Twitter Card Validator to confirm the OG preview picks up the product/store image.
Note: local `next dev` first-compile slowness (60-90s) is normal; the Vercel production build is pre-built and serves fast.

--- PART B: app.korra.com.ng -> Flutter CUSTOMER web build ---
This is the one that's currently stale (still serving an old react-router app, per your last test) — this is the fix.
1. Build: `flutter build web --release -t lib/main_customer.dart --dart-define=IS_LIVE=true --no-tree-shake-icons`. Output lands in `build/web/`.
2. Deploy that folder: `cd build/web && vercel --prod`. If `build/web/.vercel` already links to a project (it has a `.vercel` folder checked in from a prior deploy), this pushes straight to whichever project that's linked to — open the Vercel dashboard FIRST and confirm that project's assigned domain is actually `app.korra.com.ng` before running this, since a mismatch here is almost certainly why the redeploy "didn't take" last time.
3. Confirm the domain alias: in Vercel, Project Settings -> Domains -> `app.korra.com.ng` should point at this exact project. If it's attached to a different/old project (the react-router one), either move the domain onto the new project or delete/replace the old project's deployment.
4. Verify: open `app.korra.com.ng` in an incognito window (bypasses cache), check the Network tab loads `main.dart.js` (not an `index-[hash].js`), then test `app.korra.com.ng/store/david-store?product={id}&action=installment` directly — it should show the splash/home briefly then land on that product's installment flow.

--- PART C: business.korra.com.ng -> Flutter MERCHANT web build ---
Same shape as Part B, different target and domain.
1. `flutter build web --release -t lib/main_vendor.dart --dart-define=IS_LIVE=true --no-tree-shake-icons`.
2. `cd build/web && vercel --prod` — but note `build/web` is shared/overwritten by whichever flavor you last built (see caveat below), so build+deploy the merchant flavor as its own step right after, don't try to deploy both from one build.
3. Confirm `business.korra.com.ng` is aliased to this project the same way as Part B step 3.
Caveat found while testing this session: `web/index.html` (the shared source template for BOTH flavors) is currently hardcoded with `<title>Korra Business</title>` and a comment marking it merchant-only. Since `flutter build web` always copies the ONE `web/` folder regardless of `-t` target, the CUSTOMER build currently inherits the merchant's tab title too (favicon itself is fine, both flavors use the same `korra_logo_icon.webp`). Cosmetic only, not a routing/functional issue, but flag if you want it split per-flavor (would need a small pre-build script swapping index.html/manifest.json per flavor, or accept "Korra Business" title on both for now).

--- PART D: Android app -> Play Store ---
1. Build the signed bundle: `flutter build appbundle --flavor customer -t lib/main_customer.dart --release --dart-define=IS_LIVE=true` (and the `merchant`/`main_vendor.dart` equivalent for the business app — these are two separate Play Store listings, two separate packages per `assetlinks.json` above: `com.korra.shop` / `com.korra.shop.live` for customer, `com.korra.business` / `com.korra.business.live` for merchant).
2. Output: `build/app/outputs/bundle/customerRelease/app-customer-release.aab` (path varies slightly by flavor name — check the actual output path Flutter prints at the end of the build).
3. Play Console (first time): create the app listing (Play Console -> Create app), fill store listing (screenshots, description, privacy policy URL, content rating questionnaire, data safety form), upload the `.aab` under a release track. Start with **Internal testing** or **Closed testing** track, not straight to Production, so you can install/verify before it's public.
4. Once verified, promote the release to Production. First-time review can take a few days; updates are usually faster.
5. Once live, update `ANDROID_PLAY_URL` in `korra-store/lib/config.js` (or set `NEXT_PUBLIC_ANDROID_PLAY_URL` in the website's Vercel env vars) to the real `https://play.google.com/store/apps/details?id=com.korra.shop.live` listing URL, redeploy the website. That's the only change needed — `handoff.js` already reads it as a config value.

--- PART E: iOS app -> App Store (flagged, not actioned) ---
Needs a Mac + Xcode + an active Apple Developer Program membership to build/sign/upload (`flutter build ipa`, then Transporter or Xcode Organizer to App Store Connect) — none of that is possible from this Windows dev environment. `ios/` in this repo has the project scaffolding ready; when you have Mac access, the Flutter build/signing steps are the standard `flutter build ipa --flavor customer -t lib/main_customer.dart --release` per flavor, then upload via App Store Connect. Revisit this when it's actually next, no point detailing further until there's a Mac in the loop.

--- PART F: Supabase Edge Functions still pending deploy ---
`supabase functions deploy store-api` (product-level OG lookup, reviews distribution), `supabase functions deploy record-visit`, `supabase functions deploy ai-review-summary`, `supabase functions deploy campaign-broadcast` (campaign push image). Can bundle as `supabase functions deploy store-api record-visit ai-review-summary campaign-broadcast` in one command if the CLI is already logged into the right project.

### 8 July 2026 — Campaign lifecycle: manual delete replaces the 24h auto-expiry
Found while answering "does a campaign clear after 24 hours": it half-did. The OLD `Campaign.isActive` made untimed campaigns stop showing as "active" (Hot Deals, ACTIVE/EXPIRED badge) after 24h, but NOTHING ever reset the `campaignTag`/`discountedPrice` it had written onto the target products at creation time — those stuck on the product forever. David asked to drop the 24h auto-expiry entirely and let merchants delete campaigns manually instead, multi-select included.
- [Campaign.isActive](lib/data/models/vendor/campaign_model.dart): untimed campaigns now stay `true` (active) until deleted. Timed campaigns (`hasTimer`) unchanged, still expire at their explicit merchant-chosen `dealEndAt`.
- [VendorCampaignsRepository](lib/data/repository/vendors/vendor_campaigns_repository.dart): new `deleteCampaign`/`deleteCampaigns(List<Campaign>)`. Deletes the campaign doc(s) in one batch (guaranteed to exist), then reverts `campaignTag`/`discountedPrice` on every targeted product one at a time with individual try/catch (NOT a batch — `update()` throws NOT_FOUND on a since-deleted product, which would otherwise sink the whole batch including the campaign deletes that already succeeded). Known simplification, flagged in a code comment: if two campaigns targeted the same product, deleting the older one still clears whatever the newer one set too — there's no per-product "which campaign currently owns this discount" tracking.
- [create_campaign_sheet.dart](lib/presentation/vendor/product/widgets/campaigns/create_campaign_sheet.dart): the "max 3 active campaigns" creation gate no longer windows by `sentAt > 24h ago` (that's meaningless now) — it just counts all of the vendor's campaigns; delete one to free a slot. Updated the limit-reached snackbar copy to say so instead of "expire after 24 hours".
- [CampaignCard](lib/presentation/vendor/product/widgets/campaigns/campaign_card.dart): gained `selectionMode`/`selected`/`onTap`/`onLongPress`/`onDeleteTap`. Long-press enters selection mode; a checkbox circle overlays top-right in selection mode, a quick trash icon overlays there otherwise.
- [VendorCampaignsBody](lib/presentation/vendor/product/widgets/vendor_campaigns_body.dart): converted from `StatelessWidget` to hold selection state. Header row swaps between the normal "Sent Campaigns (N)" + New Campaign + a new "Select" text button, and (in selection mode) "N selected" + Cancel + a red Delete button. Both single delete (trash icon) and bulk delete (toolbar) go through the same `_confirmDelete` dialog, which explains the price/tag revert and can't-be-undone before calling the repository.

### 8 July 2026 — Product pages added to the sitemap (Google Images gap)
Individual product pages (`/store/{slug}/p/{id}`, added earlier for 14.9/14.20) had good OG/JSON-LD tags but were undiscoverable — not in `sitemap.xml`, and the product opens as a client-side modal on the store page rather than a real `<a href>`, so nothing pointed a crawler at them. Fixed the sitemap side (the on-page-link side is still open if wanted later, not built this round).
- [store-api](supabase/functions/store-api/index.ts): new `GET ?action=product-urls` → `{ urls: [{slug, productId}, ...] }` for every `status:'approved'` product across every vendor (resolves each product's `vendorId` to its store slug via one `vendors` projection query, capped at 5000 products / 2000 vendors). NEEDS DEPLOY (on top of the productId lookup from 14.9, already pending).
- [lib/api.js](korra-store/lib/api.js): new `fetchAllProductUrls()`.
- [sitemap.js](korra-store/app/sitemap.js): now merges product URLs (via `productUrl(slug, productId)`) into the sitemap alongside store URLs, `weekly`/priority 0.6.

### 8 July 2026 — Campaign "opens" counter was dead, now wired to store visits
David: "the campaign visit is not working, I visited a campaign, it did not show — if they just click on the merchant store in the app we count it as a campaign visit." Traced `Campaign.openCount`: it's read everywhere (`campaign_card.dart` shows "N opens") and initialized to 0 at creation, but literally nothing in the app or any Supabase function ever incremented it — dead counter, always "0 opens".
- [record-visit](supabase/functions/record-visit/index.ts): now, in the same call the app already fires on every real store visit, also looks up that vendor's campaigns and increments `openCount` on every currently-active one (mirrors `Campaign.isActive`: untimed campaigns always count, timed ones only while `dealEndAt` is still in the future). Wrapped in its own try/catch so a campaign-bump failure can't affect the visit count that was already written. NEEDS DEPLOY (same function as the visit-count fix from earlier — one deploy covers both once you redeploy record-visit).
- Also confirmed and intentionally left alone per David: when a merchant creates a new campaign that targets a product already tagged by an older campaign, the newer campaign's `campaignTag`/`discountedPrice` simply overwrites the product's fields (there's one `campaignTag` per product, not a history) — this was already documented as a known simplification when campaign delete was built earlier today, and David confirmed it's fine as-is.

### 8 July 2026 — App product share now embeds a screenshot, not just a link
Mirrors what [share_link_sheet.dart](lib/presentation/vendor/product/widgets/share_link_sheet.dart) already does for the merchant app (capture a widget to PNG via `RepaintBoundary.toImage`, share as an image file), but reuses the ACTUAL product details UI instead of a separately designed flyer card, per David: "take a screenshot of the product part... capture up to the part where it says installment plan available."
- [storefront_product_details_sheet.dart](lib/presentation/customer/storefront/widgets/storefront_product_details_sheet.dart): wrapped the image carousel through the payment-availability banner (name, price, deal countdown, stock chips, banner — stops before description/quantity/actions) in a `RepaintBoundary` keyed by `_shareCaptureKey`. `_shareProduct` now captures that region to a PNG (`pixelRatio: 3.0`), saves to a temp file, and shares it via `SharePlus.instance.share(ShareParams(files: [...], text: caption))` (updated off the deprecated `Share.share` static while touching this). Wrapped in try/catch, if capture fails for any reason it falls back to the original text-only share — David explicitly said not to worry if it's not possible, so a fallback rather than a hard requirement.

## 10 July 2026 - Required descriptions, character limits, and slug-clear protection

- [storefront_settings.dart](lib/presentation/vendor/product/widgets/storefront_settings.dart):
  - Store name: required, min 2 / max 40 chars with live counter (`maxLength`).
  - Store description: required, min 30 / max 160 chars with live counter, placeholder "e.g. Handmade Ankara gowns, custom sizing, delivery across Lagos", helper "This helps your store get found on Google."
  - Slug-clear protection: new `_savedSlug` loaded from Firestore; `_effectiveSlug` getter falls back to the saved slug when the field is empty. Clearing the slug text no longer deletes an existing slug on save (store link stays intact); merchants who never had a slug can still save with it empty. Share Store / View Store buttons and the store-link helper now key off `_effectiveSlug`, and a grey hint explains "Leaving this empty keeps your current slug". Uniqueness query now only runs when the slug actually changed.
- [Add_product_page.dart](lib/presentation/vendor/product/widgets/Add_product_page.dart): product title required min 3 / max 60 with counter; description now REQUIRED (was optional), min 30 / max 200 with counter, placeholder "e.g. Premium leather sandals, available in 5 colors, true to size", helper "This helps your product get found on Google."
- [product_edit_screen.dart](lib/presentation/vendor/product/widgets/product_edit_screen.dart): same title/description rules, but validators skip entirely when `_canEditIdentity` is false (live/pending products have Name/Description locked — old short descriptions must not block price/stock edits).
- korra-landing (separate repo): ISR revalidate set to 180s (3 min) in lib/api.js REVALIDATE and the three store page `export const revalidate` lines, per David (fixes stale price display without hammering store-api).

## 10 July 2026 - Product edit fully locked + storefront SEO (flash-sale meta, sitemap index)

- [product_edit_screen.dart](lib/presentation/vendor/product/widgets/product_edit_screen.dart): Name and Description are now ALWAYS locked on the edit screen regardless of product status (previously rejected products could edit them). Images/category still follow `_canEditIdentity`.
- [store-api](supabase/functions/store-api/index.ts) — NEEDS REDEPLOY (`supabase functions deploy store-api`):
  - `action=product-urls` now fully paginates ALL approved products (1000/page loop, no 5000 cap) and vendors (no 2000 cap).
  - `action=slugs` uses the same paginated vendor walk (no 1000 cap).
  - New `action=store-stats` returns `{ stores: [{ slug, rating, reviewCount }] }` for the reviews-sitemap gate.
- korra-landing (separate repo):
  - Product page `generateMetadata`: if a timed deal covering the product is live right now (same startAt/endAt window logic as DealCountdown), prepends "🔥 Flash Sale Now On — " to meta + share descriptions and appends " · Flash Sale" to the title. No deal → unchanged behavior.
  - Sitemap converted to a real sitemap INDEX at /sitemap.xml (custom route handler; old app/sitemap.js deleted). Children under /sitemaps/: pages.xml, stores-{n}.xml (50k chunks), products-{n}.xml (ALL products, 50k chunks, no per-store cap), store-{slug}-products.xml per store (in addition to the combined ones), reviews.xml. Shared builder in lib/sitemaps.js; revalidate 3600 kept.
  - Reviews threshold in lib/reviewIndexing.js: REVIEW_INDEX_MIN_RATING = 3.5, REVIEW_INDEX_MIN_COUNT = 15. Stores below either bound: reviews page gets robots noindex (still follow) and is excluded from reviews.xml.
  - lib/api.js: new fetchStoreStats().

## 10 July 2026 - Outright order customer info fix + customer order view + nav reorder

- ROOT CAUSE of "Korra Customer"/missing phone: [outright-checkout](supabase/functions/outright-checkout/index.ts) read top-level `userData.firstName`/`userData.phone`, but customer docs nest identity under `personal.first`/`personal.last`/`personal.phone` and `address.{address,city,state}` (see Customer.fromMap). Fixed to read the nested maps (top-level kept as fallback) and now also writes `customerAddress` (joined address/city/state, empty string if profile blank) onto the order doc. NEEDS REDEPLOY: `supabase functions deploy outright-checkout`. Existing orders keep their old "Korra Customer" data; only new orders are fixed.
- [outright_order.dart](lib/data/models/vendor/outright_order.dart): added `customerAddress` (default '').
- [outright_order_detail_sheet.dart](lib/presentation/vendor/reservation/widgets/outright_order_detail_sheet.dart) (merchant): the phone number now shows as text under the customer name (call + WhatsApp buttons already existed, they were just hidden because phone was always empty); wa.me now converts local 0xxxxxxxxxx to 234xxxxxxxxxx; address card (location icon) appears only when customerAddress is non-empty, otherwise the row is simply absent.
- NEW [customer_outright_order_sheet.dart](lib/presentation/customer/storefront/widgets/customer_outright_order_sheet.dart): customer-facing outright order detail bottom sheet (styled like the plan detail, but a sheet not a hosted screen). Shows Order ID (copy + share-to-merchant buttons, share text includes items and total), status pill, items, summary, dates. The status card explains explicitly: "Delivery Processing" means the merchant hasn't marked delivered yet, payment IS complete, and prompts customer to share the Order ID and ask the merchant to mark it delivered.
- [storefront_purchase_history_sheet.dart](lib/presentation/customer/storefront/widgets/storefront_purchase_history_sheet.dart): outright entries are now tappable and open the new sheet (reservations already opened plan details).
- [customer_shell.dart](lib/presentation/customer/customer_shell.dart): bottom nav order is now Home, Stores, Plans, Profile. All hardcoded indices updated: onJumpToPlan → 2, cart signal badge → tab 1, home_page.dart jump-to-plans call sites → 2.

## 10 July 2026 - Storefront (website) sticky collection bar + card image cycling
- components/store/Storefront.js: isCompressed now measured from the filter bar's own position (getBoundingClientRect vs storebar height) instead of hardcoded scrollY > 245, so it stays correct when the Flash Deals/Featured strips mount/unmount.
- Selecting a collection while the bar is docked no longer smooth-scrolls from stale offsets (felt like a page reset): it re-measures after React re-renders and instantly pins the bar in place, PageView-style - the bar stays up and only the grid below swaps.
- Product cards now cycle their gallery images while in the viewport on touch devices (IntersectionObserver, threshold 0.6, hover: none media check), matching the app's store view. Hover cycling on desktop unchanged.
- David to test with npm run dev and deploy vercel --prod himself.

## 10 July 2026 - Card gallery: step-through instead of auto-recycle
- components/store/Storefront.js: each interaction now advances the gallery ONE image (hover on desktop, card scrolling into view on touch). Index persists - next hover/scroll shows the following image; no interval loop, no reset to first image.
- Single-image products play a quick zoom pulse (img-pulse class, cardImgPulse keyframes in app/store/store.css) so the card still reacts.
- Correction (same day): mobile trigger is TOUCH not scroll-into-view - onTouchStart on the card advances the image (works even when the finger starts a scroll gesture on it); IntersectionObserver removed.

## 10 July 2026 - Outright-only link guard + home page revamp
- Merchant side: shareable getter (vendor_products_state.dart) now also requires allowReservation, so outright-only products show no Share Link button anywhere (details screen, list rows, bloc guard).
- Customer side central guard: LinkBloc emits new LinkStatus.outrightOnly when a fetched product has allowReservation == false. New shared sheet lib/presentation/shared/widgets/outright_only_sheet.dart explains the product is sold outright only and deep-links to the merchant's storefront with the product detail sheet auto-opened (/store/{slug}?product={id}, slug resolved from vendors doc, falls back to vendor uid). Wired into: home page LinkBloc listener, plans page LinkBloc listener, ClipboardScannerHelper (checks before showing the prompt sheet). Covers old shared links and merchants who later disable reservation.
- Home page reorder (home_page.dart): wallet -> Start a new plan (code field) -> Your reserve plans -> Featured products -> Recent Activity.
- Plan carousel image shortened: _aspect 4/3 -> 16/9 in plan_carousel_slider.dart so wallet + code field + carousel fit one screen.
- New FeaturedProductsStrip (home/widgets/featured_products_strip.dart): up to 5 random approved in-stock products, round-robin across shuffled vendors (single vendor fills all 5), fresh shuffle per session; tap opens the store with that product's sheet open.
- SectionHeader gained optional icon (soft tinted circle) + subtitle; home headers now use them (add_circle/receipt_2/shop/activity). Existing headers elsewhere unaffected (params optional).

## 10 July 2026 - Plans page grid view (default) + list toggle
- New widgets/plan_card_grid.dart: compact 2-col card - image with status pill (OVERDUE red / PENDING amber / ACTIVE green / COMPLETED green / CLOSED grey - no AutoPay chip per David, autopay not available), title, store, slim progress bar + %, "N(amount) left" (total for finished plans), small Pay chip on payable plans only. Tap anywhere -> plan details.
- plans_page.dart: _gridView state (default true) persisted in SharedPreferences ('plans_grid_view'); header toggle button before search; body renders SliverGrid (mainAxisExtent 252.h) or the old PlanCard SliverList. Tabs, filters, sorting, pagination untouched.
- Also fixed home empty-plan copy: "Paste a product code above to start reserving" (was "link below", stale after the reorder).

## 10 July 2026 - Merchant products grid view toggle (list stays default)
- New widgets/product_grid_item.dart: 2-col catalog card - image with status pill (APPROVED green / PENDING amber / REJECTED red / NO STOCK grey), name, price, stock line (red out-of-stock, amber low-stock). Selection-mode check circle overlays top-right; tap = details (share/edit/delete live there), long-press = selection, brand border when selected.
- vendor_products_body.dart: converted to StatefulWidget; _gridView default FALSE (merchants manage, list reads faster) persisted in SharedPreferences ('vendor_products_grid_view'); toggle IconButton beside the search bar; grid renders via SliverGrid (mainAxisExtent 226.h) with same tap/long-press/selection wiring as the list. Search, filter pills, multi-delete bar untouched.
- Earlier same day: flash-deals countdown strip confirmed already shipped (hot_deals_strip + deal_countdown_badge) - stale memory note corrected. David has run the supabase function deploys (outright-checkout, store-api, record-visit).

## 10 July 2026 - Orders (reservations + outright) grid view toggle
- New widgets: reservation_grid_tile.dart (image + status pill NEW blue/ACTIVE green/READY orange/DELIVERED grey/CLOSED red, title, customer, progress bar + %, paid of total) and outright_order_grid_tile.dart (first item image + "+N" badge for multi-item orders, status pill, title +N more, customer, green check + total paid).
- reservation_list.dart / outright_order_list.dart: new grid flag - renders 2-col SliverGrid (mainAxisExtent 244.h / 218.h) with identical tap/long-press/selection-eligibility wiring as the list tiles.
- reservations_panel.dart / outright_orders_panel.dart: converted to StatefulWidget with ONE shared pref key 'vendor_orders_grid_view' (both order panels flip together), list default, compact right-aligned toggle IconButton above the status tabs.
- Correction (same day, David's feedback): the grid/list toggle moved OUT of the panels into the Orders page header (KorraHeader trailingActions, next to the search icon). reservations_page.dart now owns _gridView + the 'vendor_orders_grid_view' pref and passes grid: down; both panels reverted to StatelessWidget with a plain grid param.

## 10 July 2026 - Fix: Ready to Deliver duplicating reservations on scroll
- Root cause (reservations_repository.getReservations): Ready/Completed/New/Ongoing tabs filter CLIENT-SIDE after a raw limit*4 fetch, but the pagination cursor anchored to the last FILTERED item - so load-more re-scanned raw docs the filter had already seen and re-appended the same ready reservations every time the scroll trigger fired (trivially re-fired on short lists, incl. scrolling upward). Outright had no client filter, hence unaffected.
- Fix: cursor now anchors to snapshot.docs.last (where the scan actually stopped) unless the filtered page was truncated past 'limit' - then it anchors to the last kept item so the overflow serves next page. hasReachedMax is now !truncated && rawCount < limit*4 (a truncated page always has leftovers). Also fixes the all-filtered-out page previously returning lastDoc null and restarting the scan from page 1.
- Defense in depth: both ReservationsBloc._onLoadMore and OutrightOrdersBloc._onLoadMore now drop any incoming item whose id is already visible before appending.

## 10 July 2026 - Website: dead-link handling (no store discovery by design)
- Decision recorded: NO store directory/discovery on the website - Korra handles payments, does not vouch for or promote merchants; discovery happens via Google through the sitemap only.
- Deleted app/[categorySlug] legacy catch-all stub (was swallowing /store/ and any random one-word URL, printing it as a heading). NOT related to app links - those are static files in public/.well-known/, untouched.
- New app/store/page.js: bare /store redirects to the landing page (truncated share links).
- New app/not-found.js: branded neutral 404 (Korra icon, "This link doesn't lead to a store or product... ask the merchant to re-share the full link", brand button home, robots noindex). Real 404 status so Google drops dead product/store URLs instead of soft-404ing.
- Confirmed sitemap only emits full /store/{slug}, /store/{slug}/p/{id}, /store/{slug}/reviews URLs - bare /store never appears.
- David to test npm run dev and deploy vercel --prod.

## 12 July 2026 - Guest web checkout (outright purchases on korra.com.ng, no account)
BACKEND (needs deploy: web-checkout, monnify-webhook, store-api):
- NEW supabase/functions/web-checkout: action=init (validates cart server-side, compliance gate, fee 3.5% cap N7,500 from store.absorbOutrightFee, creates orders doc status 'pending' + paymentStatus 'awaiting' + webPurchase true; NO ledger/stock yet), action=status (polled by site; reference doubles as guest access token; returns merchant contact once paid), action=notify-delivered (HMAC-guarded, app-only; sends delivered email once via deliveredEmailSent flag).
- NEW supabase/functions/_shared/web_order_emails.ts: Resend sender from orders@korra.com.ng + confirmed/failed/delivered templates in send-email's visual language (DM Serif/DM Sans, dark hero). No em dashes.
- monnify-webhook: ROUTE 0 added at top of event handling - metaData.purchaseType == 'web_outright' routes to new handleWebOutrightPurchase; wallet top-up + payout routes byte-for-byte untouched. Handler: idempotent via paymentStatus, verifies amountPaid covers amountCharged ('underpaid' flag otherwise), atomic txn does stock decrement, order -> paid, vendor ledger sale (pending settlement, vendorNet = subtotal - fee only when merchant absorbs), vendor_stats, company fee ledger/wallet, web_purchases/{vendorId}/purchases/{orderId} dispute copy, activity feed, monthly stats, vendor notification; push + confirmation email after commit. FAILED_TRANSACTION with web metadata cancels awaiting order + failure email.
- store-api publicStore now includes absorbOutrightFee (display only).
WEBSITE (korra-landing):
- NEW app/api/checkout/route.js proxy (init/status only) + app/api/products/route.js (FIXES pre-existing broken infinite scroll - route never existed after the merge).
- NEW lib/monnify.js (SDK loader, inline overlay, metadata purchaseType/orderId; needs NEXT_PUBLIC_MONNIFY_API_KEY + NEXT_PUBLIC_MONNIFY_CONTRACT_CODE env).
- NEW components/store/GuestCheckout.js: form (name/email/phone) -> Monnify overlay -> verifying screen (order ID shown as pending, "keep screen open", polls status 3s up to ~3min, closing is safe - email closes the loop) -> confirmed screen (big copyable order ID, WhatsApp prefilled wa.me + tel fallback, receipt-sent note) / failed screen (retry). Premium styling in store.css (.gc-*), no colored borders, mobile + desktop.
- CartModal: real subtotal/fee/total (fee line hidden when merchant absorbs), Pay Now -> GuestCheckout (clears cart on paid), app handoff demoted to secondary link. ProductModal: Buy Now (primary) -> GuestCheckout single item; Pay Installment moved to secondary row (app-only, unchanged).
MERCHANT APP:
- OutrightOrder model: customerEmail, webPurchase, paymentStatus + isAwaitingPayment. TransactionModel: webPurchase.
- Order detail sheet: WEB chip, awaiting-payment banner (delivery blocked until webhook confirms), customer email shown. Tiles (list + grid): WEB chip, "Payment Pending" state. Bulk-select excludes awaiting-payment orders. Receipt screen: "Channel: Web Store" row.
- markOutrightOrderDelivered now fires web-checkout notify-delivered (fire-and-forget) for webPurchase orders - covers single + bulk.
DAVID TODO: supabase functions deploy web-checkout monnify-webhook store-api; add NEXT_PUBLIC_MONNIFY_API_KEY/NEXT_PUBLIC_MONNIFY_CONTRACT_CODE to Vercel + .env.local; vercel --prod; rebuild merchant app. Resend domain already verified (security@ works) so orders@ needs nothing.

## 12 July 2026 - Guest checkout QA fixes (David's device testing)
- Buy Now REMOVED from product modal per David - actions restored to Add to Cart + Pay Installment; web payment happens only via the cart's Pay Now.
- Cart stock caps: cart items now persist a stock field; addToCart and updateQuantity clamp against it; cart sheet + button disables at stock; product modal caps by (live stock minus what is already in cart) so reopening the sheet cannot re-add claimed units ("All stock in cart" state).
- Stale price fix (the N94,599 vs N104,949 Monnify mismatch): cart lines kept old prices from localStorage while the server charged current ones. cart.syncWithProducts refreshes price/stock/quantity from live product data on every storefront load; GuestCheckout now displays the SERVER quote after init, and if it differs from the cart's numbers it shows "store updated its prices, new total is X, tap Pay again" instead of opening Monnify with an unseen amount. Re-tapping reuses the same awaiting order (no duplicate pending orders).
- Stuck checkout fix: close button now always visible on the guest checkout sheet (was form-step only, so dismissing the Monnify overlay odd ways left no exit); scrim tap closes except during verifying.

## 12 July 2026 - Web checkout round 2 (David's QA feedback)
- Monnify overlay close now CANCELS the abandoned order (web-checkout action=cancel, reference as token, only when still awaiting; paymentStatus 'abandoned'). Webhook paid-update sets status back to 'pending' so a transfer that lands after a close restores the order. completedRef guards against cancelling after onComplete. Next Pay creates a fresh order (no reuse).
- Verification screen: polls for 5 minutes; on timeout shows "Unable to verify payment yet" state - receipt will arrive by email when it clears, contact support@korra.com.ng with the Order ID if a successful transfer never confirms.
- monnify.js defers onComplete/onClose ~60ms - fixes the removeChild crash on back AND the mobile blank-after-payment (same teardown race).
- Merchant Orders panel: awaiting-payment web orders split into their own "AWAITING PAYMENT" section below the paid list (OutrightOrderList gained showEmpty; panel splits paidList/awaitingList; shared _openDetail).
- lib/api.js: safeFetch wrapper - transient ECONNRESET/TLS drops log one line and fail soft instead of crashing renders.
- Desktop storefront: collection icon circles removed - pills everywhere (base CSS is now the pill system, no colored borders, inset shadow ring); collection-header is a flex row so the filter icon sits beside the label, not under it.
- Confirmation screen: WhatsApp button is WhatsApp green with the real logo glyph (new WhatsApp icon in Icons.js), call button has phone icon.
- Storefront freshness: silent client re-sync of stock/price/discount for loaded products on mount + every 60s while tab visible (patches fields only - no layout jumps; checkout still server-validates). ISR stays at 180s for the SSR shell.

## 12 July 2026 - Awaiting Payment tab + customer app cart stock caps
- OutrightOrderStatus gained awaitingPayment; model's status getter maps webPurchase + paymentStatus 'awaiting' + raw 'pending' to it (isAwaitingPayment now derives from status).
- Orders panel: "Pending Payment" is a real tab (amber, between New and Delivered); inline AWAITING PAYMENT section removed. Repo getOutrightOrders splits New vs Pending Payment client-side over the shared 'pending' Firestore status with the corrected cursor pattern (raw-last unless truncated, over-fetch x2); counts (stream + fetch) tally awaitingPayment separately via shared _countByStatus, so the home KPI's New count no longer includes unpaid web orders. Bloc/state carry countAwaitingPayment. Badges added in tile ("Awaiting Payment"), grid tile ("UNPAID"), detail sheet pill.
- Customer app cart caps (mirror of the web fixes): CartItem persists stock; CartService.addToCart clamps combined quantity to live stock, updateQuantity clamps stepper at item stock, new quantityInCart helper. Product details sheet: stepper and Add to Cart now cap at stock MINUS what the cart already holds (reopening can't re-add the same stock; button reads "All stock in cart" when exhausted; qty resets after add).

## 13 July 2026 - Checkout complete-screen regression fix, Last Viewed, Promotions snapshot
WEBSITE (korra-landing, needs vercel --prod):
- Monnify back-button fix, round 2: lib/monnify.js now guarantees a callback. Watchdog polls for the overlay iframe; if it vanishes without the SDK firing onComplete/onClose (their teardown crashes with removeChild on browser-back AND on the post-payment close), we synthesize the right one: a postMessage sniffer listens to the Monnify iframe's messages (SUCCESS/COMPLETED/PAID markers) so a completed payment routes to onComplete (verifying screen) instead of being treated as a close. popstate (phone back) handled the same way. A window error trap swallows monnify.js's internal removeChild crash. FIXES David's regression where completing a payment bounced back to the checkout form and never showed confirming/confirmed.
- GuestCheckout onClose is belt-and-braces: before cancelling an "abandoned" order it asks the server (action=status) once; if the webhook already marked it paid, it jumps straight to the confirmed screen and fires onPaid (cart clears). Cart clearing after payment works through both paths now (onPaid on poll-confirm and on close-confirm).
- Spam-folder line added on the verifying / confirmed / unverified screens ("check your spam folder").
- Cart secondary button copy: "Prefer the app? Continue in Korra" -> "or continue in the app".
BACKEND (needs deploy: monnify-webhook, web-checkout, outright-checkout, view-reengagement):
- Web order push icon: monnify-webhook Route 0 push used icon "ic_launcher" which resolved wrong and showed the FLUTTER logo in the Android status bar; now "notification_icon" (the manifest default all working pushes use). Wallet/payout routes untouched.
- PROMOTIONS SNAPSHOT: outright-checkout and web-checkout init now read the vendor's campaigns at purchase time; a product's campaignTag counts only if its owning campaign is live (untimed = live until deleted, timed = only while dealEndAt in future - expired countdowns leave stale tags on products). Active tags are copied per-item (item.promotion) and order-level (promotions: string[]) onto the orders doc + the customer receiptData. Snapshot semantics: kept even if the campaign later expires/is deleted. Hidden when empty (no "Promotions: None").
- NEW supabase/functions/view-reengagement (CRON - David must schedule it hourly like the other automations): drains view_reengagement_queue markers whose notifyAt (first qualifying view + 24h) has passed; per customer reads recent_views, keeps >=5s dwell within the window (purchased items were already deleted by the app), picks the longest dwell (random among ties), sends ONE push + in-app notification (type last_viewed with productId/vendorId/slug), deletes the marker regardless so no duplicates ever.
FLUTTER (rebuild both apps):
- LAST VIEWED (customer): new logic/services/recent_views_service.dart writes customers/{uid}/recent_views/{productId} (max dwell, viewedAt, product snapshot incl. slug) when the product details sheet closes after 5+ seconds (stopwatch in initState/dispose); <5s is never logged. Prunes >24h docs opportunistically. First qualifying view creates view_reengagement_queue/{uid} (notifyAt = +24h), later views never push it back.
- New store/widgets/last_viewed_strip.dart on the Stores page (below Hot Deals, hidden while searching): 24h window, newest first, tap opens the product's detail sheet inside its merchant storefront (/store/{slug}?product=), renders NOTHING when empty by design.
- Purchase exclusion: outright checkout success and plan creation success both call RecentViewsService.removePurchased (fire-and-forget) so bought items vanish from Last Viewed immediately.
- Notification tap routing: type 'last_viewed' deep-links to /store/{slug}?product={id}.
- Promotions display: OutrightOrder model gained promotions list; merchant order detail sheet and customer order sheet (purchase history) show a "Promotions" row of amber tag chips only when non-empty.
- Custom campaign tag capped at 16 chars (was 20) in create_campaign_sheet.
DAVID TODO: supabase functions deploy monnify-webhook web-checkout outright-checkout view-reengagement; SCHEDULE view-reengagement hourly (Supabase dashboard cron, like the other automations); Firestore rules: allow customer read/write own customers/{uid}/recent_views/** and create view_reengagement_queue/{uid} (function deletes them); vercel --prod; rebuild both apps; retest web payment complete + back-button + cart clearing.

## 14 July 2026 - Campaign analytics, history, soft-delete + Web Activity
WHY THE OLD COUNT WAS WRONG: record-visit bumped openCount on every active campaign on every storefront open (per app session), no per-customer/per-day dedupe.
BACKEND (needs deploy: record-visit, outright-checkout, web-checkout, monnify-webhook, store-api):
- record-visit split into two pipelines. APP: vendor_metrics unchanged (Most Visited stays in-app only) + campaign opens now deduped per customer per calendar day via campaigns/{id}/opens/{customerId}_{yyyy-MM-dd} marker create(); fresh markers increment openCount AND dailyOpens.{date}. App now sends customerId (storefront_screen). No customerId = no campaign open. WEB (source 'web' + sessionKey): session-per-day dedupe via web_activity/{vendorId}/sessions markers, bot user-agents dropped, increments web_activity/{vendorId} total + daily only - NEVER campaigns or vendor_metrics.
- Purchase attribution: outright-checkout and web-checkout snapshot promotionCampaignIds (internal, never displayed) alongside the promotions tags; outright-checkout increments campaigns.purchases in the txn; monnify-webhook web handler increments purchases on webhook-confirmed payment only, plus web_activity purchasesTotal/purchasesDaily (raw Web Purchases count, no rate vs page views by design).
- Soft delete: deleteCampaigns now sets archived+endedAt (batch update, not delete); product tag/price revert unchanged. Archived excluded in: Campaign.isActive (model), record-visit opens, both checkout activePromo helpers, store-api fetchDeals, create sheet's max-3 limit (counts only currently ACTIVE: not archived, countdown not expired).
FLUTTER (rebuild merchant app):
- Campaign model: purchases, dailyOpens map, archived, endedAt + isPast/endDate/conversionRate helpers.
- NEW campaign_analytics_sheet.dart - tap any campaign banner (active or history) on the Campaigns screen: dark headline "X opens · Y purchases", unique-opens note, borderless stat tiles (opens/purchases/conversion), expandable daily breakdown with proportional bars (multi-day campaigns only). No border lines anywhere - tone + shadow separation.
- NEW campaign_history_tile.dart + Campaign History section on the SAME campaigns screen below active list: thumb, title, caption, tag, run dates (endedAt or dealEndAt), opens · purchases · conversion, newest first. Header now reads "Active Campaigns (n)".
- Expired countdown sweep: campaigns whose timer ran out get auto-archived once per session on screen open (also reverts their lingering product tag/discount - nothing else ever cleaned those up).
- NEW web_activity_card.dart on campaigns screen (own section): Today / Last 7 days / Web Purchases tiles + permanent caption "Approximate: counts page visits to your web store, not unique people." (deliberately not "visitors"; no em dashes).
WEBSITE (vercel --prod): NEW app/api/visit proxy (passes real UA through for the bot filter); Storefront.js pings once per store per browser session (sessionStorage key + server-side dedupe).
DAVID TODO: deploy the five functions above; Firestore rules: merchant read own web_activity/{vendorId} (opens/sessions markers are admin-SDK-only, no client rule needed); rebuild merchant + customer apps; vercel --prod. Note: existing openCount values keep their old inflated totals - only counting going forward is deduped (dailyOpens starts fresh).

## 14 July 2026 - History placement, daily breakdown fix, firebase rules, date grouping + pagination audit
- Campaign History moved ABOVE Active Campaigns: compact preview (3 most recent) + "View all" (shows when >3) opening a full CampaignHistoryScreen grouped by month ("This Month", month names, year appended only when not the current year).
- Analytics daily breakdown WAS built but hidden unless a campaign already had 2+ days of dailyOpens (which only starts collecting after the new record-visit deploys). Now: always rendered below the stat tiles, expanded by default (header collapses it), proportional bar per day; friendly note when no daily data exists yet.
- firebase_rule.txt updated (David publishes in console - fixes the web_activity PERMISSION_DENIED logs): vendor reads own web_activity/{vendorId} (sessions markers locked); customer owns customers/{uid}/recent_views; view_reengagement_queue/{uid} read+create by owner (cron deletes); campaigns/{id}/opens locked to admin SDK.
- NEW shared date_group_label.dart: recencyGroupLabel (Today / Yesterday / Last Week / Last Month / month names, ", yyyy" only when not current year - never starts with This Month) + monthGroupLabel (This Month / month names) + DateGroupHeader widget.
- Recency group headers applied to: merchant outright orders list, merchant reservations list (list view only - 2-col grids stay unbroken), merchant notifications, customer notifications, customer purchase history sheet (undated entries skip headers).
- Merchant settlement & ledger screen: daily separators like customer statements (Today / Yesterday / full date) - visual separation only, tiles unchanged.
- Pagination audit: orders/reservations (cursor), plans (dynamic limit), vendor products (limit), customer ledger (20), vendor activity feed (20), cash/liability ledgers (dynamic) all already bounded. Fixed two unbounded streams: vendor notifications now limit(50), vendor reviews now limit(50).
DAVID TODO: publish firebase_rule.txt rules in Firebase console; rebuild both apps.

## 14 July 2026 - Vendor capacity restore on outright sales + Crashlytics
- CAPACITY BUG: outright sales (app + web) decremented stock but never released the capacity that inventory held in vendor_stats.totalLiability (listing price x stock, same math delete-product-secure uses), so vendors permanently lost limit with every sale. outright-checkout and monnify-webhook's web handler now: totalLiability -= listingPrice x qty sold (listing price, not discounted - liability was charged at listing price), totalSalesVolume += subtotal, earnings unchanged (vendorNet already handled fee-absorb + store-credit split). web-checkout init untouched by design - the webhook is the real final transaction for web. NEEDS DEPLOY: outright-checkout, monnify-webhook.
- CRASH ANALYTICS (Firebase Crashlytics, global funnel - no per-callsite edits): firebase_crashlytics ^5.0.2 in pubspec (pub get ran clean); crashlytics gradle plugin added (settings.gradle.kts 3.0.6 + app plugin). NEW logic/services/crash_service.dart: KorraCrash.init() in bootstrap (both flavors) wires FlutterError.onError + PlatformDispatcher.onError (fatals), KorraBlocObserver (every bloc/cubit's unhandled errors as non-fatals), authStateChanges -> setUserIdentifier, collection disabled in debug builds. Repository coverage: KorraException now records itself to Crashlytics as a non-fatal on construction (with technicalDetails as reason) - every repo failure reaches the dashboard even when the UI handles it. Everything no-ops on web (plugin has no web support; web builds unchanged).
DAVID TODO: deploy outright-checkout + monnify-webhook; rebuild both apps (first build needs the new gradle plugin; Crashlytics console shows data after the first non-debug run).

## 14 July 2026 - Firebase Analytics (comprehensive, role-tagged)
- NEW logic/services/analytics_service.dart: single funnel wrapping FirebaseAnalytics (already in pubspec). Every event auto-injects role=customer|merchant, and app_role is set as a user property + analytics userId synced to the signed-in uid, so ANY event segments by who fired it. Role-specific events also carry customer_/merchant_ name prefixes so they read clearly in the raw event list. Fully guarded (fire-and-forget, never throws, never blocks a flow). AnalyticsEvents catalog holds every event name in one place (GA4-legal snake_case).
- Analytics.init() called in BOTH mains right after AppConfig.init (needs the flavor to know the role); collection disabled in debug builds.
- screen_view auto-logged on every route via FirebaseAnalyticsObserver wired into GetMaterialApp.navigatorObservers (korra_app.dart) - this powers "which screens do customers/merchants use most".
- Wired events (no behaviour change, pure logging): CUSTOMER - add_to_cart, remove_from_cart, product_viewed (with dwell seconds), product_shared, outright_started/success/failed (with value+currency), last_viewed_tapped, featured_tapped, notification_opened. MERCHANT - campaign_created, campaign_deleted, campaign_analytics_viewed, campaign_history_viewed, order_delivered, reservation_fulfilled, notification_opened. Existing scattered logEvent calls in auth/plan/payout/kyc/product blocs left as-is (already tracked).
- Note: web_activity_viewed event dropped - the card is always visible on the (already screen-tracked) campaigns screen, no distinct action to hang it on.
DAVID TODO: rebuild both apps; GA4 shows events after first non-debug run (debug builds don't collect). No console setup needed - events auto-register.

## 16 July 2026 - Small UX fixes: campaign history preview count, recommended stores cap, read-only cart product view
- Campaign History preview (vendor_campaigns_body.dart): now shows only the 2 most recent, and the "View all" button appears once there is a 3rd (was previewing 3 / showing View all past 3).
- "Recommended From Your Stores" (recommended_stores_section.dart): still scoped strictly to the customer's OWN network badge-holders (never a discovery feed) and has no "View all". When there are MORE than 5 badge-holders it now shows a RANDOM 5, re-rolled each time the Stores screen is opened (stable within a single view; earned badges still surface first among whichever 5 show). 5 or fewer = show all.
- Read-only cart product view: tapping a cart item now opens the full product details sheet in a new readOnly mode (storefront_product_details_sheet.dart gains `readOnly`) - hides the quantity stepper AND the Add to Cart / Pay Installments actions, and does NOT record a view (a cart peek must not feed Last Viewed / re-engagement). Cart tile (storefront_cart_item_tile.dart) gained an optional onTap; cart sheet (storefront_cart_sheet.dart) fetches the product doc on tap to build the rich view (cart only stores a light CartItem).
## 16 July 2026 - Campaign tag/discount lifecycle: expiry gate + one-campaign-per-product (app + site)
Problem: a product's campaignTag/discountedPrice are fixed fields on the product doc, only reverted by deleteCampaigns (manual delete OR the merchant-side sweep that fires only when the merchant opens the Campaigns tab). So a TIMED campaign that expired kept its tag/discount until the merchant opened that tab, and the website (which never runs the sweep) lingered indefinitely. Also products could be added to multiple campaigns at once.

Fix (self-describing data, no sweep dependency):
- Product model (product_model.dart): NEW field `campaignEndsAt` (DateTime?, set only for TIMED campaigns; null = untimed = runs until deleted). NEW getters: `promoActive` (tag set AND (untimed OR before end)), `activeCampaignTag`, `activeDiscountedPrice`. Wired through constructor/create/copyWith/fromMap/toMap.
- Campaign creation (create_campaign_sheet.dart): the product batch now writes `campaignEndsAt` = dealEndAt for timed campaigns, and FieldValue.delete() for untimed (clears any stale end time from a prior expired campaign on that product).
- Revert (vendor_campaigns_repository.deleteCampaigns): also deletes campaignEndsAt alongside campaignTag/discountedPrice.
- APP display/pricing now read the ACTIVE getters so an expired/ended campaign reverts tag AND price everywhere: storefront_card_image, storefront_details_carousel, storefront_product_card, storefront_product_details_sheet, cart_service (finalPrice), storefront_screen (deals-only filter, price sort, and the plan-data map it hands to create_plan). Raw-map readers gated with an explicit campaignEndsAt check: featured_products_strip, create_plan_screen.productPrice (installment plan price now reverts to full price once a timed campaign ends).
- ONE CAMPAIGN, ONE TAG PER PRODUCT (product_selector_page.dart): the New Campaign product picker now hides any product with an active promo (promoActive). Once its campaign ends/expires/deletes, it reappears and can take a fresh campaign + tag.
- SITE display (supabase/functions/store-api publicProduct): gates campaignTag + discountedPrice by campaignEndsAt in ONE place, covering every site surface (store page, product page, modal, cart display). No site JS component edits needed - they read the already-gated payload.
- SITE + APP authoritative charge (web-checkout + outright-checkout): the unit price now only honors discountedPrice when the product's OWNING campaign is still live (reuses the existing activePromo/activeCampaigns check, which already excludes archived + expired). This closes the window between expiry and the sweep, and also covers deleted/archived campaigns. monnify-webhook UNCHANGED - it finalizes using the amount web-checkout already computed correctly.
- Note on delete (David corrected me twice): (1) on delete the product tag DOES revert correctly; (2) deleted/expired campaigns are already excluded from Hot Deals + the Deals page (both filter !campaign.isActive). The ACTUAL lingering issue: the Hot Deals card (hot_deals_strip.dart HotDealCard) showed deal.tags = the tags of EVERY active campaign the store runs, overlaid on the NEWEST campaign's image (deal.latest). So an older campaign's tag appeared sitting on the new campaign's picture.
FINAL DECISION (David): Hot Deals is now ONE CARD PER LIVE CAMPAIGN, not per store. _buildDeals no longer groups byVendor - it emits one StoreDeal (single-campaign) per active campaign, so a store running 3 campaigns shows 3 separate cards, each with its own image + tag, sorted newest-first across all stores. This makes the tag-image mismatch structurally impossible (each card = 1 campaign). The interim "show only deal.latest.tag" chip fix still stands (each deal now has one campaign anyway). deals_page _DealListCard "other running tags" section (deal.tags.skip(1)/>1) is now effectively dead since each deal holds one campaign - harmless, left in place.
DAVID TODO: deploy store-api, web-checkout, outright-checkout edge functions; rebuild both apps. No webhook change. Existing products already in campaigns before this change have no campaignEndsAt (treated as untimed = show until deleted), which is correct.

## 16 July 2026 - Explore Stores scoped to the customer's own network (was a global directory)
- Bug: the customer Stores page "Explore Stores" list streamed the ENTIRE vendors collection (every non-banned merchant), so it read as a global store directory instead of the stores the customer has interacted with.
- Fix (store_page.dart): added _networkStream = customers/{uid}/my_vendors.snapshots(). The Explore Stores list is now filtered to that network set BY DEFAULT (when the search box is empty). SEARCH is deliberately left unscoped - typing a name/store-code still searches all vendors so a customer can find a NEW store to interact with (that's the intended discovery path, by code/link, not a browsable directory).
- vendorsById (all vendors) is still built as a lookup map for HotDealsStrip + RecommendedStoresSection to resolve names without extra reads - it's not the visible list.
- (Superseded next entry: Hot Deals is now network-scoped too.)

## 16 July 2026 - Closed marketplace scoping + Save/Unsave rename + merchant Saves count
GOAL: Korra customer discovery is a CLOSED marketplace (customer's saved stores only), not an open public directory. "Saved store" = the customer has a my_vendors/{vendorId} doc (auto-created on app purchases/plans by outright-checkout + plan-manager; web checkout does NOT auto-save, by design; also created by manual Save). NOTE: no DB rename - "pin" stays the field/flag name; only UI copy changed to Save.
- Scoping (all in the customer app):
  - Explore Stores: already scoped (prev entry) to my_vendors; search still reaches any store by code.
  - Featured Products (featured_products_strip.dart): now pulls approved products only from the customer's my_vendors stores (whereIn chunks of 10, status filtered in memory - no new index). No saved stores => empty.
  - Hot Deals (store_page.dart): HotDealsStrip is handed a network-filtered vendorsById (only my_vendors), so it only surfaces deals from saved stores.
  - Campaigns: already network-scoped - campaign-broadcast fans out via collectionGroup('my_vendors').where('vendorId','==',vendorId) (saver circle only). Deals "View all" page is fed from the (now scoped) Hot Deals. Recommended already scoped.
  - Last Viewed: INTENTIONALLY left cross-store (a viewed product can show even from an unsaved store, if it meets dwell/24h/not-purchased) - it's a way to help other merchants gain customers. Unchanged.
- Save/Unsave rename (storefront_screen.dart _togglePin + storefront_header.dart): UI now says "Save Store"/"Saved" (was Pin/Pinned); snackbars "Store saved."/"Store unsaved." (no em dashes). GUARD: a customer CANNOT unsave a store while they hold a store balance there (DB field storeCredit, always shown in UI as "store balance") - the my_vendors doc carries the balance, so unsave is blocked until it's zero with an info snackbar. Store balance now tracked live in _storeBalance from the same my_vendors snapshot the save-state listener already uses.
- Merchant Saves count (NEW saves_count_card.dart, added to vendor_campaigns_body analytics section under CampaignReachCards): borderless premium card (white, radius 18, soft shadow - NOT the bordered reach-card style). Counts customers who saved the store LIVE via collectionGroup('my_vendors').where('vendorId','==',vendorId).count() - moves BOTH ways (up on save, down on unsave), no maintained counter to drift. Number formatting TikTok/Instagram style: <1000 raw ("342"), >=1000 one-decimal K/M with trailing .0 stripped ("1K","1.2K","15.3K","1.5M"). Refreshes each time the campaigns screen opens (count() is a one-shot aggregate, not a stream).
- firebase_rule.txt: added a collectionGroup rule `match /{path=**}/my_vendors/{docId} { allow read: if isAuthenticated() && resource.data.vendorId == request.auth.uid; }` so a vendor can count docs referencing them, constrained to their own vendorId (no customer-data leak). The collectionGroup index on my_vendors.vendorId ALREADY EXISTS (campaign-broadcast relies on it) - no new index needed.
DAVID TODO: publish firebase_rule.txt (needed for the merchant Saves count query - until then it logs PERMISSION_DENIED); rebuild customer + merchant apps. Featured Products whereIn needs no new index.
OPEN (needs David): "kDebug errors being logged" - need the actual error text to diagnose. Likely candidates from tonight until rules deploy: web_activity / my_vendors collectionGroup PERMISSION_DENIED (resolve on rule publish). Paste the red log lines to pin it.

## 16 July 2026 - Scale/perf: Stores page network-first loading + merchant-app leak scan
STORES PAGE (store_page.dart) refactor for growth (was: streamed the ENTIRE vendors collection live on every page load):
- Removed _vendorsStream (whole-collection live stream). Vendor docs are now loaded on demand + memoized (_vendorDocsFor/_fetchVendorDocs):
  - DEFAULT (no search): fetch ONLY the saved stores' vendor docs via whereIn(FieldPath.documentId) in chunks of 10 - reads scale with the customer's network, not the marketplace. Keyed by the sorted network set so it refetches only when saved stores change.
  - SEARCH: one on-demand .get() of the whole vendors collection (where status != banned), cached under a stable 'search' key so it runs ONCE per search session and is reused across keystrokes; filtered by name/slug (+vendorId) client-side. NOTE: store CODE search is not wired yet (only slug exists) - when storeCode lands, add one more .contains() in the search match.
  - Structure: outer StreamBuilder(_networkStream) -> FutureBuilder(vendor docs) -> campaigns StreamBuilder -> cart ValueListenableBuilder -> CustomScrollView. Hot Deals/Recommended are hidden while searching so the all-vendors payload there is harmless.
  - Featured Products (home) also bounded: now samples up to 8 random saved stores before the whereIn, so reads stay flat (~<=40) regardless of network size.
  - Does NOT touch Last Viewed (separate recent_views collection) - a viewed product still qualifies whether the store is saved/searched/unpurchased.
MERCHANT-APP LEAK/PERF SCAN (David asked): 
- GOOD: no manual StreamSubscription/Timer in vendor UI (nothing to leak). List streams are paginated/bounded (products .limit, orders .limit, reservations .limit*4, reviews .limit, vendor notifications .limit(50)). Single-doc stat streams are fine. Product tab-counts already use efficient .count() aggregates.
- GROWTH CONCERN — NOW FIXED (David approved "as long as safe at scale"): the ORDER and RESERVATION home tab-count badges used to stream the WHOLE orders/plans collection live just to tally statuses. Converted both to server-side .count() aggregates:
  - outright_orders_repository.streamOutrightCounts -> Stream.fromFuture(_outrightCounts): 5 count() queries (pending, awaiting=web+awaiting+pending, readyToDeliver, delivered, cancelled); New = pending - awaiting (unconfirmed web payments never count as New, as before).
  - reservations_repository.streamCounts -> Stream.fromFuture(_reservationCounts): newRes=active created today; ongoing=allActive-newRes; completed=completed WITH finalFulfilledAt (counted via orderBy('finalFulfilledAt'), which only matches docs where the field exists); ready=allCompleted-completed; cancelled=whereIn[cancelled,defaulted]. Buckets mirror the old client categorization EXACTLY.
  - Kept the Stream<Map<...>> return type via Stream.fromFuture so vendor_home_body's nested StreamBuilders are UNCHANGED (zero UI edits, lowest risk). Tradeoff as agreed: counts refresh when the home rebuilds (on stats change / navigation) rather than ticking live; ~10 cheap aggregate reads per refresh vs streaming whole collections. Both wrapped in try/catch -> return {} on error, so a missing index shows 0 badges + a debugPrint, never a crash.
  - The paginated list getters still use the old per-page _countByStatus on their bounded pages - unchanged.
  DAVID TODO (indexes - a missing one just shows 0 for that bucket + a debug log until added; Firestore's error gives the create link): orders composite (vendorId + webPurchase + paymentStatus + status) for the awaiting count; plans composite (vendorId + status + finalFulfilledAt) for the fulfilled/ready split; (vendorId + status + createdAt) for newRes likely already exists (getReservations uses it); single (vendorId + status) counts likely already exist.

## 16 July 2026 - Landing page restructure: retention-first homepage + /installments route (korra-landing, Next.js)
FRAME (David's spec): retention is the umbrella. Korra = the customer retention tool; installments and the storefront are both mechanisms under it, neither leads alone. App = primary pillar (most copy/visual weight), website storefront = secondary/supporting. Terminology: "store balance" ONLY, never "store credit". NO em dashes anywhere in copy.
- MOVED, NOT REWRITTEN: the old homepage (full installment explainer) now lives at /installments, content unchanged. New files: app/installments/page.js (old home metadata, canonical https://korra.com.ng/installments) + components/landing/InstallmentsClient.jsx (verbatim copy of old HomeClient; only change: FAQ line "stays as credit" -> "stays as store balance").
- NEW HOMEPAGE (components/landing/HomeClient.jsx rewritten): hero leads with retention ("Keep your customers coming back", storefront + a way to pay that doesn't turn people away, WhatsApp/Instagram selling stays); dark insight strip ("Getting a customer once is easy. Keeping them is the business."); #app section (PRIMARY, 5 features: storefront, installments, store balance, saved stores, campaigns) with phone-duo mockups; "How Korra Installments Work" TEASER section (few lines + Link to /installments); #website section (SECONDARY, smaller: free store page, Google discovery, shareable link, framed as feeding the app); FAQ (same 6 items, backs the homepage FAQPage JSON-LD); orange CTA; footer/nav updated (The App / Website Storefront / Installments).
- SCREENSHOT PLACEHOLDERS: 3 .shot-placeholder frames inside .phone-screen (hero: storefront view; app section duo: store balance + saved stores). David will supply real screenshots (storefront mockup NOT yet available, he will send); swap each placeholder div for an <img>. CSS appended at end of app/globals.css.
- METADATA: app/page.js + app/layout.js retitled retention-first ("Korra | Keep Your Customers Coming Back"); /installments carries the old installment SEO. lib/sitemaps.js pageEntries now includes /installments. organizationJsonLd untouched (already retention-worded, FAQ @id stays on homepage).
- SiteChrome.jsx (nav/footer for /merchants + /privacy): anchors updated from dead /#businesses|customers|how to /#app, /#website, /installments; footer-desc retention-worded.
- STORE CREDIT SWEEP: grepped whole korra-landing project; only offender was that one FAQ line (fixed in both FAQ copies). Privacy policy already says "store balance". Remaining "credit" mentions are "not a loan or credit system" (correct usage).
- VERIFIED: npm run build passes; /installments is a new static route (7.54 kB).
DAVID TODO: send the 3 real app screenshots (storefront view, store balance display, saved stores) to replace the placeholders; deploy the site (vercel) when ready.

## 16 July 2026 - Product VARIANTS (flat labeled, per-variant stock) end to end + Last Viewed cap
DECISION (David): flat labeled variants, NOT an attribute matrix. A variant = free-text label + its own stock ("XL", "40", "XL / Red", "Ankara 500ml"). Combinations live in the label. One system covers size/color/material/scent/anything. Backward compatible: products without variants keep flat availableStock everywhere.
INVARIANT: when variants exist, availableStock is ALWAYS the recomputed sum of variant stocks, enforced on EVERY write path server-side. All existing readers of availableStock (JSON-LD, sold-out badges, campaign eligibility, counts) needed zero changes.
- MODEL: product_model.dart adds ProductVariant {label, stock} + variants list + hasVariants/variantStock getters; ProductItem (vendor state) mirrors it. Plan model + Reservation model + OutrightOrderItem gain variantLabel (+displayTitle helpers).
- MERCHANT EDITOR: new product_variants_editor.dart (rows: label + qty + delete, add-row button, running total). Wired into Add_product_page + product_edit_screen; when variants exist the flat Stock field mirrors the sum (so limit header/plan logic unchanged). Validation: unique labels, total > 0. Events VendorProductsAdd/Edit carry variants; bloc sends them in productMap/updateData.
- SERVER (products): add-product-secure + edit-product-secure sanitizeVariants (<=30, labels unique/non-empty <=40 chars, stock int >=0); server sum OVERRIDES client stock; edit with empty list DELETES the variants field (reverts to flat). NOTE: an outdated app editing a variant product would wipe variants; both apps must ship together.
- CUSTOMER APP: details sheet — variant products show VariantQuantityList (new storefront_variant_picker.dart): one stepper per variant, capped at stock minus in-cart, single Add to Cart adds all lines (5 x XL + 2 x XXL in one tap). Pay Installments first opens showVariantChooser (single pick, stock-gated) because ONE PLAN = ONE UNIT of ONE VARIANT (David's rule). Flat products keep the old single stepper.
- CART: CartItem gains variantLabel; line identity = product+variant (separate lines per variant); per-line stock cap = variant stock; cart tile shows a variant chip; checkout payload items carry variantLabel.
- PLAN FLOW (variantLabel threading, minimal inserts only): storefront_screen -> route args -> CreatePlanScreen.variantLabel -> LoadPlanPreview -> fetchPlanPreview body. create_plan_screen NOT restructured (one constructor param + one event arg only, per David).
- plan-manager (SURGICAL inserts only, no restructuring, per David):
  - PREVIEW: validates chosen variant exists + stock>=1, seals variant_label INSIDE the signed JWT (client can't forge at CREATE).
  - CREATE: re-validates the token's variant in-transaction; stamps variantLabel on the plan doc; stock decrement now variant-aware (deduct chosen variant, availableStock = recomputed sum); flat products keep the exact old increment(-1).
  - CANCEL: product pre-read added to PHASE 1 (reads-first rule); release restores the exact variant (+1 + recomputed sum), falls back to total-only +1 if the label vanished. PAY_INSTALLMENT/EXTEND/BULK_FULFILL untouched.
- CHECKOUTS: outright-checkout validates variant per line (cumulative across lines of same product), stamps variantLabel on order items, decrements via per-product aggregated variants write (flat products keep blind increments). web-checkout validates + stamps variantLabel but does NOT decrement (order pending until payment).
- ⚠️ MONNIFY-WEBHOOK TOUCHED (web-order branch ONLY - David REVIEW BEFORE DEPLOY): the web-order stock loop (was items.find + blind increment) is now variant-aware and aggregates lines per product. Wallet/payout routes byte-for-byte untouched. This was unavoidable: web stock deducts on payment confirmation, which only happens here.
- CANCEL/EXPIRY RESTORES (all variant-aware, restore exact variant + recomputed sum, fallback +1): plan-manager CANCEL, send-reminders performAutoCancellation (product read added at transaction top), korra_expiry_automation (read in PHASE 1), process-overdue (batch can't read: pre-reads products, mutable working copy handles multiple plans restoring same product in one run; tiny read-then-batch race accepted). korra_notification_automation: NO stock ops, untouched.
- DISPLAYS: plan details header (variant chip), purchase history sheet (plans + orders), customer/vendor outright order sheets, vendor reservation tiles + detail sheet ("Variant" row in financial breakdown so merchant knows which unit to reserve).
- WEB (korra-landing, the LIVE merged project; old korra-store project NOT updated - it's rollback only): store-api publicProduct exposes variants[]; lib/cart.js line identity product+variant, per-variant caps, syncWithProducts drops vanished/sold-out variant lines; ProductModal variant stepper rows + Add to Cart (n); CartModal variant tag + variant-aware steppers/remove; GuestCheckout payload carries variantLabel; store.css variant styles appended. npm run build PASSES.
- LAST VIEWED: capped at max 5 entries (take(5) after the 24h filter in last_viewed_strip.dart). Also confirmed Recommended stores section already caps at random 5.
DAVID TODO: rebuild BOTH apps together (old merchant app editing a variant product would drop its variants); deploy edge functions: add-product-secure, edit-product-secure, plan-manager, outright-checkout, web-checkout, store-api, send-reminders, process-overdue, korra_expiry_automation, and REVIEW+deploy monnify-webhook (web-order branch diff only); deploy korra-landing site. flutter analyze not yet run (ask David first, per rule).

## 17 July 2026 - Landing: real app screenshots + Get Started copy refresh
- SCREENSHOTS: David dropped 4 jpgs in the korra repo root; converted to webp (sharp, 800px wide, q82) into korra-landing/public/assets and wired into the homepage phone frames (all 3 .shot-placeholder frames now show real screens):
  - Hero (storefront view): shot-storefront.webp (korra_merchan_storeview.jpg - customer browsing a store's product grid)
  - App section duo left: shot-installments.webp (korra_customer_products_details.jpg - product page with Add to Cart + Pay Installments)
  - App section duo right: shot-saved-stores.webp (Korra_customer_storespage.jpg - Stores page: last viewed, recommended, explore)
  - SPARE (converted, in public/assets, not yet placed): shot-merchant-products.webp (Korra_merchant_product_list.jpg - merchant Products manager)
- GET STARTED MODAL (words only, both HomeClient + InstallmentsClient, no em dashes): Businesses "Run your store" / "Set up your storefront, manage products, and offer installments, all from one place." Customers "Shop your favorite stores" / "Browse, save your stores, and pay at your own pace with a clear plan and visible progress." APK Drive links in constants/links.js already matched David's, unchanged.
- npm run build PASSES.
PENDING (David asked, awaiting his confirmation of the rule before ANY money code): outright purchase fee rework - fee split into cash fee (3.5% of wallet-cash portion, cap 7500, merchant-absorbable) + store-balance usage fee (0.35% of credit used, MIN 100, ALWAYS paid by customer from wallet, NEVER absorbable). Store balance would apply to SUBTOTAL only; all fees from wallet. Affects outright-checkout + cart sheet preview math; web-checkout unaffected (no store balance on web). Mirrors plan-manager's existing full-payment fee model.

## 17 July 2026 - Outright fee rework: split cash fee vs store-balance usage fee (CONFIRMED by David)
RULE: store balance pays for the PRODUCT (subtotal) only; every fee is paid from the customer's WALLET.
- Cash fee: 3.5% of the wallet-cash portion of the subtotal, cap 7,500. The ONLY fee absorbOutrightFee applies to (absorbed = deducted from the merchant's take; else customer pays on top).
- Store balance usage fee: 0.35% (10% of 3.5%) of creditUsed, MIN 100, CAP 1,000 (David added the 1k cap 17 Jul). ALWAYS the customer's, from wallet, NEVER absorbable (merchant receives no cash on that portion). Example: balance 10,150 buying 10k product -> 10k from balance, customer pays 100 from wallet, merchant nets 0, absorb is a no-op.
- OUTRIGHT-CHECKOUT ONLY (David confirmed): plan-manager installment/full-payment fees untouched; web-checkout untouched (no store balance on web, its 3.5% on subtotal IS the cash fee).
- supabase/functions/outright-checkout/index.ts: new constants STORE_FEE_RATE/MIN_STORE_FEE/MAX_STORE_FEE; split creditUsed=min(balance,subtotal) + cashPortion; vendorNet = cashPortion - (absorb ? cashFee : 0); customerTotal = subtotal + customerFeePaid; walletUsed = cashPortion + customerFeePaid; wallet-too-low-for-store-fee gets its own error message. Order doc gains cashFeeAmount/storeFeeAmount (feePaidBy still describes the cash leg); receipt/ledger feeAmount = what the CUSTOMER paid (cashFeeAmount + storeFeeAmount broken out, plan-manager receipt style); company_ledger amount = cashFee + storeFee with a breakdown description.
- APP CART SHEET (storefront_cart_sheet.dart): preview math mirrors the server exactly (fee now computed INSIDE the balance StreamBuilder since it depends on storeApplied). Summary shows two fee rows: "Processing Fee" (cash fee, absorbable, hidden when 0) + "Store balance fee (min 100, max 1,000)" (hidden when 0). Confirm dialog unchanged (subtotal + customer fee == storeApplied + walletDue identity still holds). Vendor order UI reads no fee fields - no change needed.
DAVID TODO: deploy outright-checkout; rebuild customer app (cart preview). Note: old app versions preview the OLD fee against the NEW server math until users update - the server is authoritative either way.

## 18 July 2026 - Top Seller / Most Visited metrics fixed (SERVER-ONLY, no app rebuild needed)
David flagged the merchant reach metrics. Audit found 3 real issues; all fixed in edge functions only - the already-shipped app reads the same fields/endpoints unchanged.
1. compute-visibility: topSellerCircles was showing the store's VISIT count (visits.get(id) || 1) - a strong seller with few visits showed "1 circles" and both cards could show the same number. NOW: circle size = customers who saved the store (collectionGroup my_vendors count, same aggregate as the app's Saves card), counted only for the <=20 badge winners. Matches the shipped app copy "Ranked per customer circle".
2. compute-visibility rollingVisits: fallback to lifetime visitsTotal now ONLY when the doc has no daily map at all (legacy docs). Before, a store with old-only daily entries kept ranking on lifetime total forever - stale stores now decay to 0.
3. record-visit APP pipeline: visits now deduped ONE per customer per store per calendar day via marker doc vendor_metrics/{vendorId}/visitors/{customerId}_{yyyy-MM-dd} (create() = dedupe, same pattern as campaign opens). Client-side dedupe was per app session only, so relaunching inflated Most Visited (floor is just 10 visits/30 days). No customerId -> not counted. Campaign opens + Web Activity already deduped, untouched.
EXPECTED EFFECT after deploy: visit numbers grow slower (honest count); Top Seller reach number changes meaning to saves count - this matches the card caption already in the app.
DAVID TODO: deploy record-visit + compute-visibility. No app change, no Firestore rules change (both functions use admin SDK).
