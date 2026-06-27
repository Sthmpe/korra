import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/utils/korra_exception.dart';
import '../../../data/models/customer/customer_model.dart';
import '../../models/customer/customer_account_stats.dart';
import '../../models/customer/transaction_model.dart';
import '../../models/customer/vendor_profile.dart';
import 'customer_repository.dart';

extension CustomerProfile on CustomerRepository {
  /// Upgrades the customer's tier
  Future<void> upgradeTier(String uid, String tierName) async {
    try {
      // Logic: Update the 'tier' field. 
      // The 'maxSlots' getter in the model will handle the rest when data is fetched.
      await firestore.collection('customers')
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
    return firestore.collection('customers').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Customer.fromMap(doc.data()!);
    });
  }

  // STREAM: Listens to the Ledger (Transactions)
  Stream<List<TransactionModel>> streamLedger(String uid) {
    return firestore
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
    return firestore
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
      await firestore.collection('customers').doc(uid).update({
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
      final query = await firestore.collection('plans')
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

  // Real-time stream for store credit
  Stream<double> streamStoreCredit(String customerUid, String vendorId) {
    return firestore
        .collection('customers')
        .doc(customerUid)
        .collection('my_vendors')
        .doc(vendorId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return 0.0;
          final data = doc.data() as Map<String, dynamic>;
          return (data['storeCredit'] ?? 0).toDouble();
        });
  }

  // One-time fetch for store credit
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
