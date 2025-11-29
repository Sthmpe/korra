import 'dart:math';

class KorraRiskEngine {

  // =========================================================
  // 1. RANDOMIZED DP% GENERATOR (The Psychology Layer)
  //    Call this FIRST when the user clicks a product.
  // =========================================================
  static double generateRandomPercentage(double price) {
    Random random = Random();
    double minPct, maxPct;

    if (price <= 15000) {
      minPct = 0.35; maxPct = 0.45; // 0-15k -> 30-45%
    } else if (price <= 25000) {
      minPct = 0.30; maxPct = 0.35; // 15k-25k -> 30-30%
    } else if (price <= 35000) {
      minPct = 0.32; maxPct = 0.38; // 25k-35k -> 32-38%
    } else if (price <= 40000) {
      minPct = 0.35; maxPct = 0.40; // 35k-40k -> 35-40%
    } else if (price <= 55000) {
      minPct = 0.38; maxPct = 0.43; // 40k-55k -> 38-43%
    } else {
      minPct = 0.40; maxPct = 0.45; // 55k+ -> 40-45%
    }

    // Generate random double between min and max
    // Formula: min + random * (max - min)
    return minPct + random.nextDouble() * (maxPct - minPct);
  }

  // =========================================================
  // 2. BUYING LOGIC (GAP + DOWNPAYMENT)
  //    Returns NULL if the Gap is too high (Decline).
  // =========================================================
  static Map<String, dynamic>? calculateBuyingLogic({
    required double productPrice,
    required double availableLimit, // (Total Limit - Current Debt)
    required double dpPercentage,   // The random % generated above
    required bool isEligibleForSpecialGap, // True if user is "Good Behavior"
    double? lastLimitUsed,          // Needed for Special Gap check
  }) {
    
    // --- STEP A: CALCULATE GAP ---
    double gap = 0.0;
    double lendablePortion = 0.0;

    if (productPrice > availableLimit) {
      gap = productPrice - availableLimit;
      lendablePortion = availableLimit; 
    } else {
      gap = 0.0;
      lendablePortion = productPrice;
    }

    // --- STEP B: THE "HARD STOP" DECLINE RULE ---
    // Rule: If Gap > 65% of Product Price, DECLINE.
    // Logic: The user is paying too much upfront, risk is too low for us.
    if (gap > (productPrice * 0.65)) {
      return null; // Return null to signal "Decline Transaction"
    }

    // --- STEP C: SPECIAL GAP CHECK ---
    // If there is a Gap, and the user wants a 2nd item...
    if (gap > 0 && lastLimitUsed != null) {
      // "Only give special GAP if gap <= 85% of the limit just used"
      bool isGapReasonable = gap <= (lastLimitUsed * 0.85);

      if (!isEligibleForSpecialGap || !isGapReasonable) {
         // You might choose to be stricter here, or decline.
         // For now, we proceed but flag it, or you can return null here to strict decline.
      }
    }

    // --- STEP D: CALCULATE UPFRONT ---
    // Formula: Gap + (Lendable Limit * DP%)
    double percentageAmount = lendablePortion * dpPercentage;
    double totalUpfront = gap + percentageAmount;

    return {
      "status": "APPROVED",
      "productPrice": productPrice,
      "gap": gap,
      "percentageAmount": percentageAmount,
      "totalUpfront": totalUpfront,
      "loanAmount": productPrice - totalUpfront,
      "generatedDpPercentage": dpPercentage,
    };
  }

  // =========================================================
  // 3. LIMIT GROWTH & REDUCTION (The 3 Tiers)
  // =========================================================
  static double calculateNewLimit({
    required double currentLimit,
    required int daysTaken,
    required bool hasDefaulted,
  }) {
    const double MAX_CAP = 100000.0;
    const double BASE_LIMIT = 15000.0;

    // --- DECREASE RULES (Universal) ---
    if (hasDefaulted || daysTaken > 90) {
      if (currentLimit <= 35000) {
        return BASE_LIMIT; // Reset small users to start
      } else {
        return max(BASE_LIMIT, currentLimit * 0.50); // Cut big users by half
      }
    }

    // --- INCREASE RULES (By Category) ---
    double increase = 0.0;

    // CATEGORY 1: STANDARD USERS (0 - 35k) -> Aggressive Growth
    if (currentLimit <= 35000) {
      if (daysTaken <= 14) increase = 0.70;      // 70%
      else if (daysTaken <= 30) increase = 0.50; // 50%
      else if (daysTaken <= 45) increase = 0.25; // 25%
      else if (daysTaken <= 60) increase = 0.20; // 20%
      else if (daysTaken <= 80) increase = 0.15; // 15%
      else if (daysTaken <= 90) increase = 0.05; // 5%
    } 
    
    // CATEGORY 2: HIGH USERS (36k - 50k) -> Moderate Growth
    else if (currentLimit <= 50000) {
      if (daysTaken <= 14) increase = 0.30;      // 30%
      else if (daysTaken <= 30) increase = 0.20; // 20%
      else if (daysTaken <= 45) increase = 0.10; // 10%
      else if (daysTaken <= 65) increase = 0.05; // 5%
    }
    
    // CATEGORY 3: HIGHER USERS (50k - 100k) -> Slow Growth
    else {
      if (daysTaken <= 14) increase = 0.25;      // 25%
      else if (daysTaken <= 30) increase = 0.15; // 15%
      else if (daysTaken <= 45) increase = 0.05; // 5%
    }

    // Apply Increase
    double newLimit = currentLimit + (currentLimit * increase);
    return min(newLimit, MAX_CAP);
  }
}