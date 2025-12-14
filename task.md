# 🚀 Korra Customer App - Final Polish Sprint

## 1. Create Plan & Scheduling Logic (The "Micro-Tier" Engine)
**Goal:** Enforce strict duration limits based on price to protect vendors.

- [ ] **Update `CreatePlanBloc` Risk Engine:**
    - Implement the 4 Price Tiers:
        - `0 - 7k`: 15 Days (No Extension)
        - `7k - 15k`: 25 Days (No Extension)
        - `15k - 20k`: 30 Days (10 Day Extension)
        - `20k+`: Standard (90 Days)
    - Logic to hide "Monthly" frequency for short-duration plans (< 20k).
- [ ] **Update `CreatePlanScreen` UI:**
    - Add the `_buildLiabilityCheckbox` (50% Penalty Waiver) before the "Pay" button.
    - Add a "Duration Breakdown" card showing: "Base Time: X Days" + "Extension Available: Yes/No".
    - Enforce Checkbox validation (Button disabled until checked).

## 2. The "Warning System" (Notifications & Notices)
**Goal:** Ensure the user knows exactly when they are about to lose their money.

- [ ] **Database Triggers (Supabase Cron):**
    - Logic to check `nextDueDate` vs `today`.
    - Logic to check `planExpiry` vs `today`.
- [ ] **Push Notifications:**
    - "Payment Due Soon" (3 days before).
    - "Plan Closing Notice" (3 days before final expiry).
- [ ] **In-App "Notice" Screen:**
    - Create a specialized screen state when a plan is in "Notice Period".
    - Show a big countdown timer: "48 Hours to Refund or Extend".

## 3. Cancellation & Refund Logic (The "Refund Jail")
**Goal:** Handle the "I give up" scenario gracefully but strictly.

- [ ] **Update `PlanDetailsScreen` Actions:**
    - "Cancel Plan" button logic (Trigger 50% penalty calculation).
    - Show confirmation dialog explaining the loss.
- [ ] **The "Refund Status" UI:**
    - If status is `refund_pending`:
        - Remove "Pay" button.
        - Show a "Processing Refund" card.
        - Display the specific Date (Today + 30 Days) when wallet will be credited.

## 4. "Awaiting Vendor Approval" State
**Goal:** Handle edge cases where a vendor needs to approve a plan or extension.

- [ ] **UI State:**
    - Add `pending_approval` status handling to `PlanCard` and `PlanDetails`.
    - Show an orange "Waiting for Vendor" banner.
    - Disable "Pay" button while pending.

## 5. Legal & Education (Trust Engineering)
**Goal:** Transparency to prevent support tickets.

- [ ] **Update `HelpCenterScreen` (FAQs):**
    - Add specific Q&A for:
        - "Why did I lose 50%?"
        - "Why is my refund taking 30 days?"
        - "Why can't I extend my ₦7k plan?"
- [ ] **Update `LegalScreen` (T&C):**
    - Insert the "Korra Layaway Agreement" text.
    - Explicitly mention the "Vendor Liquidity" rule (Vendor gets funds early).
    - Explicitly mention the "Non-Refundable Deposit" clause.