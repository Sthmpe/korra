import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String customerId;
  final double amount;
  final String type; // 'deposit', 'fee', 'down_payment', 'installment'
  final String description;
  final String planId; // 'none' for deposits
  final String reference; // payment reference or plan ID
  final String status; // 'success', 'pending', 'failed'
  final double balanceBefore;
  final double balanceAfter;
  final DateTime createdAt;
  final double convertedAmount;
  // ✅ NEW: Snapshot of the receipt at the moment of transaction
  final Map<String, dynamic>? receiptData;

  const TransactionModel({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.type,
    required this.description,
    required this.planId,
    required this.reference,
    required this.status,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.createdAt,
    required this.convertedAmount,
    this.receiptData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'amount': amount,
      'type': type,
      'description': description,
      'planId': planId,
      'reference': reference,
      'status': status,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'createdAt': FieldValue.serverTimestamp(),
      'convertedAmount': convertedAmount,
      'receiptData': receiptData, // ✅ Saved to DB
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      customerId: map['customerId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      type: map['type'] ?? 'unknown',
      description: map['description'] ?? '',
      planId: map['planId'] ?? 'none',
      reference: map['reference'] ?? '',
      status: map['status'] ?? 'pending',
      balanceBefore: (map['balanceBefore'] ?? 0).toDouble(),
      balanceAfter: (map['balanceAfter'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      convertedAmount:(map['metadata']?['convertedAmount'] != null) ? (map['metadata']?['convertedAmount']).toDouble() : 0,
      // ✅ Parse the Map safely
      receiptData: map['receiptData'] != null 
          ? Map<String, dynamic>.from(map['receiptData']) 
          : null,
    );
  }
}