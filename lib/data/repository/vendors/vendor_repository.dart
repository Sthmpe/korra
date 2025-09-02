import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../data/repository/monnify_repository.dart';
import '../../../logic/bloc/auth/signup_vendor/signup_vendor_state.dart';
import '../../models/vendor/vendor_model.dart';

class VendorRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final MonnifyRepository monnify;

  VendorRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    MonnifyRepository? monnifyRepo,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _db = db ?? FirebaseFirestore.instance,
       monnify = monnifyRepo ?? MonnifyRepository();

  /// Throws on:
  /// - email already used by a customer (if you enforce that),
  /// - KYC not verified,
  /// - Firebase/Monnify errors.
  Future<String> createVendorFromState(SignupVendorState state) async {
    // Enforce KYC
    if (!state.ninVerified || !state.bvnVerified) {
      throw Exception('Please verify NIN and BVN first.');
    }

    final email = state.email.trim().toLowerCase();
    final password = state.password;

    // (Optional) Enforce different email from customers collection
    final custSnap = await _db
        .collection('customers')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (custSnap.docs.isNotEmpty) {
      throw Exception('Email is already used by a customer.');
    }

    // Create Auth user (this also guarantees unique email among all auth users)
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    // Build base vendor doc
    var vendor = Vendor.fromState(state, uid, status: 'active');

    // (Optional) Create a Monnify wallet AFTER BVN verification
    try {
      final walletRef =
          'korra_${uid.substring(0, 6)}_${DateTime.now().millisecondsSinceEpoch}';
      final wallet = await monnify.createWallet(
        walletReference: walletRef,
        walletName: vendor.storeName,
        customerName: '${vendor.ownerFirst} ${vendor.ownerLast}'.trim(),
        customerEmail: vendor.email,
        bvn: vendor.bvn,
        bvnDateOfBirth: _fmtDobIso(vendor.dob!), // same format we used earlier
      );

      vendor = vendor.copyWithMonnify(
        walletReference: wallet['walletReference'] as String?,
        accountNumber:  wallet['accountNumber']  as String?,
        accountName:    wallet['accountName']    as String?,
        status: 'active', // explicit (keeps as active)
      );
    } catch (_) {
     // Wallet failed → keep vendor but mark status accordingly
      vendor = vendor.copyWithMonnify(status: 'pending-wallet');
    }

    // Persist — optionally prefer server timestamps to avoid bad device clocks
    final map = vendor.toMap();
    map['createdAt'] = FieldValue.serverTimestamp();
    map['updatedAt'] = FieldValue.serverTimestamp();

    await _db.collection('vendors').doc(uid).set(map);
    return uid;
  }

  String _fmtDobIso(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
