// lib/data/services/recent_views_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/product_model.dart';

/// Records products the customer actually LOOKED at (product details sheet
/// open for at least [minDwell]) across every store. Feeds two things:
///
///  1. The "Last Viewed" strip on the Stores page — views from the last 24
///     hours, newest first, purchased products removed immediately.
///  2. The re-engagement push (view-reengagement edge function): one push per
///     customer, 24h after their first qualifying view, for the product with
///     the longest dwell time in that window.
///
/// Storage:
///  - customers/{uid}/recent_views/{productId} — one doc per product, dwellMs
///    keeps the MAX across repeat views, viewedAt the most recent view.
///  - view_reengagement_queue/{uid} — single marker doc telling the cron when
///    this customer's 24h window closes; created on the FIRST qualifying view
///    and deleted by the function after (or instead of) sending the push.
class RecentViewsService {
  static final RecentViewsService instance = RecentViewsService._internal();
  RecentViewsService._internal();

  static const Duration minDwell = Duration(seconds: 5);
  static const Duration viewLifetime = Duration(hours: 24);

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _views(String uid) =>
      _db.collection('customers').doc(uid).collection('recent_views');

  /// Views from the last 24h, newest first, for the Last Viewed strip.
  /// (The client filters the 24h cutoff so no composite index is needed.)
  Stream<QuerySnapshot<Map<String, dynamic>>>? watchRecentViews() {
    final uid = _uid;
    if (uid == null) return null;
    return _views(uid).orderBy('viewedAt', descending: true).limit(15).snapshots();
  }

  /// Called by the product details sheet when it closes after a qualifying
  /// dwell. Fire-and-forget: view logging must never surface an error.
  Future<void> recordView(Product product, Duration dwell, {String? storeSlug}) async {
    if (dwell < minDwell) return;
    final uid = _uid;
    if (uid == null) return;

    try {
      final ref = _views(uid).doc(product.id);
      final existing = await ref.get();
      final prevDwell = (existing.data()?['dwellMs'] as num?)?.toInt() ?? 0;

      await ref.set({
        'productId': product.id,
        'vendorId': product.vendorId,
        'storeName': product.storeName,
        if (storeSlug != null && storeSlug.isNotEmpty) 'slug': storeSlug,
        'name': product.name,
        'imageUrl': product.images.isNotEmpty ? product.images.first : '',
        'price': (product.discountedPrice != null && product.discountedPrice! > 0)
            ? product.discountedPrice
            : product.price,
        // Longest single dwell wins — it's the push candidate ranking.
        'dwellMs': dwell.inMilliseconds > prevDwell ? dwell.inMilliseconds : prevDwell,
        'viewedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // First qualifying view opens the 24h re-engagement window; later views
      // in the same window must not push the send time back.
      final queueRef = _db.collection('view_reengagement_queue').doc(uid);
      final queue = await queueRef.get();
      if (!queue.exists) {
        await queueRef.set({
          'customerId': uid,
          'windowStart': FieldValue.serverTimestamp(),
          'notifyAt': Timestamp.fromDate(DateTime.now().add(viewLifetime)),
        });
      }

      _pruneExpired(uid);
    } catch (e) {
      debugPrint('RecentViews: record failed (non-fatal): $e');
    }
  }

  /// Purchased products never appear in Last Viewed — called right after a
  /// successful outright checkout or reservation.
  Future<void> removePurchased(List<String> productIds) async {
    final uid = _uid;
    if (uid == null || productIds.isEmpty) return;
    try {
      final batch = _db.batch();
      for (final id in productIds) {
        batch.delete(_views(uid).doc(id));
      }
      await batch.commit();
    } catch (e) {
      debugPrint('RecentViews: purchase cleanup failed (non-fatal): $e');
    }
  }

  /// Views older than 24h drop off the UI by the query filter; this deletes
  /// their docs so the collection stays tiny. Best-effort background sweep.
  Future<void> _pruneExpired(String uid) async {
    try {
      final cutoff = Timestamp.fromDate(DateTime.now().subtract(viewLifetime));
      final stale = await _views(uid).where('viewedAt', isLessThan: cutoff).get();
      if (stale.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in stale.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {
      // sweep again next view
    }
  }
}
