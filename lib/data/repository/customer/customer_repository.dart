import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Required for debugPrint
import 'package:korra/data/models/customer/customer_model.dart';
import 'package:korra/data/repository/customer/topup_repository.dart';
import 'package:korra/data/repository/customer/wallet_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, FunctionsClient;

import '../../../logic/bloc/auth/signup_customer/signup_customer_state.dart';
import '../../models/customer/topup/topup_details.dart';
import '../remote/monnify_functions.dart';

class CustomerRepository {
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

  Future<Map<String, dynamic>?> getCustomerReserveLimit(
    String customerId,
  ) async {
    try {
      final doc = await firestore
          .collection('customer_reserve_limits')
          .doc(customerId)
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data();
      } else {
        debugPrint('No customer limit found for $customerId');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting customer limit: $e');
      return null;
    }
  }

  Future<void> createCustomerReserveLimit(Customer customer) async {
    final customerDoc = firestore.collection('customer').doc(customer.uid);
    await customerDoc.set(customer.toMap());

    final customerLimitDoc = firestore
        .collection('customer_reserve_limits')
        .doc(customer.uid);
    await customerLimitDoc.set({
      'customerId': customer.uid,
      'reservationLimit': 100000, // default limit for new customer
      'currentUsedAmount': 0,
    });
  }

  /// Creates a new customer account with Firebase Auth, a Monnify wallet,
  /// and a Firestore document.
  Future<String> createCustomerFromState(SignupCustomerState state) async {
    if (!state.ninVerified || !state.bvnVerified) {
      throw Exception('NIN and BVN must be verified before account creation.');
    }

    final email = state.email.trim().toLowerCase();

    try {
      final authCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: state.password,
      );
      final uid = authCredential.user!.uid;
      debugPrint('Firebase user created with UID: $uid');

      var customer = Customer.fromState(state, uid, status: 'pending-wallet');
      final walletData = await createWallet(customer, uid); // 👈 use wrapper
      customer = customer.copyWithMonnify(
        walletReference: walletData['walletReference'] as String?,
        accountNumber: walletData['accountNumber'] as String?,
        accountName: walletData['accountName'] as String?,
        status: 'active',
      );
      debugPrint(
        'Monnify wallet created successfully for customer: ${customer.walletReference}',
      );

      // Save payout details immediately, even if bank account is not set yet
      final topup = TopUpDetails(
        availableBalance: 0,
        walletAccountNumber: customer.accountNumber ?? '',
        walletAccountName: customer.accountName ?? '',
        walletAccountReference: customer.walletReference ?? '',
      );
      await saveTopUpDetails(uid, topup);
      await updateAvailableBalance(uid, customer.accountNumber ?? '');
      await createCustomerReserveLimit(customer);
      debugPrint('Top-up details initialized in Firestore.');
      await _saveCustomerToFirestore(customer);
      debugPrint('Customer data saved to Firestore.');

      await _sendWelcomeEmail(customer);
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

  /// Saves the customer data to Firestore with server timestamps.
  Future<void> _saveCustomerToFirestore(Customer customer) async {
    final map = customer.toMap();
    map['createdAt'] = FieldValue.serverTimestamp();
    map['updatedAt'] = FieldValue.serverTimestamp();
    await db.collection('customer').doc(customer.uid).set(map);
  }

  /// Calls a Supabase Edge Function to send a welcome email.
  Future<void> _sendWelcomeEmail(Customer customer) async {
    try {
      await fx.invoke(
        'send-welcome-email',
        body: {
          'name': '${customer.firstName} ${customer.lastName}'.trim(),
          'email': customer.email,
        },
      );
    } catch (e) {
      debugPrint('Failed to send welcome email: $e');
    }
  }

  /// Authenticates a customer using email and password.
  Future<String> signInCustomer(String email, String password) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    debugPrint(
      'Customer signed in successfully with UID: ${credential.user!.uid}',
    );
    return credential.user!.uid;
  }

  /// Logs out the current customer.
  Future<void> logout() async {
    try {
      await auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }
}
