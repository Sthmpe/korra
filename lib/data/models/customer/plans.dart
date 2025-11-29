import 'package:cloud_firestore/cloud_firestore.dart';

class Plan {
  // =========================================================
  // 1. IDENTIFIERS
  // =========================================================
  final String id;
  final String productId;
  final String productCode;
  final String customerId;
  final String vendorId;

  // =========================================================
  // 2. DISPLAY DATA
  // =========================================================
  final String title;
  final String storeName;
  final List<String> imageUrls;

  // =========================================================
  // 3. FINANCIALS - GENERAL
  // =========================================================
  final double totalAmount; // The full price of the product
  final double amountPaid; // Total user has paid so far
  final double nextAmount; // The specific value of the next installment
  final double? amountPerPeriod; // How much per week/month

  // =========================================================
  // 4. FINANCIALS - RISK ENGINE
  //    These are required to track Debt and Limit Growth properly.
  // =========================================================
  final double
  initialDownPayment; // The total upfront paid (Gap + Skin in Game)
  final double loanAmount; // The amount Korra actually lent (Limit Used)
  final double
  outstandingLoanAmount; // The remaining debt (decreases with payments)
  final double dpPercentage; // The random % generated (for auditing)

  // =========================================================
  // 5. PAYMENT CADENCE
  // =========================================================
  final int? cadenceDays; // 1 = daily, 7 = weekly, 30 = monthly
  final String? cadenceType; // "daily", "weekly", "monthly"
  final bool commitmentEnabled; // Whether customer chose commitment plan
  final int durationMonths;

  // =========================================================
  // 6. DATES
  // =========================================================
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime nextDueDate;

  // =========================================================
  // 7. REMINDERS
  // =========================================================
  final DateTime reminderStartDate;
  final DateTime nextReminderDate;

  // =========================================================
  // 8. STATUS
  // =========================================================
  // Values: 'active', 'completed', 'cancelled', 'defaulted'
  final String status;

  const Plan({
    required this.id,
    required this.productId,
    required this.productCode,
    required this.customerId,
    required this.vendorId,
    required this.title,
    required this.storeName,
    required this.imageUrls,
    required this.totalAmount,
    required this.amountPaid,
    required this.nextAmount,
    this.cadenceDays,
    this.cadenceType,
    required this.commitmentEnabled,
    required this.createdAt,
    required this.updatedAt,
    required this.nextDueDate,
    required this.reminderStartDate,
    required this.nextReminderDate,
    required this.durationMonths,
    this.amountPerPeriod,
    // --- New Required Fields ---
    required this.initialDownPayment,
    required this.loanAmount,
    required this.outstandingLoanAmount,
    required this.dpPercentage,
    required this.status,
  });

  // =========================================================
  // FACTORY FOR NEW PLAN CREATION
  // =========================================================
  factory Plan.create({
    required String generatedId,
    required String vendorId,
    required String customerId,
    required String productId,
    required String productCode,
    required String title,
    required String storeName,
    required List<String> imageUrls,
    // Inputs from Risk Engine
    required double totalProductPrice, // Was totalAmount
    required double totalUpfrontPaid, // Was downPayment (Gap + Skin)
    required double loanAmount, // New: The Risk Amount
    required double dpPercentage, // New: The Random %
    // Inputs from User Selection
    String? cadenceType,
    required bool commitmentEnabled,
    required int durationMonths,
    double? amountPerPeriod,
  }) {
    final now = DateTime.now();

    int cadenceDays;
    switch (cadenceType) {
      case "daily":
        cadenceDays = 1;
        break;
      case "weekly":
        cadenceDays = 7;
        break;
      default:
        cadenceDays = 30;
    }

    return Plan(
      id: generatedId,
      customerId: customerId,
      productId: productId,
      productCode: productCode,
      vendorId: vendorId,
      title: title,
      storeName: storeName,
      imageUrls: imageUrls,

      // Mapped Financials
      totalAmount: totalProductPrice,
      amountPaid: totalUpfrontPaid,
      nextAmount:
          amountPerPeriod ??
          0.0, // This should usually be the installment amount
      amountPerPeriod: amountPerPeriod,

      // New Risk Fields
      initialDownPayment: totalUpfrontPaid,
      loanAmount: loanAmount,
      outstandingLoanAmount: loanAmount, // At start, debt = loan amount
      dpPercentage: dpPercentage,

      // Scheduling
      cadenceDays: cadenceDays,
      cadenceType: cadenceType ?? "monthly",
      commitmentEnabled: commitmentEnabled,
      durationMonths: durationMonths,

      // Dates
      createdAt: now,
      updatedAt: now,
      nextDueDate: now.add(Duration(days: cadenceDays)),
      reminderStartDate: now.add(const Duration(days: 30)),
      nextReminderDate: now
          .add(const Duration(days: 30))
          .add(const Duration(days: 7)),

      // Status
      status: (totalUpfrontPaid >= totalProductPrice) ? 'completed' : 'active',
    );
  }

