import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Required for debugPrint
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, FunctionsClient;
import 'package:korra/logic/bloc/auth/signup_vendor/signup_vendor_state.dart';
import 'package:korra/data/models/vendor/vendor_model.dart';

import '../remote/monnify_functions.dart';

class VendorRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FunctionsClient _fx;
  final MonnifyFunctions _monnify;

  VendorRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    FunctionsClient? functions,
    MonnifyFunctions? monnify,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _db = db ?? FirebaseFirestore.instance,
       _fx = functions ?? Supabase.instance.client.functions,
       _monnify = monnify ?? MonnifyFunctions();

  /// ✅ Verify BVN through Monnify
  Future<void> verifyBvn({
    required String bvn,
    required String name,
    required String dateOfBirthIso,
    required String mobileNo,
  }) async {
    try {
      final result = await _monnify.verifyBvn(
        bvn: bvn,
        name: name,
        dateOfBirthIso: dateOfBirthIso,
        mobileNo: mobileNo,
      );

      // Business rule: must not be NO_MATCH
      final nameMatch = result['nameMatch'] as String? ?? "NO_MATCH";
      final mobileMatch = result['mobileMatch'] as String? ?? "NO_MATCH";

      if (nameMatch == "NO_MATCH" || mobileMatch == "NO_MATCH") {
        throw Exception(
          "BVN verification failed: Name or Mobile did not match",
        );
      }

      debugPrint("✅ BVN verified successfully for $name");
    } catch (e) {
      debugPrint("❌ BVN verification failed: $e");
      throw Exception("BVN verification failed: $e");
    }
  }

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

    final authCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: state.password,
    );
    final uid = authCredential.user!.uid;
    debugPrint('Firebase user created with UID: $uid');

    var vendor = Vendor.fromState(state, uid, status: 'pending-wallet');

    try {
      final walletData = await _createWalletViaFx(vendor, uid);
      vendor = vendor.copyWithMonnify(
        walletReference: walletData['walletReference'] as String?,
        accountNumber: walletData['accountNumber'] as String?,
        accountName: walletData['accountName'] as String?,
        status: 'active',
      );
      debugPrint(
        'Monnify wallet created successfully for vendor: ${vendor.storeName}',
      );
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

    final credential = await _auth.signInWithEmailAndPassword(
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
    final custSnap = await _db
        .collection('customers')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return custSnap.docs.isNotEmpty;
  }

  /// Calls the Supabase Edge Function to create a Monnify wallet.
  Future<Map<String, dynamic>> _createWalletViaFx(
    Vendor vendor,
    String uid,
  ) async {
    final walletRef =
        'korra_${uid.substring(0, 6)}_${DateTime.now().millisecondsSinceEpoch}';

    final res = await _fx.invoke(
      'create-wallet',
      body: {
        'walletReference': walletRef,
        'walletName': vendor.storeName,
        'customerName': '${vendor.ownerFirst} ${vendor.ownerLast}'.trim(),
        'customerEmail': vendor.email,
        'bvn': vendor.bvn,
        'bvnDateOfBirth': _fmtDobIso(vendor.dob!),
      },
    );

    if (res.data is Map &&
        res.data['ok'] == true &&
        res.data['result'] is Map) {
      return Map<String, dynamic>.from(res.data['result'] as Map);
    }

    final message = res.data is Map
        ? (res.data['message'] ?? res.data['error'])
        : 'Wallet creation failed';
    throw Exception(message);
  }

  /// Saves the vendor data to Firestore with server timestamps.
  Future<void> _saveVendorToFirestore(Vendor vendor) async {
    final map = vendor.toMap();
    map['createdAt'] = FieldValue.serverTimestamp();
    map['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('vendors').doc(vendor.uid).set(map);
  }

  /// Calls a Supabase Edge Function to send a welcome email.
  Future<void> _sendWelcomeEmail(Vendor vendor) async {
    try {
      await _fx.invoke(
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

  /// Formats a DateTime object into a "YYYY-MM-DD" string.
  String _fmtDobIso(DateTime dob) {
    return "${dob.year.toString().padLeft(4, '0')}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}";
  }
}
