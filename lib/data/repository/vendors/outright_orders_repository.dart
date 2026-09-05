// lib/data/repository/vendors/outright_orders_repository.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../../models/vendor/outright_order.dart';
import 'vendor_repository.dart';

extension OutrightOrdersRepository on VendorRepository {
  
  // 1. TAB COUNTS — computed with server-side .count() aggregates instead of
  // streaming the whole orders collection (which grew unbounded per vendor).
  // Kept as a Stream (emits once) so the merchant home StreamBuilder is
  // unchanged; it refreshes whenever that widget rebuilds.
  Stream<Map<OutrightOrderStatus, int>> streamOutrightCounts(String vendorId) {
    return Stream.fromFuture(_outrightCounts(vendorId));
  }

  Future<Map<OutrightOrderStatus, int>> _outrightCounts(String vendorId) async {
    try {
      final base =
          firestore.collection('orders').where('vendorId', isEqualTo: vendorId);
      final res = await Future.wait([
        base.where('status', isEqualTo: 'pending').count().get(),
        // Unconfirmed web payments are their own tab, never counted as "New".
        base
            .where('webPurchase', isEqualTo: true)
            .where('paymentStatus', isEqualTo: 'awaiting')
            .where('status', isEqualTo: 'pending')
            .count()
            .get(),
        base.where('status', isEqualTo: 'readyToDeliver').count().get(),
        base.where('status', isEqualTo: 'delivered').count().get(),
        base.where('status', isEqualTo: 'cancelled').count().get(),
      ]);
      final pendingRaw = res[0].count ?? 0;
      final awaiting = res[1].count ?? 0;
      return {
        OutrightOrderStatus.awaitingPayment: awaiting,
        OutrightOrderStatus.pending: (pendingRaw - awaiting).clamp(0, pendingRaw),
        OutrightOrderStatus.readyToDeliver: res[2].count ?? 0,
        OutrightOrderStatus.delivered: res[3].count ?? 0,
        OutrightOrderStatus.cancelled: res[4].count ?? 0,
      };
    } catch (e) {
      debugPrint("Outright count aggregate failed: $e");
      return const {};
    }
  }

  // 2. FETCH COUNTS (Initial load counts)
  Future<Map<OutrightOrderStatus, int>> getOutrightCounts(String vendorId) async {
    try {
      final snapshot = await firestore
          .collection('orders')
          .where('vendorId', isEqualTo: vendorId)
          .get();

      return _countByStatus(snapshot.docs);
    } catch (e) {
      debugPrint("Error fetching outright counts: $e");
      return {
        OutrightOrderStatus.awaitingPayment: 0,
        OutrightOrderStatus.pending: 0,
        OutrightOrderStatus.readyToDeliver: 0,
        OutrightOrderStatus.delivered: 0,
        OutrightOrderStatus.cancelled: 0,
      };
    }
  }

  // Shared tally: unconfirmed web payments count as their own tab, never New.
  Map<OutrightOrderStatus, int> _countByStatus(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    int awaitingPayment = 0;
    int pending = 0;
    int readyToDeliver = 0;
    int delivered = 0;
    int cancelled = 0;

    for (var doc in docs) {
      final data = doc.data();
      final status = data['status'] ?? 'pending';
      final isAwaiting = data['webPurchase'] == true &&
          data['paymentStatus'] == 'awaiting' &&
          status == 'pending';

      if (isAwaiting) {
        awaitingPayment++;
        continue;
      }
      switch (status) {
        case 'pending':
          pending++;
          break;
        case 'readyToDeliver':
          readyToDeliver++;
          break;
        case 'delivered':
          delivered++;
          break;
        case 'cancelled':
          cancelled++;
          break;
      }
    }

    return {
      OutrightOrderStatus.awaitingPayment: awaitingPayment,
      OutrightOrderStatus.pending: pending,
      OutrightOrderStatus.readyToDeliver: readyToDeliver,
      OutrightOrderStatus.delivered: delivered,
      OutrightOrderStatus.cancelled: cancelled,
    };
  }

