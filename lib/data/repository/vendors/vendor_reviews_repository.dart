// lib/data/repository/vendors/vendor_reviews_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/vendor/vendor_review.dart';
import 'vendor_repository.dart';

extension VendorReviewsRepository on VendorRepository {
  // Bounded: newest reviews only, never the whole subcollection at once.
  Stream<List<VendorReview>> streamReviews(String vendorId, {int limit = 50}) {
    return firestore
        .collection('vendors')
        .doc(vendorId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VendorReview.fromFirestore(doc))
            .toList());
  }
}
