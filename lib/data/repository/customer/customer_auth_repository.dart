import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/constants/prefs_keys.dart';
import '../../../config/utils/korra_exception.dart';
import '../../../data/models/customer/customer_model.dart';
import '../../../logic/bloc/auth/signup_customer/signup_customer_state.dart';
import 'customer_repository.dart';

extension CustomerAuth on CustomerRepository {
  /// Checks if Email exists securely (Works for Vendors OR Customers)
  Future<bool> checkCollectionForEmail(
    String collectionName,
    String email,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Do the Math: Hash the timestamp using the secret key
      final hmacSha256 = Hmac(sha256, utf8.encode(korraSecret));
      final digest = hmacSha256.convert(utf8.encode(timestamp));
      final signature = digest.toString();

      debugPrint("🔒 Calling check_uniqueness with HMAC Signature...");

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

  //// Authenticates a customer and performs the "Zombie Account" check.
  Future<String> signInCustomer(String email, String password) async {
    // 1. Sign In via Firebase Auth
    final credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    // 2. THE ORPHAN CHECK (Safety Net)
    try {
      // We look for the document.
      final doc = await firestore.collection('customers').doc(uid).get();

      if (!doc.exists) {
        // If the doc really doesn't exist, we throw a specific error
        throw FirebaseException(plugin: 'cloud_firestore', code: 'not-found');
      }

      // 🛡️ ISOLATE FCM LOGIC: Don't let a missing web worker kill the login!
      try {
        final String? newToken = await FirebaseMessaging.instance.getToken();

        if (newToken != null) {
          await updateFcmToken(uid, newToken); 
        }
      } catch (fcmError) {
        debugPrint('⚠️ FCM Token fetch failed: $fcmError');
      }
    } catch (e) {
      // 🛑 STOP! Do NOT delete the account here. 
      // It might just be a network error or an App Check failure.
      
      debugPrint('Login Verification Failed: $e');

      // Just sign them out so they can't use the app without a profile
      await auth.signOut();

      // Check if it was actually a "Not Found" error we threw above
      if (e is FirebaseException && e.code == 'not-found') {
         throw KorraException(
          'Account setup incomplete. Please contact support or sign up again.',
          technicalDetails: 'Profile document missing',
        );
      }

      // Otherwise, it's likely a network/permission/AppCheck error.
      // Re-throw it so the UI shows "Network Error" instead of "Account Deleted".
      throw KorraException(
        'Unable to verify account profile. Please check your connection.',
        technicalDetails: e.toString(),
      );
    }

    return uid;
  }

  // Helper method to isolate Auth sign-in exceptions
  Future<void> logout(String uid) async {
    // 1. Clear FCM Token (Isolated)
    try {
      final String? currentToken = await FirebaseMessaging.instance.getToken();
      if (currentToken != null) {
        await FirebaseFirestore.instance.collection('customers').doc(uid).update({
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
            debugPrint("⚠️ Google sign out timed-out during customer logout");
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

  Future<String> createCustomerFromState(SignupCustomerState state) async {
    User? firebaseUser;
    String? uid;

    try {
      // --- STEP 1: Verify Firebase Auth User ---
      firebaseUser = auth.currentUser;

      if (firebaseUser == null) {
        throw Exception("Security Error: Phone number not verified. Please restart signup.");
      }

      uid = firebaseUser.uid;
      debugPrint('Step 1: Firebase user verified: $uid');

      // --- STEP 2: Construct & Save Base Profile to Firestore ---

      // A. Create Base Customer Object
      var customer = Customer.fromState(state, uid, status: 'active');

      // B. Save Profile 
      await _saveCustomerToFirestore(customer, "");

      // C. Send Welcome Email
      await _sendWelcomeEmail(customer);
      
      debugPrint('Step 2: Customer saved successfully. Bank setup deferred.');

      return uid;
      
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Auth Create Failed (Technical): ${e.code} - ${e.message}');
      throw KorraException(_translateFirebaseAuthCreateError(e), technicalDetails: e.toString());
    } catch (err) {
      // --- ROLLBACK LOGIC ---
      debugPrint('CRITICAL ERROR: Signup failed. Initiating Rollback... Technical: $err');
      if (uid != null) {
        try {
          // Attempt to clean up Firestore documents
          await firestore.collection('customers').doc(uid).delete();
          await firestore.collection('customer_limits').doc(uid).delete();
        } catch (_) {}
      }
      if (firebaseUser != null) {
        try {
          // Attempt to delete Auth user
          await firebaseUser.delete();
        } catch (_) {}
      }
      
      if (err is KorraException) {
        rethrow;
      }
      
      // Generic fallback for network or unknown errors (e.g., Firestore failure)
      throw KorraException(
        'Account setup failed due to a critical error. Please contact support.',
        technicalDetails: err.toString(),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // HELPER METHODS (Auth Error Translators)
  // ---------------------------------------------------------------------------



  String _translateFirebaseAuthCreateError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already linked to an existing account.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-email':
        return 'The email address is not valid.';
      default:
        return 'Account creation failed. Please try again.';
    }
  }

  Future<void> _saveCustomerToFirestore(
    Customer customer,
    String bankName,
  ) async {
    final map = customer.toMap();
    map['createdAt'] = FieldValue.serverTimestamp();
    map['updatedAt'] = FieldValue.serverTimestamp();

    if (map['monnify'] is Map) {
      final monnifyMap = Map<String, dynamic>.from(map['monnify']);
      monnifyMap['bankName'] = bankName;
      monnifyMap['availableBalance'] = 0.00;
      map['monnify'] = monnifyMap;
    } else {
      map['monnify'] = {
        'walletReference': customer.walletReference,
        'accountNumber': customer.accountNumber,
        'accountName': customer.accountName,
        'bankName': bankName,
        'availableBalance': 0.00,
      };
    }

    await firestore
        .collection('customers')
        .doc(customer.uid)
        .set(map, SetOptions(merge: true));
  }

  Future<void> _sendWelcomeEmail(Customer customer) async {
    try {
      await fx.invoke(
        'send-welcome-email',
        body: {
          'name': '${customer.firstName} ${customer.lastName}'.trim(),
          'email': customer.email,
          'phone': customer.phone,
          'userType': 'customer',
        },
      );
    } catch (e) {
      debugPrint('Failed to send welcome email: $e');
    }
  }
}
