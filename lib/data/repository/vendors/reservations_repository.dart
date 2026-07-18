// lib/data/repository/vendors/reservations_repository.dart

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/utils/korra_exception.dart';
import '../../models/vendor/reservation.dart';
import 'vendor_repository.dart';

extension ReservationsRepository on VendorRepository {
  
  // ✅ 1. TAB COUNTS — server-side .count() aggregates instead of streaming the
  // whole plans collection (which grew unbounded per vendor). Kept as a Stream
  // (emits once) so the merchant home StreamBuilder is unchanged.
  //
  // Buckets mirror the old client categorization exactly:
  //  - newRes  = active created today
  //  - ongoing = active created before today   (= allActive - newRes)
  //  - ready   = completed but NOT yet fulfilled (finalFulfilledAt missing)
  //  - completed = completed AND fulfilled (finalFulfilledAt present)
  //  - cancelled = cancelled | defaulted
  // The ready/completed split uses orderBy('finalFulfilledAt'), which counts
  // ONLY docs where the field exists (= fulfilled); ready is the remainder.
  Stream<Map<ReservationStatus, int>> streamCounts(String vendorId) {
    return Stream.fromFuture(_reservationCounts(vendorId));
  }

  Future<Map<ReservationStatus, int>> _reservationCounts(String vendorId) async {
    try {
      final base =
          firestore.collection('plans').where('vendorId', isEqualTo: vendorId);
      final now = DateTime.now();
      final todayStart = Timestamp.fromDate(DateTime(now.year, now.month, now.day));

      final res = await Future.wait([
        base
            .where('status', isEqualTo: 'active')
            .where('createdAt', isGreaterThanOrEqualTo: todayStart)
            .count()
            .get(), // newRes
        base.where('status', isEqualTo: 'active').count().get(), // all active
        base.where('status', isEqualTo: 'completed').count().get(), // all completed
        base
            .where('status', isEqualTo: 'completed')
            .orderBy('finalFulfilledAt')
            .count()
            .get(), // fulfilled only (field present)
        base
            .where('status', whereIn: ['cancelled', 'defaulted'])
            .count()
            .get(), // cancelled
      ]);

      final newRes = res[0].count ?? 0;
      final activeAll = res[1].count ?? 0;
      final completedAll = res[2].count ?? 0;
      final fulfilled = res[3].count ?? 0;

      return {
        ReservationStatus.newRes: newRes,
        ReservationStatus.ongoing: (activeAll - newRes).clamp(0, activeAll),
        ReservationStatus.readyForPickup:
            (completedAll - fulfilled).clamp(0, completedAll),
        ReservationStatus.completed: fulfilled,
        ReservationStatus.cancelled: res[4].count ?? 0,
      };
    } catch (e) {
      debugPrint("Reservation count aggregate failed: $e");
      return const {};
    }
  }

