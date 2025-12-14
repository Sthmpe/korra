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

  // =========================================================
  // 5. PAYMENT CADENCE & LIMITS (MICRO-TIER)
  // =========================================================
  final int? cadenceDays; 
  final String? cadenceType; 
  final bool commitmentEnabled; 
  final int durationMonths; // For UI Display (e.g. "3 Months")
  
  // ✅ NEW: Strict Limit Fields
  final int baseDurationDays;   // e.g. 15, 30, 90
  final int noticePeriodDays;   // e.g. 3, 10
  final int extensionGraceDays; // e.g. 0, 10, 30

  // =========================================================
  // 6. DATES
  // =========================================================
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime nextDueDate;
  
  // ✅ NEW: Automation Dates
  final DateTime planExpiryDate;   // Hard stop date
  final DateTime noticeStartDate;  // Warning date

  // =========================================================
  // 8. STATUS
  // =========================================================
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
    required this.planExpiryDate,    // NEW
    required this.noticeStartDate,   // NEW
    required this.durationMonths,
    this.amountPerPeriod,
    required this.initialDownPayment,
    required this.loanAmount,
    required this.outstandingLoanAmount,
    required this.dpPercentage,
    required this.status,
    
    // Micro-Tier Defaults
    required this.baseDurationDays,
    required this.noticePeriodDays,
    required this.extensionGraceDays,
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
    String? cadenceType,
    required bool commitmentEnabled,
    required int durationMonths,
    double? amountPerPeriod,
    
    // ✅ NEW: Tier Inputs (Passed from Bloc)
    required int baseDurationDays, 
    required int noticeDays, 
    required int extensionDays, 
  }) {
    final now = DateTime.now();

    int cadenceDays;
    switch (cadenceType) {
      case "daily": cadenceDays = 1; break;
      case "weekly": cadenceDays = 7; break;
      case "bi-weekly": cadenceDays = 14; break; // Added bi-weekly
      default: cadenceDays = 30;
    }
    
    // Calculate Hard Dates
    final expiryDate = now.add(Duration(days: baseDurationDays));
    final noticeDate = expiryDate.subtract(Duration(days: noticeDays));

    return Plan(
      id: generatedId,
      customerId: customerId,
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
    );
  }

  // =========================================================
  // COMPUTED PROPERTIES
  // =========================================================

  double get progressPercent =>
      totalAmount == 0 ? 0 : ((amountPaid / totalAmount).clamp(0, 1) * 100);

  double get amountRemaining =>
      (totalAmount - amountPaid).clamp(0, totalAmount);

  bool get isOverdue =>
      DateTime.now().isAfter(nextDueDate) &&
      status != 'completed' &&
      status != 'cancelled';

  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled'; // Double L check
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
      cadenceDays: 30,
      cadenceType: 'monthly',
      commitmentEnabled: false,
      durationMonths: 0,
      createdAt: now,
      updatedAt: now,
      nextDueDate: now,
      status: 'active',
      
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
      "status": status,
      
      // ✅ NEW: Automation Fields
      "planExpiryDate": planExpiryDate,
      "noticeStartDate": noticeStartDate,
      "baseDurationDays": baseDurationDays,
      "noticePeriodDays": noticePeriodDays,
      "extensionGraceDays": extensionGraceDays,
    };
  }

  factory Plan.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
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
      totalAmount: (map["totalAmount"] ?? 0.0).toDouble(),
      amountPaid: (map["amountPaid"] ?? 0.0).toDouble(),
      nextAmount: (map["nextAmount"] ?? 0.0).toDouble(),
      cadenceDays: map["cadenceDays"] ?? 30,
      cadenceType: map["cadenceType"] ?? "monthly",
      commitmentEnabled: map["commitmentEnabled"] ?? false,
      createdAt: parseDate(map["createdAt"]),
      updatedAt: parseDate(map["updatedAt"]),
      nextDueDate: parseDate(map["nextDueDate"]),
      durationMonths: map["durationMonths"] ?? 0,
      amountPerPeriod: (map["amountPerPeriod"] ?? 0.0).toDouble(),
      initialDownPayment: (map["initialDownPayment"] ?? 0.0).toDouble(),
      loanAmount: (map["loanAmount"] ?? 0.0).toDouble(),
      outstandingLoanAmount: (map["outstandingLoanAmount"] ?? 0.0).toDouble(),
      dpPercentage: (map["dpPercentage"] ?? 0.0).toDouble(),
      status: map["status"] ?? 'active',
      
      // ✅ NEW: Map Automation Fields
      planExpiryDate: parseDate(map["planExpiryDate"]),
      noticeStartDate: parseDate(map["noticeStartDate"]),
      baseDurationDays: map["baseDurationDays"] ?? 30,
      noticePeriodDays: map["noticePeriodDays"] ?? 5,
      extensionGraceDays: map["extensionGraceDays"] ?? 0,
    );
  }
}

class ProductFetchResult {
  final Map<String, dynamic> data;
  final String id;
  ProductFetchResult({required this.data, required this.id});
  factory ProductFetchResult.empty() => ProductFetchResult(data: {}, id: '');
}