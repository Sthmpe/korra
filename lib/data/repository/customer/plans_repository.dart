import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 

import '../../../config/utils/korra_exception.dart';
import '../../models/customer/payment_receipt_data.dart';
import '../../models/customer/plans.dart';
import 'customer_repository.dart';

extension CustomerPlans on CustomerRepository { 
  
  // ===========================================================================
  // 1. PREVIEW (Risk Engine & Token Generation)
  // ===========================================================================
  Future<Map<String, dynamic>> fetchPlanPreview({
    required String customerUid,
    required double productPrice,
    required String productId,
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

      debugPrint("🔒 Calling plan-manager with Double Lock...");

      final response = await fx.invoke(
        'plan-manager', // The unified backend function
        headers: {
          'firebase-token': 'Bearer $idToken',  // 🔐 Lock 2: User Identity
          'x-korra-timestamp': timestamp,      // 🔐 Lock 1: Time Check
          'x-korra-signature': signature,      // 🔐 Lock 1: Signature Check
        },
        body: {
          "action": "PREVIEW",
          "customerUid": customerUid,
          "productId": productId,
        },
      );

      final data = response.data;

      if (data == null || data['status'] != 'SUCCESS') {
        throw KorraException(data?['error'] ?? 'Plan declined by risk engine.');
      }

      // Return { minDownPayment: 123.0, secureToken: "ey..." }
      return data as Map<String, dynamic>;
      
    } catch (e) {
      debugPrint("❌ Preview Error: $e");
      
      if (e is FunctionException) {
         final details = e.details;
         // Handle standard Supabase error format
         if (details is Map && details['error'] != null) {
            throw KorraException(details['error']);
         }
         if (details is String) {
            throw KorraException(details);
         }
      }
      
      if (e is KorraException) rethrow;
      throw KorraException("Could not calculate plan preview. Check connection.");
    }
  }

  // ===========================================================================
  // 2. CREATE PLAN (Atomic Transaction)
  // ===========================================================================
  Future<void> createPlanSecurely({
    required Plan plan,
    required double totalDebitAmount,
    required String secureToken // ✅ New Param
  }) async {
    try {
      final rawMap = plan.toMap();
      final safeMap = _sanitizeMap(rawMap);

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

      debugPrint("🔒 Calling plan-manager with Double Lock...");

      final response = await fx.invoke(
        'plan-manager', // The unified backend function
        headers: {
          'firebase-token': 'Bearer $idToken',  // 🔐 Lock 2: User Identity
          'x-korra-timestamp': timestamp,      // 🔐 Lock 1: Time Check
          'x-korra-signature': signature,      // 🔐 Lock 1: Signature Check
        },
        body: {
          "action": "CREATE",
          "secureToken": secureToken, // ✅ Send Token
          "customerUid": plan.customerId,
          "amount": totalDebitAmount, // (User Principal + Fee)
          "productId": plan.productId,
          "planData": safeMap, 
        },
      );

      final data = response.data;

      // Handle Soft Failures
      if (data != null && data['status'] != 'SUCCESS') {
        _handleBusinessErrors(data['error'] ?? "Unknown error occurred");
      }

      debugPrint("✅ Plan Created via Supabase. ID: ${data['planId']}");

    } catch (e) {
      debugPrint("❌ Create Error (Technical): $e");

      if (e is KorraException) rethrow;

      if (e is FunctionException) { 
       final details = e.details;
       if (details is Map && details['error'] != null) {
          throw KorraException(details['error']);
       }
    }

      throw KorraException(
        "Something went wrong while creating your plan.",
        technicalDetails: e.toString(),
      );
    }
  }

