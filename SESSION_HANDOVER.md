# 🚀 Korra — Session Handover Document
> **Date:** 26 June 2026  
> **Purpose:** Complete technical handover so any developer (or AI session) can pick up exactly where we left off without asking "what did we do?" ever again.

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
| **Payment Gateway** | Paystack (TEMPORARY — migrating to Monnify, see §10) |
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
| `vendor` | `main_vendor.dart` | `app-merchant-release.apk` | Merchants |

**Build commands:**
```bash
# Customer
flutter build apk --flavor customer -t lib/main_customer.dart --release

# Vendor
flutter build apk --flavor vendor -t lib/main_vendor.dart --release

# Run for debug
flutter run --flavor customer -t lib/main_customer.dart
flutter run --flavor vendor -t lib/main_vendor.dart

# Analyze
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
✅ Payout to bank via Paystack (Monnify is the target, pending)  
✅ Transaction PIN for vendor withdrawals  
✅ BVN/NIN verification via Supabase (CURRENTLY OPTIONAL during signup — see §10)  
✅ Vendor reservations with pagination + bulk fulfilment marking  
✅ Product pagination (load-more, 10 items at a time)  
✅ Push notifications (FCM setup complete)  
✅ Firebase Analytics across all BLoCs (added this session)  
✅ Design system tokens partially implemented (KorraColors, KorraSizes, KorraPaddings, Gaps, KorraIcons)

---

## 10. Known Issues / Technical Debt

### 🔴 CRITICAL

#### Paystack → Monnify Migration
See `MONNIFY_MIGRATION.md` for the full checklist. The app uses Paystack for payouts as a **temporary workaround**. When Monnify live API is approved:

- `payout_bloc.dart`: Remove `_mapMonnifyToPaystackCode()` and the Paystack recipient creation call
- `VendorRepository`: Remove `createPaystackRecipientViaEdge()` method
- `PayoutDetails` model: Remove `paystackRecipientCode` field
- `vendor-transaction-ops/index.ts`: Switch from Paystack transfer to Monnify transfer block
- Dashboard: Update webhook URL to `monnify-webhook` edge function

#### KYC Verification Bypassed
BVN/NIN verification is skipped during vendor signup. After Monnify:
- Remove bypass code in `signup_vendor_bloc.dart` `_onNext`
- Remove the "temporarily paused" banner from `step_identity.dart`
- Re-enable `KorraValidators.nin/bvn` validators in the form
- Add KYC blocker check in `payout_bloc.dart._onWithdrawClicked`

### 🟡 IMPORTANT

#### Design System Refactor (`BATCH1_SCAN.md`)
Large refactor pending: replace hardcoded colors/sizes/strings in 19 auth UI files with design system tokens.

**Step A** (do first): Add new tokens to `colors.dart`, `sizes.dart`, `strings.dart`, `gaps.dart`, `paddings.dart`  
**Step B**: Execute the 19-file replacement table  
The exact replacement map is already in `BATCH1_SCAN.md`. **Do NOT re-scan. Just execute.**

#### Open Plan Tasks (`task.md`)
- Micro-tier engine changes (₦7k/15k/20k tiers with shorter durations)
- Warning system — Supabase cron for "Payment Due Soon" / "Plan Closing Notice" push notifications
- Cancellation refund UI (50% penalty, "Processing Refund" card)
- "Awaiting Vendor Approval" status handling (`pending_approval`)
- Help Center FAQ and Legal T&C updates

### 🟢 MINOR

- Biometric auth in `role_login_bloc.dart` is a **mock** (fake delays + success). Not wired to `local_auth`.
- `home_bloc.dart` `_onStarted` has empty stub — load logic not implemented
- `_formatDobForBvn()` helper duplicated in 4 files — should be in `config/utils/`
- `PlanActionBloc` and `PlanActionCubit` overlap in functionality — consolidate
- `dart:math` imported but unused in `vendor_products_bloc.dart` — remove to fix lint

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
| `vendor-transaction-ops.ts` | Vendor payout processing (currently Paystack) |
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

# 2. Run customer app (debug)
flutter run --flavor customer -t lib/main_customer.dart

# 3. Run vendor app (debug)
flutter run --flavor vendor -t lib/main_vendor.dart

# 4. Build release APKs
flutter build apk --flavor customer -t lib/main_customer.dart --release
flutter build apk --flavor vendor -t lib/main_vendor.dart --release

# 5. Analyze for issues
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

### Created:
- `SESSION_HANDOVER.md` (this document) in project root

---

## 17. What to Do Next (Prioritized)

### Immediately After This Session
1. `flutter analyze lib/` — confirm no new errors from analytics imports
2. Test analytics in Firebase DebugView on a device: `flutter run --flavor customer -t lib/main_customer.dart` then enable Analytics Debug mode:
   ```bash
   adb shell setprop debug.firebase.analytics.app [your.package.name]
   ```
3. Verify events appear in Firebase Console → Analytics → DebugView

### Short Term (Next 1–2 Sessions)
1. Execute `BATCH1_SCAN.md` Step A (add token constants) then Step B (19 files)
2. Implement micro-tier engine from `task.md` §1

### Medium Term
1. **Monnify Migration** — `MONNIFY_MIGRATION.md` full checklist
2. **Re-enable KYC enforcement** post-Monnify
3. Wire up real biometric auth (`local_auth` package)

### Long Term
1. Consolidate `PlanActionBloc` + `PlanActionCubit`
2. Extract `_formatDobForBvn` to shared utility
3. Add BLoC unit tests
4. Set up CI/CD for automated APK builds

---

*Last updated: 26 June 2026. Update this document at the start of each new session with what changed.*
