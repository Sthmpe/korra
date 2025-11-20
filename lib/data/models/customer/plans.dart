import 'package:cloud_firestore/cloud_firestore.dart';

class Plan {
  final String id;
  final String productCode;
  final String customerId;
  final String vendorId;

  // Display
  final String title;
  final String storeName;
  final List<String> imageUrls;

  // Financial
  final double totalAmount;
  final double amountPaid;
  final double nextAmount;

  // Payment cadence
  final int? cadenceDays;           // 1 = daily, 7 = weekly, 30 = monthly
  final String? cadenceType;        // "daily", "weekly", "monthly"
  final bool commitmentEnabled;    // Whether customer chose commitment plan

  // Dates
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime nextDueDate;

  // Reminders
  final DateTime reminderStartDate; // createdAt + 30 days
  final DateTime nextReminderDate;  // weekly only for all after 30 days

  // Status
  final bool isCompleted;
  final bool isCancelled;

  const Plan({
    required this.id,
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
    required this.isCompleted,
    required this.isCancelled,
  });

  // =========================================================
  // FACTORY FOR NEW PLAN CREATION
  // =========================================================
  factory Plan.create({
    required String vendorId,
    required String title,
    required List<String> imageUrls,
    required double totalAmount,
    required String storeName,
    required String customerId,
    required String productCode,
    required double downPayment,
    required String generatedId,
    String? cadenceType,      // daily, weekly, monthly
    required bool commitmentEnabled,
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
      productCode: productCode,
      vendorId: vendorId,
      title: title,
      storeName: storeName,
      imageUrls: imageUrls,
      totalAmount: totalAmount,
      amountPaid: downPayment,
      nextAmount: totalAmount - downPayment,
      cadenceDays: cadenceDays,
      cadenceType: cadenceType ?? "monthly",
      commitmentEnabled: commitmentEnabled,
      createdAt: now,
      updatedAt: now,
      nextDueDate: now.add(Duration(days: cadenceDays)),
      reminderStartDate: now.add(const Duration(days: 30)),
      nextReminderDate: now.add(const Duration(days: 30)).add(const Duration(days: 7)),
      isCompleted: downPayment >= totalAmount,
      isCancelled: false,
    );
  }

  // =========================================================
  // COMPUTED PROPERTIES
  // =========================================================

  double get progressPercent => totalAmount == 0
      ? 0
      : ((amountPaid / totalAmount).clamp(0, 1) * 100);

  double get amountRemaining =>
      (totalAmount - amountPaid).clamp(0, totalAmount);

  bool get isOverdue =>
      DateTime.now().isAfter(nextDueDate) &&
      !isCompleted &&
      !isCancelled;

  // =========================================================
  // FIRESTORE SERIALIZATION
  // =========================================================

  Map<String, dynamic> toMap() {
    return {
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
      "isCompleted": isCompleted,
      "isCancelled": isCancelled,
    };
  }

  factory Plan.fromMap(Map<String, dynamic> map, String id) {
    return Plan(
      id: id,
      productCode: map["productCode"],
      customerId: map["customerId"],
      vendorId: map["vendorId"],
      title: map["title"],
      storeName: map["storeName"],
      imageUrls: List<String>.from(map["imageUrls"] ?? []),
      totalAmount: map["totalAmount"]?.toDouble() ?? 0.0,
      amountPaid: map["amountPaid"]?.toDouble() ?? 0.0,
      nextAmount: map["nextAmount"]?.toDouble() ?? 0.0,
      cadenceDays: map["cadenceDays"] ?? 30,
      cadenceType: map["cadenceType"] ?? "monthly",
      commitmentEnabled: map["commitmentEnabled"] ?? false,
      createdAt: (map["createdAt"] as Timestamp).toDate(),
      updatedAt: (map["updatedAt"] as Timestamp).toDate(),
      nextDueDate: (map["nextDueDate"] as Timestamp).toDate(),
      reminderStartDate: (map["reminderStartDate"] as Timestamp).toDate(),
      nextReminderDate: (map["nextReminderDate"] as Timestamp).toDate(),
      isCompleted: map["isCompleted"] ?? false,
      isCancelled: map["isCancelled"] ?? false,
    );
  }
}


class ProductFetchResult {
  final Map<String, dynamic> data;
  final String id;

  ProductFetchResult({required this.data, required this.id});
}