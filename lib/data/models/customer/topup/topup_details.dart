class TopUpDetails {
  final num availableBalance;
  final String walletAccountNumber;
  final String walletAccountName;
  final String walletAccountReference;

  // Optional — for external deposit sources (e.g. linked bank/card)
  final String fundingSource; // e.g., "bank_transfer", "card", "ussd"
  final String lastTopUpMethod; // for quick UI recall

  TopUpDetails({
    required this.availableBalance,
    required this.walletAccountNumber,
    required this.walletAccountName,
    required this.walletAccountReference,
    this.fundingSource = '',
    this.lastTopUpMethod = '',
  });

  factory TopUpDetails.fromMap(Map<String, dynamic> map) {
    return TopUpDetails(
      availableBalance: map['available_balance'] ?? 0,
      walletAccountNumber: map['wallet_account_number'] ?? '',
      walletAccountName: map['wallet_account_name'] ?? '',
      walletAccountReference: map['wallet_account_reference'] ?? '',
      fundingSource: map['funding_source'] ?? '',
      lastTopUpMethod: map['last_top_up_method'] ?? '',
    );
  }

  factory TopUpDetails.empty() {
    return TopUpDetails(
      availableBalance: 0,
      walletAccountNumber: '',
      walletAccountName: '',
      walletAccountReference: '',
      fundingSource: '',
      lastTopUpMethod: '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'available_balance': availableBalance,
      'wallet_account_number': walletAccountNumber,
      'wallet_account_name': walletAccountName,
      'wallet_account_reference': walletAccountReference,
      'funding_source': fundingSource,
      'last_top_up_method': lastTopUpMethod,
    };
  }

  TopUpDetails copyWith({
    num? availableBalance,
    String? walletAccountNumber,
    String? walletAccountName,
    String? walletAccountReference,
    String? fundingSource,
    String? lastTopUpMethod,
  }) {
    return TopUpDetails(
      availableBalance: availableBalance ?? this.availableBalance,
      walletAccountNumber: walletAccountNumber ?? this.walletAccountNumber,
      walletAccountName: walletAccountName ?? this.walletAccountName,
      walletAccountReference:
          walletAccountReference ?? this.walletAccountReference,
      fundingSource: fundingSource ?? this.fundingSource,
      lastTopUpMethod: lastTopUpMethod ?? this.lastTopUpMethod,
    );
  }

  /// Display helper — e.g., "₦5,000 • Wallet"
  String get summary {
    final balanceStr = availableBalance.toStringAsFixed(2);
    return '₦$balanceStr • Wallet';
  }
}