  // ===========================================================================
  // 3. PAY INSTALLMENT
  // ===========================================================================
  Future<PaymentReceiptData> payInstallment({
    required String planId,
    required String customerUid,
    required double amount,
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

      debugPrint("🔒 Calling plan-manager with Double Lock...");

      final response = await fx.invoke(
        'plan-manager', // The unified backend function
        headers: {
          'firebase-token': 'Bearer $idToken',  // 🔐 Lock 2: User Identity
          'x-korra-timestamp': timestamp,      // 🔐 Lock 1: Time Check
          'x-korra-signature': signature,      // 🔐 Lock 1: Signature Check
        },
        body: {
          "action": "PAY_INSTALLMENT",
          "planId": planId,
          "customerUid": customerUid,
          "amount": amount,
        },
      );

      final data = Map<String, dynamic>.from(response.data);

      // 1. Check Backend Logic Error
      if (data['status'] == 'ERROR') {
        throw KorraException(data['error'] ?? "Unknown payment error");
      }

      // 2. ✅ FAIL-SAFE PARSING
      // If parsing 'receiptData' fails, we catch it locally so we don't 
      // throw a "Payment Failed" error to the user when money was actually deducted.
      try {
        if (data['receiptData'] == null) throw "No receipt data returned";
        return PaymentReceiptData.fromJson(Map<String, dynamic>.from(data['receiptData']));
      } catch (parseError) {
        debugPrint("⚠️ Receipt Parsing Error: $parseError");
        debugPrint("Raw Data: $data");
        
        // 3. RETURN FALLBACK RECEIPT (Critical for Trust)
        // Money is gone, so we MUST return success.
        return PaymentReceiptData.fromPartial(
          amount: amount,
          date: DateTime.now(),
          title: "Payment Successful",
          reference: "REF-${DateTime.now().millisecondsSinceEpoch}",
          status: "SUCCESSFUL",
        );
      }
    } on FunctionException catch (e) {
      final details = e.details;
       if (details is Map && details['error'] != null) {
          throw KorraException(details['error']);
       }
       throw KorraException(
        "Payment failed. Please try again.",
        technicalDetails: e.toString(),
      );
    } catch (e) {
      throw KorraException("Payment failed. Please try again.");
    }
  }

  // ===========================================================================
  // 4. CANCEL PLAN
  // ===========================================================================
  Future<void> cancelPlan({
    required String planId,
    required String customerUid,
    required String reason,
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

      debugPrint("🔒 Calling plan-manager with Double Lock...");

      final response = await fx.invoke(
        'plan-manager', // The unified backend function
        headers: {
          'firebase-token': 'Bearer $idToken',  // 🔐 Lock 2: User Identity
          'x-korra-timestamp': timestamp,      // 🔐 Lock 1: Time Check
          'x-korra-signature': signature,      // 🔐 Lock 1: Signature Check
        },
        body: {
          "action": "CANCEL",
          "planId": planId,
          "customerUid": customerUid,
          "reason": reason,
        },
      );

      final data = response.data;

      if (data['status'] != 'SUCCESS') {
        _handleCancelErrors(data['error']);
      }

      debugPrint("✅ Plan Cancelled.");
    } catch (e) {
      debugPrint("❌ Cancel Error: $e");

      if (e is KorraException) rethrow;
      
      if (e is FunctionException) {
         final details = e.details;
         if (details is Map && details['error'] != null) {
            _handleCancelErrors(details['error'].toString());
         }
      }

      throw KorraException("Could not close plan.");
    }
  }