 Future<Map<String, dynamic>> getReservations({
    required ReservationStatus status,
    required String vendorId,
    DocumentSnapshot? lastDoc,
    int limit = 20,
  }) async {
    Query query = firestore
        .collection('plans')
        .where('vendorId', isEqualTo: vendorId);

    // 1. QUERY BUILDER (Server Side)
    switch (status) {
      case ReservationStatus.newRes:
      case ReservationStatus.ongoing:
        // Fetch all active, we will sort/filter later if needed
        query = query.where('status', isEqualTo: 'active')
                     .orderBy('createdAt', descending: true); 
        break;
        
      case ReservationStatus.readyForPickup:
      case ReservationStatus.completed:
        // ✅ FETCH ALL COMPLETED (Both Ready & History)
        // We cannot rely on .where('fulfilledAt', isNull: true) because the field might be missing.
        query = query.where('status', isEqualTo: 'completed')
                     .orderBy('updatedAt', descending: true);  
        break;
        
      case ReservationStatus.cancelled:
        query = query.where('status', whereIn: ['cancelled', 'defaulted'])
                     .orderBy('updatedAt', descending: true); 
        break;
    }

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    // Note: We might fetch slightly more than 'limit' to handle client-side filtering
    // but for now, keep it simple.
    query = query.limit(limit * 4); 

    final snapshot = await query.get();
    
    // 2. CONVERT
    var results = snapshot.docs.map((doc) => Reservation.fromFirestore(doc)).toList();

    // 3. FILTERING (Client Side - The Fix)
    if (status == ReservationStatus.readyForPickup) {
      // ✅ Show only if finalFulfilledAt is missing (null)
      results = results.where((r) => r.finalFulfilledAt == null).toList();
    } 
    else if (status == ReservationStatus.completed) {
      // ✅ Show only if finalFulfilledAt EXISTS (History)
      results = results.where((r) => r.finalFulfilledAt != null).toList();
    }
    else if (status == ReservationStatus.newRes) {
       final now = DateTime.now();
       final todayStart = DateTime(now.year, now.month, now.day);
       results = results.where((r) => r.createdAt.isAfter(todayStart)).toList();
    } 
    else if (status == ReservationStatus.ongoing) {
       final now = DateTime.now();
       final todayStart = DateTime(now.year, now.month, now.day);
       results = results.where((r) => r.createdAt.isBefore(todayStart)).toList();
    }

    // Apply strict limit after filtering
    final bool truncated = results.length > limit;
    if (truncated) {
      results = results.sublist(0, limit);
    }

    // Cursor rule: the next page must start where THIS SCAN stopped, not at
    // the last filtered item. Anchoring to the last kept item re-scans raw
    // docs the filter already saw and re-appends the same "ready" items on
    // every load-more (the Ready-tab duplication bug). Only when we truncated
    // do we anchor to the last kept item, so the dropped overflow is served
    // on the next page instead of skipped.
    DocumentSnapshot? newLastDoc;
    if (truncated) {
      newLastDoc = snapshot.docs.firstWhere((doc) => doc.id == results.last.id);
    } else if (snapshot.docs.isNotEmpty) {
      newLastDoc = snapshot.docs.last;
    }

    // 🚀 Return the Map so the BLoC can paginate!
    return {
      'items': results,
      'lastDoc': newLastDoc,
      // Truncated pages always have leftovers to serve; otherwise a short
      // raw snapshot means the collection scan is finished.
      'hasReachedMax': !truncated && snapshot.docs.length < (limit * 4),
    };
  }

  // ✅ 3. FETCH COUNTS (Initial Load)
  Future<Map<ReservationStatus, int>> getCounts(String vendorId) async {
    try {
      final snapshot = await firestore
          .collection('plans')
          .where('vendorId', isEqualTo: vendorId)
          .get();

      final allDocs = snapshot.docs;

      int newRes = 0;
      int ongoing = 0;
      int ready = 0;
      int completed = 0;
      int cancelled = 0;

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      for (var doc in allDocs) {
        final data = doc.data();
        final status = data['status'] ?? 'active';
        final fulfilledAt = data['finalFulfilledAt'];
        final createdAtRaw = data['createdAt'];

        DateTime createdDate;
        if (createdAtRaw is Timestamp) {
          createdDate = createdAtRaw.toDate();
        } else {
          createdDate = DateTime.now();
        }

        if (status == 'cancelled' || status == 'defaulted') {
          cancelled++;
        } else if (status == 'completed') {
          // ✅ Split Logic
          if (fulfilledAt != null) {
            completed++;
          } else {
            ready++;
          }
        } else if (status == 'active') {
          if (createdDate.isAfter(todayStart) || createdDate.isAtSameMomentAs(todayStart)) {
            newRes++;
          } else {
            ongoing++;
          }
        }
      }

      return {
        ReservationStatus.newRes: newRes,
        ReservationStatus.ongoing: ongoing,
        ReservationStatus.readyForPickup: ready,
        ReservationStatus.completed: completed,
        ReservationStatus.cancelled: cancelled,
      };
    } catch (e) {
      debugPrint("Error fetching counts: $e");
      return {
        ReservationStatus.newRes: 0,
        ReservationStatus.ongoing: 0,
        ReservationStatus.readyForPickup: 0,
        ReservationStatus.completed: 0,
        ReservationStatus.cancelled: 0,
      };
    }
  }

  // =========================================================
  // ✅ BULK FULFILLMENT (Secure Edge Function Call)
  // =========================================================
  Future<void> markReservationsFulfilled(String vendorUid, List<String> planIds) async {
    try {
      final user = auth.currentUser;
      if (user == null) throw "You must be logged in.";

      // 1. VIP Passes
      final idToken = await user.getIdToken(true);
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // 2. Cryptographic Signature
      final hmacSha256 = Hmac(sha256, utf8.encode(korraSecret));
      final digest = hmacSha256.convert(utf8.encode(timestamp));
      final signature = digest.toString();

      debugPrint("🔒 Calling plan-manager for BULK FULFILL...");

      // 3. Invoke Backend
      final result = await fx.invoke(
        'plan-manager', 
        headers: {
          'firebase-token': 'Bearer $idToken',  
          'x-korra-timestamp': timestamp,  
          'x-korra-signature': signature,  
        },
        body: {
          "action": "BULK_FULFILL", 
          "vendorUid": vendorUid,
          "planIds": planIds, // Sending the array to the backend
        },
      );

      final data = result.data;
      if (data['success'] != true) {
        throw KorraException(
          data['error'] ?? "Bulk fulfillment failed.",
          technicalDetails: "Server returned false success status.",
        );
      }
    } catch (e) {
      throw handleError(e, context: "Bulk Fulfill");
    }
  }


