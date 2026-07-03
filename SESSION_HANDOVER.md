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

## 16. This Session — Exact Changes Made

### Firebase Analytics Added to 10 BLoC/Cubit files:

| File | Events Added |
|---|---|
| `auth/role_login/role_login_bloc.dart` | `login_success` (email + google), `login_failed` |
| `auth/signup_customer/signup_customer_bloc.dart` | `sign_up`, `signup_failed` |
| `auth/signup_vendor/signup_vendor_bloc.dart` | `sign_up`, `signup_failed` |
| `customer/plans/create_plan_bloc.dart` | `plan_preview_loaded`, `plan_created`, `plan_creation_failed` |
| `customer/plans/pay_plan_bloc.dart` | `installment_paid`, `installment_payment_failed` |
| `customer/plans/plan_action_bloc.dart` | `installment_paid`, `plan_cancelled` |
| `customer/plans/plan_action_cubit.dart` | `plan_converted_to_store_credit`, `plan_extended` |
| `customer/kyc/customer_kyc_bloc.dart` | `kyc_bvn_verified`, `kyc_nin_verified` |
| `vendor/product/vendor_products_bloc.dart` | `product_added`, `product_deleted`, `products_deleted_bulk` |
| `vendor/payout/payout_bloc.dart` | `payout_initiated`, `payout_failed` |

