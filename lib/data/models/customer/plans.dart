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
  final double totalAmount; 
  final double amountPaid; 
  final double nextAmount; 
  final double? amountPerPeriod;

  // =========================================================
  // 4. FINANCIALS - RISK ENGINE
  // =========================================================
  final double initialDownPayment; 
  final double loanAmount; 
  final double outstandingLoanAmount; 
  final double dpPercentage; 

  final double processingFee;

  // =========================================================
  // 5. PAYMENT CADENCE & LIMITS (MICRO-TIER)
  // =========================================================
  final int? cadenceDays; 
  final String? cadenceType; 
  final bool commitmentEnabled; 
  final int durationMonths; 
  
  // Strict Limit Fields
  final int baseDurationDays;   // e.g. 15, 30, 90
  final int noticePeriodDays;   // e.g. 3, 10
  final int extensionGraceDays; // e.g. 0, 10, 30

  // =========================================================
  // 6. DATES
  // =========================================================
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime nextDueDate;
  
  // Automation Dates
  final DateTime planExpiryDate;   // Hard stop date
  final DateTime noticeStartDate;  // Warning date

  // =========================================================
  // 7. STATUS & POLICY
  // =========================================================
  final String status;
  
  // ✅ NEW: The policy locked in at purchase time
  // Values: "50% Refund" OR "Store Credit"
  final String cancellationPolicy;
  final String customerName;
  final String customerPhone; 
  final String customerEmail;
  final String modelType;

  final DateTime? extensionStartDate;
  final String? pickupCode; // Null until completed
  final DateTime? fulfilledAt; // Null until picked up
  final DateTime? completedAt; // When payment finished

  /// Variant this plan reserved ("XL / Red"); stamped server-side by
  /// plan-manager CREATE from the verified token. Null for products
  /// without variants (and all pre-variant plans).
  final String? variantLabel;

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
    required this.planExpiryDate,    
    required this.noticeStartDate,   
    required this.durationMonths,
    this.amountPerPeriod,
    required this.initialDownPayment,
    required this.loanAmount,
    required this.outstandingLoanAmount,
    required this.dpPercentage,
    required this.processingFee,
    required this.status,
    required this.cancellationPolicy, // ✅ Required
    
    // Micro-Tier Defaults
    required this.baseDurationDays,
    required this.noticePeriodDays,
    required this.extensionGraceDays,

    this.customerName = '',
    this.customerPhone = '',
    this.customerEmail = '',
    this.modelType = 'direct',
    this.extensionStartDate,
    this.pickupCode,
    this.fulfilledAt,
    this.completedAt,
    this.variantLabel,
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
    required double totalProductPrice, 
    required double totalUpfrontPaid, 
    required double loanAmount, 
    required double dpPercentage,
    required double processingFee, 
    required String cancellationPolicy, // ✅ PASSED FROM UI
    String? cadenceType,
    required bool commitmentEnabled,
    required int durationMonths,
    double? amountPerPeriod,
    required String customerName,  // ✅ Require this from UI
    required String customerPhone,
    required String customerEmail,
    
    // Tier Inputs (Passed from Bloc)
    required int baseDurationDays, 
    required int noticeDays, 
    required int extensionDays, 
    required String modelType,
  }) {
    final now = DateTime.now();

    int cadenceDays;
    switch (cadenceType) {
      case "daily": cadenceDays = 1; break;
      case "weekly": cadenceDays = 7; break;
      case "bi-weekly": cadenceDays = 14; break; 
      default: cadenceDays = 30;
    }
    
    // Calculate Hard Dates
    final expiryDate = now.add(Duration(days: baseDurationDays));
    final noticeDate = expiryDate.subtract(Duration(days: noticeDays));

    return Plan(
      id: generatedId,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      productId: productId,
      productCode: productCode,
      vendorId: vendorId,
      title: title,
      storeName: storeName,
      imageUrls: imageUrls,

      totalAmount: totalProductPrice,
      amountPaid: totalUpfrontPaid,
      nextAmount: amountPerPeriod ?? 0.0,
      amountPerPeriod: amountPerPeriod,

      initialDownPayment: totalUpfrontPaid,
      loanAmount: loanAmount,
      outstandingLoanAmount: loanAmount,
      dpPercentage: dpPercentage,
      processingFee: processingFee,

      cadenceDays: cadenceDays,
      cadenceType: cadenceType ?? "monthly",
      commitmentEnabled: commitmentEnabled,
      durationMonths: durationMonths,

      createdAt: now,
      updatedAt: now,
      nextDueDate: now.add(Duration(days: cadenceDays)),
      
      // New Fields
      planExpiryDate: expiryDate,
      noticeStartDate: noticeDate,
      baseDurationDays: baseDurationDays,
      noticePeriodDays: noticeDays,
      extensionGraceDays: extensionDays,

      status: (totalUpfrontPaid >= totalProductPrice) ? 'completed' : 'active',
      cancellationPolicy: cancellationPolicy, // ✅ Saved
      modelType: modelType,
    );
  }

  // =========================================================
  // COMPUTED PROPERTIES
  // =========================================================

  double get progressPercent =>
      totalAmount == 0 ? 0 : ((amountPaid / totalAmount).clamp(0.0, 1.0) * 100);

  double get amountRemaining =>
      (totalAmount - amountPaid).clamp(0.0, totalAmount);

  // 1. Is Extension Active? (Only true if date exists in DB)
  bool get isExtensionActive => extensionStartDate != null;

  // 2. Effective Deadline Logic
  DateTime get effectiveDeadline {
    // If extended, the deadline is calculated from the day they clicked "Extend"
    // Example: Clicked Wed + 5 Days = Ends next Monday.
    if (isExtensionActive && extensionStartDate != null) {
      return extensionStartDate!.add(Duration(days: extensionGraceDays));
    }
    // Normal deadline
    return planExpiryDate;
  }

  // The "Hard Stop" (When the plan effectively dies)
  DateTime get absoluteTerminationDate {
    // CASE 1: EXTENDED PLAN (The "Hard Stop")
    // If they already extended, they don't get another Notice Period.
    // The Deadline IS the Termination Date.
    if (isExtensionActive) {
      return effectiveDeadline;
    }

    // CASE 2: NORMAL PLAN (The "Warning Zone")
    // They haven't extended yet. We give them the Notice Period to act.
    // Termination = Deadline + 3 Days Warning.
    return effectiveDeadline.add(Duration(days: noticePeriodDays ?? 0));
  }

  // 3. Overdue Logic (Uses Effective Deadline)
  bool get isOverdue {
    if (status != 'active') return false;
    
    final now = DateTime.now();
    // It is overdue if NOW is past the Deadline BUT before the Hard Stop.
    return now.isAfter(effectiveDeadline) && now.isBefore(absoluteTerminationDate);
  }

  // 4. Termination Logic (Game Over 🛑)
  bool get isEffectivelyTerminated {
    if (status == 'cancelled') return true;
    
    // If active, but we are past the Hard Stop.
    // - For Extended plans: Happens 1 second after the extension ends.
    // - For Normal plans: Happens 1 second after the Notice Period ends.
    if (status == 'active' && DateTime.now().isAfter(absoluteTerminationDate)) {
      return true;
    }
    return false;
  }
  
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isActive => status == 'active';

  // =========================================================
  // 🏭 FACTORY: SHELL PLAN
  // =========================================================
  factory Plan.empty({required String id}) {
    final now = DateTime.now();
    return Plan(
      id: id,
      productId: '',
      productCode: '',
      customerId: '',
      customerName: '',
      customerPhone: '',
      customerEmail: '',
      vendorId: '',
      title: 'Loading...',
      storeName: '...',
      imageUrls: const [],
      totalAmount: 0.0,
      amountPaid: 0.0,
      nextAmount: 0.0,
      amountPerPeriod: 0.0,
      initialDownPayment: 0.0,
      loanAmount: 0.0,
      outstandingLoanAmount: 0.0,
      dpPercentage: 0.0,
      processingFee: 0.0,
      cadenceDays: 30,
      cadenceType: 'monthly',
      commitmentEnabled: false,
      durationMonths: 0,
      createdAt: now,
      updatedAt: now,
      nextDueDate: now,
      status: 'active',
      cancellationPolicy: 'Store Credit', // ✅ Default Safety
      modelType: 'direct',
      
      // Shell Defaults
      planExpiryDate: now.add(const Duration(days: 30)),
      noticeStartDate: now.add(const Duration(days: 25)),
      baseDurationDays: 30,
      noticePeriodDays: 5,
      extensionGraceDays: 0,
    );
  }

  // =========================================================
  // SERIALIZATION
  // =========================================================

  Map<String, dynamic> toMap() {
    return {
      "productId": productId,
      "productCode": productCode,
      "customerId": customerId,
      "customerName": customerName,
      "customerPhone": customerPhone,
      "customerEmail": customerEmail,
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
      "durationMonths": durationMonths,
      "amountPerPeriod": amountPerPeriod,
      "initialDownPayment": initialDownPayment,
      "loanAmount": loanAmount,
      "outstandingLoanAmount": outstandingLoanAmount,
      "dpPercentage": dpPercentage,
      "processingFee": processingFee,
      "status": status,
      "cancellationPolicy": cancellationPolicy, // ✅
      
      // Automation Fields
      "planExpiryDate": planExpiryDate,
      "noticeStartDate": noticeStartDate,
      "baseDurationDays": baseDurationDays,
      "noticePeriodDays": noticePeriodDays,
      "extensionGraceDays": extensionGraceDays,
      "modelType": modelType,
      "extensionStartDate": extensionStartDate,
    };
  }

  factory Plan.fromMap(Map<String, dynamic> map, String id) {
    // Helper for MANDATORY dates (defaults to Now if missing to prevent null errors)
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    // ✅ Helper for NULLABLE dates (Returns null if missing)
    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return Plan(
      id: id,
      productId: map["productId"] ?? '',
      productCode: map["productCode"] ?? '',
      customerId: map["customerId"] ?? '',
      customerName: map["customerName"] ?? "Unknown Customer",
      customerPhone: map["customerPhone"] ?? "",
      customerEmail: map["customerEmail"] ?? "",
      vendorId: map["vendorId"] ?? '',
      title: map["title"] ?? '',
      storeName: map["storeName"] ?? '',
      imageUrls: List<String>.from(map["imageUrls"] ?? []),
      totalAmount: (map["totalAmount"] ?? 0.0).toDouble(),
      amountPaid: (map["amountPaid"] ?? 0.0).toDouble(),
      nextAmount: (map["nextAmount"] ?? 0.0).toDouble(),
      cadenceDays: map["cadenceDays"] ?? 30,
      cadenceType: map["cadenceType"] ?? "monthly",
      commitmentEnabled: map["commitmentEnabled"] ?? false,
      
      // Mandatory Dates
      createdAt: parseDate(map["createdAt"]),
      updatedAt: parseDate(map["updatedAt"]),
      nextDueDate: parseDate(map["nextDueDate"]),
      planExpiryDate: parseDate(map["planExpiryDate"]),
      noticeStartDate: parseDate(map["noticeStartDate"]),
      
      durationMonths: map["durationMonths"] ?? 0,
      amountPerPeriod: (map["amountPerPeriod"] ?? 0.0).toDouble(),
      initialDownPayment: (map["initialDownPayment"] ?? 0.0).toDouble(),
      loanAmount: (map["loanAmount"] ?? 0.0).toDouble(),
      outstandingLoanAmount: (map["outstandingLoanAmount"] ?? 0.0).toDouble(),
      dpPercentage: (map["dpPercentage"] ?? 0.0).toDouble(),
      processingFee: (map["processingFee"] ?? 0.0).toDouble(),
      status: map["status"] ?? 'active',
      cancellationPolicy: map["cancellationPolicy"] ?? 'Store Credit',
      
      baseDurationDays: map["baseDurationDays"] ?? 30,
      noticePeriodDays: map["noticePeriodDays"] ?? 5,
      extensionGraceDays: map["extensionGraceDays"] ?? 0,
      modelType: map["modelType"] ?? 'direct',
      
      // ✅ Correctly parsed Nullable Date
      extensionStartDate: parseNullableDate(map["extensionStartDate"]),
      pickupCode: map['pickupCode'],
      fulfilledAt: parseNullableDate(map['fulfilledAt']),
      completedAt: parseNullableDate(map['completedAt']),
      variantLabel: map['variantLabel'] as String?,
    );
  }
}

class ProductFetchResult {
  final Map<String, dynamic> data;
  final String id;
  ProductFetchResult({required this.data, required this.id});
  factory ProductFetchResult.empty() => ProductFetchResult(data: {}, id: '');
}