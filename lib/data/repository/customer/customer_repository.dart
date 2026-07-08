import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, FunctionsClient, FunctionException;

// --- MODELS ---
import '../../../config/utils/korra_exception.dart';
import '../../../logic/services/notification_service.dart';
import '../remote/monnify_functions.dart';

// --- EXTENSIONS ---
export 'customer_auth_repository.dart';
export 'customer_profile_repository.dart';
export 'plans_repository.dart';
export 'verification_repository.dart';
export 'customer_activity_feed.dart';
export 'outright_checkout_repository.dart';

class CustomerRepository implements INotificationRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FunctionsClient fx;
  final MonnifyFunctions monnify;

  CustomerRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FunctionsClient? functions,
    MonnifyFunctions? monnify,
  }) : auth = auth ?? FirebaseAuth.instance,
       firestore = firestore ?? FirebaseFirestore.instance,
       fx = functions ?? Supabase.instance.client.functions,
       monnify = monnify ?? MonnifyFunctions();

  // ---------------------------------------------------------------------------
  // CORE UTILITIES & CONFIG
  // ---------------------------------------------------------------------------

  final korraSecret = dotenv.env['KORRA_SECRET_CODE'] ?? '';

  @override 
  Future<void> updateFcmToken(String uid, String token) async {
    try {
      // We merge it so we don't overwrite other data
      await firestore.collection('customers').doc(uid).set({
        'fcmToken': token,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Failed to update FCM Token: $e");
    }
  }

  Future<void> createReserveAccount({
    required String uid,
    required String email,
    required String firstName,
    required String lastName,
    required String bvn,
    required String nin,
  }) async {
    try {
      // --- STEP 1: Verify Firebase Auth User ---
      final firebaseUser = auth.currentUser;
      if (firebaseUser == null || firebaseUser.uid != uid) {
        throw Exception("Security Error: Unauthorized request. Please log in again.");
      }

      debugPrint('Step 1: Firebase user verified: $uid');

      // 1. Get the User VIP Pass
      final idToken = await firebaseUser.getIdToken(true);

      // 2. Get the Device VIP Pass
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final hmacSha256 = Hmac(sha256, utf8.encode(korraSecret));
      final digest = hmacSha256.convert(utf8.encode(timestamp));
      final signature = digest.toString();

      debugPrint("🔒 Calling create-reserve-account with Double Lock & KYC...");

      // --- STEP 2: Call Supabase (Monnify Reservation) ---
      final response = await fx.invoke(
        'create-reserve-account',
        headers: {
          'x-korra-timestamp': timestamp,
          'x-korra-signature': signature,
          'firebase-token': 'Bearer $idToken', 
        },
        body: {
          'uid': uid,
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'bvn': bvn,
          'nin': nin,
        },
      );

      final responseData = response.data;

      if (responseData['success'] != true) {
        throw KorraException(
          'Banking Setup Failed: ${responseData['error'] ?? "Unknown"}',
        );
      }

      final bankData = responseData['data'];
      debugPrint('✅ Step 2: Reserve Account Created: ${bankData['accountNumber']}');

      // --- STEP 3: Update Firestore ---
      await firestore.collection('customers').doc(uid).update({
        'monnify.walletReference': bankData['accountReference'],
        'monnify.accountNumber': bankData['accountNumber'],
        'monnify.accountName': bankData['accountName'],
        'monnify.bankName': bankData['bankName'],
        'monnify.availableBalance': 0.00,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Customer profile updated with bank details.');

    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Auth Error: ${e.code} - ${e.message}');
      throw KorraException("Authentication error. Please log in again.", technicalDetails: e.toString());
    } on FunctionException catch (e) {
      debugPrint('❌ Supabase Bank Setup Failed (Technical): $e');
      final serverError = (e.details as Map?)?['error'] ?? e.reasonPhrase ?? 'Unknown server error.';
      throw KorraException(serverError.toString(), technicalDetails: e.toString()); 
    } catch (err) {
      debugPrint('CRITICAL ERROR: Wallet creation failed: $err');
      if (err is KorraException) {
        rethrow;
      }
      throw KorraException(
        'Account setup failed due to a critical error. Please contact support.',
        technicalDetails: err.toString(),
      );
    }
  }

  Future<String?> initializeWebCheckout({
    required double amount,
    required String email,
    required String name,
    required String paymentReference,
  }) async {
    try {
      final firebaseUser = auth.currentUser;
      if (firebaseUser == null) {
        throw Exception("You must be logged in to initialize payment.");
      }

      final idToken = await firebaseUser.getIdToken(true);
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final hmacSha256 = Hmac(sha256, utf8.encode(korraSecret));
      final digest = hmacSha256.convert(utf8.encode(timestamp));
      final signature = digest.toString();

      debugPrint("🔒 Initializing Monnify web checkout...");

      final response = await fx.invoke(
        'monnify-checkout',
        headers: {
          'x-korra-timestamp': timestamp,
          'x-korra-signature': signature,
          'firebase-token': 'Bearer $idToken', 
        },
        body: {
          'amount': amount,
          'customerName': name.isNotEmpty ? name : 'Korra Guest',
          'customerEmail': email.isNotEmpty ? email : 'hello@korra.com.ng',
          'paymentReference': paymentReference,
          'paymentDescription': 'Korra Wallet Deposit',
          'redirectUrl': kIsWeb ? Uri.base.toString() : 'https://app.korra.com.ng',
        },
      );

      final responseData = response.data;
      if (responseData == null || responseData['error'] != null) {
        throw KorraException(
          responseData != null ? responseData['error'] : 'Failed to parse server response.',
        );
      }

      final String? checkoutUrl = responseData['checkoutUrl'];
      return checkoutUrl;
    } on FunctionException catch (e) {
      debugPrint('❌ Supabase Payment Init Failed (Technical): $e');
      final serverError = (e.details as Map?)?['error'] ?? e.reasonPhrase ?? 'Unknown server error.';
      throw KorraException(serverError.toString(), technicalDetails: e.toString()); 
    } catch (err) {
      debugPrint('CRITICAL ERROR: Monnify web checkout failed: $err');
      if (err is KorraException) {
        rethrow;
      }
      throw KorraException(
        'Payment initialization failed. Please try again.',
        technicalDetails: err.toString(),
      );
    }
  }
}
