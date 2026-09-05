// lib/data/repository/vendors/vendor_campaigns_repository.dart

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
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

  // 2. CREATE CAMPAIGN (Store campaign document in Firestore, then fan out)
  Future<void> createCampaign(Campaign campaign) async {
    late final String campaignId;
    try {
      final doc = firestore.collection('campaigns').doc();
      campaignId = doc.id;
      await doc.set(campaign.toMap());
    } catch (e) {
      throw Exception("Failed to create marketing campaign: $e");
    }

    // Fan out to the store's circle (push + in-app), skipping muted stores.
    // Fire-and-forget: the campaign already exists, so a broadcast hiccup must
    // NOT surface as a "campaign failed" error to the merchant.
    unawaited(_broadcastCampaign(campaign, campaignId));
  }

  Future<void> _broadcastCampaign(Campaign campaign, String campaignId) async {
    try {
      final user = auth.currentUser;
      if (user == null) return;

      final idToken = await user.getIdToken(true);
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature =
          Hmac(sha256, utf8.encode(korraSecret)).convert(utf8.encode(timestamp)).toString();

      await fx.invoke(
        'campaign-broadcast',
        headers: {
          'firebase-token': 'Bearer $idToken',
          'x-korra-timestamp': timestamp,
          'x-korra-signature': signature,
        },
        body: {
          'vendorId': campaign.vendorId,
          'campaignId': campaignId,
          'title': campaign.title,
          'body': campaign.caption,
          'imageUrl': campaign.imageUrl,
        },
      );
    } catch (e) {
      // Non-fatal — customers still see the campaign in Hot Deals.
      debugPrint("Campaign broadcast failed (non-fatal): $e");
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

  // 4. DELETE CAMPAIGN(S) — campaigns no longer auto-expire, so this is now
  // how a merchant ends one. SOFT delete: the doc survives as Campaign
  // History (archived + endedAt), keeping its opens/purchases analytics;
  // everything that treats campaigns as live filters archived out. Also
  // reverts the campaign's own effect on its target products (campaignTag +
  // discountedPrice), since nothing else ever did. Note: if a product was
  // later re-tagged by a NEWER campaign, deleting an older campaign that also
  // targeted it will still clear that newer tag/price too — campaigns don't
  // track "which one currently owns" a product's discount, so this is a
  // known simplification.
  Future<void> deleteCampaigns(List<Campaign> campaigns) async {
    if (campaigns.isEmpty) return;

    // Campaign docs themselves: guaranteed to exist (we just streamed them),
    // safe as one atomic batch.
    final batch = firestore.batch();
    for (final campaign in campaigns) {
      batch.update(firestore.collection('campaigns').doc(campaign.id), {
        'archived': true,
        'endedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    // Product cleanup: best-effort, one at a time. A product that was since
    // deleted must not block the campaign deletion above, which already
    // succeeded — `update()` throws NOT_FOUND on a missing doc, so each is
    // caught independently rather than risking an all-or-nothing batch.
    final productIds = campaigns.expand((c) => c.productIds).toSet();
    await Future.wait(productIds.map((id) async {
      try {
        await firestore.collection('products').doc(id).update({
          'campaignTag': FieldValue.delete(),
          'discountedPrice': FieldValue.delete(),
          'campaignEndsAt': FieldValue.delete(),
        });
      } catch (e) {
        debugPrint("Campaign cleanup: could not revert product $id: $e");
      }
    }));
  }

  Future<void> deleteCampaign(Campaign campaign) => deleteCampaigns([campaign]);
}
