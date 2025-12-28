// lib/data/models/vendor/transaction_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final double amount; // This is the NET amount (what hits the wallet)
  final String type; 
  final String description;
  final String reference;
  final String status;
  final double balanceBefore;
  final double balanceAfter;
  final DateTime createdAt;

  // --- OPTIONAL FIELDS ---
  final DateTime? releaseDate;
  final String? orderId;
  final String? planId;
  
  // ✅ NEW: Fee Transparency Fields
  final double? grossAmount; // The amount the customer actually paid
  final double? feeAmount;   // The cut Korra took

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
    this.grossAmount,
    this.feeAmount,
  });

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
      'releaseDate': releaseDate != null ? Timestamp.fromDate(releaseDate!) : null,
      'orderId': orderId,
      'planId': planId,
      // ✅ Save to DB
      'grossAmount': grossAmount,
      'feeAmount': feeAmount,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      type: map['type'] ?? 'unknown',
      description: map['description'] ?? '',
      reference: map['reference'] ?? '',
      status: map['status'] ?? 'pending',
      balanceBefore: (map['balanceBefore'] ?? 0).toDouble(),
      balanceAfter: (map['balanceAfter'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      
      releaseDate: (map['releaseDate'] as Timestamp?)?.toDate(),
      orderId: map['orderId'],
      planId: map['planId'],

      // ✅ Parse safely (Handle nulls if old data doesn't have it)
      grossAmount: (map['grossAmount'] as num?)?.toDouble(),
      feeAmount: (map['feeAmount'] as num?)?.toDouble(),
    );
  }
}