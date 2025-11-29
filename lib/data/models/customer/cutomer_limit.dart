import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerLimit {
  final String uid; 
  final double totalCreditLimit; 
  final double activeDebt;
  
  // Risk Scoring Data
  final int successfulRepayments; 
  final int defaultCount;
  final DateTime lastUpdated;

  // Computed: This is what the UI shows and what the Risk Engine checks
  double get availableLimit => totalCreditLimit - activeDebt;

  const CustomerLimit({
    required this.uid,
    required this.totalCreditLimit,
    required this.activeDebt,
    required this.successfulRepayments,
    required this.defaultCount,
    required this.lastUpdated,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'totalCreditLimit': totalCreditLimit,
      'activeDebt': activeDebt,
      'successfulRepayments': successfulRepayments,
      'defaultCount': defaultCount,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  factory CustomerLimit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomerLimit(
      uid: data['uid'] ?? '',
      totalCreditLimit: (data['totalCreditLimit'] ?? 0).toDouble(),
      activeDebt: (data['activeDebt'] ?? 0).toDouble(),
      successfulRepayments: data['successfulRepayments'] ?? 0,
      defaultCount: data['defaultCount'] ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }
}