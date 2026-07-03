// lib/data/repository/vendors/outright_orders_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/vendor/outright_order.dart';
import 'vendor_repository.dart';

extension OutrightOrdersRepository on VendorRepository {
  
  // 1. STREAM COUNTS (Realtime counts for Outright Orders tabs)
  Stream<Map<OutrightOrderStatus, int>> streamOutrightCounts(String vendorId) {
    return firestore
        .collection('orders')
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) {
          final allDocs = snapshot.docs;

          int pending = 0;
          int readyToDeliver = 0;
          int delivered = 0;
          int cancelled = 0;

          for (var doc in allDocs) {
            final data = doc.data();
            final status = data['status'] ?? 'pending';

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
            OutrightOrderStatus.pending: pending,
            OutrightOrderStatus.readyToDeliver: readyToDeliver,
            OutrightOrderStatus.delivered: delivered,
            OutrightOrderStatus.cancelled: cancelled,
          };
        });
  }

  // 2. FETCH COUNTS (Initial load counts)
  Future<Map<OutrightOrderStatus, int>> getOutrightCounts(String vendorId) async {
    try {
      final snapshot = await firestore
          .collection('orders')
          .where('vendorId', isEqualTo: vendorId)
          .get();

      final allDocs = snapshot.docs;

      int pending = 0;
      int readyToDeliver = 0;
      int delivered = 0;
      int cancelled = 0;

      for (var doc in allDocs) {
        final data = doc.data();
        final status = data['status'] ?? 'pending';

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
        OutrightOrderStatus.pending: pending,
        OutrightOrderStatus.readyToDeliver: readyToDeliver,
        OutrightOrderStatus.delivered: delivered,
        OutrightOrderStatus.cancelled: cancelled,
      };
    } catch (e) {
      debugPrint("Error fetching outright counts: $e");
      return {
        OutrightOrderStatus.pending: 0,
        OutrightOrderStatus.readyToDeliver: 0,
        OutrightOrderStatus.delivered: 0,
        OutrightOrderStatus.cancelled: 0,
      };
    }
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

      String statusStr = 'pending';
      switch (status) {
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

      query = query.where('status', isEqualTo: statusStr)
                   .orderBy('createdAt', descending: true);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      final results = snapshot.docs.map((doc) => OutrightOrder.fromFirestore(doc)).toList();

      return {
        'items': results,
        'lastDoc': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        'hasReachedMax': snapshot.docs.length < limit,
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
      await firestore.collection('orders').doc(orderId).update({
        'status': 'delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Failed to mark order as delivered: $e");
    }
  }
}