  // =========================================================
  // ✅ 1. VERIFY PICKUP (The New Function)
  // =========================================================
  Future<void> verifyPickup({
    required String planId,
    required String pin,
    required String vendorUid,
    required String customerUid,
  }) async {
    try {
      final user = auth.currentUser;

      if (user == null) throw "You must be logged in.";

      // 1. Get the User VIP Pass (Who they are)
      final idToken = await user.getIdToken(true);

      // 2. Get the Device VIP Pass (Proves it is the real Korra app, not a bot)
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Do the Math: Hash the timestamp using the secret key
      final hmacSha256 = Hmac(sha256, utf8.encode(korraSecret));
      final digest = hmacSha256.convert(utf8.encode(timestamp));
      final signature = digest.toString();

      debugPrint("User ID: ${user.uid}");
      debugPrint("🔒 Calling plan-manager with Double Lock...");

      final result = await fx.invoke(
        'plan-manager', // The unified backend function
        headers: {
          'firebase-token': 'Bearer $idToken',  // 🔐 Lock 2: User Identity
          'x-korra-timestamp': timestamp,  // 🔐 Lock 1: Time-based Anti-Replay
          'x-korra-signature': signature,  // 🔐 Lock 1: Cryptographic Anti-Forgery
        },
        body: {
          "action": "VERIFY_PICKUP",
          "planId": planId,
          "pin": pin,
          "vendorUid": vendorUid,
          "customerUid": customerUid,
        },
      );

      final data = result.data;
      if (data['success'] != true) {
        throw KorraException(
          data['error'] ?? "Verification failed.",
          technicalDetails: "Server returned false success status.",
        );
      }
    } catch (e) {
      throw handleError(e, context: "Verify Pickup");
    }
  }

  // =========================================================
  // ✅ 2. HUMAN-READABLE ERROR HANDLER (FIXED)
  // =========================================================
  KorraException handleError(Object error, {String context = "operation"}) {
    debugPrint("❌ VendorRepository Error ($context): $error");

    final String msg = error.toString().toLowerCase();

    // 1. PIN / Verification Specifics
    if (msg.contains('incorrect pin')) {
      return KorraException(
        "Incorrect PIN. Please ask the customer to check their screen again.",
        technicalDetails: "Invalid Credential",
      );
    }
    if (msg.contains('not authorized')) {
      return KorraException(
        "You are not authorized to fulfill this order.",
        technicalDetails: "Auth Mismatch",
      );
    }
    if (msg.contains('already collected')) {
      return KorraException(
        "This item has already been marked as collected.",
        technicalDetails: "Double Spend Prevention",
      );
    }

    // 2. Network Issues
    if (error is SocketException ||
        msg.contains('socketexception') ||
        msg.contains('connection refused') ||
        msg.contains('network request failed')) {
      return KorraException(
        "No internet connection. Please check your network.",
        technicalDetails: "SocketException",
      );
    }
    
    // 3. Supabase/Cloud Function Errors (FIXED HERE)
    if (error is FunctionException) {
        final details = error.details;
        String serverMsg = "Server Error";
        
        // Extract message from details map if possible
        if (details is Map) {
           if (details['error'] != null) {
             serverMsg = details['error'].toString();
           } else if (details['message'] != null) {
             serverMsg = details['message'].toString();
           }
        } 
        // Fallback to reasonPhrase if details didn't help
        else if (error.reasonPhrase != null) {
            serverMsg = error.reasonPhrase!;
        }
        
        return KorraException(
            "Server Error: $serverMsg",
            technicalDetails: "Cloud Function ${error.status}",
        );
    }

    // 4. Pass-through (If it's already a clean KorraException)
    if (error is KorraException) return error;

    // 5. Catch-All
    return KorraException(
      "Something went wrong. Please try again.",
      technicalDetails: error.toString(),
    );
  }
  
  String get currentVendorUid => auth.currentUser?.uid ?? '';
}