### Startup & Build Performance Optimizations:
- Created [lazy_indexed_stack.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/shared/widgets/lazy_indexed_stack.dart) under shared widgets.
- Fixed compilation parameter error in [lazy_indexed_stack.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/shared/widgets/lazy_indexed_stack.dart) by mapping the `fit` parameter to `sizing` inside `IndexedStack`.
- Refactored [customer_shell.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/customer_shell.dart) and [vendor_shell.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/vendor_shell.dart) to replace `IndexedStack` with `LazyIndexedStack` to optimize startup rendering and prevent all tab pages from building at launch.
- Configured R8 Full Mode in [gradle.properties](file:///c:/Users/USER/Desktop/flutter_projects/korra/android/gradle.properties) by adding `android.enableR8.fullMode=true` for optimal release code shrinking.

### NotificationService Singleton Implementation:
- Converted `NotificationService` in [notification_service.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/logic/services/notification_service.dart) to extend `GetxService` and implement a static `to` getter.
- Moved repository and UID parameters to the `initialize` method so that it does not require constructor arguments.
- Managed single-registration of message handlers and listeners via `_listenersRegistered` boolean to avoid duplicate FCM initialization on page rebuilds.
- Registered the service globally inside [bootstrap.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/bootstrap.dart) using `Get.put()`.
- Updated [home_page.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/home/home_page.dart) and [home_page.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/home/home_page.dart) to call `NotificationService.to.initialize(...)` instead of instantiating new objects.

### GoogleFonts Caching (Central Style Files Optimization):
- Restructured [text_styles.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/config/constants/text_styles.dart) by resolving the `'Inter'` font family string once at class loading time via `GoogleFonts.inter().fontFamily!`.
- Implemented `KorraTextStyles.inter(...)` helper method that returns a standard `TextStyle` using the cached font family name.
- Replaced all inline `GoogleFonts.inter(...)` calls inside [text_styles.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/config/constants/text_styles.dart) and [input_styles.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/config/constants/input_styles.dart) with the new optimized `KorraTextStyles.inter(...)` helper. This eliminates dynamic GoogleFonts lookups and dynamic platform resolution on every widget rebuild.

### Constructor Dependency Injection Cleanup (Architecture Refactoring):
- Wrapped the root-level `GetMaterialApp` inside [korra_app.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/korra_app.dart) in a flavor-specific `RepositoryProvider` (`CustomerRepository` or `VendorRepository`). This exposes the active repository via context globally across both shell routes and all dynamically pushed routes.
- Refactored [bank_details_screen.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/profile/bank_details_screen.dart), [statements_screen.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/profile/statements_screen.dart), and [edit_profile_screen.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/profile/edit_profile_screen.dart) to remove `CustomerRepository` from their constructors and class fields. They now fetch the repository instance directly from context using `context.read<CustomerRepository>()`.
- Refactored [create_plan_screen.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/plans/create_plan_screen.dart), [plan_details_screen.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/plans/widgets/plan_details_screen.dart), [plan_details_loader_screen.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/plans/widgets/plan_details_loader_screen.dart), [pay_plan_input_screen.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/plans/widgets/pay_plan_input_screen.dart), and [change_password_screen.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/profile/change_password_screen.dart) (both customer and vendor versions) to resolve repositories from the widget build context rather than constructors, completely removing constructor parameters and arguments on navigation routes.
- Fully completed Customer-side DI refactoring: removed `CustomerRepository` constructor parameters from [HomePage](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/home/home_page.dart), [PlansPage](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/plans/plans_page.dart), [ProfilePage](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/profile/profile_page.dart), [NotificationScreen](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/home/notification_screen.dart), and [LimitUpgradeScreen](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/profile/limit_upgrade_screen.dart).
- Cleaned up [customer_shell.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/customer_shell.dart) (no longer passes `customerRepo` to tab pages), and updated route definitions in [app_pages.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/config/routes/app_pages.dart) for `customerNotifications` and `customerLimitUpgrade` to drop repository route arguments.
- Refactored [pay_confirmation_sheet.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/plans/widgets/pay_confirmation_sheet.dart) to resolve `CustomerRepository` from context rather than constructor params/helper args.
- Fully completed Vendor-side DI refactoring: removed `VendorRepository` constructor parameters from [VendorHomePage](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/home/home_page.dart), [VendorHomeBody](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/home/vendor_home_body.dart), [VendorVaultScreen](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/home/widgets/vault_screen.dart), [VendorProductsPage](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/products_page.dart), [AddProductPage](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/Add_product_page.dart), [ProductDetailsScreen](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/product_details_screen.dart), [ProductEditScreen](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/product_edit_screen.dart), [PayoutSettingsScreen](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/profile/payout_settings_screen.dart), [VendorSettlementScreen](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/profile/vendor_settlement_screen.dart), [VendorProfilePage](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/profile/profile_page.dart), and [ReservationsPage](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/reservation/reservations_page.dart).
- Cleaned up [vendor_shell.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/vendor_shell.dart) (no longer passes `repo` to tab pages), and updated route definitions in [app_pages.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/config/routes/app_pages.dart) for all vendor sub-pages (`vendorReservations`, `vendorAddProduct`, `vendorProductDetails`, `vendorEditProduct`, `vendorSettlement`, and `vendorPayoutSettings`) to drop repository route arguments, utilizing `context.read<VendorRepository>()` dynamically instead.
- Cleaned up duplicate `db` field from both `CustomerRepository` and `VendorRepository`, unifying all Firestore queries onto the `firestore` property, and updated references accordingly (e.g. inside `create_plan_screen.dart`).
- Replaced hardcoded `korraSecret` string constants inside `CustomerRepository` and `VendorRepository` with environment configuration (`dotenv.env['KORRA_SECRET_CODE']`).
- Optimized `plans_page.dart` by removing duplicate `StreamBuilder<List<Plan>>` inside the AppBar and instead using `_cachedPlans` to serve list data to search delegate.
- Decomposed `plans_page.dart` by extracting the private `_SkeletonCard` widget to a public `PlanSkeletonCard` widget under `widgets/plan_skeleton_card.dart`.
- Flattened the nested `StreamBuilder` tree in `plans_page.dart` by replacing the outer customer profile stream builder with a background `StreamSubscription` in `initState` to prevent profile updates from triggering plans list reload cycles.
- Decomposed `vendor_home_body.dart` by extracting the liveness failure blocker modal sheet to a public standalone `LivenessBlockerSheet` widget under [liveness_blocker_sheet.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/home/widgets/liveness_blocker_sheet.dart).
- Decomposed `plan_details_screen.dart` by extracting status banners, completed pickup arrangements, financial progress tracking, timeline grace periods, target payment calculator details, metadata info grids, resolve sheets, conversion sheets, and sticky bottom action bars into separate reusable widgets, shrinking the file size from 1,372 lines to 337 lines.
- Fixed a nesting compilation error in [korra_app.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/korra_app.dart) where the conditional `isMerchant` RepositoryProvider block was accidentally placed inside the `_PremiumDesktopBlocker` widget class instead of the root `KorraApp` class.

### Widget Performance Extraction (create_plan_screen.dart cleanup):
- Extracted `_PenaltyExplainerSheet` to public widget `PenaltyExplainerSheet` in [penalty_explainer_sheet.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/plans/widgets/penalty_explainer_sheet.dart).
- Extracted `_buildFullPaymentSuccess` to public widget `FullPaymentSuccessCard` in [full_payment_success_card.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/plans/widgets/full_payment_success_card.dart).
- Extracted `_buildModelPill` to public widget `PlanModelPill` in [plan_model_pill.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/plans/widgets/plan_model_pill.dart).
- Extracted `_buildDurationCard` to public widget `PlanDurationCard` in [plan_duration_card.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/plans/widgets/plan_duration_card.dart).
- Extracted `_buildLiabilityDisclaimer` to public widget `PlanLiabilityDisclaimer` in [plan_liability_disclaimer.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/plans/widgets/plan_liability_disclaimer.dart).
- Refactored [customer_shell.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/customer_shell.dart) and [vendor_shell.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/vendor_shell.dart) to replace `IndexedStack` with `LazyIndexedStack`.
- Configured R8 Full Mode in [gradle.properties](file:///c:/Users/USER/Desktop/flutter_projects/korra/android/gradle.properties).

### Widget Performance & Cleanup:
- Extracted `PlanLimitContainer`, `PlanImageCarousel`, `PlanPaymentModeToggle`, `PlanGoalSelector`, `PlanCadenceSelector`, `PlanCommitmentMessage`, `PlanBottomBar`, and `PlanLiabilityCheckbox` to public widgets.
- Decomposed `vendor_home_body.dart` by extracting the `LivenessBlockerSheet`.
- Decomposed `plan_details_screen.dart` into reusable modules (banners, pickup arrangements, financial progress, etc.).
- Fixed nesting compilation error in [korra_app.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/korra_app.dart).
- Decomposed `Add_product_page.dart` and `product_edit_screen.dart` by extracting shared widgets: `ProductLimitHeader`, `ProductModelTabs`, `ProductCategorySelectorSheet`, and `ProductInfoBox`.
- Consolidated duplicated KYC code by creating 6 shared, flavor-agnostic fields (`KycBvnField`, `KycNinField`, `KycDobSelector`, `KycGenderSelector`, `KycPhoneSection`, and `KycPremiumInput`) under `lib/presentation/shared/widgets/kyc/` and integrated them into both customer and vendor KYC sheets, deleting over 1,200 lines of duplicated code.
- Decomposed customer `pay_plan_input_screen.dart` by extracting its fee breakdown preview card to a standalone `PayPlanFeeSummary` widget.
- Optimized customer `profile_page.dart` by extracting the `LevelUpSlotsRow` to a standalone widget with its own `StreamBuilder`.
- Refactored vendor `profile_page.dart` to extract `StaticInfoRow` to a dedicated widget file.

### Created:
- `SESSION_HANDOVER.md` (this document) in project root


### Widget Rebuild Optimizations (Phase 3.2):
- Added `buildWhen` filters to `BlocBuilder` and `BlocConsumer` blocks across several screens and widgets:
  - [AddProductPage](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/Add_product_page.dart)
  - [ProductEditScreen](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/product_edit_screen.dart)
  - [CreatePlanScreen](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/plans/create_plan_screen.dart)
  - [ReservationsPage](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/reservation/reservations_page.dart) (deep properties comparison implemented for non-Equatable state)
  - [PayoutScreen](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/payout/payout_screen_ui.dart)
- Cleaned up obsolete Paystack-to-Monnify migration references across all documentation.

### State Management Consolidation (Task B):
- Consolidated `PlanActionBloc` and `PlanActionCubit` by transferring the enums `PlansTab` and `SortBy` directly to the top of [plan_action_cubit.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/logic/bloc/customer/plans/plan_action_cubit.dart).
- Decommissioned and emptied the unused [plan_action_bloc.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/logic/bloc/customer/plans/plan_action_bloc.dart) to remove dead code.
- Updated imports in [plans_page.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/plans/plans_page.dart), [plans_filter_sheet.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/plans/widgets/plans_filter_sheet.dart), and [segmented_tabs.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/plans/widgets/segmented_tabs.dart) to resolve from the cubit file.

### Print Cleanups (Task D):
- Replaced all raw `print(...)` statements with standard `debugPrint(...)` in:
  - [app_pages.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/config/routes/app_pages.dart)
  - [vendor_repository.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/data/repository/vendors/vendor_repository.dart)
  - [create_plan_screen.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/plans/create_plan_screen.dart)
  - [profile_page.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/profile/profile_page.dart) (commented print updated)

### Static Analysis & Const Constructors (Task A):
- Added `prefer_const_constructors` and `prefer_const_literals_to_create_immutables` rules to [analysis_options.yaml](file:///c:/Users/USER/Desktop/flutter_projects/korra/analysis_options.yaml).
- Audited recently refactored widgets (e.g. KYC selectors, liveness blocker, plan summaries) to ensure constructor declarations and usage conform to `const`-safe requirements.

### Vendor/Customer Repository Decomposing (Task A Extension):
- Split `CustomerRepository` into `customer_auth_repository.dart` and `customer_profile_repository.dart` as extensions.
- Split VendorRepository into vendor_auth_repository.dart, vendor_stats_repository.dart, and vendor_settings_repository.dart as extensions (including implementing the missing `changePassword` method in the auth extension).
- Cleaned up duplicate/deprecated imports, unused local variables, and fields across both repository directories.
- Consolidated duplicate `_formatDobForBvn` helper declarations into the centralized `formatDateOfBirthForBvn` helper in `date_formatters.dart` (cleaned up 4 duplicate implementations).
- Fixed `catchError` handlers on both `verification_repository` files to return proper types (`then<void>((_) {})`).
- Ran static analysis on `lib/data/repository/` and verified 0 warnings or errors.

### AppBar StreamBuilder Optimizations (Task B):
- Optimized the notification badge stream builder on both customer `HomePage` and `VendorHomePage` AppBars.
- Moved the `StreamBuilder` inside the `Positioned` widget so that only the badge red dot rebuilds dynamically, preventing redundant rebuilds of the entire `IconButton` and its handlers.

### APK Size Reduction & Modular Flavor-Routing (Phase 4):
- Split monolithic `app_pages.dart` into `common_pages.dart`, `customer_pages.dart`, and `vendor_pages.dart` to separate routes and screen imports.
- Updated `main_customer.dart` and `main_vendor.dart` to load respective flavor route files, allowing the tree-shaker to omit merchant screens in customer APKs and vice versa.
- Converted `monnify.png` to WebP (`monnify.webp`) and updated all codebase references (`role_login_screen.dart`, `image_string.dart`).
- Created `unused_assets/` at the root and moved all unused original png/json files there (`google-logo.png`, `korra_logo_icon.png`, `moniepoint.png`, `paystack.png`, `monnify.png`, and `payment_sucess.json`).
- Audited Lottie animation packages, verified they are unused, removed `lottie` dependency from `pubspec.yaml`, and deleted empty assets directories.

### Navigation Freeze Resolution & Pop Optimization:
- Replaced custom `Get.back()` navigation calls with standard native `Navigator.pop(context)` in `KorraHeader` (the default back action) to guarantee full compatibility with predictive back gestures in Flutter 3.22/3.24.
- Updated all occurrences of `Get.back()` in customer screens (`create_plan_screen.dart`, `limit_upgrade_screen.dart`, `notification_screen.dart`, `plan_details_loader_screen.dart`, `plan_details_screen.dart`, `change_password_screen.dart`, and `edit_profile_screen.dart`) to standard native pops, resolving routing stack corruption/freezing.
- Cleaned up the `customer_failure_sheet.dart` UI buttons to natively dismiss modal sheets using standard `Navigator.pop(context)`.
- Removed unused `get` package imports from modified profile screens to maintain zero warnings.

### Web Optimization & Auth Service Fixes:
- Safeguarded `GoogleSignIn.instance.signOut()` calls across `AuthService`, `CustomerAuthRepository`, and `VendorAuthRepository` with `kIsWeb` platform checks and a 2-second timeout fallback. This completely prevents the web app from getting stuck on unresolved native futures during startup/zombie checks or logout events.
- Optimized `web/vercel.json` configurations by introducing high-performance edge-caching headers for CanvasKit WebAssembly modules and application assets (`/assets/(.*)` and `/canvaskit/(.*)`), boosting repeat page load speed on Vercel.
- Created a comprehensive [design.md](file:///C:/Users/USER/Desktop/flutter_projects/korra/design.md) specification file in the root of the project, detailing the brand palette, typography scales, layout spacing, shape corners, component metrics, and micro-interactions for other design/developer agents.

### Clipboard Product Scanner (Task F):
- Converted [customer_shell.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/customer_shell.dart) to include a stateful lifecycle observer body (`_CustomerShellBody`) that watches for launch and app resume (`WidgetsBindingObserver`).
- Implemented a secure [clipboard_scanner_helper.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/plans/widgets/clipboard_scanner_helper.dart) utility:
  * Automatically scans the device clipboard for standard Korra product code patterns (`^K-[A-Z0-9]{4}-[A-Z0-9]{7}$`).
  * Fetches the product from Firestore and prompts a beautiful custom bottom sheet preview.
  * Caches the scanned code to `SharedPreferences` to prevent repeat dialog popups for the same code.
  * Automatically bypasses web instances (`kIsWeb`) to prevent browser popup interference.

### Post-Auth Redirect Flow (Task G):
- Updated [role_login_screen.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/auth/role_login/role_login_screen.dart) to check for a `redirect` parameter inside route arguments on login success.
- New users are forwarded to customer/vendor signup screens with the `redirect` route passed along.
- Existing users are routed to their target deep-link screen using a stack-safe dual transition (`Get.offAllNamed(shellRoute)` followed by `Get.toNamed(redirectRoute)`), ensuring proper back button behavior.
- Integrated matching post-signup redirect handlers inside [signup_customer_screen.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/auth/signup_customer/signup_customer_screen.dart) and [signup_vendor_screen.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/auth/signup_vendor/signup_vendor_screen.dart).

### App Links & Universal Links Configuration (Task H):
- Configured dynamic `appLinkHost` manifest placeholders per build flavor inside [build.gradle.kts](file:///c:/Users/USER/Desktop/flutter_projects/korra/android/app/build.gradle.kts).
- Added an auto-verifying `<intent-filter>` bound to `${appLinkHost}` inside [AndroidManifest.xml](file:///c:/Users/USER/Desktop/flutter_projects/korra/android/app/src/main/AndroidManifest.xml) to isolate routing behavior per flavor APK.
- Created [Runner.entitlements](file:///c:/Users/USER/Desktop/flutter_projects/korra/ios/Runner/Runner.entitlements) listing both subdomains to enable iOS Associated Domains / Universal Links.
- Generated unified configuration files [assetlinks.json](file:///c:/Users/USER/Desktop/flutter_projects/korra/web/.well-known/assetlinks.json) and [apple-app-site-association](file:///c:/Users/USER/Desktop/flutter_projects/korra/web/.well-known/apple-app-site-association) under the `web/.well-known/` directory to serve verified association signatures for both subdomains.

### App Download Interstitial (Task I):
- Created [app_download_interstitial.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/shared/pwa/app_download_interstitial.dart) to show a download recommendation overlay on mobile web browsers (Android and iOS).
- Utilized SharedPreferences to cache user dismissals so they are not prompted again during the active session.
- Configured dynamic redirection links pointing to the Play Store closed test tracks per build flavor (`customer` vs `merchant`).
- Integrated the rendering logic into the root stack builder of [korra_app.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/korra_app.dart) (currently commented out as requested).

### Monnify, Clipboard, and Product Casing Bug Fixes (Task J):
- **Monnify Init Fix**: Wrapped the `_initMonnify` call in [bank_details_screen.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/profile/bank_details_screen.dart) inside `Future.delayed(Duration.zero)` to prevent synchronous `setState` build-time crashes when live keys are missing.
- **Clipboard Timeout & Delay**: Added a 2-second delay and a 2-second `.timeout()` guard to `Clipboard.getData` inside [clipboard_scanner_helper.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/plans/widgets/clipboard_scanner_helper.dart) to prevent native channel hangs on launch.
- **Product Code Normalization**: Updated the query in [plans_repository.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/data/repository/customer/plans_repository.dart) to automatically convert codes to uppercase (e.g., `K-SMTN-91F175A`) before querying Firestore. This ensures search matches succeed regardless of whether the customer typed or pasted it in lowercase, uppercase, or mixed-case.
- **Monnify Web JS SDK Modal Overlay**:
  * Injected the Monnify JS SDK script tag inside the HTML head of [index.customer.html](file:///c:/Users/USER/Desktop/flutter_projects/korra/index.customer.html) and [web/index.html](file:///c:/Users/USER/Desktop/flutter_projects/korra/web/index.html).
  * Updated [bank_details_screen.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/profile/bank_details_screen.dart) to import `dart:js` and invoke `MonnifySDK.initialize` directly via JS interop when running on Web (`kIsWeb`).
  * Passed the required `metadata: { customerUid: uid }` payload to ensure your Monnify webhook correctly associates successful transactions with the correct customer ID in Firebase.
  * This keeps web payments inside the application overlay, preventing browser redirects and app reloads while ensuring Firestore updates stream in real-time.
- **Vercel Caching Bypass for Environment Configurations**:
  * Added a top-level rule to [vercel.json](file:///c:/Users/USER/Desktop/flutter_projects/korra/web/vercel.json) to disable caching specifically for `.env` and `.env.prod` files (matching path `/assets/.env*`).
  * This bypasses the default 1-year browser/CDN caching for web assets, ensuring customers instantly load newly updated API keys without requiring manual cache clears or incognito windows.
- **Temporary Cache-Buster Script**:
  * Injected a temporary cache-reset script inside [index.customer.html](file:///c:/Users/USER/Desktop/flutter_projects/korra/index.customer.html), [index.merchant.html](file:///c:/Users/USER/Desktop/flutter_projects/korra/index.merchant.html), and [web/index.html](file:///c:/Users/USER/Desktop/flutter_projects/korra/web/index.html).
  * The script automatically unregisters old service workers and clears browser cache storage on the next page load for returning users.
  * *Note: Recommend removing this script after a couple of days to restore standard offline caching benefits.*
- **Automated Merchant Storefronts**:
  * Added route constant `Routes.customerStorefront = '/store/:slug'` in [app_routes.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/config/routes/app_routes.dart) and registered it in [customer_pages.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/config/routes/customer_pages.dart) for deep-linking compatibility.
  * Implemented [storefront_screen.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/storefront/storefront_screen.dart) displaying branded cover/banner, contact links, pin/unpin toggles, search, and category filtering.
  * Integrated navigation inside [my_vendors_screen.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/profile/my_vendors_screen.dart) to redirect users to their storefronts on card tap.
  * Created [store_page.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/store/store_page.dart) and integrated it as the third navigation tab (Stores) in [customer_shell.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/customer_shell.dart), aligning bottom navigation order to `{ Home, Plans, Stores, Profile }`.
  * Added dynamic product preview thumbnails inside the Explore Stores list item cards, displaying up to 3 featured products under each merchant.
  * Configured [storefront_screen.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/storefront/storefront_screen.dart) with a header back button, resolved the customer profile type casting exception when clicking product cards, and added a receipt button in the top right to stream purchase history created specifically with that merchant.
- **Storefront Performance Optimization & Refactoring**:
  * Decomposed large inline widget trees in `StorefrontScreen` and `StorePage` into standalone memory-efficient widgets under respective `/widgets/` subdirectories:
    * [discover_store_list_item.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/store/widgets/discover_store_list_item.dart)
    * [storefront_header.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/storefront/widgets/storefront_header.dart)
    * [storefront_filter_bar.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/storefront/widgets/storefront_filter_bar.dart)
    * [storefront_product_card.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/storefront/widgets/storefront_product_card.dart)
    * [storefront_purchase_history_sheet.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/storefront/widgets/storefront_purchase_history_sheet.dart)
  * Cleansed and streamlined [storefront_screen.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/storefront/storefront_screen.dart) from >1000 lines down to ~400 lines to optimize CPU rendering cycles and memory usage.
- **Merchant Product Installment Toggles & UI Enhancements**:
  * Integrated an "Allow Installments (Reservation)" toggle switch into [Add_product_page.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/Add_product_page.dart) and [product_edit_screen.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/product_edit_screen.dart).
  * Collapses/hides timeline selectors and model tabs when disabled, streamlining product listing.
  * Mapped `allowReservation` through the BLoC layer (using `VendorProductsAdd` and `VendorProductsEdit` in `vendor_products_event.dart`) to persist the boolean state to Cloud Firestore.
  * Resolved compile-time errors in `product_edit_screen.dart` and `products_page.dart` by adding `allowReservation` (with JSON mapping and props) to `ProductItem` model inside `vendor_products_state.dart`, and corrected `unselectedStyle` to `unselectedLabelStyle` on the custom TabBar indicator.
  * Redesigned the product card in [product_list_item_premium.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/product_list_item_premium.dart) using clean, border-free containers, standard Material and `MdiIcons` (removing `iconsax`), a flat monospace product code text, and replaced the outright info icon with a clean shopping bag icon.
  * Added top padding to the search bar inside [vendor_products_body.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/vendor_products_body.dart) for clean breathing room.
- **Product Management Widgets Refactoring (Memory & Performance Optimization)**:
  * Decomposed large inline widget trees in `AddProductPage`, `ProductEditScreen`, and `ProductDetailsScreen` into standalone, memory-efficient widgets under the `/widgets/` directory:
    * [product_restriction_banner.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/product_restriction_banner.dart)
    * [product_submit_area.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/product_submit_area.dart)
    * [product_timeline_logic_box.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/product_timeline_logic_box.dart)
    * [product_strict_settings_card.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/product_strict_settings_card.dart)
    * [product_direct_settings_card.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/product_direct_settings_card.dart)
    * [product_details_gallery.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/product_details_gallery.dart)
    * [product_details_timeline.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/product_details_timeline.dart)
  * Shrunk page controller/viewer sizes: `Add_product_page.dart` (~1300 to ~900 lines), `product_edit_screen.dart` (~1200 to ~700 lines), `product_details_screen.dart` (~500 to ~330 lines) to prevent unnecessary rebuild churn and CPU rendering overhead.
  * Extracted image gallery slider index page tracking into a localized stateful widget (`ProductDetailsGallery`) to eliminate main details page rebuilds on slide actions.
- **Storefront Contact Privacy & Link Sharing**:
  * Introduced a **"Contact Phone (Business Line)"** setting inside [storefront_settings.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/storefront_settings.dart) with a phone prefix icon, alongside WhatsApp, Instagram, and Twitter (X) fields utilizing `FaIcon` (FontAwesome).
  * Defaults to the verified personal number as a fallback.
  * Enforced storefront slug uniqueness checking in `_saveSettings` to prevent duplicate slugs across merchants.
  * Added a **"Share Store Link"** shortcut below the slug input using `share_plus` to allow quick sharing of the `https://korra.shop/store/{slug}` storefront link.
  * Modified the repository [vendor_settings_repository.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/data/repository/vendors/vendor_settings_repository.dart) and [storefront_screen.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/storefront/storefront_screen.dart) to write and fetch this contact number.
- **Product Details & Outright Purchases**:
  * Tap gestures on storefront product cards now trigger a dynamic **Product Details Sheet** instead of redirecting directly to plans.
  * Displays a green "Installment Plan Available" badge if installments are enabled, or a grey "Outright Purchase Only" badge if disabled.
  * Configured card model tags to display **"OUTRIGHT"** if `allowReservation` is false.
  * Implemented a **"Buy Outright"** action with confirmation. Executes a Firestore write batch to deduct the price from the customer's `availableBalance`, decrement the product's `availableStock`, and record the order as a completed plan with `modelType: 'outright'` and `status: 'completed'`.
- **Unified Debug App Switcher Discarded**:
  * Deleted `lib/main_debug.dart` as requested by the user, adhering strictly to target build configurations.
- **Compilation Correctness & Deprecations Resolution**:
  * Resolved the remaining compile error in [Add_product_page.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/Add_product_page.dart) by defining `_showContactSheet` using `ContactSupportSheet`, and removed the unused `_blockMessage` field and its corresponding handler.
  * Removed unused classes, imports, and methods across `product_details_screen.dart`, `Add_product_page.dart`, and `product_edit_screen.dart`.
  * Replaced deprecated `withOpacity` calls with `.withValues(alpha: ...)` across details screens and timeline widgets.
  * Corrected deprecated `activeColor` to `activeThumbColor` for Switch widgets.
- **Outright Purchase Order Handling (Vendor-Side UI)**:
  * Modified the `Reservation` model inside [reservation.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/data/models/vendor/reservation.dart) to parse and support `modelType` (e.g., `'outright'`), introducing an `isOutright` getter.
  * Refactored [reservation_tile.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/reservation/widgets/reservation_tile.dart) (list view item) to hide active saving progress percentages/progress bars for outright purchases, showing a solid green "Outright Purchase" status with 1.0 progress.
  * Updated status badges on the list view tiles to show "Ready to Deliver" (for ready to fulfill state) or "Delivered" (for history state) when the order is an outright purchase.
  * Updated [vendor_reservation_detail_sheet.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/reservation/widgets/vendor_reservation_detail_sheet.dart) to show "Order Details", "Ready to Deliver / Order Delivered", "Mark as Delivered" actions, and contextualize the financial breakdown to hide outstanding balances for outright payments.

---

## 17. What to Do Next (Prioritized)

### Short Term (Next 1–2 Sessions)
1. **Shorebird OTA Integration**:
   - Integrate **Shorebird** for push-to-device Over-The-Air (OTA) updates on Android and iOS (bypassing App Store/Play Store review delays for minor updates).
2. **App Links & Deep Linking (Web & Mobile)**:
   - **Cross-Platform Dual Domains**: Configure independent App Links / Universal Links for each app:
     * **Customer App (`app.korra.com.ng`)**: Map App Link domains and associated `.well-known` configurations to the Customer app.
     * **Merchant App (`business.korra.com.ng`)**: Map App Link domains and associated `.well-known` configurations to the Merchant app.
     * *Note: When clicked on mobile, they deep-link directly into the respective native app. On desktop/browser, they fall back to the respective Web Apps.*
   - **Post-Auth Redirect Flow**: Implement deep-link target caching (saving the destination route in memory/session storage if the user is unauthenticated). When a user gets blocked by route guards and completes signup/login, automatically redirect them to the originally requested deep-linked page (e.g. storefront or product form).
   - **Clipboard Product Scanner (Customer App)**: Inspect clipboard on app launch. If a valid product code pattern is found, show a summary card/link sheet.
   - **Flexible Share Options (Merchant App)**: Enable merchants to share either a direct App Link or the raw alphanumeric store code.
   - **Form Direct Routing**: Deep link directly to the "Add Product" screen for merchants.
3. **APK Size Reduction (Phase 4)**:
   - Audit the `monnify_payment_sdk` size footprint.

### Medium Term: Upcoming Korra Platform Extensions

#### 1. Automated Merchant Storefronts & Links
* **Shared Experience**: Automatically generate store-specific URLs (e.g., `korra.shop/store/merchant-name`) for social media bios.
* **Isolated Multi-Store Shopping**: Users view one specific storefront at a time. No combined global catalog. Checkout is strictly isolated (customers pay for items from only one specific merchant at a time).

#### 2. Product Setup & Reservation Quantity Locks
* **Flexible Listing Choices**: Toggles during product setup to enable *Full Payment Only*, *Reservation Only*, or *Both*.
* **Total Reservation Stock Limit**: Caps the total stock that can be locked in active customer reservation layouts simultaneously.
* **Per-Customer Limits**: Default lock of 1 unit per plan transaction. Reserving more requires completing checkout and starting a new transaction layout.

#### 3. Merchant Dashboard: Analytics & Metrics
* **Saved Storefront Count**: Track how many customer profiles have pinned the merchant's store.
* **Weekly Traffic Meter**: Display a rolling 7-day unique visitor traffic meter.

#### 4. Hyper-Local Customer Leaderboards ("Top Sellers")
* **Dynamic Rankings**: Localized rankings based strictly on saved/interacted merchants.
* **Activation Thresholds**:
  * *Fewer than 5 saved merchants*: Hidden from UI.
  * *5 to 19 saved merchants*: Highlights exactly 1 Top Seller.
  * *20 or more saved merchants*: Leaderboard showing top 5 to 10 sellers.

#### 5. Post-Purchase Merchant Profile Reviews
* **Merchant-Level Ratings**: Feedback and rating prompts triggered on order completion.
* **Vendor Credibility Focus**: Reviews are attached directly to the merchant profile (evaluating trust and payment tracking rather than individual item features).

#### 6. Merchant Marketing Campaigns (Broadcast Alerts)
* **Local Broadcasts**: Dashboard tool for merchants to send promotional alerts to following buyers.
* **Customer Controls**: Full settings page toggles for customers to mute promotional alerts or manage notifications per store.

#### 7. Network Discovery & Safe Disconnection (With Store Balances)
* **Store Code Search**: Alphanumeric store code lookups to find new merchants.
* **Store Balance Safeguards**: Prevent dashboard removals / unfollows if active plan balances exist with that vendor, enforcing confirmation warnings.

#### 8. Time-Capsule Wishlist with Purchase Prompts
* **Date-Driven Wishlist**: Save items with target acquisition dates.
* **Intelligent Alerts**: Automated reminder on the target date or warnings when stock drops low before the date.
* **Installment Hook**: Prompts users to start a reservation plan instead of risking a stockout.

### Long Term
1. Wire up real biometric auth (`local_auth` package).
2. Add BLoC unit tests.
3. Set up CI/CD for automated APK builds.

---

*Last updated: 3 July 2026. Update this document at the start of each new session with what changed.*

---

## 🛒 Orders Page — Architecture Decision (3 July 2026)

### What Changed — Terminology
The vendor "Reservations" page and all related UI text has been renamed:

| Old | New |
|---|---|
| Reservations (page title) | Orders |
| Reservation Details | Order Details |
| Ready to Fulfill | Ready to Deliver |
| Mark as Fulfilled | Mark as Delivered |
| Fulfilled (tab + badge) | Delivered |
| No reservations found | No orders found |
| Confirm Fulfillment | Confirm Delivery |

Files changed: `reservations_page.dart`, `reservation_status_tabs.dart`, `reservation_tile.dart`, `vendor_reservation_detail_sheet.dart`, `reservation_list.dart`, `reservation.dart` (removed `isOutright` getter).

---

### Database Split — Agreed Architecture

| Collection | Purpose |
|---|---|
| `plans/` | **Layaway/installment reservations ONLY** — one plan = one product, one customer |
| `orders/` | **Outright purchases ONLY** — one order = one customer, multiple line items (TBD, not yet built) |

> [!IMPORTANT]
> The `isOutright` getter has been **removed** from `Reservation` model. The `plans` collection is now strictly for layaway. Outright purchases will have their own `OutrightOrder` model and `orders` Firestore collection.

---

### Orders Page — Swipe UX (NOT YET BUILT)

The `ReservationsPage` (renamed Orders) will become a **horizontal PageView** with two panels:

```
Page 0 (default) — Reservations    ← from plans/ collection
Page 1            — Outright Orders ← from orders/ collection (TBD)
```

A custom `orders_panel_switcher.dart` swipe indicator sits at the top of the page to switch between panels. Full file breakdown is in `implementation_plan.md`.

**Reservations panel status tabs:** New · Active · Ready to Deliver · Delivered · Closed

**Outright orders panel status tabs:** New · Ready to Deliver · Delivered · Cancelled
*(No "Active" tab — outright purchases are paid instantly)*

---

### Storefront Fee Policy (Already Implemented)

Added to [storefront_settings.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/storefront_settings.dart):

- **Reservations:** 3.5% fee always on customer — non-configurable, not shown in settings
- **Outright:** Merchant can choose via toggle in Storefront Settings → "Outright Purchase Settings"
  - **Customer Pays Fee** (default) → 3.5% (max ₦7,500) added to checkout total
  - **I Absorb the Fee** → 3.5% (max ₦7,500) deducted from vendor payout

Stored in Firestore at `vendors/{uid}/store.absorbOutrightFee` (bool).
Read from `vendor_settings_repository.dart` → `saveStorefrontSettings()`.

> [!NOTE]
> The checkout and payout logic must read `store.absorbOutrightFee` when processing an outright order payment. This wiring is **not yet done** — it's a customer-side + backend (Supabase Edge Function) concern for a future session.

---

### Update: 3 July 2026 (Orders Page Swipe Architecture Implemented)
We have fully implemented the Swipe UX / PageView architecture for the Orders screen:
- **Model:** Created [OutrightOrder](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/data/models/vendor/outright_order.dart) with support for multi-item arrays, item mapping, total amount, and status helpers.
- **Repository:** Created [OutrightOrdersRepository](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/data/repository/vendors/outright_orders_repository.dart) to handle real-time streaming counts and pagination for the new `orders` collection.
- **BLoC:** Implemented [OutrightOrdersBloc](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/logic/bloc/vendor/outright_order/outright_orders_bloc.dart) (and its [events](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/logic/bloc/vendor/outright_order/outright_orders_event.dart) / [states](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/logic/bloc/vendor/outright_order/outright_orders_state.dart)) to manage tabs, search queries, pagination state, and delivery confirmation state.
- **UI & Widgets:**
  - [orders_panel_switcher.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/reservation/widgets/orders_panel_switcher.dart): Toggle switcher with animated selection slide.
  - [reservations_panel.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/reservation/widgets/reservations_panel.dart) & [outright_orders_panel.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/reservation/widgets/outright_orders_panel.dart): Decoupled widget pages under 500 lines.
  - [outright_order_tile.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/reservation/widgets/outright_order_tile.dart) & [outright_order_list.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/reservation/widgets/outright_order_list.dart): Paginated lists displaying order previews and items count.
  - [outright_order_detail_sheet.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/reservation/widgets/outright_order_detail_sheet.dart): Details modal sheet showing line-item summary, customer contact channels (phone, WhatsApp using FontAwesome icon support), and action button.
- **Integration:** Updated [reservations_page.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/reservation/reservations_page.dart) with `MultiBlocProvider` and `PageView` containing both panels.
- **Search Header Redesign:** Converted [korra_header.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/shared/widgets/korra_header.dart) to a stateful widget to support an expanding title bar search mode. Integrated this inside [reservations_page.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/reservation/reservations_page.dart), letting merchants click a search action icon in the header to filter orders dynamically as they type. Deleted the redundant full-width `ReservationSearchBar` inputs from both panel views to clean up screen real estate.
- **Icons Standardization:** Standardized all UI icons across [korra_header.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/shared/widgets/korra_header.dart), [outright_order_detail_sheet.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/reservation/widgets/outright_order_detail_sheet.dart), [outright_order_list.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/reservation/widgets/outright_order_list.dart), and [outright_order_tile.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/reservation/widgets/outright_order_tile.dart) to use standard Material `Icons` (such as `Icons.search`, `Icons.arrow_back`, `Icons.call`, `Icons.inbox_outlined`, `Icons.person_outline`, etc.) in place of `Iconsax` to keep UI consistent and lightweight.
- **Search Input Size Tuning:** Wrapped the text field inside a light-grey search pill container (`height: 36.h`, `borderRadius: 8.r`) in [korra_header.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/shared/widgets/korra_header.dart) with `isDense: true` and internal search/clear icons. This makes the search input look extremely clean, compact, and native to the title bar, eliminating any oversized layout issues.
- **Store Ratings & Reviews:** Implemented the rating summary and list of customer feedback within the Store page tab bar:
  - **Data Model:** Created [VendorReview](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/data/models/vendor/vendor_review.dart) model.
  - **Repository:** Created [VendorReviewsRepository](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/data/repository/vendors/vendor_reviews_repository.dart) extension on `VendorRepository` to stream customer reviews from `vendors/{uid}/reviews` ordered by date.
  - **UI & Widgets:** Built [vendor_reviews_body.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/vendor_reviews_body.dart) displaying average rating score, star percentage progress bars, and scrollable review feed.
  - **Integration:** Modified [products_page.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/products_page.dart) to check for `kIsWeb` dynamically. In mobile app mode, it instantiates 3 tabs (Products, Storefront, Reviews) and changes header title to "Ratings & Reviews" on the third tab. In web mode, it collapses back to 2 tabs.
- **Firestore Security Rules:** Updated [firebase_rule.txt](file:///c:/Users/USER/Desktop/flutter_projects/korra/firebase_rule.txt) to include read/write permissions for the `orders` collection and the `vendors/{uid}/reviews` subcollection, resolving the `PERMISSION_DENIED` errors on both reviews and outright orders.
- **Mock Data Seeding Actions:** Integrated a seeding system to quickly insert mock/demo reviews and outright orders for testing (with a `isMock: true` flag), and a corresponding "Clear Demo Data" warning banner at the top of the reviews screen for easy cleanup.
- **Store Campaigns & Visibility (Plan D):** Added marketing suite:
  - **Isolated Visibility Model:** Built [VendorVisibility](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/data/models/vendor/vendor_visibility.dart) to store Top Seller / Most Visited reach stats and Highlighted status without modifying the core `Vendor` model.
  - **Firestore Rules:** Updated [firebase_rule.txt](file:///c:/Users/USER/Desktop/flutter_projects/korra/firebase_rule.txt) to permit read/write on campaigns and visibility.
  - **Campaigns Main Body:** [vendor_campaigns_body.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/vendor_campaigns_body.dart) (under 250 lines) managing list views.
  - **Decomposed UI Sub-Widgets:** 
    - [campaign_reach_cards.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/campaigns/campaign_reach_cards.dart): Renders analytics stats (renamed "orders volume" instead of plans).
    - [highlighted_store_promo.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/campaigns/highlighted_store_promo.dart): Borderless card using local state switch to avoid page refreshes.
    - [campaign_card.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/campaigns/campaign_card.dart): Shows 24h active/expired badges, 1-line caption, tags, and product lists.
    - [create_campaign_sheet.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/campaigns/create_campaign_sheet.dart): Bottom sheet form with character validations (20 for title/tags, 40 for caption), compulsory banner photo, and 3-active campaigns limit check.
    - [product_selector_page.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/campaigns/product_selector_page.dart): Selection page listing in-stock inventory products in an e-commerce grid.
- **Rules updates:** Added delete rules to orders MATCH block inside [firebase_rule.txt](file:///c:/Users/USER/Desktop/flutter_projects/korra/firebase_rule.txt) to enable mock order deletes.
- **Customer Storefront Redesign (Plan E):** Implemented Pinterest/Temu UI:
  - **Pin/Unpin Permission Fix:** Fixed customer Firestore rules in [firebase_rule.txt](file:///c:/Users/USER/Desktop/flutter_projects/korra/firebase_rule.txt) by updating `/customers/{uid}/my_vendors/{vendorId}` rules to allow write access to resolving pin failures.
  - **Featuring Properties:** Added `isFeatured`, `campaignTag`, and `discountedPrice` to [product_model.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/data/models/product_model.dart) with full mapping logic.
  - **Merchant Featuring Switches:** Added the "Feature this product" switch to both [Add_product_page.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/Add_product_page.dart) and [product_edit_screen.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/vendor/product/widgets/product_edit_screen.dart).
  - **Horizontal Featured Carousel:** Implemented a horizontal scrolling list view for featured products on the customer storefront.
  - **Pinterest Staggered Masonry Grid:** Replaced rigid grid layouts with a staggered masonry style (`SliverMasonryGrid.count`) inside [storefront_screen.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/storefront/storefront_screen.dart) and implemented dynamic card aspect ratios based on product ID hashes in [storefront_product_card.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/storefront/widgets/storefront_product_card.dart) to deliver genuine staggered grid heights.
  - **Persistent Multi-Store Shopping Cart:** Created [storefront_cart_sheet.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/storefront/widgets/storefront_cart_sheet.dart) supporting quantity controls, item removals, subtotal tracking, and batch outright purchase checkouts. Carts are persisted per-store in Firestore under `/customers/{customerId}/carts/{vendorId}` so they sync across devices and sessions. Added a shopping bag badge button in the storefront header.
  - **Details Sheet Carousel & Quantities:** Redesigned the product details sheet to show a swipable horizontal `PageView.builder` image carousel with page indicators, a quantity adjuster row, and an **"Add to Cart"** button.
  - **Shein/Temu Circular Category Cards:** Upgraded storefront category filters in [storefront_filter_bar.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/storefront/widgets/storefront_filter_bar.dart) to display circular collection cards with representative icons instead of simple text chips.
  - **Price Sorting Filter:** Added a sleek Price Sorting toggle chip (`Default` / `Price: Low to High` / `Price: High to Low`) in the filter bar which applies responsive in-memory sorting to the feed.
  - **Store Ratings & Customer Reviews Feed:** Added a stream listener in the header to display the store's average stars and review count, and moved the reviews list to open inside a dedicated reviews modal sheet when clicking on the `4.4 ★★★★☆ reviews >` rating line under the store name.
  - **Dev Seeder & Rules Updates:** Updated write permissions for `/products/{productId}` in [firebase_rule.txt](file:///c:/Users/USER/Desktop/flutter_projects/korra/firebase_rule.txt) to allow seeding from the app. Seeder seeds 4 mock merchants and 12 detailed products (with multiple images for swiping).
  - **Active Selection Borders Removed:** Active category collections and price sort toggle filter chips now remove their outline borders entirely when selected to offer a cleaner look.
  - **Visual Spacing & Icons:** Balanced search bar spacing and added proportional padding around the "Shop by Collection" header. Upgraded the shopping bag app bar icon to a solid, bold `Icons.shopping_bag_rounded` for maximum visibility.
  - **CRITICAL NOTE ON FIREBASE RULES DEPLOYMENT:** Since the cart uses a new Firestore path `/customers/{uid}/carts/{vendorId}` and pinning uses `/customers/{uid}/my_vendors/{vendorId}`, you **MUST** deploy the updated security rules in [firebase_rule.txt](file:///c:/Users/USER/Desktop/flutter_projects/korra/firebase_rule.txt) to your Firebase backend. If you don't copy-paste these rules into the Firestore Rules tab on your Firebase Console, the database will return `PERMISSION_DENIED` and cart operations/pinning will fail.
  - **Dynamic Checkout Processing Fee:** Added live checkout fee calculation to [storefront_cart_sheet.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/storefront/widgets/storefront_cart_sheet.dart) checking the merchant's `absorbOutrightFee` setting. If the merchant pushes the fee to the customer, we charge a **3.5% fee** (up to a max of **₦7,500**) and display it clearly. If absorbed, it displays **₦0 (absorbed by merchant)**. The checkout footer total is now labelled **Paying Now** instead of total amount due.
  - **In-Memory Fallback Products:** Created [mock_marketplace_data.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/storefront/widgets/mock_marketplace_data.dart) and made `rawDoc` parameters optional on [storefront_product_card.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/storefront/widgets/storefront_product_card.dart) and [storefront_product_details_sheet.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/presentation/customer/storefront/widgets/storefront_product_details_sheet.dart). If the Firestore products collection is empty (e.g. database has not been seeded), the catalog automatically loads mock products locally, allowing you to test shopping and checkout flows offline.
  - **Offline Gate Layout Crash Fix:** Resolved a startup crash (`BoxConstraints forces an infinite height`) in [korra_offline_gate.dart](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/logic/core/net/korra_offline_gate.dart) by lifting `ModalBarrier` from the sliding bottom sheet inner Stack to the outer finite Stack.


