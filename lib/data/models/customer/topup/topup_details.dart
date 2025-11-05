class TopUpDetails {
  final num availableBalance;
  final String walletAccountNumber;
  final String walletAccountName;
  final String walletAccountReference;
  final String walletBankName;
  final String bankLogoImageString;

  // Optional — for external deposit sources (e.g. linked bank/card)
  final String fundingSource; // e.g., "bank_transfer", "card", "ussd"
  final String lastTopUpMethod; // for quick UI recall

  TopUpDetails({
    required this.availableBalance,
    required this.walletAccountNumber,
    required this.walletAccountName,
    required this.walletAccountReference,
    this.walletBankName = 'Moniepoint',
    this.bankLogoImageString = 'assets/images/moniepoint-inc-icon.png',
    this.fundingSource = '',
    this.lastTopUpMethod = '',
  });

  factory TopUpDetails.fromMap(Map<String, dynamic> map) {
    return TopUpDetails(
      availableBalance: map['available_balance'] ?? 0,
      walletAccountNumber: map['wallet_account_number'] ?? '',
      walletAccountName: map['wallet_account_name'] ?? '',
      walletAccountReference: map['wallet_account_reference'] ?? '',
      walletBankName: map['wallet_bank_name'] ?? 'Moniepoint',
      fundingSource: map['funding_source'] ?? '',
      lastTopUpMethod: map['last_top_up_method'] ?? '',
      bankLogoImageString: map['bank_logo_image_string'] ?? 'assets/images/moniepoint-inc-icon.png',
    );
  }

  factory TopUpDetails.empty() {
    return TopUpDetails(
      availableBalance: 0,
      walletAccountNumber: '',
      walletAccountName: '',
      walletAccountReference: '',
      walletBankName: 'Moniepoint',
      fundingSource: '',
      lastTopUpMethod: '',
      bankLogoImageString: 'assets/images/moniepoint-inc-icon.png',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'available_balance': availableBalance,
      'wallet_account_number': walletAccountNumber,
      'wallet_account_name': walletAccountName,
      'wallet_account_reference': walletAccountReference,
      'wallet_bank_name': walletBankName,
      'funding_source': fundingSource,
      'last_top_up_method': lastTopUpMethod,
      'bank_logo_image_string': bankLogoImageString,
    };
  }

  TopUpDetails copyWith({
    num? availableBalance,
    String? walletAccountNumber,
    String? walletAccountName,
    String? walletAccountReference,
    String? walletBankName,
    String? fundingSource,
    String? lastTopUpMethod,
    String? bankLogoImageString,
  }) {
    return TopUpDetails(
      availableBalance: availableBalance ?? this.availableBalance,
      walletAccountNumber: walletAccountNumber ?? this.walletAccountNumber,
      walletAccountName: walletAccountName ?? this.walletAccountName,
      walletBankName: walletBankName ?? this.walletBankName,
      walletAccountReference:
          walletAccountReference ?? this.walletAccountReference,
      fundingSource: fundingSource ?? this.fundingSource,
      lastTopUpMethod: lastTopUpMethod ?? this.lastTopUpMethod,
      bankLogoImageString:
          bankLogoImageString ?? this.bankLogoImageString,
    );
  }

  /// Display helper — e.g., "₦5,000 • Wallet"
  String get summary {
    final balanceStr = availableBalance.toStringAsFixed(2);
    return '₦$balanceStr • Wallet';
  }

  /// Masked bank account (e.g., "GTB ••1234")
  String get masked {
    if (walletAccountNumber.isEmpty || walletBankName.isEmpty) return '';
    final last4 = walletAccountNumber.length >= 4
        ? walletAccountNumber.substring(walletAccountNumber.length - 4)
        : walletAccountNumber;
    return '${walletBankName.toUpperCase()} •• $last4';
  }
}
