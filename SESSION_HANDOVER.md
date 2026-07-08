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
