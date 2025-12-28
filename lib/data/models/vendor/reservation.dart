// lib/data/models/vendor/reservation.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum ReservationStatus {
  newRes,         // Active (Created Today)
  ongoing,        // Active (Older)
  readyForPickup, // Completed but NOT picked up (Action Required)
  completed,      // Completed AND Picked up (History)
  cancelled       // Cancelled
}

class Reservation {
  final String id;
  final String customerName;
  final String customerPhone;
  final String? customerId;
  final String productTitle;
  final String productCode;
  final String imageUrl;
  final double totalAmount;
  final double amountPaid;
  final DateTime createdAt;
  final String statusRaw; 
  
  // ✅ NEW FIELD
  final DateTime? fulfilledAt; 

  Reservation({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.productTitle,
    required this.productCode,
    required this.imageUrl,
    required this.totalAmount,
    required this.amountPaid,
    required this.createdAt,
    required this.statusRaw,
    this.fulfilledAt,
    this.customerId,
  });

  // Helpers
  bool get isCompleted => statusRaw == 'completed';
  bool get isCancelled => statusRaw == 'cancelled' || statusRaw == 'defaulted';
  
  // ✅ The Logic
  bool get isReadyForPickup => isCompleted && fulfilledAt == null;
  bool get isFulfilled => fulfilledAt != null;

  // Formatting
  String get totalText => "₦${(totalAmount).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";
  String get paidText => "₦${(amountPaid).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";
  String get remainingText => "₦${(totalAmount - amountPaid).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";
  
  int get progress => totalAmount == 0 ? 0 : ((amountPaid / totalAmount) * 100).toInt();
  double get progress01 => totalAmount == 0 ? 0 : (amountPaid / totalAmount).clamp(0.0, 1.0);

  // ✅ UPDATED STATUS MAPPING
  ReservationStatus get status {
    if (statusRaw == 'cancelled' || statusRaw == 'defaulted') return ReservationStatus.cancelled;
    
    if (statusRaw == 'completed') {
      // If completed but not fulfilled -> Ready for Pickup
      if (fulfilledAt == null) return ReservationStatus.readyForPickup;
      // If fulfilled -> Completed (History)
      return ReservationStatus.completed;
    }
    
    // Active Logic (New vs Ongoing)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // If created today, it's New
    if (createdAt.isAfter(today)) return ReservationStatus.newRes;
    
    return ReservationStatus.ongoing;
  }

  factory Reservation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reservation(
      id: doc.id,
      customerName: data['customerName'] ?? 'Unknown',
      customerPhone: data['customerPhone'] ?? '',
      customerId: data['customerId'] ?? '',
      productTitle: data['title'] ?? 'Product',
      productCode: data['productCode'] ?? '',
      imageUrl: (data['imageUrls'] != null && (data['imageUrls'] as List).isNotEmpty) 
          ? data['imageUrls'][0] 
          : '',
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      amountPaid: (data['amountPaid'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statusRaw: data['status'] ?? 'active',
      
      // ✅ Parse Date
      fulfilledAt: data['fulfilledAt'] != null 
          ? (data['fulfilledAt'] as Timestamp).toDate() 
          : null,
    );
  }
}