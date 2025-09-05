import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Required for debugPrint
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, FunctionsClient;
import 'package:korra/logic/bloc/auth/signup_vendor/signup_vendor_state.dart';
import 'package:korra/data/models/vendor/vendor_model.dart';

import '../../models/vendor/payout/payout_details.dart';
import '../../models/vendor/payout/payout_history.dart';
import '../remote/monnify_functions.dart';

class VendorRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFirestore _db;
  final FunctionsClient _fx;
  final MonnifyFunctions _monnify;

  VendorRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    FirebaseFirestore? firestore,
    FunctionsClient? functions,
    MonnifyFunctions? monnify,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _db = db ?? FirebaseFirestore.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _fx = functions ?? Supabase.instance.client.functions,
       _monnify = monnify ?? MonnifyFunctions();

  /// Reference to payout history collection for a vendor
  CollectionReference<Map<String, dynamic>> _historyRef(String vendorUid) {
    return _firestore
        .collection('payouts')
        .doc(vendorUid)
        .collection('history');
  }

  /// Add a new payout (auto ID)
  Future<String> addPayout(String vendorUid, PayoutHistory payout) async {
    final docRef = _historyRef(vendorUid).doc(); // auto-id
    await docRef.set(payout.toMap());
    return docRef.id;
  }

  /// Update a payout
  Future<void> updatePayout(
    String vendorUid,
    String payoutId,
    Map<String, dynamic> updates,
  ) async {
    await _historyRef(vendorUid).doc(payoutId).update(updates);
  }

  /// Get one payout by ID
  Future<PayoutHistory?> getPayoutById(
    String vendorUid,
    String payoutId,
  ) async {
    final doc = await _historyRef(vendorUid).doc(payoutId).get();
    if (!doc.exists) return null;
    return PayoutHistory.fromMap(doc.id, doc.data()!);
  }

  // Get paginated payouts (10 at a time, newest first)
  Future<List<PayoutHistory>> getPaginatedPayouts(
    String vendorUid, {
    DocumentSnapshot? lastDoc,
    int limit = 10,
  }) async {
    Query<Map<String, dynamic>> query = _historyRef(
      vendorUid,
    ).orderBy('created_at', descending: true).limit(limit);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => PayoutHistory.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Stream payouts in real-time (optional)
  Stream<List<PayoutHistory>> watchLatestPayouts(
    String vendorUid, {
    int limit = 10,
  }) {
    return _historyRef(vendorUid)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PayoutHistory.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Fetch all wallets created by the merchant
  Future<void> fetchWallets({int pageSize = 10, int pageNo = 0}) async {
    final wallets = await _monnify.fetchWallets(
      pageSize: pageSize,
      pageNo: pageNo,
    );

    debugPrint("Total wallets: ${wallets.length}");
    for (var wallet in wallets) {
      debugPrint("Wallet Details:");
      // Use jsonEncode to print the entire wallet map as a formatted string
      debugPrint(jsonEncode(wallet));
      debugPrint("---"); // Optional separator for readability
    }
  }

  /// Get wallet balance
  Future<num> getWalletBalance(String accountNumber) async {
    final data = await _monnify.getWalletBalance(accountNumber: accountNumber);
    return (data['availableBalance'] as num?) ?? 0;
  }

  Future<void> updateWithdrawableBalance(
    String vendorUid,
    String walletAccountNumber,
  ) async {
    final data = await _monnify.getWalletBalance(
      accountNumber: walletAccountNumber,
    );
    final balance = data['availableBalance'] as num? ?? 0;

    final repository = VendorRepository();
    final currentDetails = await repository.getPayoutDetails(vendorUid);

    if (currentDetails != null) {
      // Update only the withdrawable balance, keep other details
      final updatedDetails = PayoutDetails(
        withdrawableBalance: balance,
        walletAccountNumber: currentDetails.walletAccountNumber,
        walletAccountName: currentDetails.walletAccountName,
        walletAccountReference: currentDetails.walletAccountReference,
        bankCode: currentDetails.bankCode,
        bankAccountNumber: currentDetails.bankAccountNumber,
        bankAccountName: currentDetails.bankAccountName,
        bankName: currentDetails.bankName,
      );

      await repository.savePayoutDetails(vendorUid, updatedDetails);
    }
  }

  /// Get payout details for a vendor
  Future<PayoutDetails?> getPayoutDetails(String vendorUid) async {
    final doc = await _firestore.collection('payouts').doc(vendorUid).get();

    debugPrint('PayoutDetails Doc: ${doc.data()}');

    if (doc.exists && doc.data()?['payout_details'] != null) {
      return PayoutDetails.fromMap(doc.data()!['payout_details']);
    }

    return null;
  }

  /// Save/Update payout details
  Future<void> savePayoutDetails(
    String vendorUid,
    PayoutDetails details,
  ) async {
    await _firestore.collection('payouts').doc(vendorUid).set({
      'payout_details': details.toMap(),
    }, SetOptions(merge: true));
  }

  /// Fetch transactions for a reserved account
  Future<List<Map<String, dynamic>>> fetchReservedAccountTransactions({
    required String accountReference,
    int page = 0,
    int size = 10,
  }) async {
    final result = await _monnify.getReservedAccountTransactions(
      accountReference: accountReference,
      page: page,
      size: size,
    );

    // Only return the transactions array
    final transactions = List<Map<String, dynamic>>.from(
      result["transactions"] ?? [],
    );
    return transactions;
  }

  /// Deallocate reserved account through Monnify
  Future<Map<String, dynamic>> deallocateReservedAccount({
    required String accountReference,
  }) async {
    final result = await _monnify.deallocateReservedAccount(
      accountReference: accountReference,
    );

    // Only return confirmation of deallocation
    return {
      "accountReference": result["accountReference"],
      "status": result["status"], // "DEALLOCATED"
    };
  }

  /// Create Reserved Account through Monnify
  Future<Map<String, dynamic>> createReservedAccount({
    required String accountReference,
    required String accountName,
    required String currencyCode,
    required String contractCode,
    required String customerEmail,
    String? customerName,
    String? bvn,
    String? nin,
    List<Map<String, dynamic>>? incomeSplitConfig,
  }) async {
    final result = await _monnify.createReservedAccount(
      accountReference: accountReference,
      accountName: accountName,
      currencyCode: currencyCode,
      contractCode: contractCode,
      customerEmail: customerEmail,
      customerName: customerName,
      bvn: bvn,
      nin: nin,
      incomeSplitConfig: incomeSplitConfig,
    );

    // Only return the assigned account info
    return {
      "accountNumber": result["accountNumber"],
      "bankName": result["bankName"],
      "bankCode": result["bankCode"],
    };
  }

  /// Validate bank account (returns only account name + number)
  Future<Map<String, String>> validateBankAccount({
    required String accountNumber,
    required String bankCode,
  }) async {
    final result = await _monnify.validateBankAccount(
      accountNumber: accountNumber,
      bankCode: bankCode,
    );

    return {
      "accountNumber": result["accountNumber"],
      "accountName": result["accountName"],
    };
  }

  /// Check status of a transfer
  Future<String> checkTransferStatus(String reference) async {
    try {
      final result = await _monnify.checkTransferStatus(reference: reference);
      debugPrint("Transfer ${result['reference']} status: ${result['status']}");
      return result['status']; // e.g. SUCCESS, FAILED, PENDING
    } catch (e) {
      debugPrint("Check transfer status failed: $e");
      rethrow;
    }
  }

  /// Initiate a transfer
  Future<Map<String, dynamic>> initiateTransfer({
    required double amount,
    required String reference,
    required String narration,
    required String destinationBankCode,
    required String destinationAccountNumber,
    String currency = "NGN",
    required String sourceAccountNumber,
  }) async {
    return await _monnify.initiateTransfer(
      amount: amount,
      reference: reference,
      narration: narration,
      destinationBankCode: destinationBankCode,
      destinationAccountNumber: destinationAccountNumber,
      currency: currency,
      sourceAccountNumber: sourceAccountNumber,
    );
  }

  /// Get all wallet transactions for a vendor
  Future<List<Map<String, dynamic>>> getVendorWalletTransactions(
    String accountNumber,
  ) async {
    try {
      final txns = await _monnify.getWalletTransactions(
        accountNumber: accountNumber,
      );
      debugPrint("Fetched ${txns.length} transactions for $accountNumber");
      return txns;
    } catch (e) {
      debugPrint("Error fetching vendor wallet transactions: $e");
      rethrow;
    }
  }

  /// Get vendor available wallet balance
  /// Returns only the availableBalance (int or double)
  Future<num> getVendorWalletBalance(String accountNumber) async {
    try {
      final result = await _monnify.getWalletBalance(
        accountNumber: accountNumber,
      );
      final balance = result['availableBalance'] as num;
      debugPrint("Vendor available balance: $balance");
      return balance;
    } catch (e) {
      debugPrint("Error fetching vendor wallet balance: $e");
      rethrow;
    }
  }

  /// Verify NIN through Monnify
  Future<void> verifyNin(String nin) async {
    try {
      await _monnify.verifyNin(nin);
      debugPrint("NIN verified successfully for $nin");
      return;
    } catch (e) {
      debugPrint("NIN verification failed: $e");
      throw Exception("NIN verification failed: $e");
    }
  }

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
      final walletData = await _createWallet(vendor, uid); // 👈 use wrapper
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

  /// ✅ Calls MonnifyFunctions to create a wallet.
  Future<Map<String, dynamic>> _createWallet(Vendor vendor, String uid) async {
    final walletRef =
        'korra_${uid.substring(0, 6)}_${DateTime.now().millisecondsSinceEpoch}';

    return await _monnify.createWallet(
      walletReference: walletRef,
      walletName: vendor.storeName,
      customerName: '${vendor.ownerFirst} ${vendor.ownerLast}'.trim(),
      customerEmail: vendor.email,
      bvn: vendor.bvn,
      bvnDateOfBirth: _fmtDobIso(vendor.dob!),
    );
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
