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
  final String paymentMethod; // e.g., "Store Credit" or "Wallet"
  final double balanceRemaining;
  final String status;
  final bool isFinished;
  
  // ✅ NEW FIELDS
  final double creditUsed;
  final double walletUsed;
  final DateTime? nextDueDate; // Nullable (doesn't exist if plan is finished)

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
      
      // ✅ Map new fields safely
      creditUsed: (json['creditUsed'] ?? 0).toDouble(),
      walletUsed: (json['walletUsed'] ?? 0).toDouble(),
      nextDueDate: json['nextDueDate'] != null ? DateTime.tryParse(json['nextDueDate']) : null,
    );
  }

  factory PaymentReceiptData.fromPartial({
    required double amount,
    required DateTime date,
    required String title, // Used as Product Name
    String? reference,
    String status = 'SUCCESSFUL',
    String vendorName = 'Korra Partner',
    String customerName = 'Me',
  }) {
    return PaymentReceiptData(
      reference: reference ?? 'TX-${date.millisecondsSinceEpoch}',
      date: date,
      vendorName: vendorName,
      customerName: customerName,
      productName: title,
      productCode: '',
      totalValue: amount, // Assume total = amount for simple views
      amountPaidSoFar: amount,
      amountPaidNow: amount,
      paymentMethod: 'Wallet/Card',
      balanceRemaining: 0.0,
      status: status,
      isFinished: false,
      creditUsed: 0,
      walletUsed: amount,
    );
  }
}