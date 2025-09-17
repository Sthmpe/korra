import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/vendor/payout/payout_details.dart';
import '../../models/vendor/payout/payout_history.dart';
import 'vendor_repository.dart';

extension PayoutRepository on VendorRepository {
  /// Reference to payout history collection for a vendor
  CollectionReference<Map<String, dynamic>> historyRef(String vendorUid) {
    return firestore.collection('payouts').doc(vendorUid).collection('history');
  }

   /// Add a new payout
  Future<String> addPayout(String vendorUid, PayoutHistory payout) async {
    final docRef = historyRef(vendorUid).doc();
    await docRef.set(payout.toMap());
    return docRef.id;
  }

  /// Update a payout
  Future<void> updatePayout(String vendorUid, String payoutId, Map<String, dynamic> updates) async {
    await historyRef(vendorUid).doc(payoutId).update(updates);
  }

  /// Get one payout by ID
  Future<PayoutHistory?> getPayoutById(String vendorUid, String payoutId) async {
    final doc = await historyRef(vendorUid).doc(payoutId).get();
    if (!doc.exists) return null;
    return PayoutHistory.fromMap(doc.id, doc.data()!);
  }

  // Get paginated payouts (10 at a time, newest first)
  Future<List<PayoutHistory>> getPaginatedPayouts(
    String vendorUid, {
    DocumentSnapshot? lastDoc,
    int limit = 10,
  }) async {
    Query<Map<String, dynamic>> query = historyRef(
      vendorUid,
    ).orderBy('created_at', descending: true).limit(limit);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => PayoutHistory.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Stream payouts in real-time (optional)
  Stream<List<PayoutHistory>> watchLatestPayouts(
    String vendorUid, {
    int limit = 10,
  }) {
    return historyRef(vendorUid)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PayoutHistory.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Get payout details for a vendor
  Future<PayoutDetails?> getPayoutDetails(String vendorUid) async {
    final doc = await firestore.collection('payouts').doc(vendorUid).get();

    if (doc.exists && doc.data()?['payout_details'] != null) {
      return PayoutDetails.fromMap(doc.data()!['payout_details']);
    }

    return null;
  }

  /// Save/Update payout details
  Future<void> savePayoutDetails(
    String vendorUid,
    PayoutDetails details,
  ) async {
    await firestore.collection('payouts').doc(vendorUid).set({
      'payout_details': details.toMap(),
    }, SetOptions(merge: true));
  }
}
