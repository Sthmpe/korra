// lib/data/models/vendor/vendor_visibility.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class VendorVisibility {
  final String vendorId;
  final int topSellerCircles;
  final int mostVisitedCircles;
  final bool isHighlighted;

  VendorVisibility({
    required this.vendorId,
    this.topSellerCircles = 0,
    this.mostVisitedCircles = 0,
    this.isHighlighted = false,
  });

  factory VendorVisibility.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      return VendorVisibility(vendorId: doc.id);
    }
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return VendorVisibility(
      vendorId: doc.id,
      topSellerCircles: (data['topSellerCircles'] ?? 0).toInt(),
      mostVisitedCircles: (data['mostVisitedCircles'] ?? 0).toInt(),
      isHighlighted: data['isHighlighted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'topSellerCircles': topSellerCircles,
      'mostVisitedCircles': mostVisitedCircles,
      'isHighlighted': isHighlighted,
    };
  }
}
