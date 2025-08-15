// lib/data/models/plan.dart
class Plan {
  // required
  final String id;
  final String title;
  final String vendor;
  final String imageUrl;
  final int progress;     // 0..100
  final String nextDue;   // e.g. "Due Fri"

  // optional UI summaries (nullable on purpose — UI has fallbacks)
  final String? amountPaidText;     // e.g. "₦75,500"
  final String? amountRemainText;   // e.g. "₦224,500"
  final String? cadenceText;        // e.g. "Weekly plan"
  final String? nextAmountText;     // e.g. "₦12,500"

  const Plan({
    required this.id,
    required this.title,
    required this.vendor,
    required this.imageUrl,
    required this.progress,
    required this.nextDue,
    this.amountPaidText,
    this.amountRemainText,
    this.cadenceText,
    this.nextAmountText,
  });
}
