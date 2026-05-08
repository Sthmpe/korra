

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, FunctionsClient, FunctionException;

// --- MODELS ---
import '../../../config/constants/prefs_keys.dart';
import '../../../config/utils/korra_exception.dart';
import '../../../data/models/customer/customer_model.dart';
import '../../../logic/services/notification_service.dart';
import '../../models/customer/customer_account_stats.dart';
import '../../models/customer/transaction_model.dart';
import '../../../logic/bloc/auth/signup_customer/signup_customer_state.dart';

// --- REMOTE ---
import '../../models/customer/vendor_profile.dart';
import '../remote/monnify_functions.dart';

class CustomerRepository implements INotificationRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseFirestore db;
  final FunctionsClient fx;
  final MonnifyFunctions monnify;

  CustomerRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    FirebaseFirestore? firestore,
    FunctionsClient? functions,
    MonnifyFunctions? monnify,
  }) : auth = auth ?? FirebaseAuth.instance,
       db = db ?? FirebaseFirestore.instance,
       firestore = firestore ?? FirebaseFirestore.instance,
       fx = functions ?? Supabase.instance.client.functions,
       monnify = monnify ?? MonnifyFunctions();

  // ---------------------------------------------------------------------------
  // UTILITY METHODS
  // ---------------------------------------------------------------------------

  final korraSecret = "7f8a9b2d4c6e1f3a5b7c9d0e2f4a6b8c1d3e5f7a9b0c2d4e6f8a1b3c5d7e9f0a";

  @override 
  Future<void> updateFcmToken(String uid, String token) async {
    try {
      // We merge it so we don't overwrite other data
      await db.collection('customers').doc(uid).set({
        'fcmToken': token,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Failed to update FCM Token: $e");
    }
  }

  /// Upgrades the customer's tier
  Future<void> upgradeTier(String uid, String tierName) async {
    try {
      // Logic: Update the 'tier' field. 
      // The 'maxSlots' getter in the model will handle the rest when data is fetched.
      await db.collection('customers')
          .doc(uid)
          .collection('account_stats')
          .doc('main')
          .set({
            'tier': tierName, 
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          
      debugPrint("✅ Tier Upgraded to $tierName");
    } catch (e) {
      throw KorraException("Failed to upgrade tier. Please check your connection.");
    }
  }

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

  // ---------------------------------------------------------------------------
  // AUTHENTICATION (SIGN IN & LOGOUT)
  // ---------------------------------------------------------------------------

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
      // NOTE: Ensure your collection name is correct! 
      // Your bloc says 'customers' (plural), but here you used 'customer' (singular).
      // I have updated it to 'customers' based on your previous code context.
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
      await GoogleSignIn.instance.signOut();
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
      // Bank details will default to empty/null based on your model.
      var customer = Customer.fromState(state, uid, status: 'active');

      // B. Save Profile 
      // Passing an empty string for bankName since it hasn't been generated yet.
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
          await db.collection('customers').doc(uid).delete();
          await db.collection('customer_limits').doc(uid).delete();
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
      // We update the specific 'monnify' map fields to match your structure
      await db.collection('customers').doc(uid).update({
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
      // NOTE: We don't rollback/delete the user here like in sign-up, 
      // because they already have a valid account, just the wallet creation failed.
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

  // ---------------------------------------------------------------------------
  // HELPER METHODS (Auth Error Translators)
  // ---------------------------------------------------------------------------

  String _translateFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid email or password.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Access temporarily blocked due to too many failed login attempts.';
      default:
        return 'Login failed. Please check your credentials.';
    }
  }

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

    await db
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
          'userType': 'customer',
        },
      );
    } catch (e) {
      debugPrint('Failed to send welcome email: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // READ METHODS (Used by UI)
  // ---------------------------------------------------------------------------

  /// Stream Limit for Dashboard
  Stream<CustomerAccountStats?> streamCustomerStats(String uid) {
    return firestore
      .collection('customers')
        .doc(uid)
        .collection('account_stats')
        .doc('main')
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return CustomerAccountStats.fromFirestore(doc);
        });
  }

  /// Stream Balance & Profile
  Stream<Customer?> streamCustomer(String uid) {
    return db.collection('customers').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Customer.fromMap(doc.data()!);
    });
  }

  // STREAM: Listens to the Ledger (Transactions)
  Stream<List<TransactionModel>> streamLedger(String uid) {
    return db
        .collection('customers')
        .doc(uid)
        .collection('ledger_transactions')
        .orderBy('createdAt', descending: true) // Newest first
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            // Fix: Pass both the data AND the document ID
            return TransactionModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  /// STREAM: Listens to My Vendors
  Stream<List<VendorProfile>> streamMyVendors(String uid) {
    return db
        .collection('customers')
        .doc(uid)
        .collection('my_vendors')
        .orderBy('lastInteractionAt', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            // ✅ FIX: Pass both doc.data() AND doc.id
            return VendorProfile.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Future<void> updateCustomerAddress({
    required String uid,
    required String address,
    required String city,
    required String state,
  }) async {
    try {
      await db.collection('customers').doc(uid).update({
        'address.address': address.trim(),
        'address.city': city.trim(),
        'address.state': state.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw KorraException("Failed to update profile.", technicalDetails: e.toString());
    }
  }

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

  Future<void> deleteAccount() async {
    final user = auth.currentUser;
    if (user == null) return;

    try {
      // 1. Call the Executioner Function
      final response = await fx.invoke(
        'delete-account',
        body: { 'customerUid': user.uid },
      );

      final data = response.data;

      // 2. Handle Business Logic Errors (e.g., Active Plans)
      if (data['success'] == false) {
        throw KorraException(data['error'] ?? "Could not delete account");
      }
      
      // 3. If successful, the Auth token is now invalid on the server.
      // We sign out locally to clear the state.
      await auth.signOut();

    } catch (e) {
      // 4. Handle Technical Errors
      if (e is FunctionException) {
         // Extract error from Supabase response if possible
         final details = e.details;
         if (details is Map && details['error'] != null) {
            throw KorraException(details['error']);
         }
      }
      // If it's already a KorraException, rethrow
      if (e is KorraException) rethrow;

      throw KorraException("Unable to delete account. Please contact support.");
    }
  }

  
  // Efficient check: Returns TRUE if user has any plan that isn't closed
  Future<bool> hasActivePlans(String uid) async {
    try {
      final query = await db.collection('plans')
          .where('customerId', isEqualTo: uid)
          .where('status', whereIn: ['active', 'overdue', 'pending_approval'])
          .limit(1) // Optimization: We only need to know if ONE exists
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      return false; // Fallback
    }
  }

  Future<void> recalculateLimit(String uid) async {
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

      debugPrint("🔒 Calling recalculate-limit with Double Lock...");

      final res = await fx.invoke(
        'recalculate-limit',
        headers: {
          'firebase-token': 'Bearer $idToken',
          'x-korra-timestamp': timestamp,
          'x-korra-signature': signature,
        }, 
        body: {'customerUid': uid});
      final data = res.data;
      
      if (data['success'] != true) {
         throw KorraException(data['message'] ?? "Limit update failed.");
      }
    } catch (e) {
      if (e is FunctionException) {
         final details = e.details;
         if (details is Map && details['message'] != null) {
            throw KorraException(details['message']);
         }
      }
      throw KorraException("Could not update limit.", technicalDetails: e.toString());
    }
  }

  // ✅ 1. REAL-TIME STREAM (For PayPlanInputScreen)
  // Listens to changes. If vendor updates credit, UI updates instantly.
  Stream<double> streamStoreCredit(String customerUid, String vendorId) {
    return firestore
        .collection('customers')
        .doc(customerUid)
        .collection('my_vendors') // Ensure this matches your DB collection name exactly
        .doc(vendorId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return 0.0;
          final data = doc.data() as Map<String, dynamic>;
          // Safety: Handle int/double mismatch from Firestore
          return (data['storeCredit'] ?? 0).toDouble();
        });
  }

  // ✅ 2. ONE-TIME FETCH (For your Helper Function)
  // Just gets the value once without listening.
  Future<double> getStoreCredit(String customerUid, String vendorId) async {
    try {
      final doc = await firestore
          .collection('customers')
          .doc(customerUid)
          .collection('my_vendors')
          .doc(vendorId)
          .get();

      if (!doc.exists || doc.data() == null) return 0.0;
      
      final data = doc.data() as Map<String, dynamic>;
      return (data['storeCredit'] ?? 0).toDouble();
    } catch (e) {
      debugPrint("Repo Error fetching store credit: $e");
      return 0.0; // Fail safe to 0
    }
  }

}
