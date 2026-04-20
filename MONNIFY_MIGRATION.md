# 🚀 Post-Monnify Migration Checklist

This document tracks the temporary technical debt and bypasses implemented to launch Korra using Paystack. Once the Monnify Live API is approved and active, follow this checklist to clean up the codebase and restore the original flow.

## 1. Identity Verification (KYC)

**File:** `lib/.../logic/bloc/auth/signup_vendor/signup_vendor_bloc.dart`
- [ ] **Remove:** The Identity Step bypass at the end of the `_onNext` function.
  ```dart
  /// To be removed after Monnify live api integration
  if (state.pageIndex == identityStepIndex) { ... }
  ```
- [ ] **Uncomment:** The actual NIN/BVN verification logic (`_vendorsRepo.verifyNin` and `_vendorsRepo.verifyBvn`).

**File:** `lib/.../ui/screens/auth/signup_vendor/step_identity.dart`
- [ ] **Remove:** The highlighted pause banner (`Container` with the info icon) stating "Identity verification is temporarily paused."
- [ ] **Remove:** The ` - Optional` text from the NIN and BVN labels.
- [ ] **Uncomment:** `validator: KorraValidators.nin,` on the NIN input.
- [ ] **Uncomment:** `validator: KorraValidators.bvn,` on the BVN input.
- [ ] **Remove:** `serverError: null` overrides on both inputs.

---

## 2. Payouts & Bank Verification (Bank Linking)

**File:** `lib/.../logic/bloc/vendor/payout/payout_bloc.dart`
- [ ] **Remove:** The mapping function `_mapMonnifyToPaystackCode()`.
- [ ] **Remove:** The call to `repo.createPaystackRecipientViaEdge()`.
- [ ] **Update:** Save the bank details directly without the extra recipient creation step.

**File:** `lib/.../data/repositories/vendor_repository.dart`
- [ ] **Remove:** The `createPaystackRecipientViaEdge()` HTTP method.

**File:** `lib/.../models/payout_details.dart`
- [ ] **Remove:** `final String? paystackRecipientCode;` from the model, constructor, `toMap()`, and `fromMap()`.

---

## 3. Payout Execution (Edge Function)

**File:** `supabase/functions/vendor-transaction-ops/index.ts`
- [ ] **Uncomment:** The `/* MONNIFY IMPLEMENTATION */` block inside the `transfer` route.
- [ ] **Delete/Comment:** The `PAYSTACK IMPLEMENTATION` block (the `api.paystack.co/transfer` fetch request).
- [ ] **Keep:** The EMTL fee deduction, ledger math, and Firebase notification logic exactly as is.

---

## 4. Webhooks & Infrastructure

**Paystack / Monnify Dashboard:**
- [ ] **Action:** Log into the Monnify Dashboard -> Developer Settings -> Webhooks.
- [ ] **Action:** Set the Webhook URL to point to your deployed `monnify-webhook` edge function.

**Supabase / Firebase Edge Functions:**
- [ ] **Delete/Deprecate:** `paystack_webhook` function.
- [ ] **Delete/Deprecate:** `paystack_create_recipient` function.
- [ ] **Environment Variables:** Remove `PAYSTACK_SECRET_KEY` from your backend environment.

---

## 5. The "Legacy User" Catch (CRITICAL)

Because early merchants signed up without providing NIN/BVN, they must be forced to complete KYC before they can withdraw via Monnify.

**File:** `lib/.../ui/screens/vendor_dashboard/home_screen.dart` (or similar)
- [ ] **Add:** A check on app load. If `vendor.nin` is null or empty, display a permanent warning banner: *"⚠️ Action Required: Please complete your Identity Verification in settings to unlock withdrawals."*

**File:** `lib/.../logic/bloc/vendor/payout/payout_bloc.dart`
- [ ] **Add:** A strict blocker inside `_onWithdrawClicked` or `_onPinSubmitted`.
  ```dart
  if (state.vendor.nin == null || state.vendor.nin!.isEmpty) {
     emit(state.copyWith(
       status: PayoutStatus.failure,
       errorMessage: "Please complete your Identity Verification (KYC) in settings before withdrawing.",
     ));
     return;
  }
  ```

---

## 6. Database Schema (Firestore)
- [ ] **Action:** No migration script is strictly required, but be aware that older vendor documents in the `vendors` collection will have a `paystackRecipientCode` field. New vendors onboarded via Monnify will not.