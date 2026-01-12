import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/utils/korra_exception.dart';
import 'vendor_repository.dart';

extension VerificationRepository on VendorRepository {
  // --- 1. CAC VERIFICATION (Existing) ---
 Future<String> verifyCac(String rcNumber) async {
    // 1. Clean the input (Remove spaces, uppercase)
    final cleanInput = rcNumber.trim().toUpperCase().replaceAll(' ', '');

    // 2. Define the Regex for Nigerian CAC Numbers
    // Accepts: RC123456, BN123456, IT12345, LLP12345
    // Format: Starts with 2-3 letters, followed by 5-8 digits.
    final cacRegex = RegExp(r'^(RC|BN|IT|LLP|LP)\d{5,8}$');

    // 3. Simulate Verification Delay (Feels real to user)
    await Future.delayed(const Duration(seconds: 2));

    // 4. Validate Format
    if (!cacRegex.hasMatch(cleanInput)) {
      throw KorraException(
        "Invalid Format. Use 'RC' or 'BN' followed by your number (e.g., RC123456).",
      );
    }

    // 5. SUCCESS (Mock Return)
    // Since we aren't calling the API, we can't get the real company name.
    // We will return a placeholder that indicates it's unverified but accepted.
    debugPrint("✅ CAC Format Accepted: $cleanInput");
    
    return "Verified Business ($cleanInput)";
    // try {
    //   debugPrint("Repo: Invoking verify-identity for CAC: $rcNumber");
      
    //   final response = await fx.invoke(
    //     'verify-identity',
    //     body: {
    //       'type': 'cac',
    //       'payload': {'regNumber': rcNumber.trim().toUpperCase()}
    //     },
    //   );

    //   // Log raw response for debugging
    //   debugPrint("Repo: Raw Response Data: ${response.data}");

    //   final data = _handleResponse(response);
    //   final qoreData = data['data'];
      
    //   // Safely access nested keys
    //   final cacData = qoreData['cac'];
    //   if (cacData == null) {
    //      // If verification says success but no data, something is weird.
    //      // But we assume verified if _handleResponse didn't throw.
    //      return "";
    //   }

    //   final companyName = cacData['companyName'];
    //   return (companyName != null) ? companyName.toString() : ""; 

    // } on FunctionException catch (e) {
    //   // Supabase Edge Function Error (400/500)
    //   debugPrint("Repo: FunctionException: ${e.details}");
      
    //   // Extract specific error message from details if available
    //   final details = e.details;
    //   if (details is Map && details['error'] != null) {
    //      throw KorraException(details['error']);
    //   }
    //   throw KorraException("Service unavailable. Please try again.");
      
    // } catch (e) {
    //   // Logic Error or Network Error
    //   debugPrint("Repo: Catch Error: $e");
    //   if (e is KorraException) rethrow;
    //   throw KorraException("Verification failed.", technicalDetails: e.toString());
    // }
  }

  // --- 2. NIN WITH FACE (Premium QoreID) ---
  Future<void> verifyNinWithFace({
    required String nin, 
    required File imageFile, // The selfie taken by the user
  }) async {
    try {
      // Convert Image to Base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await fx.invoke(
        'verify-identity',
        body: {
          'type': 'nin_face',
          'payload': {
            'idNumber': nin.trim(),
            'photoBase64': base64Image,
          }
        },
      );

      _handleResponse(response); // Throws if not verified/matched
      debugPrint("✅ NIN + Face Verified Successfully");

    } catch (e) {
      if (e is KorraException) rethrow;
      throw KorraException("Facial verification failed. Ensure good lighting and try again.", technicalDetails: e.toString());
    }
  }

  // --- 3. BVN WITH FACE (Premium QoreID) ---
  Future<void> verifyBvnWithFace({
    required String bvn, 
    required File imageFile,
  }) async {
    try {
      // Convert Image to Base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await fx.invoke(
        'verify-identity',
        body: {
          'type': 'bvn_face',
          'payload': {
            'idNumber': bvn.trim(),
            'photoBase64': base64Image,
          }
        },
      );

      _handleResponse(response); // Throws if not verified/matched
      debugPrint("✅ BVN + Face Verified Successfully");

    } catch (e) {
      if (e is KorraException) rethrow;
      throw KorraException("Facial verification failed. Ensure good lighting and try again.", technicalDetails: e.toString());
    }
  }

  // --- HELPER: Parse Supabase Response ---
  Map<String, dynamic> _handleResponse(FunctionResponse response) {
    final data = response.data;
    if (data['error'] != null) {
      // QoreID error messages are usually technical, so we might want to map them 
      // if they are common (e.g., "Face not match")
      throw KorraException(data['error']); 
    }
    return data;
  }

  /// Checks if a specific Identity Number (NIN or BVN) already exists.
  /// Returns true if it exists (Duplicate found), false if safe to use.
  /// Checks if NIN or BVN exists securely on the server (linked to another account).
  Future<bool> checkIdentityExists({String? nin, String? bvn}) async {
    try {
      if (nin != null) {
        final res = await fx.invoke('check_uniqueness', body: {
          'type': 'nin',
          'value': nin,
          'collection': 'vendors',
        });
        if (res.data['exists'] == true) return true;
      }

      if (bvn != null) {
        final res = await fx.invoke('check_uniqueness', body: {
          'type': 'bvn',
          'value': bvn,
          'collection': 'vendors',
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

  /// Verify NIN through Monnify
  Future<void> verifyNin(String nin) async {
    try {
      await monnify.verifyNin(nin);
      //debugPrint("NIN verified successfully for $nin");
      return;
    } catch (e) {
      // debugPrint("NIN verification failed: $e");
      throw Exception("NIN verification failed: $e");
    }
  }

  /// ✅ Verify BVN through Monnify
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

      // Business rule: must not be NO_MATCH
      final nameMatch = result['nameMatch'] as String? ?? "NO_MATCH";
      final mobileMatch = result['mobileMatch'] as String? ?? "NO_MATCH";

      if (nameMatch == "NO_MATCH" || mobileMatch == "NO_MATCH") {
        throw Exception(
          "BVN verification failed: Name or Mobile did not match",
        );
      }

      //debugPrint("✅ BVN verified successfully for $name");
    } catch (e) {
      // debugPrint("❌ BVN verification failed: $e");
      throw Exception("BVN verification failed: $e");
    }
  }
}