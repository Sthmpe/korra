// lib/data/models/plan.dart
class Plan {
  // required
  final String id;
  final String title;
  final String storeName;
  final String vendorUid;
  final List<String> imageUrls;
  final int progress;     // 0..100
  final String nextDue;   // e.g. "Due Fri"

  // optional UI summaries (nullable on purpose — UI has fallbacks)
  final double amountPaid;     // e.g. "₦75,500"
  final double amountRemain;   // e.g. "₦224,500"
  final double? nextAmount;     // e.g. "₦12,500"
  final String? cadenceText;        // e.g. "Weekly plan"

  const Plan({
    required this.id,
    required this.title,
    required this.vendorUid,
    required this.storeName,
    required this.imageUrls,
    required this.progress,
    required this.nextDue,
    required this.amountPaid,
    required this.amountRemain,
    required this.nextAmount,
    this.cadenceText,
  });
}
