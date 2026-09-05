import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show FunctionException;

import '../../../config/constants/prefs_keys.dart';
import '../../../config/utils/korra_exception.dart';
import '../../../logic/bloc/auth/signup_vendor/signup_vendor_state.dart';
import '../../models/vendor/vendor_model.dart';
import 'vendor_repository.dart';

extension VendorAuth on VendorRepository {
  /// Creates a new vendor account securely using Supabase Functions (Ledger Only)
  Future<String> createVendorFromState(SignupVendorState state) async {
    final email = state.email.trim().toLowerCase();
    
    User? firebaseUser;
    String? uid;

    try {
      // --- STEP 1: Grab the Firebase User (Created during Phone OTP) ---
      firebaseUser = auth.currentUser;
      
      if (firebaseUser == null) {
        throw Exception("Security Error: Phone number not verified. Please restart signup.");
      }

      uid = firebaseUser.uid;
      debugPrint('Step 1: Found Firebase Vendor Identity: $uid');
      
      // 1. Get the User VIP Pass (Who they are)
      final idToken = await firebaseUser.getIdToken(true);

      // 2. Get the Device VIP Pass (Proves it is the real Korra app, not a bot)
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Do the Math: Hash the timestamp using the secret key
      final hmacSha256 = Hmac(sha256, utf8.encode(korraSecret));
      final digest = hmacSha256.convert(utf8.encode(timestamp));
      final signature = digest.toString();

      debugPrint("🔒 Calling create-vendor-account with Double Lock...");

      // --- STEP 2: Call Supabase (Initialize Ledger) ---
      final response = await fx.invoke(
        'create-vendor-account',
        headers: {
          'firebase-token': 'Bearer $idToken',
          'x-korra-timestamp': timestamp,
          'x-korra-signature': signature,
        },
        body: {
          'uid': uid,
          'email': email,
          'firstName': state.firstName,
          'lastName': state.lastName,
          'storeName': state.storeName,
        },
      );

      final responseData = response.data;
      if (responseData['success'] != true) {
        throw Exception(
          'Vendor Setup Failed: ${responseData['error'] ?? "Unknown Error"}',
        );
      }
      debugPrint('Step 2: Vendor Ledger Initialized');

      // --- STEP 3: Construct & Save Profile to Firestore ---
      var vendor = Vendor.fromState(state, uid, status: 'active');

      // Save Profile
      await _saveVendorToFirestore(vendor);
      debugPrint('Step 3: Vendor Profile Saved');

      // --- STEP 4: Send Welcome Email ---
      try {
        if (email.isNotEmpty) {
          await _sendWelcomeEmail(vendor);
        }
      } catch (e) {
        debugPrint("Email failed but account created: $e");
      }

      return uid;
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth Error: ${e.message}');
      throw Exception(e.message ?? 'Failed to create account.');
    } on FunctionException catch (e) {
      debugPrint('Supabase Error: $e');
      final serverError =
          (e.details as Map?)?['error'] ??
          e.reasonPhrase ??
          'Server setup failed.';
      throw Exception(serverError);
    } catch (err) {
      // --- ROLLBACK LOGIC ---
      debugPrint('CRITICAL ERROR: Vendor Signup failed. Rolling back...');
      if (uid != null) {
        try {
          await firestore.collection('vendors').doc(uid).delete();
        } catch (_) {}
      }
      if (firebaseUser != null) {
        try {
          await firebaseUser.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Authenticates a vendor using email and password.
  Future<String> signInVendor(String email, String password) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      debugPrint('Vendor signed in successfully: ${credential.user!.uid}');
      final String vendorUid = credential.user!.uid;

      // THE ORPHAN CHECK (Safety Net) — mirrors CustomerAuth.signInCustomer.
      // Same account can hold a customers/{uid} AND vendors/{uid} profile
      // (already true via Google sign-in); this just makes email/password
      // login require the profile for the app you're actually logging into.
      try {
        final doc = await firestore.collection('vendors').doc(vendorUid).get();
        if (!doc.exists) {
          throw FirebaseException(plugin: 'cloud_firestore', code: 'not-found');
        }
      } catch (e) {
        debugPrint('Vendor login verification failed: $e');
        await auth.signOut();

        if (e is FirebaseException && e.code == 'not-found') {
          throw KorraException(
            'This account is not registered as a merchant. Please use the Korra app instead.',
            technicalDetails: 'Vendor profile document missing',
          );
        }
        throw KorraException(
          'Unable to verify account profile. Please check your connection.',
          technicalDetails: e.toString(),
        );
      }

      // 🛡️ ISOLATE FCM LOGIC: Don't let a missing web worker kill the login!
      try {
        final String? newToken = await FirebaseMessaging.instance.getToken();

        if (newToken != null) {
          await updateFcmToken(vendorUid, newToken);
        }
      } catch (fcmError) {
        debugPrint('⚠️ FCM Token fetch failed: $fcmError');
      }

      return vendorUid;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } on KorraException {
      rethrow;
    } catch (e) {
      throw KorraException(
        'Login failed. Please check your connection and try again.',
        technicalDetails: "Unknown Error",
      );
    }
  }

  // --- HELPER: FIREBASE ERROR TRANSLATOR ---
  KorraException _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return KorraException(
          'Incorrect email or password.',
          technicalDetails: 'Invalid Credentials',
        );
      case 'invalid-email':
        return KorraException(
          'Please enter a valid email address.',
          technicalDetails: 'Malformed Email',
        );
      case 'user-disabled':
        return KorraException(
          'This account has been disabled. Please contact support.',
          technicalDetails: 'User Disabled',
        );
      case 'too-many-requests':
        return KorraException(
          'Too many failed attempts. Please try again in a few minutes.',
          technicalDetails: 'Rate Limited',
        );
      case 'network-request-failed':
        return KorraException(
          'Network error. Please check your internet connection.',
          technicalDetails: 'No Internet',
        );
      default:
        return KorraException(
          'Authentication failed. Please try again.',
          technicalDetails: e.code,
        );
    }
  }

