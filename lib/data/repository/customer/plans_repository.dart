import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 

import '../../../config/utils/korra_exception.dart';
import '../../models/customer/plans.dart';
import 'customer_repository.dart';

extension CustomerPlans on CustomerRepository { 
  
  // ===========================================================================
  // 1. PREVIEW (Risk Engine & Token Generation)
  // ===========================================================================
  Future<Map<String, dynamic>> fetchPlanPreview({
    required String customerUid,
    required double productPrice,
  }) async {
    try {
      final response = await fx.invoke(
        'plan-manager',
        body: {
          "action": "PREVIEW",
          "customerUid": customerUid,
          "productPrice": productPrice,
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

      final response = await fx.invoke(
        'plan-manager', 
        body: {
          "action": "CREATE",
          "secureToken": secureToken, // ✅ Send Token
          "customerUid": plan.customerId,
          "downPaymentAmount": totalDebitAmount, // (User Principal + Fee)
          "productId": plan.productId,
          "productPrice": plan.totalAmount,
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
  Future<void> payInstallment({
    required String planId,
    required String customerUid,
    required double amount,
  }) async {
    try {
      final response = await fx.invoke(
        'plan-manager',
        body: {
          "action": "PAY_INSTALLMENT",
          "planId": planId,
          "customerUid": customerUid,
          "amount": amount,
        },
      );

      final data = response.data;

      if (data['status'] != 'SUCCESS') {
         _handlePaymentErrors(data['error']);
      }

      debugPrint("✅ Installment Paid: $amount");
    } catch (e) {
      debugPrint("❌ Payment Error: $e");

      if (e is KorraException) rethrow;

      if (e is FunctionException) {
         final details = e.details;
         if (details is Map && details['error'] != null) {
            _handlePaymentErrors(details['error'].toString());
         }
      }

      throw KorraException("Payment could not be processed.");
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
      final response = await fx.invoke(
        'plan-manager',
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

      throw KorraException("Could not cancel plan.");
    }
  }

  // ===========================================================================
  // 🔸 ERROR TRANSLATORS (UI Friendly Messages)
  // ===========================================================================
  
  void _handleBusinessErrors(String? error) {
    final err = error?.toLowerCase() ?? '';
    
    // 1. Money Issues
    if (err.contains('insufficient') || err.contains('wallet')) {
      throw KorraException("Your wallet balance is too low for this down payment.");
    }
    
    // 2. Inventory Issues
    if (err.contains('out of stock')) {
      throw KorraException("This item just went out of stock!");
    } 
    
    // 3. Slot / Limit Issues
    // Handles: "Slot Limit Reached"
    if (err.contains('slot limit')) {
      throw KorraException("Slot Limit Reached. Please complete or cancel an active plan first.");
    }
    
    // 4. Security / Validation Issues
    if (err.contains('security') || err.contains('session')) {
      throw KorraException("Session expired. Please go back and try again.");
    }
    if (err.contains('payment too low')) {
      throw KorraException("The payment amount does not meet the required down payment.");
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
    if (err.contains('inactive')) throw KorraException("Cannot cancel an inactive plan.");
    throw KorraException(error ?? "Cancellation failed.");
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

  Stream<List<Plan>> streamCustomerPlans(String customerId) {
    return firestore
        .collection("plans")
        .where("customerId", isEqualTo: customerId)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => Plan.fromMap(doc.data(), doc.id)).toList(),
        );
  }

  Stream<Plan> streamSinglePlan(String planId) {
    return firestore.collection('plans').doc(planId).snapshots().map((doc) {
      if (!doc.exists) throw Exception("Plan not found");
      return Plan.fromMap(doc.data()!, doc.id);
    });
  }
}