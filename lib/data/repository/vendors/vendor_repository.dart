import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Required for debugPrint
import 'package:korra/data/repository/vendors/payout_repository.dart';
import 'package:korra/data/repository/vendors/wallet_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, FunctionsClient;
import 'package:korra/logic/bloc/auth/signup_vendor/signup_vendor_state.dart';
import 'package:korra/data/models/vendor/vendor_model.dart';

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

  /// Creates a new vendor account with Firebase Auth, a Monnify wallet,
  /// and a Firestore document.
  Future<String> createVendorFromState(SignupVendorState state) async {
    if (!state.ninVerified || !state.bvnVerified) {
      throw Exception('NIN and BVN must be verified before account creation.');
    }

    final email = state.email.trim().toLowerCase();

    final customerExists = await _checkIfCustomerExists(email);

    if (customerExists) {
      throw Exception('Email is already used by a customer.');
    }

    final authCredential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: state.password,
    );
    final uid = authCredential.user!.uid;
    debugPrint('Firebase user created with UID: $uid');

    var vendor = Vendor.fromState(state, uid, status: 'pending-wallet');

    try {
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
      debugPrint('Payout details initialized in Firestore.');
    } catch (err) {
      debugPrint('Wallet creation failed: $err');
    }

    await _saveVendorToFirestore(vendor);
    debugPrint('Vendor data saved to Firestore.');

    await _sendWelcomeEmail(vendor);
    debugPrint('Welcome email function triggered.');

    return uid;
  }

  /// Authenticates a vendor using email and password.
  Future<String> signInVendor(String email, String password) async {
    final customerExists = await _checkIfCustomerExists(
      email.trim().toLowerCase(),
    );
    if (customerExists) {
      throw Exception('Email is already used by a customer.');
    }

    final credential = await auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    debugPrint(
      'Vendor signed in successfully with UID: ${credential.user!.uid}',
    );
    return credential.user!.uid;
  }

  /// Checks if an email is already associated with a customer account.
  Future<bool> _checkIfCustomerExists(String email) async {
    final custSnap = await db
        .collection('customers')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return custSnap.docs.isNotEmpty;
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
          'name': '${vendor.ownerFirst} ${vendor.ownerLast}'.trim(),
          'email': vendor.email,
        },
      );
    } catch (e) {
      debugPrint('Failed to send welcome email: $e');
    }
  }
}
