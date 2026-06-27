import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../models/vendor/vendor_model.dart';
import '../../models/vendor/vendor_activity_type.dart';
import '../../models/vendor/vendor_compliance.dart';
import '../../models/vendor/vendor_monthly_flow.dart';

import '../../models/vendor/transaction_model.dart';
import 'vendor_repository.dart';

extension VendorStatsExtension on VendorRepository {
  Stream<int> streamUnreadCount(String uid) {
    return firestore
        .collection('vendors')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Stream Recent Activity Feed
  Stream<List<VendorActivityItem>> streamActivityFeed(String uid) {
    return firestore
        .collection('vendors')
        .doc(uid)
        .collection('activity_feed')
        .orderBy('date', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return VendorActivityItem.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Stream CASH LEDGER
  Stream<List<TransactionModel>> streamCashLedger(String uid, {int limit = 50}) {
    return firestore
        .collection('vendors')
        .doc(uid)
        .collection('ledger_transactions')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return TransactionModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Stream LIABILITY LEDGER (Store Credit Owed)
  Stream<List<TransactionModel>> streamLiabilityLedger(String uid, {int limit = 50}) {
    return firestore
        .collection('vendors')
        .doc(uid)
        .collection('liabilities')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return TransactionModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Stream<VendorCompliance> streamComplianceStatus(String vendorId) {
    return firestore
        .collection('vendor_compliance')
        .doc(vendorId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) {
            return VendorCompliance.initial();
          }
          return VendorCompliance.fromMap(doc.data()!);
        });
  }

  Stream<Vendor?> streamVendor(String uid) {
    return firestore
        .collection('vendors')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            return null;
          }
          final data = snapshot.data()!;
          data['uid'] = snapshot.id;
          try {
            return Vendor.fromMap(data);
          } catch (e) {
            debugPrint("Error parsing Vendor data: $e");
            return null;
          }
        });
  }



  /// Stream the Ledger for the Vendor
  Stream<List<TransactionModel>> streamLedger(String uid, {int limit = 50}) {
    return firestore
        .collection('vendors')
        .doc(uid)
        .collection('ledger_transactions')
        .orderBy('createdAt', descending: true) 
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => TransactionModel.fromMap(doc.data(), doc.id)).toList();
        });
  }

  // Get the Pending Balance (Locked Vault)
  Future<double> getPendingBalance(String uid) async {
    try {
      final query = firestore.collection('vendors').doc(uid).collection('ledger_transactions')
          .where('settlementStatus', isEqualTo: 'pending');
          
      final agg = await query.aggregate(sum('amount')).get();
      debugPrint("Pending Balance Aggregate Result: ${agg.getSum('amount')}");
      return agg.getSum('amount') ?? 0.0;
    } catch (e) {
      debugPrint("Error pending balance: $e");
      return 0.0;
    }
  }

  // Get the Available Balance (Withdrawable)
  Future<double> getAvailableBalance(String uid) async {
    try {
      final query = firestore.collection('vendors').doc(uid).collection('ledger_transactions')
          .where('settlementStatus', isEqualTo: 'cleared');
          
      final agg = await query.aggregate(sum('amount')).get();
      debugPrint("Available Balance Aggregate Result: ${agg.getSum('amount')}");
      return agg.getSum('amount') ?? 0.0;
    } catch (e) {
      debugPrint("Error available balance: $e");
      return 0.0;
    }
  }

  // Fetch EVERYTHING for the current month in one single read!
  Stream<VendorMonthlyFlow> streamCurrentMonthStats(String uid) {
    final now = DateTime.now();
    final currentMonthStr = DateFormat('yyyy-MM').format(now);

    return firestore
        .collection('vendors')
        .doc(uid)
        .collection('monthly_stats')
        .doc(currentMonthStr)
        .snapshots()
        .map((doc) => VendorMonthlyFlow.fromMap(doc.data()));
  }

  Future<Map<String, String>> getComplianceStatus(String uid) async {
    try {
      final doc = await firestore.collection('vendor_compliance').doc(uid).get();
      if (!doc.exists) {
        return {
          'status': 'verification_pending', 
          'message': 'Account verification required.'
        };
      }
      final data = doc.data()!;
      return {
        'status': data['status']?.toString() ?? 'verification_pending',
        'message': data['publicMessage']?.toString() ?? 'Account verification required.'
      };
    } catch (e) {
      debugPrint('Error fetching compliance status: $e');
      return {'status': 'error', 'message': 'Could not verify account status.'};
    }
  }

  // GET KYC & PERSONAL DETAILS
  Future<Map<String, dynamic>> getKycDetails(String vendorUid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorUid)
          .get();

      if (!doc.exists) {
        return {
          'kyc': {},
          'personal': {},
        };
      }

      final data = doc.data() ?? {};
      return {
        'kyc': data['kyc'] ?? {},
        'personal': data['personal'] ?? {},
      };
    } catch (e) {
      debugPrint("❌ Error fetching KYC details: $e");
      return {
        'kyc': {},
        'personal': {},
      };
    }
  }
}