  // =========================================================
  // COMPUTED PROPERTIES
  // =========================================================

  double get progressPercent =>
      totalAmount == 0 ? 0 : ((amountPaid / totalAmount).clamp(0, 1) * 100);

  double get amountRemaining =>
      (totalAmount - amountPaid).clamp(0, totalAmount);

  // *** UPDATED: Using status check instead of boolean ***
  bool get isOverdue =>
      DateTime.now().isAfter(nextDueDate) &&
      status != 'completed' &&
      status != 'cancelled';

  // *** COMPATIBILITY HELPERS: Keeps old UI code working ***
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isActive => status == 'active';
  bool get isDefaulted => status == 'defaulted';

  // =========================================================
  // FIRESTORE SERIALIZATION
  // Updated to include new fields
  // =========================================================

  Map<String, dynamic> toMap() {
    return {
      "productId": productId,
      "productCode": productCode,
      "customerId": customerId,
      "vendorId": vendorId,
      "title": title,
      "storeName": storeName,
      "imageUrls": imageUrls,
      "totalAmount": totalAmount,
      "amountPaid": amountPaid,
      "nextAmount": nextAmount,
      "cadenceDays": cadenceDays,
      "cadenceType": cadenceType,
      "commitmentEnabled": commitmentEnabled,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
      "nextDueDate": nextDueDate,
      "reminderStartDate": reminderStartDate,
      "nextReminderDate": nextReminderDate,
      "durationMonths": durationMonths,
      "amountPerPeriod": amountPerPeriod,
      // --- New Fields ---
      "initialDownPayment": initialDownPayment,
      "loanAmount": loanAmount,
      "outstandingLoanAmount": outstandingLoanAmount,
      "dpPercentage": dpPercentage,
      "status": status,
    };
  }

  // =========================================================
  // 🏭 FACTORY: SHELL PLAN (For Instant Navigation)
  // =========================================================
  factory Plan.empty({required String id}) {
    final now = DateTime.now();
    return Plan(
      id: id,
      // Identifiers
      productId: '',
      productCode: '',
      customerId: '',
      vendorId: '',
      // Display
      title: 'Loading...',
      storeName: '...',
      imageUrls: const [],
      // Financials
      totalAmount: 0.0,
      amountPaid: 0.0,
      nextAmount: 0.0,
      amountPerPeriod: 0.0,
      // Risk
      initialDownPayment: 0.0,
      loanAmount: 0.0,
      outstandingLoanAmount: 0.0,
      dpPercentage: 0.0,
      // Cadence
      cadenceDays: 30,
      cadenceType: 'monthly',
      commitmentEnabled: false,
      durationMonths: 0,
      // Dates
      createdAt: now,
      updatedAt: now,
      nextDueDate: now,
      reminderStartDate: now,
      nextReminderDate: now,
      // Status
      status: 'active', // Default to active so UI renders normally
    );
  }
  
  factory Plan.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now(); // Fallback if null
    }

    return Plan(
      id: id,
      productId: map["productId"] ?? '',
      productCode: map["productCode"] ?? '',
      customerId: map["customerId"] ?? '',
      vendorId: map["vendorId"] ?? '',
      title: map["title"] ?? '',
      storeName: map["storeName"] ?? '',
      imageUrls: List<String>.from(map["imageUrls"] ?? []),

      // Numbers
      totalAmount: (map["totalAmount"] ?? 0.0).toDouble(),
      amountPaid: (map["amountPaid"] ?? 0.0).toDouble(),
      nextAmount: (map["nextAmount"] ?? 0.0).toDouble(),
      cadenceDays: map["cadenceDays"] ?? 30,
      cadenceType: map["cadenceType"] ?? "monthly",
      commitmentEnabled: map["commitmentEnabled"] ?? false,

      // ✅ THE FIX: Use parseDate() for all date fields
      createdAt: parseDate(map["createdAt"]),
      updatedAt: parseDate(map["updatedAt"]),
      nextDueDate: parseDate(map["nextDueDate"]),
      reminderStartDate: parseDate(map["reminderStartDate"]),
      nextReminderDate: parseDate(map["nextReminderDate"]),

      durationMonths: map["durationMonths"] ?? 0,
      amountPerPeriod: (map["amountPerPeriod"] ?? 0.0).toDouble(),
      initialDownPayment: (map["initialDownPayment"] ?? 0.0).toDouble(),
      loanAmount: (map["loanAmount"] ?? 0.0).toDouble(),
      outstandingLoanAmount: (map["outstandingLoanAmount"] ?? 0.0).toDouble(),
      dpPercentage: (map["dpPercentage"] ?? 0.0).toDouble(),
      status: map["status"] ?? 'active',
    );
  }
}

class ProductFetchResult {
  final Map<String, dynamic> data;
  final String id;

  ProductFetchResult({required this.data, required this.id});

  factory ProductFetchResult.empty() {
    return ProductFetchResult(data: {}, id: '');
  }
}
