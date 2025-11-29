import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Required for FunctionException

import '../../../config/utils/korra_exception.dart';
import '../../models/customer/plans.dart';
import 'customer_repository.dart';

extension CustomerPlans on CustomerRepository { 
  // ===========================================================================
  // 1. PREVIEW (Risk Engine)
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

      if (data['status'] == 'DECLINED') {
        throw KorraException(data['reason'] ?? 'Plan declined by risk engine.');
      }

      return data['result'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint("❌ Preview Error: $e");
      
      if (e is FunctionException) {
         final details = e.details;
         if (details is Map && details['error'] != null) {
            throw KorraException(details['error']);
         }
      }
      
      if (e is KorraException) rethrow;
      throw KorraException("Could not calculate plan preview.", technicalDetails: e.toString());
    }
  }

  // ===========================================================================
  // 2. CREATE PLAN (Atomic Transaction)
  // ===========================================================================
  Future<void> createPlanSecurely({required Plan plan}) async {
    try {
      final rawMap = plan.toMap();
      final safeMap = _sanitizeMap(rawMap);

      final response = await fx.invoke(
        'plan-manager',
        body: {
          "action": "CREATE",
          "customerUid": plan.customerId,
          "productPrice": plan.totalAmount,
          "planData": safeMap,
        },
      );

      final data = response.data;

      // Handle Soft Failures (200 OK but logic error)
      if (data['status'] != 'SUCCESS') {
        _handleBusinessErrors(data['error']);
      }

      debugPrint("✅ Plan Created via Supabase. ID: ${data['planId']}");
    } catch (e) {
      debugPrint("❌ Create Error (Technical): $e");

      // 1. Pass through existing KorraExceptions
      if (e is KorraException) rethrow;

      // 2. Handle Supabase 500 Errors (FunctionException)
      if (e is FunctionException) {
        // The log says: details: {error: Out of Stock.}
        final details = e.details; 
        
        if (details is Map && details['error'] != null) {
           // We found the error message inside the exception!
           // Pass it to our helper to translate it into user-friendly text
           _handleBusinessErrors(details['error'].toString());
        }
      }

      // 3. Fallback for Crashes / Network Issues
      throw KorraException(
        "Something went wrong while creating your plan. Please check your connection.",
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

      throw KorraException(
        "Payment could not be processed.",
        technicalDetails: e.toString(),
      );
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

      throw KorraException(
        "Could not cancel plan.",
        technicalDetails: e.toString(),
      );
    }
  }

  // ===========================================================================
  // 🔸 ERROR TRANSLATORS (Keeps code clean)
  // ===========================================================================
  
  void _handleBusinessErrors(String? error) {
    final err = error?.toLowerCase() ?? '';
    
    if (err.contains('insufficient') || err.contains('wallet')) {
      throw KorraException("Your wallet balance is too low for this down payment.");
    }
    if (err.contains('out of stock')) {
      throw KorraException("This item just went out of stock!");
    } if (err.contains('gap') && err.contains('high')) {
      throw KorraException("You have low reservation limit complete outstanding plans");
    }
    
    // Default
    throw KorraException("Could not create plan.", technicalDetails: error);
  }

  void _handlePaymentErrors(String? error) {
    final err = error?.toLowerCase() ?? '';
    
    if (err.contains('insufficient')) {
       throw KorraException("Insufficient wallet balance for this payment.");
    }
    if (err.contains('active')) {
       throw KorraException("This plan is already completed or cancelled.");
    }
    throw KorraException(error ?? "Payment failed.");
  }

  void _handleCancelErrors(String? error) {
    final err = error?.toLowerCase() ?? '';

    if (err.contains('expired')) {
       throw KorraException("The cancellation window has closed.");
    }
    if (err.contains('refund') && err.contains('negative')) {
       throw KorraException("Cannot cancel: Breakage fee exceeds paid amount.");
    }
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

    if (snap.docs.isEmpty) {
      throw Exception('Product not found for code: $productCode');
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