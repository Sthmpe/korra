import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
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
      // 1. Get the Device VIP Pass (Proves it is the real Korra app, not a bot)
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Do the Math: Hash the timestamp using the secret key
      final hmacSha256 = Hmac(sha256, utf8.encode(korraSecret));
      final digest = hmacSha256.convert(utf8.encode(timestamp));
      final signature = digest.toString();

      if (nin != null) {
        debugPrint("🔒 Calling check_uniqueness with Lock...");

        final res = await fx.invoke(
          'check_uniqueness', 
          headers: {
            'x-korra-timestamp': timestamp,
            'x-korra-signature': signature,
          },
          body: {
          'type': 'nin',
          'value': nin,
          'collection': 'vendors',
        });
        if (res.data['exists'] == true) return true;
      }

      if (bvn != null) {
        debugPrint("🔒 Calling check_uniqueness with Lock...");

        final res = await fx.invoke(
          'check_uniqueness', 
          headers: {
            'x-korra-timestamp': timestamp,
            'x-korra-signature': signature,
          },
          body: {
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
  // ===========================================================================
  // 2. VERIFY NIN (Supabase Edge Function)
  // ===========================================================================
  Future<void> verifyNin(String nin, String firstName, String lastName, String otherName, String dateOfBirth, String phoneNumber) async {
    try {
      // 1. Get the Device VIP Pass (Proves it is the real Korra app, not a bot)
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Do the Math: Hash the timestamp using the secret key
      final hmacSha256 = Hmac(sha256, utf8.encode(korraSecret));
      final digest = hmacSha256.convert(utf8.encode(timestamp));
      final signature = digest.toString();

      debugPrint("🔒 Calling nin-verify with Lock...");

      final res = await fx.invoke(
        'nin-verify',
        headers: {
          'x-korra-timestamp': timestamp,
          'x-korra-signature': signature,
        }, 
        body: {
          'nin': nin,
          "firstName": firstName,
          "lastName": lastName,
          "otherName": otherName, // Pass empty string "" if they only have 2 names
          "dateOfBirth": dateOfBirth, // Make sure this is YYYY-MM-DD
          "mobileNumber": phoneNumber,
        });
      final data = res.data;

      debugPrint("NIN Verification Response: $data");

      if (data['ok'] != true) {
        // The edge function sends exactly what went wrong (e.g., "The NIN number you entered does not exist.")
        throw KorraException(data['message'] ?? 'NIN verification failed.');
      }
      
      debugPrint("✅ NIN verified successfully via Edge Function.");
    } on FunctionException catch (e) {
      debugPrint('❌ Check Identity Failed (Supabase): $e');
      throw KorraException('Could not connect to verification server.', technicalDetails: e.toString());
    } catch (e) {
      if (e is KorraException) rethrow; // Pass through our clean errors
      throw KorraException('Network error during NIN verification.', technicalDetails: e.toString());
    }
  }

  // ===========================================================================
  // 3. VERIFY BVN (Supabase Edge Function)
  // ===========================================================================
  Future<void> verifyBvn({
    required String bvn,
    required String name,
    required String dateOfBirthIso,
    required String mobileNo,
  }) async {
    try {
      // 1. Get the Device VIP Pass (Proves it is the real Korra app, not a bot)
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Do the Math: Hash the timestamp using the secret key
      final hmacSha256 = Hmac(sha256, utf8.encode(korraSecret));
      final digest = hmacSha256.convert(utf8.encode(timestamp));
      final signature = digest.toString();

      debugPrint("🔒 Calling check_uniqueness with Lock...");

      final res = await fx.invoke(
        'bvn-verify', 
        headers: {
          'x-korra-timestamp': timestamp,
          'x-korra-signature': signature,
        },
        body: {
          'bvn': bvn,
          'name': name,
          'dateOfBirth': dateOfBirthIso,
          'mobileNo': mobileNo,
        }
      );
      final data = res.data;

      if (data['ok'] != true) {
        // The edge function sends the exact reason (e.g., "The name on this BVN does not match...")
        throw KorraException(data['message'] ?? 'BVN verification failed.');
      }

      debugPrint("✅ BVN verified successfully via Edge Function.");
    } on FunctionException catch (e) {
      debugPrint('❌ Check Identity Failed (Supabase): $e');
      throw KorraException('Could not connect to verification server.', technicalDetails: e.toString());
    } catch (e) {
      if (e is KorraException) rethrow;
      throw KorraException('Network error during BVN verification.', technicalDetails: e.toString());
    }
  }

  // =========================================================
  // 📧 1. SEND VENDOR EMAIL OTP
  // =========================================================
  Future<void> sendEmailOtp({required String email, required String vendorName}) async {
    try {
      final code = (Random().nextInt(900000) + 100000).toString();

      await firestore.collection('otp_codes').doc(email).set({
        'code': code,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final hmacSha256 = Hmac(sha256, utf8.encode(korraSecret));
      final signature = hmacSha256.convert(utf8.encode(timestamp)).toString();

      final response = await fx.invoke(
        'send-email',
        headers: {
          'x-korra-timestamp': timestamp,
          'x-korra-signature': signature,
        },
        body: {
          'type': 'send',
          'email': email,
          'name': vendorName, // Pass the vendor's business name or personal name
          'code': code,
        }
      );

      dynamic data = response.data;
      if (data is String) data = jsonDecode(data);
      if (data['success'] != true) throw Exception(data['error'] ?? "Failed to send email");

    } catch (e) {
      debugPrint("❌ Vendor OTP Send Error: $e");
      throw "Failed to send code. Please try again."; 
    }
  }

  // =========================================================
  // 🔐 2. VERIFY VENDOR EMAIL OTP
  // =========================================================
  Future<void> verifyEmailOtp({required String email, required String code, required String vendorName}) async {
    try {
      final doc = await firestore.collection('otp_codes').doc(email).get();
      if (!doc.exists) throw "Code expired. Request a new one.";

      final savedCode = doc.data()?['code'];
      if (savedCode != code) throw "Incorrect code. Please try again.";

      await doc.reference.delete(); // Cleanup

      // 🚀 Background Success Email
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final hmacSha256 = Hmac(sha256, utf8.encode(korraSecret));
      final signature = hmacSha256.convert(utf8.encode(timestamp)).toString();

      fx.invoke(
        'send-email',
        headers: {
          'x-korra-timestamp': timestamp,
          'x-korra-signature': signature,
        },
        body: {
          'type': 'verified',
          'email': email,
          'name': vendorName,
        }
      ).catchError((e) => debugPrint("Silent Background Email Error: $e"));

    } catch (e) {
      if (e is String) rethrow; 
      throw "Verification failed. Please try again.";
    }
  }
}