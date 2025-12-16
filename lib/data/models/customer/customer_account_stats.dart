import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerAccountStats {
  final String uid;
  
  // 🎰 Slot System Counters
  final int activePlansCount;
  final int completedPlansCount;
  final int defaultsCount;
  final int cancelledPlansCount;
  
  // 🏆 Gamification
  final String tier; // "Starter", "Keeper", "Collector", "VIP"
  
  final DateTime lastUpdated;

  const CustomerAccountStats({
    required this.uid,
    required this.activePlansCount,
    required this.completedPlansCount,
    required this.defaultsCount,
    required this.cancelledPlansCount,
    required this.tier,
    required this.lastUpdated,
  });

  // --- 🧠 COMPUTED LOGIC (The "Brain") ---

  /// Determines the Max Slots based on the Tier stored in DB
  int get maxSlots {
    switch (tier) {
      case 'VIP':
        return 9999; // Unlimited
      case 'Collector':
        return 10;
      case 'Keeper':
        return 5;
      case 'Starter':
      default:
        return 3;
    }
  }

  /// How many more plans can they create?
  int get availableSlots => (maxSlots - activePlansCount).clamp(0, 9999);

  /// Is the user blocked from creating new plans?
  bool get isSlotsFull => availableSlots <= 0;

  /// Helper for UI colors (Green = Good, Red = Bad)
  bool get hasDefaultHistory => defaultsCount > 0;

  // --- SERIALIZATION ---

  factory CustomerAccountStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?; // Safety check
    
    if (data == null) return CustomerAccountStats.empty(doc.id);

    return CustomerAccountStats(
      uid: data['uid'] ?? doc.id,
      activePlansCount: data['activePlansCount'] ?? 0,
      completedPlansCount: data['completedPlansCount'] ?? 0,
      defaultsCount: data['defaultsCount'] ?? 0,
      cancelledPlansCount: data['cancelledPlansCount'] ?? 0,
      tier: data['tier'] ?? 'Starter',
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Fallback for new users before cloud function runs
  factory CustomerAccountStats.empty(String uid) {
    return CustomerAccountStats(
      uid: uid,
      activePlansCount: 0,
      completedPlansCount: 0,
      defaultsCount: 0,
      cancelledPlansCount: 0,
      tier: 'Starter',
      lastUpdated: DateTime.now(),
    );
  }
}