import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/utils/korra_exception.dart';
import 'customer_repository.dart';

extension VerificationRepository on CustomerRepository {
  // ===========================================================================
  // 1. CHECK IDENTITY UNIQUENESS (Server-side Fraud Check)
  // ===========================================================================
  /// Checks if NIN or BVN exists securely on the server (linked to another account).
  Future<bool> checkIdentityExists({String? nin, String? bvn}) async {
    try {
      if (nin != null) {
        final res = await fx.invoke('check_uniqueness', body: {
          'type': 'nin',
          'value': nin,
          'collection': 'customers',
        });
        if (res.data['exists'] == true) return true;
      }

      if (bvn != null) {
        final res = await fx.invoke('check_uniqueness', body: {
          'type': 'bvn',
          'value': bvn,
          'collection': 'customers',
        });
        if (res.data['exists'] == true) return true;
      }

      return false;
    } on FunctionException catch (e) {
      // Supabase Function failed (e.g., bad request or server crash)
      debugPrint('❌ Check Identity Failed (Technical - Supabase): $e');
      throw KorraException(
        'Could not confirm identity uniqueness due to a server error.',
        technicalDetails: e.toString(),
      );
    } catch (e) {
      // Network or general Flutter exception
      debugPrint('❌ Check Identity Failed (Technical - Generic): $e');
      throw KorraException(
        'Identity verification failed due to network issues. Please try again.',
        technicalDetails: e.toString(),
      );
    }
  }

  // ===========================================================================
  // 2. VERIFY NIN (Monnify)
  // ===========================================================================
  Future<void> verifyNin(String nin) async {
    try {
      await monnify.verifyNin(nin);
      debugPrint("✅ NIN verified successfully.");
    } catch (e) {
      debugPrint("❌ NIN verification failed (Technical): $e");
      
      // We assume Monnify throws an exception with a reason string we can pass through.
      // If 'e' is a Monnify API exception, we extract its message.
      String userMessage = e.toString().contains('Invalid NIN') 
          ? "The NIN provided is invalid." 
          : "NIN verification failed. Please try again later.";

      throw KorraException(userMessage, technicalDetails: e.toString());
    }
  }

  // ===========================================================================
  // 3. VERIFY BVN (Monnify)
  // ===========================================================================
  Future<void> verifyBvn({
    required String bvn,
    required String name,
    required String dateOfBirthIso,
    required String mobileNo,
  }) async {
    try {
      final result = await monnify.verifyBvn(
        bvn: bvn,
        name: name,
        dateOfBirthIso: dateOfBirthIso,
        mobileNo: mobileNo,
      );

      // Business rule: Name and Mobile Match must succeed
      final nameMatch = result['nameMatch'] as String? ?? "NO_MATCH";
      final mobileMatch = result['mobileMatch'] as String? ?? "NO_MATCH";

      if (nameMatch == "NO_MATCH") {
        throw KorraException(
          "Name mismatch: The name provided does not match the BVN record.",
          technicalDetails: "BVN name match failed",
        );
      }
      
      if (mobileMatch == "NO_MATCH") {
        throw KorraException(
          "Mobile number mismatch: The phone number does not match the BVN record.",
          technicalDetails: "BVN mobile match failed",
        );
      }
      
      // BVN/DOB mismatch is usually caught by the Monnify API and wrapped in the catch block.

      debugPrint("✅ BVN verified successfully for $name");
    } catch (e) {
      debugPrint("❌ BVN verification failed (Technical): $e");
      
      // If the error comes directly from Monnify/network, we translate it.
      String userMessage;

      if (e.toString().contains("Invalid BVN")) {
         userMessage = "The BVN provided is invalid or not recognized.";
      } else if (e.toString().contains("Name or Mobile did not match")) {
         // This catches the KorraException thrown earlier if name/mobile mismatch
         userMessage = e.toString();
      } else if (e.toString().contains("DOB mismatch")) {
         userMessage = "Date of birth provided does not match the BVN record.";
      } else {
         userMessage = "BVN verification failed due to an API error.";
      }
      
      // Throw the clean error.
      throw KorraException(userMessage, technicalDetails: e.toString());
    }
  }
}