class PaymentReceiptData {
  final String reference;
  final DateTime date;
  final String vendorName;
  final String customerName;
  final String productName;
  final String productCode;
  final double totalValue;
  final double amountPaidSoFar;
  final double amountPaidNow;
  final String paymentMethod;
  final double balanceRemaining;
  final String status;
  final bool isFinished;
  final double creditUsed;
  final double walletUsed;
  final DateTime? nextDueDate;

  // ✅ FEE FIELDS
  final double feeAmount;           // Total fee (cash fee + store fee)
  final double cashFeeAmount;       // 3.5% of cash portion only
  final double storeFeeAmount;      // 0.35% of store balance used, min ₦100
  final double appliedToItem;       // Amount that actually went to plan
  final double totalWalletDeducted; // Cash + store fee from wallet

  PaymentReceiptData({
    required this.reference,
    required this.date,
    required this.vendorName,
    required this.customerName,
    required this.productName,
    required this.productCode,
    required this.totalValue,
    required this.amountPaidSoFar,
    required this.amountPaidNow,
    required this.paymentMethod,
    required this.balanceRemaining,
    required this.status,
    required this.isFinished,
    required this.creditUsed,
    required this.walletUsed,
    this.nextDueDate,
    this.feeAmount = 0.0,
    this.cashFeeAmount = 0.0,
    this.storeFeeAmount = 0.0,
    this.appliedToItem = 0.0,
    this.totalWalletDeducted = 0.0,
  });

  factory PaymentReceiptData.fromJson(Map<String, dynamic> json) {
    return PaymentReceiptData(
      reference: json['reference'] ?? 'REF-UNKNOWN',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      vendorName: json['vendorName'] ?? 'Vendor',
      customerName: json['customerName'] ?? 'Customer',
      productName: json['productName'] ?? 'Item',
      productCode: json['productCode'] ?? '',
      totalValue: (json['totalValue'] ?? 0).toDouble(),
      amountPaidSoFar: (json['amountPaidSoFar'] ?? 0).toDouble(),
      amountPaidNow: (json['amountPaidNow'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? 'Wallet',
      balanceRemaining: (json['balanceRemaining'] ?? 0).toDouble(),
      status: json['status'] ?? 'IN PROGRESS',
      isFinished: json['isFinished'] ?? false,
      creditUsed: (json['creditUsed'] ?? 0).toDouble(),
      walletUsed: (json['walletUsed'] ?? 0).toDouble(),
      nextDueDate: json['nextDueDate'] != null
          ? DateTime.tryParse(json['nextDueDate'])
          : null,
      // ✅ Map new fee fields safely
      feeAmount: (json['feeAmount'] ?? 0).toDouble(),
      cashFeeAmount: (json['cashFeeAmount'] ?? 0).toDouble(),
      storeFeeAmount: (json['storeFeeAmount'] ?? 0).toDouble(),
      appliedToItem: (json['appliedToItem'] ?? 0).toDouble(),
      totalWalletDeducted: (json['totalWalletDeducted'] ?? 0).toDouble(),
    );
  }

  factory PaymentReceiptData.fromPartial({
    required double amount,
    required DateTime date,
    required String title,
    String? reference,
    String status = 'SUCCESSFUL',
    String vendorName = 'Korra Partner',
    String customerName = 'Me',
  }) {
    final cashFee = double.parse((amount * 0.035).toStringAsFixed(2));
    final applied = double.parse((amount - cashFee).toStringAsFixed(2));
    return PaymentReceiptData(
      reference: reference ?? 'TX-\${date.millisecondsSinceEpoch}',
      date: date,
      vendorName: vendorName,
      customerName: customerName,
      productName: title,
      productCode: '',
      totalValue: amount,
      amountPaidSoFar: amount,
      amountPaidNow: amount,
      paymentMethod: 'Wallet/Card',
      balanceRemaining: 0.0,
      status: status,
      isFinished: false,
      creditUsed: 0,
      walletUsed: amount,
      feeAmount: cashFee,
      cashFeeAmount: cashFee,
      storeFeeAmount: 0.0,
      appliedToItem: applied,
      totalWalletDeducted: amount,
    );
  }
}