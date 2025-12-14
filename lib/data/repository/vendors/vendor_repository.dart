import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, FunctionsClient, FunctionException;
import 'package:korra/logic/bloc/auth/signup_vendor/signup_vendor_state.dart';
import 'package:korra/data/models/vendor/vendor_model.dart';

import '../../../config/utils/korra_exception.dart';
import '../../../logic/bloc/vendor/payout/bank.dart';
import '../../../logic/bloc/vendor/product/vendor_products_state.dart';
import '../../models/vendor/payout/payout_details.dart';
import '../../models/vendor/transaction_model.dart';
import '../../models/vendor/vendor_setting.dart';
import '../../models/vendor/vendor_stat.dart';
import '../remote/monnify_functions.dart';

class VendorRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseFirestore db;
  final FunctionsClient fx;
  final MonnifyFunctions monnify;

  VendorRepository({
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

  // 🔹 Local in-memory cache (lives with the repository instance)
  // 🔹 Local cache for ProductItems
  final List<ProductItem> productItemCache = [];
  List<Bank>? cachedBankList;
  VendorSettings? cachedSettings;

  final supabase = Supabase.instance.client;

  /// Optional helpers
  void clearProductCache() => productItemCache.clear();

  void updateProductCache(List<ProductItem> products) {
    productItemCache
      ..clear()
      ..addAll(products);
  }

  KorraException handleError(Object error, {String context = "operation"}) {
    debugPrint("❌ BankRepository Error ($context): $error");

    final String msg = error.toString().toLowerCase();

    // 1. User Mistakes (Logic Errors)
    if (msg.contains('account not found') || msg.contains('invalid account')) {
      return KorraException(
        "Account not found. Please check the number and try again.",
        technicalDetails: "404/Invalid Account",
      );
    }
    
    // 2. Network Issues
    if (error is SocketException || msg.contains('socketexception') || msg.contains('connection refused')) {
      return KorraException(
        "No internet connection. Please check your network.",
        technicalDetails: "SocketException",
      );
    }
    if (error is TimeoutException || msg.contains('timeout')) {
      return KorraException(
        "The bank network is taking too long to respond. Please try again.",
        technicalDetails: "TimeoutException",
      );
    }

    // 3. Server Issues
    if (msg.contains('500') || msg.contains('internal server error')) {
      return KorraException(
        "Our banking partner is having a moment. Please try again shortly.",
        technicalDetails: "500 Server Error",
      );
    }
    
    if (msg.contains('503') || msg.contains('service unavailable')) {
      return KorraException(
        "Bank verification is currently down for maintenance.",
        technicalDetails: "503 Service Unavailable",
      );
    }

    // 4. Pass-through (If it's already a clean KorraException)
    if (error is KorraException) return error;

    // 5. Catch-All
    return KorraException(
      "Something went wrong. Please try again.",
      technicalDetails: error.toString(),
    );
  }

  /// Creates a new vendor account securely using Supabase Functions (Ledger Only)
  Future<String> createVendorFromState(SignupVendorState state) async {
    if (!state.ninVerified || !state.bvnVerified) {
      throw Exception('NIN and BVN must be verified before account creation.');
    }

    final email = state.email.trim().toLowerCase();
    User? firebaseUser;
    String? uid;

    try {
      // --- STEP 1: Create Firebase Auth User ---
      final authCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: state.password,
      );
      firebaseUser = authCredential.user;
      uid = firebaseUser!.uid;
      debugPrint('Step 1: Firebase Vendor created: $uid');

      // --- STEP 2: Call Supabase (Initialize Ledger) ---
      // No Monnify wallet is created here. Just internal DB setup.
      final response = await fx.invoke(
        'create-vendor-account', 
        body: {
          'uid': uid,
          'email': email,
          'firstName': state.firstName,
          'lastName': state.lastName,
          'storeName': state.storeName,
          // We don't strictly need BVN/NIN in Supabase unless you want to save them 
          // to a secure collection. For now, we rely on the Flutter Profile save.
        },
      );

      final responseData = response.data;
      if (responseData['success'] != true) {
        throw Exception('Vendor Setup Failed: ${responseData['error'] ?? "Unknown Error"}');
      }
      debugPrint('Step 2: Vendor Ledger Initialized');

      // --- STEP 3: Construct & Save Profile to Firestore ---
      
      // Create Base Vendor Object
      // Status is 'active' immediately because we removed the "Pending Call" requirement
      var vendor = Vendor.fromState(state, uid, status: 'active');

      // Save Profile
      await _saveVendorToFirestore(vendor);
      debugPrint('Step 3: Vendor Profile Saved');

      // --- STEP 4: Send Welcome Email ---
      try {
        await _sendWelcomeEmail(vendor);
      } catch (e) {
        debugPrint("Email failed but account created: $e");
        // Don't fail the whole signup just because email failed
      }

      return uid;

    } on FirebaseAuthException catch (e) {
      debugPrint('Auth Error: ${e.message}');
      throw Exception(e.message ?? 'Failed to create account.');
    } on FunctionException catch (e) {
      debugPrint('Supabase Error: $e');
      final serverError = (e.details as Map?)?['error'] ?? e.reasonPhrase ?? 'Server setup failed.';
      throw Exception(serverError);
    } catch (err) {
      // --- ROLLBACK LOGIC ---
      debugPrint('CRITICAL ERROR: Vendor Signup failed. Rolling back...');
      if (uid != null) {
        try {
           // Cleanup Firestore using Admin SDK logic implies manual fix, 
           // but we try to delete the main doc here if possible.
           await db.collection('vendors').doc(uid).delete();
           // Note: Cannot delete subcollections (ledger) from Client SDK easily, 
           // but the orphaned data is harmless without the main doc.
        } catch (_) {}
      }
      if (firebaseUser != null) {
        try { await firebaseUser.delete(); } catch (_) {}
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
      return credential.user!.uid;
      
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
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
  Future<void> logout() async {
    try {
      await auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  /// Listen to the Vendor's Risk/Stats Profile in real-time
  Stream<VendorStats> streamVendorStats(String uid) {
    return firestore
        .collection('vendor_stats')
        .doc(uid)
        .snapshots()
        .map((doc) => VendorStats.fromFirestore(doc));
  }
  
  /// Stream the Ledger for the Vendor
  /// This listens to the 'ledger_transactions' subcollection in real-time.
  Stream<List<TransactionModel>> streamLedger(String uid) {
    return firestore
        .collection('vendors')
        .doc(uid)
        .collection('ledger_transactions')
        .orderBy('createdAt', descending: true) // Newest transactions first
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            // Convert Firestore Document to TransactionModel
            return TransactionModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  /// Checks if Email exists securely (Works for Vendors OR Customers)
  Future<bool> checkCollectionForEmail(String collectionName, String email) async {
    try {
      final res = await fx.invoke('check_uniqueness', body: {
        'type': 'email',
        'value': email,
        'collection': collectionName,
      });
      return res.data['exists'] == true;
    } catch (e) {
      debugPrint('Check Email Failed: $e');
      return false;
    }
  }

  /// Saves the vendor data to Firestore with server timestamps.
  Future<void> _saveVendorToFirestore(Vendor vendor) async {
    final map = vendor.toMap();
    map['createdAt'] = FieldValue.serverTimestamp();
    map['updatedAt'] = FieldValue.serverTimestamp();
    await db.collection('vendors').doc(vendor.uid).set(map);
  }

  Future<String> getStoreName(String vendorUid) async {
    return await firestore.collection("vendors")
          .doc(vendorUid)
          .get()
          .then((snap) => snap.data()?["store"]["storeName"] ?? "Korra_Vendor-${vendorUid.substring(0, 5)}");
  }

  /// Calls a Supabase Edge Function to send a welcome email.
  Future<void> _sendWelcomeEmail(Vendor vendor) async {
    try {
      await fx.invoke(
        'send-welcome-email',
        body: {
          'name': '${vendor.firstName} ${vendor.lastName}'.trim(),
          'email': vendor.email,
        },
      );
    } catch (e) {
      debugPrint('Failed to send welcome email: $e');
    }
  }

  /// Fetches both Payout Details and PIN Status in one go.
  Future<VendorSettings> getVendorSettings(String uid, {bool forceRefresh = false}) async {
    if (cachedSettings != null && !forceRefresh) {
      return cachedSettings!;
    }

    try {
      // Run both queries in parallel for speed
      final results = await Future.wait([
        firestore.collection('vendors').doc(uid).collection('settings').doc('payout_details').get(),
        firestore.collection('vendors').doc(uid).collection('security').doc('transaction_pin').get(),
      ]);

      final payoutDoc = results[0];
      final pinDoc = results[1];

      // 1. Parse Payout Details
      PayoutDetails details = PayoutDetails.empty();
      if (payoutDoc.exists && payoutDoc.data() != null) {
        details = PayoutDetails.fromMap(payoutDoc.data() as Map<String, dynamic>);
      }

      // 2. Check if PIN exists
      final bool isPinSet = pinDoc.exists;

      cachedSettings = VendorSettings(
        payoutDetails: details,
        isPinSet: isPinSet,
      );

      return cachedSettings!;
    } catch (e) {
      // If error, return empty settings so the UI doesn't crash
      return VendorSettings(payoutDetails: PayoutDetails.empty(), isPinSet: false);
    }
  }

    // -------------------------------------------------------
  // 4. SAVE PAYOUT DETAILS (Direct Write)
  // -------------------------------------------------------
  Future<void> savePayoutDetails(String uid, PayoutDetails details) async {
    try {
      await firestore
          .collection('vendors')
          .doc(uid)
          .collection('settings')
          .doc('payout_details')
          .set({
            'bankName': details.bankName,
            'accountNumber': details.bankAccountNumber,
            'accountName': details.bankAccountName,
            'bankCode': details.bankCode,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)); // Merge prevents overwriting unrelated fields
      if (cachedSettings != null) {
        cachedSettings = VendorSettings(
          payoutDetails: details, 
          isPinSet: cachedSettings!.isPinSet
        );
      }
    } catch (e) {
      throw Exception("Error saving details: $e");
    }
  }
}
