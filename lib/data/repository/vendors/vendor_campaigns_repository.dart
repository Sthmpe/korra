// lib/data/repository/vendors/vendor_campaigns_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/vendor/campaign_model.dart';
import '../../models/vendor/vendor_visibility.dart';
import 'vendor_repository.dart';

extension VendorCampaignsRepository on VendorRepository {
  // 1. STREAM CAMPAIGNS (Realtime feed of campaigns for a merchant)
  Stream<List<Campaign>> streamCampaigns(String vendorId) {
    return firestore
        .collection('campaigns')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Campaign.fromFirestore(doc))
            .toList());
  }

  // 2. CREATE CAMPAIGN (Store campaign document in Firestore)
  Future<void> createCampaign(Campaign campaign) async {
    try {
      final doc = firestore.collection('campaigns').doc();
      final data = campaign.toMap();
      await doc.set(data);
    } catch (e) {
      throw Exception("Failed to create marketing campaign: $e");
    }
  }

  // 3. STREAM VISIBILITY (Realtime visibility and reach stats)
  Stream<VendorVisibility> streamVisibility(String vendorId) {
    return firestore
        .collection('vendor_visibility')
        .doc(vendorId)
        .snapshots()
        .map((snapshot) => VendorVisibility.fromFirestore(snapshot));
  }
}
