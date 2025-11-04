import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:korra/data/models/customer/topup/topup_details.dart';
import 'package:korra/data/repository/customer/customer_repository.dart';


extension TopUpRepository on CustomerRepository {
  /// Get payout details for a vendor
  Future<TopUpDetails?> getTopUpDetails(String customerUid) async {
    final doc = await firestore.collection('topup').doc(customerUid).get();

    if (doc.exists && doc.data()?['topup_details'] != null) {
      return TopUpDetails.fromMap(doc.data()!['topup_details']);
    }

    return null;
  }

  /// Save/Update payout details
  Future<void> saveTopUpDetails(
    String customerUid,
    TopUpDetails details,
  ) async {
    await firestore.collection('topup').doc(customerUid).set({
      'topup_details': details.toMap(),
    }, SetOptions(merge: true));
  }
}
