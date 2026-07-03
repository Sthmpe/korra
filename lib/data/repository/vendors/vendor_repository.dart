import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, FunctionsClient;

import '../../../config/utils/korra_exception.dart';
import '../../../logic/bloc/vendor/product/vendor_products_state.dart';
import '../../../logic/services/notification_service.dart';
import '../../models/vendor/vendor_setting.dart';
import '../../../logic/bloc/vendor/payout/bank.dart';
import '../remote/monnify_functions.dart';

// --- EXTENSIONS ---
export 'vendor_auth_repository.dart';
export 'vendor_stats_repository.dart';
export 'vendor_settings_repository.dart';
export 'bank_repository.dart';
export 'pin_repository.dart';
export 'product_repository.dart';
export 'reservations_repository.dart';
export 'transfer_repository.dart';
export 'verification_repository.dart';
export 'vendor_reviews_repository.dart';
export 'vendor_campaigns_repository.dart';

class VendorRepository implements INotificationRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FunctionsClient fx;
  final MonnifyFunctions monnify;

  VendorRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FunctionsClient? functions,
    MonnifyFunctions? monnify,
  }) : auth = auth ?? FirebaseAuth.instance,
       firestore = firestore ?? FirebaseFirestore.instance,
       fx = functions ?? Supabase.instance.client.functions,
       monnify = monnify ?? MonnifyFunctions();

  // 🔹 Local in-memory cache (lives with the repository instance)
  final List<ProductItem> productItemCache = [];
  List<Bank>? cachedBankList;
  VendorSettings? cachedSettings;

  final supabase = Supabase.instance.client;
  final korraSecret = dotenv.env['KORRA_SECRET_CODE'] ?? '';

  /// Optional helpers
  void clearProductCache() => productItemCache.clear();

  @override
  Future<void> updateFcmToken(String uid, String token) async {
    try {
      // We merge it so we don't overwrite other data
      await firestore.collection('vendors').doc(uid).set({
        'fcmToken': token,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Failed to update FCM Token: $e");
    }
  }

  void updateProductCache(List<ProductItem> products) {
    productItemCache
      ..clear()
      ..addAll(products);
  }

  KorraException handleError(Object error, {String context = "operation"}) {
    debugPrint("❌ BankRepository Error ($context): $error");

    final String msg = error.toString().toLowerCase();

    // 1. User Mistakes (Logic Errors)
    if (msg.contains('account not found') || msg.contains('invalid account')) {
      return KorraException(
        "Account not found. Please check the number and try again.",
        technicalDetails: "404/Invalid Account",
      );
    }

    // 2. Network Issues
    if (error is SocketException ||
        msg.contains('socketexception') ||
        msg.contains('connection refused')) {
      return KorraException(
        "No internet connection. Please check your network.",
        technicalDetails: "SocketException",
      );
    }
    if (error is TimeoutException || msg.contains('timeout')) {
      return KorraException(
        "The bank network is taking too long to respond. Please try again.",
        technicalDetails: "TimeoutException",
      );
    }

    // 3. Server Issues
    if (msg.contains('500') || msg.contains('internal server error')) {
      return KorraException(
        "Our banking partner is having a moment. Please try again shortly.",
        technicalDetails: "500 Server Error",
      );
    }

    if (msg.contains('503') || msg.contains('service unavailable')) {
      return KorraException(
        "Bank verification is currently down for maintenance.",
        technicalDetails: "503 Service Unavailable",
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

  Future<String> getStoreName(String vendorUid) async {
    return await firestore
        .collection("vendors")
        .doc(vendorUid)
        .get()
        .then(
          (snap) =>
              snap.data()?["store"]["storeName"] ??
              "Korra_Vendor-${vendorUid.substring(0, 5)}",
        );
  }
}