  // ===========================================================================
  // 5. EXTEND PLAN (New Method)
  // ===========================================================================
  Future<void> extendPlan(String planId) async {
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

      debugPrint("🔒 Calling plan-manager with Double Lock...");

      final response = await fx.invoke(
        'plan-manager', // The unified backend function
        headers: {
          'firebase-token': 'Bearer $idToken',  // 🔐 Lock 2: User Identity
          'x-korra-timestamp': timestamp,      // 🔐 Lock 1: Time Check
          'x-korra-signature': signature,      // 🔐 Lock 1: Signature Check
        },
        body: {
          "action": "EXTEND",
          "planId": planId,
          "customerUid": user.uid,
        },
      );

      final data = response.data;

      if (data['status'] != 'SUCCESS') {
        _handleBusinessErrors(data['error']);
      }

      debugPrint("✅ Plan Extended Successfully.");
    } catch (e) {
      debugPrint("❌ Extension Error: $e");
      
      if (e is KorraException) rethrow;

      if (e is FunctionException) {
         final details = e.details;
         if (details is Map && details['error'] != null) {
            _handleBusinessErrors(details['error'].toString());
         }
      }
      throw KorraException("Could not extend plan.");
    }
  }

  // ===========================================================================
  // 🔸 ERROR TRANSLATORS (UI Friendly Messages)
  // ===========================================================================
  
  void _handleBusinessErrors(String? error) {
    final err = error?.toLowerCase() ?? '';
    
    // 1. Money Issues
    if (err.contains('insufficient') || err.contains('wallet')) {
      throw KorraException("Your wallet balance is too low for this initial deposit.");
    }
    
    // 2. Inventory Issues
    if (err.contains('out of stock')) {
      throw KorraException("This item just went out of stock!");
    } 
    
    // 3. Slot / Limit Issues
    // Handles: "Slot Limit Reached"
    if (err.contains('slot limit')) {
      throw KorraException("Slot Limit Reached. Please complete or close an active plan first.");
    }
    
    // 4. Security / Validation Issues
    if (err.contains('security') || err.contains('session')) {
      throw KorraException("Session expired. Please go back and try again.");
    }
    if (err.contains('payment too low')) {
      throw KorraException("The payment amount does not meet the required deposit.");
    }
    
    // Default Fallback
    throw KorraException(error ?? "Could not create plan.");
  }

  void _handlePaymentErrors(String? error) {
    final err = error?.toLowerCase() ?? '';
    if (err.contains('insufficient')) throw KorraException("Insufficient wallet balance.");
    if (err.contains('active')) throw KorraException("This plan is not active.");
    throw KorraException(error ?? "Payment failed.");
  }

  void _handleCancelErrors(String? error) {
    final err = error?.toLowerCase() ?? '';
    if (err.contains('inactive')) throw KorraException("Cannot close an inactive plan.");
    throw KorraException(error ?? "Closing failed.");
  }

  // ===========================================================================
  // 🔸 HELPERS & READS
  // ===========================================================================

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> map) {
    final newMap = <String, dynamic>{};
    map.forEach((key, value) {
      if (value is DateTime) {
        newMap[key] = value.toIso8601String();
      } else if (value is Timestamp) {
        newMap[key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        newMap[key] = _sanitizeMap(value);
      } else if (value is List) {
        newMap[key] = value.map((item) {
          if (item is DateTime) return item.toIso8601String();
          if (item is Timestamp) return item.toDate().toIso8601String();
          return item;
        }).toList();
      } else {
        newMap[key] = value;
      }
    });
    return newMap;
  }

  Future<ProductFetchResult?> getProduct(String productCode) async {
    final snap = await firestore
        .collection("products")
        .where("code", isEqualTo: productCode)
        .limit(1)
        .get();

    debugPrint("🔍 Product Fetch Snap: ${snap.docs.length} found for code $productCode");

    if (snap.docs.isEmpty) {
      return null;
    }

    final doc = snap.docs.first;
    return ProductFetchResult(data: doc.data(), id: doc.id);
  }

 Stream<List<Plan>> streamCustomerPlans(String customerId, {int limit = 15}) {
    return firestore
        .collection("plans")
        .where("customerId", isEqualTo: customerId)
        .orderBy("updatedAt", descending: true)
        .limit(limit) // 👈 Use the dynamic limit here
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => Plan.fromMap(doc.data(), doc.id)).toList(),
        );
  }

  Future<Plan?> getPlanById(String planId) async {
    try {
      final doc = await firestore.collection('plans').doc(planId).get();
      if (doc.exists && doc.data() != null) {
        return Plan.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw KorraException("Failed to fetch plan: $e");
    }
  }

  Stream<Plan> streamSinglePlan(String planId) {
    return firestore.collection('plans').doc(planId).snapshots().map((doc) {
      if (!doc.exists) throw Exception("Plan not found");
      return Plan.fromMap(doc.data()!, doc.id);
    });
  }

  Future<Map<String, dynamic>> getComplianceStatus(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('vendor_compliance').doc(uid).get();
      
      // Default to 'verification_pending' if doc doesn't exist 
      // (We set blockPayments to false here so new merchants can still accept initial digital reservations)
      if (!doc.exists) {
        return {
          'status': 'verification_pending', 
          'blockPayments': false,
          'message': 'Account verification required.'
        };
      }
      
      final data = doc.data()!;
      return {
        'status': data['status']?.toString() ?? 'verification_pending',
        'blockPayments': data['blockPayments'] ?? false, // Pull the new field, default to false if missing
        'message': data['publicMessage']?.toString() ?? 'Account verification required.'
      };
    } catch (e) {
      // 🛑 If error, completely fail safe and lock the transaction
      debugPrint("Error fetching compliance: $e");
      return {
        'status': 'error', 
        'blockPayments': true, // Force block on backend failure
        'message': 'Could not verify merchant account status.'
      };
    }
  }
}