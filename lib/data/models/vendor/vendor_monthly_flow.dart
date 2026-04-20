class VendorMonthlyFlow {
  final double earnings;
  final double creditIssued;
  final double creditRedeemed;

  VendorMonthlyFlow({
    required this.earnings, 
    required this.creditIssued, 
    required this.creditRedeemed
  });

  factory VendorMonthlyFlow.fromMap(Map<String, dynamic>? data) {
    if (data == null) return VendorMonthlyFlow(earnings: 0, creditIssued: 0, creditRedeemed: 0);
    return VendorMonthlyFlow(
      earnings: (data['earnings'] ?? 0.0).toDouble(),
      creditIssued: (data['storeCreditIssued'] ?? 0.0).toDouble(),
      creditRedeemed: (data['storeCreditRedeemed'] ?? 0.0).toDouble(),
    );
  }
}