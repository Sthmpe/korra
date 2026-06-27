# 🚀 Korra — Session Handover Document
> **Date:** 26 June 2026  
> **Purpose:** Complete technical handover so any developer (or AI session) can pick up exactly where we left off without asking "what did we do?" ever again.

> [!WARNING]
> Only focus on the active conversation, `SESSION_HANDOVER.md`, and the `implementation_plan.md` artifact. Ignore all other `.md` files in the root directory (such as `BATCH1_SCAN.md` or `MONNIFY_MIGRATION.md`) as they are outdated reference files.

> [!IMPORTANT]
> **CRITICAL RULE:** Focus strictly on this conversation context, `SESSION_HANDOVER.md`, and the `implementation_plan.md` artifact. Avoid looking at or editing other `.md` files (like `BATCH1_SCAN.md` or `MONNIFY_MIGRATION.md`) as they are outdated. Do not perform any `flutter analyze` or execution of commands; the user will handle them locally. Keep UI styles and business logic 100% identical. Never assume code is wrong; ask the user first.

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

---

## 17. What to Do Next (Prioritized)

### Short Term (Next 1–2 Sessions)
1. **APK Size Reduction (Phase 4)**:
   - Audit the `monnify_payment_sdk` size footprint.

### Medium Term
1. Wire up real biometric auth (`local_auth` package).
2. Add BLoC unit tests.
3. Set up CI/CD for automated APK builds.

---

*Last updated: 27 June 2026. Update this document at the start of each new session with what changed.*
