import 'package:cloud_firestore/cloud_firestore.dart';

class PayoutHistory {
  final String id; // Firestore document ID
  final num amount;
  final String status; // pending, completed, failed
  final String transactionRef;
  final String destinationAccountNumber;
  final String destinationAccountName;
  final String destinationBankName;
  final String destinationBankCode;
  final DateTime createdAt;

  PayoutHistory({
    required this.id,
    required this.amount,
    required this.status,
    required this.transactionRef,
    required this.destinationAccountNumber,
    required this.destinationAccountName,
    required this.destinationBankName,
    required this.destinationBankCode,
    required this.createdAt,
  });

  factory PayoutHistory.fromMap(String id, Map<String, dynamic> map) {
    return PayoutHistory(
      id: id,
      amount: map['amount'] ?? 0,
      status: map['status'] ?? 'pending',
      transactionRef: map['transaction_ref'] ?? '',
      destinationAccountNumber: map['destination_account_number'] ?? '',
      destinationAccountName: map['destination_account_name'] ?? '',
      destinationBankName: map['destination_bank_name'] ?? '',
      destinationBankCode: map['destination_bank_code'] ?? '',
      createdAt: map['created_at'] != null
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'status': status,
      'transaction_ref': transactionRef,
      'destination_account_number': destinationAccountNumber,
      'destination_account_name': destinationAccountName,
      'destination_bank_name': destinationBankName,
      'destination_bank_code': destinationBankCode,
      'created_at': createdAt,
    };
  }
}
