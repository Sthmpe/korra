import 'package:cloud_firestore/cloud_firestore.dart';

class VendorStats {
  final String uid;
  
  // Financials
  final double totalSalesVolume;
  final double totalEarnings;
  final double activeLocks;
  
  // Risk & Limits
  final int reputationScore;
  final bool isVerified;
  final double maxPlanAmount;       // Max price per single item (e.g. 100k)
  final double maxReservationLimit; // Total capacity (250K)
  
  // Usage Tracking
  final double totalLiability;         // Store Credit owed to customers
  final double currentActivePlanValue; // Value of all running plans
  
  final DateTime lastUpdated;

  const VendorStats({
    required this.uid,
    required this.totalSalesVolume,
    required this.totalEarnings,
    required this.activeLocks,
    required this.reputationScore,
    required this.isVerified,
    required this.maxPlanAmount,
    required this.maxReservationLimit,
    required this.totalLiability,
    required this.currentActivePlanValue,
    required this.lastUpdated,
  });

  // --- HELPER GETTERS FOR UI ---
  // Calculates how much of the limit is currently "busy"
  double get usedLimit => totalLiability + currentActivePlanValue;
  
  // Calculates what's left for new business
  double get remainingLimit => (maxReservationLimit - usedLimit).clamp(0.0, maxReservationLimit);

  // Calculates percentage for Progress Bars (0.0 to 1.0)
  double get usagePercentage => (maxReservationLimit > 0) 
      ? (usedLimit / maxReservationLimit).clamp(0.0, 1.0) 
      : 0.0;

  /// Factory to create the object from Firestore data safely
  factory VendorStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) return VendorStats.empty();

    return VendorStats(
      uid: doc.id,
      // Use (num? ?? 0).toDouble() pattern to prevent int/double crashes
      totalSalesVolume: (data['totalSalesVolume'] as num? ?? 0).toDouble(),
      totalEarnings: (data['totalEarnings'] as num? ?? 0).toDouble(),
      activeLocks: (data['activeLocks'] as num? ?? 0).toDouble(),
      
      reputationScore: (data['reputationScore'] as num? ?? 100).toInt(),
      isVerified: data['isVerified'] ?? false,
      
      // Limit Configuration
      maxPlanAmount: (data['maxPlanAmount'] as num? ?? 100000).toDouble(),
      maxReservationLimit: (data['maxReservationLimit'] as num? ?? 250000).toDouble(),
      
      // Live Usage
      totalLiability: (data['totalLiability'] as num? ?? 0).toDouble(),
      currentActivePlanValue: (data['currentActivePlanValue'] as num? ?? 0).toDouble(),
      
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Empty state for initial loading
  factory VendorStats.empty() {
    return VendorStats(
      uid: '',
      totalSalesVolume: 0,
      totalEarnings: 0,
      activeLocks: 0,
      reputationScore: 100,
      isVerified: false,
      maxPlanAmount: 100000,       // Default Start
      maxReservationLimit: 250000, // Default Start
      totalLiability: 0,
      currentActivePlanValue: 0,
      lastUpdated: DateTime.now(),
    );
  }
}