import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Required for debugPrint
import 'package:korra/data/repository/vendors/payout_repository.dart';
import 'package:korra/data/repository/vendors/wallet_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, FunctionsClient;
import 'package:korra/logic/bloc/auth/signup_vendor/signup_vendor_state.dart';
import 'package:korra/data/models/vendor/vendor_model.dart';

import '../../../logic/bloc/vendor/product/vendor_products_state.dart';
import '../../models/vendor/payout/payout_details.dart';
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

  final supabase = Supabase.instance.client;

  /// Optional helpers
  void clearProductCache() => productItemCache.clear();

  void updateProductCache(List<ProductItem> products) {
    productItemCache
      ..clear()
      ..addAll(products);
  }

  Future<void> updateVendorUsedAmount(
    String vendorId, {
    required double amount,
    required bool increase,
    double? newCurrent,
  }) async {
    try {
      final docRef = firestore.collection('vendor_limits').doc(vendorId);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        debugPrint('No vendor limit found for $vendorId');
        return;
      }

      final data = docSnap.data()!;
      double current = (data['currentUsedAmount'] ?? 0).toDouble();

      if (newCurrent != null) {
        current = newCurrent;
      } else if (increase) {
        current += amount; // vendor adds a product worth "amount"
      } else {
        current = current - amount < 0
            ? 0
            : current - amount; // vendor completes a reservation
      }

      await docRef.update({'currentUsedAmount': current});
      debugPrint('Vendor used amount updated for $vendorId');
    } catch (e) {
      debugPrint('Error updating vendor used amount: $e');
    }
  }

  Future<Map<String, dynamic>?> getVendorLimit(String vendorId) async {
    try {
      final doc = await firestore
          .collection('vendor_limits')
          .doc(vendorId)
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data();
      } else {
        debugPrint('No vendor limit found for $vendorId');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting vendor limit: $e');
      return null;
    }
  }

  Future<void> createVendorWithLimit(Vendor vendor) async {
    final vendorDoc = firestore.collection('vendors').doc(vendor.uid);
    await vendorDoc.set(vendor.toMap());

    final vendorLimitDoc = firestore
        .collection('vendor_limits')
        .doc(vendor.uid);
    await vendorLimitDoc.set({
      'vendorId': vendor.uid,
      'reservationLimit': 100000, // default limit for new vendor
      'currentUsedAmount': 0,
    });
  }

  /// Creates a new vendor account with Firebase Auth, a Monnify wallet,
  /// and a Firestore document.
  Future<String> createVendorFromState(SignupVendorState state) async {
    if (!state.ninVerified || !state.bvnVerified) {
      throw Exception('NIN and BVN must be verified before account creation.');
    }

    debugPrint('vendor state: $state');

    final email = state.email.trim().toLowerCase();

    try {
      final authCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: state.password,
      );
      final uid = authCredential.user!.uid;
      debugPrint('Firebase user created with UID: $uid');

      var vendor = Vendor.fromState(state, uid, status: 'pending-wallet');

      final walletData = await createWallet(vendor, uid); // 👈 use wrapper
      vendor = vendor.copyWithMonnify(
        walletReference: walletData['walletReference'] as String?,
        accountNumber: walletData['accountNumber'] as String?,
        accountName: walletData['accountName'] as String?,
        status: 'active',
      );
      debugPrint(
        'Monnify wallet created successfully for vendor: ${vendor.storeName}',
      );

      // Save payout details immediately, even if bank account is not set yet
      final payout = PayoutDetails(
        withdrawableBalance: 0,
        walletAccountNumber: vendor.accountNumber ?? '',
        walletAccountName: vendor.accountName ?? '',
        walletAccountReference: vendor.walletReference ?? '',
        bankCode: '',
        bankAccountNumber: '',
        bankAccountName: '',
        bankName: '',
      );
      await savePayoutDetails(uid, payout);
      await updateWithdrawableBalance(uid, vendor.accountNumber ?? '');
      await createVendorWithLimit(vendor);
      debugPrint('Payout details initialized in Firestore.');
      await _saveVendorToFirestore(vendor);
      debugPrint('Vendor data saved to Firestore.');

      await _sendWelcomeEmail(vendor);
      debugPrint('Welcome email function triggered.');

      return uid;
    } on FirebaseAuthException catch (err) {
      debugPrint('FirebaseAuth error: ${err.message}');
      throw Exception(err.message ?? 'Failed to create account.');
    } catch (err) {
      debugPrint('Unexpected error during signup: $err');
      throw Exception('Unexpected signup error: $err');
    }
  }

  /// Authenticates a vendor using email and password.
  Future<String> signInVendor(String email, String password) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    debugPrint(
      'Vendor signed in successfully with UID: ${credential.user!.uid}',
    );
    return credential.user!.uid;
  }

  /// Logs out the current vendor.
  Future<void> logout() async {
    try {
      await auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  // Helper function to check a single collection for the nested email
  Future<bool> checkCollectionForEmail(
    String collectionName,
    String email,
  ) async {
    try {
      final snapshot = await db
          .collection(collectionName)
          // Use dot notation to access the email field inside the 'owner' map
          .where('personal.email', isEqualTo: email)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      // Handle potential errors (e.g., permission denied, network issues)
      debugPrint('Error checking email in $collectionName: $e');
      return false; // Return false on error to prevent exposing existence
    }
  }

  /// Saves the vendor data to Firestore with server timestamps.
  Future<void> _saveVendorToFirestore(Vendor vendor) async {
    final map = vendor.toMap();
    map['createdAt'] = FieldValue.serverTimestamp();
    map['updatedAt'] = FieldValue.serverTimestamp();
    await db.collection('vendors').doc(vendor.uid).set(map);
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
}