  // 3. GET OUTRIGHT ORDERS (Paginated list)
  Future<Map<String, dynamic>> getOutrightOrders({
    required OutrightOrderStatus status,
    required String vendorId,
    DocumentSnapshot? lastDoc,
    int limit = 20,
  }) async {
    try {
      Query query = firestore
          .collection('orders')
          .where('vendorId', isEqualTo: vendorId);

      // Both the New tab and the Awaiting Payment tab live on the same
      // Firestore status ('pending'); paymentStatus splits them client-side.
      String statusStr = 'pending';
      switch (status) {
        case OutrightOrderStatus.awaitingPayment:
        case OutrightOrderStatus.pending:
          statusStr = 'pending';
          break;
        case OutrightOrderStatus.readyToDeliver:
          statusStr = 'readyToDeliver';
          break;
        case OutrightOrderStatus.delivered:
          statusStr = 'delivered';
          break;
        case OutrightOrderStatus.cancelled:
          statusStr = 'cancelled';
          break;
      }

      final bool splitTab = status == OutrightOrderStatus.pending ||
          status == OutrightOrderStatus.awaitingPayment;

      query = query.where('status', isEqualTo: statusStr)
                   .orderBy('createdAt', descending: true);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      // Over-fetch when we filter client-side so a page isn't mostly eaten
      // by the other half of the split.
      final int rawLimit = splitTab ? limit * 2 : limit;
      query = query.limit(rawLimit);

      final snapshot = await query.get();
      var results =
          snapshot.docs.map((doc) => OutrightOrder.fromFirestore(doc)).toList();

      if (status == OutrightOrderStatus.awaitingPayment) {
        results = results.where((o) => o.isAwaitingPayment).toList();
      } else if (status == OutrightOrderStatus.pending) {
        results = results.where((o) => !o.isAwaitingPayment).toList();
      }

      // Cursor rule (same fix as reservations): continue where the SCAN
      // stopped, not at the last kept item — unless we truncated, in which
      // case the dropped overflow must be served on the next page.
      final bool truncated = results.length > limit;
      if (truncated) {
        results = results.sublist(0, limit);
      }
      DocumentSnapshot? newLastDoc;
      if (truncated) {
        newLastDoc = snapshot.docs.firstWhere((d) => d.id == results.last.id);
      } else if (snapshot.docs.isNotEmpty) {
        newLastDoc = snapshot.docs.last;
      }

      return {
        'items': results,
        'lastDoc': newLastDoc,
        'hasReachedMax': !truncated && snapshot.docs.length < rawLimit,
      };
    } catch (e) {
      debugPrint("Error fetching outright orders: $e");
      return {
        'items': <OutrightOrder>[],
        'lastDoc': null,
        'hasReachedMax': true,
      };
    }
  }

  // 4. MARK ORDER DELIVERED (Update status in Firestore)
  Future<void> markOutrightOrderDelivered(String orderId) async {
    try {
      final orderRef = firestore.collection('orders').doc(orderId);
      final orderDoc = await orderRef.get();

      await orderRef.update({
        'status': 'delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
      });

      // Guest web purchases have no app to notify: email is their only
      // channel, so tell web-checkout to send the delivered email. Fire and
      // forget; the delivery itself must never fail on an email hiccup.
      final data = orderDoc.data();
      if (data != null &&
          data['webPurchase'] == true &&
          (data['customerEmail'] ?? '').toString().isNotEmpty) {
        _notifyWebOrderDelivered(orderId);
      }
    } catch (e) {
      throw Exception("Failed to mark order as delivered: $e");
    }
  }

  Future<void> _notifyWebOrderDelivered(String orderId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final hmacSha256 = Hmac(sha256, utf8.encode(korraSecret));
      final signature = hmacSha256.convert(utf8.encode(timestamp)).toString();

      await fx.invoke(
        'web-checkout',
        headers: {
          'x-korra-timestamp': timestamp,
          'x-korra-signature': signature,
        },
        body: {
          'action': 'notify-delivered',
          'orderId': orderId,
        },
      );
    } catch (e) {
      debugPrint("Web order delivered email failed (non-fatal): $e");
    }
  }
}
