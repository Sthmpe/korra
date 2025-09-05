class PayoutDetails {
  final num withdrawableBalance;
  final String walletAccountNumber;
  final String walletAccountName;
  final String walletAccountReference;
  final String bankCode;
  final String bankAccountNumber;
  final String bankAccountName;
  final String bankName;

  PayoutDetails({
    required this.withdrawableBalance,
    required this.walletAccountNumber,
    required this.walletAccountName,
    required this.walletAccountReference,
    required this.bankCode,
    required this.bankAccountNumber,
    required this.bankAccountName,
    required this.bankName,
  });

  factory PayoutDetails.fromMap(Map<String, dynamic> map) {
    return PayoutDetails(
      // It now correctly reads the snake_case keys from Firestore
      withdrawableBalance: map['withdrawable_balance'] ?? 0,
      walletAccountNumber: map['wallet_account_number'] ?? '',
      walletAccountName: map['wallet_account_name'] ?? '',
      walletAccountReference: map['wallet_account_reference'] ?? '',
      bankCode: map['bank_code'] ?? '',
      bankAccountNumber: map['bank_account_number'] ?? '',
      bankAccountName: map['bank_account_name'] ?? '',
      bankName: map['bank_name'] ?? '',
    );
  }

  /// Create an empty PayoutDetails instance
  factory PayoutDetails.empty() {
    return PayoutDetails(
      withdrawableBalance: 0,
      walletAccountNumber: '',
      walletAccountName: '',
      walletAccountReference: '',
      bankCode: '',
      bankAccountNumber: '',
      bankAccountName: '',
      bankName: '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'withdrawable_balance': withdrawableBalance,
      'wallet_account_number': walletAccountNumber,
      'wallet_account_name': walletAccountName,
      'wallet_account_reference': walletAccountReference,
      'bank_code': bankCode,
      'bank_account_number': bankAccountNumber,
      'bank_account_name': bankAccountName,
      'bank_name': bankName,
    };
  }

  PayoutDetails copyWith({
    num? withdrawableBalance,
    String? walletAccountNumber,
    String? walletAccountName,
    String? walletAccountReference,
    String? bankCode,
    String? bankAccountNumber,
    String? bankAccountName,
    String? bankName,
  }) {
    return PayoutDetails(
      withdrawableBalance: withdrawableBalance ?? this.withdrawableBalance,
      walletAccountNumber: walletAccountNumber ?? this.walletAccountNumber,
      walletAccountName: walletAccountName ?? this.walletAccountName,
      walletAccountReference:
          walletAccountReference ?? this.walletAccountReference,
      bankCode: bankCode ?? this.bankCode,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankName: bankName ?? this.bankName,
    );
  }

  /// Masked bank account (e.g., "GTB ••1234")
  String get masked {
    if (bankAccountNumber.isEmpty || bankName.isEmpty) return '';
    final last4 = bankAccountNumber.length >= 4
        ? bankAccountNumber.substring(bankAccountNumber.length - 4)
        : bankAccountNumber;
    return '${bankName.toUpperCase()} •• $last4';
  }
}
