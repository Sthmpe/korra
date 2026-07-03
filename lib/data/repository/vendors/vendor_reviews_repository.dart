// lib/data/repository/vendors/vendor_reviews_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/vendor/vendor_review.dart';
import 'vendor_repository.dart';

extension VendorReviewsRepository on VendorRepository {
  Stream<List<VendorReview>> streamReviews(String vendorId) {
    return firestore
        .collection('vendors')
        .doc(vendorId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VendorReview.fromFirestore(doc))
            .toList());
  }
}
