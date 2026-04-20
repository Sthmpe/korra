import 'package:cloud_firestore/cloud_firestore.dart';

class PayoutDetails {
  final String bankName;
  final String bankCode;
  final String bankAccountNumber; // Firestore key: 'accountNumber'
  final String bankAccountName;   // Firestore key: 'accountName'
  final String? paystackRecipientCode; // New field for Paystack recipient code
  final DateTime? updatedAt;

  // Note: We do NOT store 'withdrawableBalance' here anymore.
  // Balance is a live calculated value from the Ledger, passed separately in the State.

  const PayoutDetails({
    required this.bankName,
    required this.bankCode,
    required this.bankAccountNumber,
    required this.bankAccountName,
    this.paystackRecipientCode,
    this.updatedAt,
  });

  /// Creates an empty instance for initial state
  factory PayoutDetails.empty() {
    return const PayoutDetails(
      bankName: '',
      bankCode: '',
      bankAccountNumber: '',
      bankAccountName: '',
      paystackRecipientCode: null,
      updatedAt: null,
    );
  }

  /// Converts Firestore Document Data to Model
  factory PayoutDetails.fromMap(Map<String, dynamic> data) {
    return PayoutDetails(
      bankName: data['bankName'] ?? '',
      bankCode: data['bankCode'] ?? '',
      // Map Firestore 'accountNumber' to our internal 'bankAccountNumber'
      bankAccountNumber: data['accountNumber'] ?? '', 
      // Map Firestore 'accountName' to our internal 'bankAccountName'
      bankAccountName: data['accountName'] ?? '',
      paystackRecipientCode: data['paystackRecipientCode'],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts Model to Map (If saving directly from Flutter)
  Map<String, dynamic> toMap() {
    return {
      'bankName': bankName,
      'bankCode': bankCode,
      'accountNumber': bankAccountNumber,
      'accountName': bankAccountName,
      'paystackRecipientCode': paystackRecipientCode,
      'updatedAt': FieldValue.serverTimestamp(), 
    };
  }

  /// Helper for updating state immutably
  PayoutDetails copyWith({
    String? bankName,
    String? bankCode,
    String? bankAccountNumber,
    String? bankAccountName,
    String? paystackRecipientCode,
    DateTime? updatedAt,
  }) {
    return PayoutDetails(
      bankName: bankName ?? this.bankName,
      bankCode: bankCode ?? this.bankCode,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      paystackRecipientCode: paystackRecipientCode ?? this.paystackRecipientCode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}