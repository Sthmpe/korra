import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/vendor/vendor_setting.dart';
import '../../models/vendor/payout/payout_details.dart';
import 'vendor_repository.dart';

extension VendorSettingsExtension on VendorRepository {
  /// Fetches both Payout Details and PIN Status in one go.
  Future<VendorSettings> getVendorSettings(
    String uid, {
    bool forceRefresh = false,
  }) async {
    if (cachedSettings != null && !forceRefresh) {
      return cachedSettings!;
    }

    try {
      final results = await Future.wait([
        firestore
            .collection('vendors')
            .doc(uid)
            .collection('settings')
            .doc('payout_details')
            .get(),
        firestore
            .collection('vendors')
            .doc(uid)
            .collection('security')
            .doc('transaction_pin')
            .get(),
      ]);

      final payoutDoc = results[0];
      final pinDoc = results[1];

      // 1. Parse Payout Details
      PayoutDetails details = PayoutDetails.empty();
      if (payoutDoc.exists && payoutDoc.data() != null) {
        details = PayoutDetails.fromMap(
          payoutDoc.data() as Map<String, dynamic>,
        );
      }

      // 2. Check if PIN exists
      final bool isPinSet = pinDoc.exists;

      cachedSettings = VendorSettings(
        payoutDetails: details,
        isPinSet: isPinSet,
      );

      return cachedSettings!;
    } catch (e) {
      debugPrint('streamVendorSettings error: $e');
      return VendorSettings(
        payoutDetails: PayoutDetails.empty(),
        isPinSet: false,
      );
    }
  }

  // SAVE PAYOUT DETAILS
  Future<void> savePayoutDetails(String uid, PayoutDetails details) async {
    try {
      await firestore
          .collection('vendors')
          .doc(uid)
          .collection('settings')
          .doc('payout_details')
          .set(
            {
              'bankName': details.bankName,
              'accountNumber': details.bankAccountNumber,
              'accountName': details.bankAccountName,
              'bankCode': details.bankCode,
              'paystackRecipientCode': details.paystackRecipientCode,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
      if (cachedSettings != null) {
        cachedSettings = VendorSettings(
          payoutDetails: details,
          isPinSet: cachedSettings!.isPinSet,
        );
      }
    } catch (e) {
      throw Exception("Error saving details: $e");
    }
  }

  // SAVE STOREFRONT SETTINGS
  Future<void> saveStorefrontSettings({
    required String uid,
    required String storeName,
    required String description,
    required String slug,
    required String logoUrl,
    required String coverUrl,
    required String whatsappGroup,
    required String instagram,
    required String tiktok,
    required String contactPhone,
    required bool absorbOutrightFee,
  }) async {
    try {
      await firestore.collection('vendors').doc(uid).set({
        'store': {
          'storeName': storeName,
          'description': description,
          'slug': slug.toLowerCase().trim().replaceAll(' ', '-'),
          'logoUrl': logoUrl,
          'coverUrl': coverUrl,
          'contactPhone': contactPhone,
          'absorbOutrightFee': absorbOutrightFee,
        },
        'socials': {
          'whatsappGroup': whatsappGroup,
          'instagram': instagram,
          'tiktok': tiktok,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception("Error saving storefront settings: $e");
    }
  }
}
