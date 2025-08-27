import 'package:equatable/equatable.dart';

enum ReservationStatus { newRes, ongoing, completed, cancelled }

class VendorReservation extends Equatable {
  // ---- Source-of-truth fields (from DB/API) ----
  final String id;
  final String productTitle;
  final String productImageUrl; // canonical
  final String sku;
  final int quantity;
  final int unitPrice; // in NGN whole units
  final int total;     // in NGN whole units
  final int paid;      // in NGN whole units
  final DateTime createdAt;
  final DateTime? nextDueAt;
  final bool approved;
  final bool cancelled;
  final bool autoPay;
  final String customerName;

  const VendorReservation({
    required this.id,
    required this.productTitle,
    required this.productImageUrl,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.paid,
    required this.createdAt,
    required this.nextDueAt,
    required this.approved,
    required this.cancelled,
    required this.autoPay,
    required this.customerName,
  });

  // ---- Computed/derived for UI (keep logic out of widgets) ----

  /// Alias for legacy UI that references `imageUrl`.
  String get imageUrl => productImageUrl;

  /// 0..1 progress (safe for charts)
  double get progress01 =>
      total <= 0 ? 0.0 : (paid / total).clamp(0.0, 1.0);

  /// 0..100 progress (used by your tile)
  int get progress => (progress01 * 100).round();

  int get remaining => (total - paid).clamp(0, total);

  bool get isCompleted => paid >= total && total > 0;

  bool get overdue {
    if (isCompleted || cancelled) return false;
    if (nextDueAt == null) return false;
    final now = DateTime.now();
    return nextDueAt!.isBefore(now);
  }

  ReservationStatus get status {
    if (cancelled) return ReservationStatus.cancelled;
    if (!approved) return ReservationStatus.newRes;
    if (isCompleted) return ReservationStatus.completed;
    return ReservationStatus.ongoing;
  }

  // ---- Formatted strings (UI-ready, no intl dependency) ----

  String get unitPriceText => _naira(unitPrice);
  String get totalText => _naira(total);
  String get remainingText => '${_naira(remaining)} left';

  String get createdAtText {
    final m = _monthsShort[createdAt.month - 1];
    final dd = createdAt.day.toString();
    final hh = _two(createdAt.hour);
    final mm = _two(createdAt.minute);
    return '$m $dd • $hh:$mm';
  }

  String get nextDueText {
    if (cancelled) return 'Cancelled';
    if (isCompleted) return 'Paid off';
    if (nextDueAt == null) return '—';
    final dow = _weekdaysShort[nextDueAt!.weekday % 7];
    final prefix = overdue ? 'Was due' : 'Due';
    return '$prefix $dow';
  }

  // ---- Helpers ----

  static const List<String> _monthsShort = [
    'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  static const List<String> _weekdaysShort = [
    'Sun','Mon','Tue','Wed','Thu','Fri','Sat'
  ];

  static String _two(int n) => n < 10 ? '0$n' : '$n';

  static String _naira(int amount) {
    final s = amount.abs().toString();
    final withCommas = s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    final sign = amount < 0 ? '-' : '';
    return '$sign₦$withCommas';
  }

  @override
  List<Object?> get props => [
    id, productTitle, productImageUrl, sku, quantity, unitPrice, total, paid,
    createdAt, nextDueAt, approved, cancelled, autoPay, customerName
  ];
}
