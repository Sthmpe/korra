class PinModel {
  final String userId;
  final String pinHash; // hashed value, never store raw pin
  final DateTime createdAt;

  PinModel({
    required this.userId,
    required this.pinHash,
    required this.createdAt,
  });

  factory PinModel.fromMap(Map<String, dynamic> map) {
    return PinModel(
      userId: map['userId'],
      pinHash: map['pinHash'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'pinHash': pinHash,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