  /// Logs out the current vendor.
  Future<void> logout(String vendorUid) async {
    // 1. Clear FCM Token (Isolated)
    try {
      final String? currentToken = await FirebaseMessaging.instance.getToken();
      if (currentToken != null) {
        await FirebaseFirestore.instance.collection('vendors').doc(vendorUid).update({
          'fcmToken': FieldValue.delete(), 
        });
      }
      await FirebaseMessaging.instance.deleteToken();
      debugPrint("✅ FCM Cleared");
    } catch (e) {
      debugPrint('⚠️ FCM cleanup failed: $e');
    }

    // 2. Disconnect Google (Isolated)
    try {
      if (!kIsWeb) {
        await GoogleSignIn.instance.signOut().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            debugPrint("⚠️ Google sign out timed-out during vendor logout");
            return null;
          },
        );
      }
      debugPrint("✅ Google Disconnected");
    } catch (e) {
      debugPrint('⚠️ Google disconnect failed: $e');
    }

    // 3. Wipe SharedPreferences (Isolated)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(PrefsKeys.userUid);
      await prefs.remove(PrefsKeys.userRole);
      debugPrint("✅ Local Storage Wiped");
    } catch (e) {
      debugPrint('⚠️ SharedPreferences wipe failed: $e');
    }

    // 4. Sign out of Firebase (Isolated & Critical)
    try {
      await FirebaseAuth.instance.signOut();
      debugPrint("✅ Firebase Signed Out");
    } catch (e) {
      debugPrint('❌ Firebase sign-out failed: $e');
      throw Exception('Logout failed at Firebase level.');
    }
  }

  /// Checks if Email exists securely (Works for Vendors OR Customers)
  Future<bool> checkCollectionForEmail(
    String collectionName,
    String email,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      final hmacSha256 = Hmac(sha256, utf8.encode(korraSecret));
      final digest = hmacSha256.convert(utf8.encode(timestamp));
      final signature = digest.toString();

      debugPrint("🔒 Calling check_uniqueness with Lock...");

      final res = await fx.invoke(
        'check_uniqueness',
        headers: {
          'x-korra-timestamp': timestamp,
          'x-korra-signature': signature,
        },
        body: {'type': 'email', 'value': email, 'collection': collectionName},
      );
      return res.data['exists'] == true;
    } catch (e) {
      debugPrint('Check Email Failed: $e');
      return false;
    }
  }

  /// Checks if Phone exists securely (Works for Vendors OR Customers)
  Future<bool> checkCollectionForPhone(
    String collectionName,
    String phone,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      final hmacSha256 = Hmac(sha256, utf8.encode(korraSecret));
      final digest = hmacSha256.convert(utf8.encode(timestamp));
      final signature = digest.toString();

      debugPrint("🔒 Calling check_uniqueness for phone...");

      final res = await fx.invoke(
        'check_uniqueness',
        headers: {
          'x-korra-timestamp': timestamp,
          'x-korra-signature': signature,
        },
        body: {'type': 'phone', 'value': phone, 'collection': collectionName},
      );
      return res.data['exists'] == true;
    } catch (e) {
      debugPrint('Check Phone Failed: $e');
      return false;
    }
  }

  /// Saves the vendor data to Firestore with server timestamps.
  Future<void> _saveVendorToFirestore(Vendor vendor) async {
    final map = vendor.toMap();
    map['createdAt'] = FieldValue.serverTimestamp();
    map['updatedAt'] = FieldValue.serverTimestamp();
    await firestore.collection('vendors').doc(vendor.uid).set(map);
  }

  /// Calls a Supabase Edge Function to send a welcome email.
  Future<void> _sendWelcomeEmail(Vendor vendor) async {
    try {
      await fx.invoke(
        'send-welcome-email',
        body: {
          'name': '${vendor.firstName} ${vendor.lastName}'.trim(),
          'email': vendor.email,
          'phone': vendor.phone,
          'userType': 'vendor'
        },
      );
    } catch (e) {
      debugPrint('Failed to send welcome email: $e');
    }
  }

  /// Sends the 6-digit OTP to the provided phone number via Firebase.
  Future<String> sendPhoneOtp(String phone) async {
    final completer = Completer<String>();

    String normalizedPhone = phone.trim();
    if (normalizedPhone.startsWith('0')) {
      normalizedPhone = '+234${normalizedPhone.substring(1)}';
    } else if (!normalizedPhone.startsWith('+')) {
      normalizedPhone = '+$normalizedPhone';
    }

    debugPrint("📱 Sending Firebase OTP to: $normalizedPhone");
    if (kDebugMode) {
      await auth.setSettings(appVerificationDisabledForTesting: true);
    }

    await auth.verifyPhoneNumber(
      phoneNumber: normalizedPhone,
      verificationCompleted: (PhoneAuthCredential credential) async {},
      verificationFailed: (FirebaseAuthException e) {
        debugPrint("❌ Firebase Phone Auth Failed: ${e.code}");
        if (!completer.isCompleted) {
          completer.completeError(KorraException(e.message ?? 'Verification failed. Try again.'));
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );

    return completer.future;
  }

  /// Verifies the 6-digit SMS code typed by the user.
  Future<void> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await auth.signInWithCredential(credential);
      debugPrint("✅ Firebase Phone OTP Verified! User UID: ${auth.currentUser?.uid}");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        throw KorraException("The 6-digit code is incorrect.");
      }
      throw KorraException(e.message ?? "Failed to verify code.");
    }
  }

  /// Triggers the Google Sign-In flow
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint("🚀 Initializing Google Sign-In...");

      if (kIsWeb) {
        debugPrint("Running Web Flow...");
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        debugPrint("Running Native Flow...");
        final GoogleSignIn googleSignIn = GoogleSignIn.instance;
        await googleSignIn.initialize(
          serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'], 
        );
        final googleUser = await googleSignIn.authenticate();

        final googleAuth = googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        return await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Firebase Google Auth Error: ${e.code}");
      throw Exception(e.message ?? "Failed to connect to Firebase. Try again.");
    } catch (e) {
      debugPrint("❌ General Google Sign-In Error: $e");
      throw Exception("Google sign-in failed. Please check your connection and try again.");
    }
  }

  /// Change vendor's password securely (Re-Auth required)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = auth.currentUser;
    if (user == null) throw KorraException("User not logged in");

    // 1. Create Credential for Re-Auth
    final cred = EmailAuthProvider.credential(
      email: user.email!, 
      password: currentPassword
    );

    try {
      // 2. Re-Authenticate (Critical Security Step)
      await user.reauthenticateWithCredential(cred);

      // 3. Update Password
      await user.updatePassword(newPassword);
      
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw KorraException("The current password is incorrect.");
      } else if (e.code == 'weak-password') {
        throw KorraException("New password is too weak.");
      } else if (e.code == 'requires-recent-login') {
        throw KorraException("Please log out and log back in before changing your password.");
      }
      throw KorraException("Update failed: ${e.message}");
    } catch (e) {
      throw KorraException("An unknown error occurred.");
    }
  }
}
