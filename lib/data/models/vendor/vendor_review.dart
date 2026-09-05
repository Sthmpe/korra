// lib/data/models/vendor/vendor_review.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class VendorReview {
  final String id;
  final String customerId;
  final String customerName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final bool isMock;

  VendorReview({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.isMock = false,
  });

  factory VendorReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VendorReview(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? 'Anonymous',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isMock: data['isMock'] ?? false,
    );
  }
}
