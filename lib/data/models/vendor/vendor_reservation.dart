import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ReservationStatus { newRes, ongoing, completed, cancelled }

class VendorReservation extends Equatable {
  // ---- Source-of-truth fields (from DB/API) ----
  final String id;
  final String productTitle;
  final String productImageUrl; 
  final String productCode;
  final int quantity;
  final double unitPrice; 
  final double total;     
  final double paid;      
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
    required this.productCode,
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

  // ---- 🏭 Factory: Match Backend Data Structure ----
  factory VendorReservation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // 1. Extract Basic Fields
    final statusStr = data['status'] ?? 'active';
    final totalAmt = (data['totalAmount'] ?? 0).toDouble();
    final amtPaid = (data['amountPaid'] ?? 0).toDouble();
    final initDown = (data['initialDownPayment'] ?? 0).toDouble();

    // 2. Determine Logic Flags
    final bool isCancelled = statusStr == 'cancelled';
    final bool isCompleted = statusStr == 'completed';
    
    // Logic: Approved if Active AND Paid > DownPayment
    final bool isApproved = isCompleted || (statusStr == 'active' && amtPaid > (initDown + 100));

    return VendorReservation(
      id: doc.id,
      productTitle: data['title'] ?? 'Unknown Product',
      productImageUrl: (data['imageUrls'] as List?)?.firstOrNull ?? '',
      productCode: data['productCode'] ?? 'N/A', // Using productCode as productCode
      quantity: 1, 
      unitPrice: (data['totalProductPrice'] ?? 0).toDouble(),
      total: totalAmt,
      paid: amtPaid,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nextDueAt: (data['nextPaymentDate'] as Timestamp?)?.toDate(), 
      approved: isApproved,
      cancelled: isCancelled,
      autoPay: false, 
      customerName: data['customerName'] ?? 'Unknown Customer',
    );
  }

  // ---- Computed/derived for UI ----

  // ✅ FIX: Added this getter because ReservationTile uses data.imageUrl
  String get imageUrl => productImageUrl;

  double get progress01 => total <= 0 ? 0.0 : (paid / total).clamp(0.0, 1.0);
  int get progress => (progress01 * 100).round();
  double get remaining => (total - paid).clamp(0.0, total);
  bool get isCompleted => paid >= total && total > 0;

  bool get overdue {
    if (isCompleted || cancelled) return false;
    if (nextDueAt == null) return false;
    final now = DateTime.now();
    return nextDueAt!.isBefore(now);
  }

  ReservationStatus get status {
    if (cancelled) return ReservationStatus.cancelled;
    if (isCompleted) return ReservationStatus.completed;
    if (!approved) return ReservationStatus.newRes;
    return ReservationStatus.ongoing;              
  }

  // ---- Formatted strings ----

  String get unitPriceText => _naira(unitPrice);
  String get totalText => _naira(total);
  String get remainingText => '${_naira(remaining)} left';
  String get paidText => _naira(paid);

  String get createdAtText {
    final m = _monthsShort[createdAt.month - 1];
    final dd = createdAt.day.toString();
    return '$m $dd';
  }

  String get nextDueText {
    if (cancelled) return 'Cancelled';
    if (isCompleted) return 'Paid off';
    if (nextDueAt == null) return 'No due date';
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

  static String _naira(double amount) {
    final s = amount.toStringAsFixed(0);
    final withCommas = s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '₦$withCommas';
  }

  @override
  List<Object?> get props => [
    id, productTitle, total, paid, cancelled, approved, customerName
  ];
}