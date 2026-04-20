import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
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
            'collection': 'customers',
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

      debugPrint("🔒 Calling bvn-verify with Lock...");

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
  // 📧 1. SEND EMAIL OTP
  // =========================================================
  Future<void> sendEmailOtp({required String email, required String firstName}) async {
    try {
      // 1. Generate 6-digit code
      final code = (Random().nextInt(900000) + 100000).toString();

      // 2. Save to Firestore
      await firestore.collection('otp_codes').doc(email).set({
        'code': code,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Generate HMAC Security Lock
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final hmacSha256 = Hmac(sha256, utf8.encode(korraSecret)); // Use your secret variable
      final signature = hmacSha256.convert(utf8.encode(timestamp)).toString();

      // 4. Call Edge Function
      final response = await fx.invoke(
        'send-email',
        headers: {
          'x-korra-timestamp': timestamp,
          'x-korra-signature': signature,
        },
        body: {
          'type': 'send',
          'email': email,
          'name': firstName,
          'code': code,
        }
      );

      dynamic data = response.data;
      if (data is String) data = jsonDecode(data);
      if (data['success'] != true) throw Exception(data['error'] ?? "Failed to send email");

      debugPrint("✅ OTP Sent Successfully via Resend to $email");

    } catch (e) {
      debugPrint("❌ OTP Send Error: $e");
      // Use your custom KorraException if you have it, otherwise standard throw
      throw "Failed to send code. Please try again."; 
    }
  }

  // =========================================================
  // 🔐 2. VERIFY EMAIL OTP
  // =========================================================
  Future<void> verifyEmailOtp({required String email, required String code, required String firstName}) async {
    try {
      // 1. Read from Firestore
      final doc = await firestore.collection('otp_codes').doc(email).get();

      if (!doc.exists) {
        throw "Code expired. Request a new one.";
      }

      final savedCode = doc.data()?['code'];

      // 2. Check the code
      if (savedCode != code) {
        throw "Incorrect code. Please try again.";
      }

      // 3. Cleanup: Delete the code so it can't be reused
      await doc.reference.delete();

      // 4. 🚀 Background Success Email (Fire and forget)
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
          'name': firstName,
        }
      ).catchError((e) => debugPrint("Silent Background Email Error: $e"));

    } catch (e) {
      debugPrint("❌ OTP Verify Error: $e");
      // Rethrow the exact string if it's one of our custom messages
      if (e is String) rethrow; 
      throw "Verification failed. Please try again.";
    }
  }
}