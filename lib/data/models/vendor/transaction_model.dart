import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId; // Renamed from customerId to be generic
  final double amount;
  final String type; // 'deposit', 'sale', 'withdrawal', 'fee'
  final String description;
  final String reference; // Payment reference or Order ID
  final String status; // 'success', 'pending', 'failed', 'locked'
  final double balanceBefore;
  final double balanceAfter;
  final DateTime createdAt;

  // --- NEW FIELDS FOR VENDOR ---
  final DateTime? releaseDate; // If set, money is locked until this date
  final String? orderId;       // Links to the sale (if it's a vendor sale)
  
  // --- NEW FIELDS FOR CUSTOMER ---
  final String? planId;        // Links to the plan (if it's a customer repayment)

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.description,
    required this.reference,
    required this.status,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.createdAt,
    this.releaseDate,
    this.orderId,
    this.planId,
  });

  // Helper to check if funds are currently locked
  bool get isLocked {
    if (releaseDate == null) return false;
    return DateTime.now().isBefore(releaseDate!);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type,
      'description': description,
      'reference': reference,
      'status': status,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'createdAt': FieldValue.serverTimestamp(),
      // Optional fields (Firestore ignores nulls usually, or stores null)
      'releaseDate': releaseDate != null ? Timestamp.fromDate(releaseDate!) : null,
      'orderId': orderId,
      'planId': planId,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      userId: map['userId'] ?? map['customerId'] ?? '', // Fallback for old data
      amount: (map['amount'] ?? 0).toDouble(),
      type: map['type'] ?? 'unknown',
      description: map['description'] ?? '',
      reference: map['reference'] ?? '',
      status: map['status'] ?? 'pending',
      balanceBefore: (map['balanceBefore'] ?? 0).toDouble(),
      balanceAfter: (map['balanceAfter'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      
      // Parse Vendor Specifics
      releaseDate: (map['releaseDate'] as Timestamp?)?.toDate(),
      orderId: map['orderId'],
      
      // Parse Customer Specifics
      planId: map['planId'],
    );
  }
}