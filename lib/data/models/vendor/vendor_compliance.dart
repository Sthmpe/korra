class VendorCompliance {
  final bool livenessPassed;
  final bool livenessBypass;
  final double matchPercentage;

  VendorCompliance({
    required this.livenessPassed,
    required this.livenessBypass,
    required this.matchPercentage,
  });

  // Default factory if doc doesn't exist yet
  factory VendorCompliance.initial() {
    return VendorCompliance(
      livenessPassed: false, 
      livenessBypass: true, // Safe default
      matchPercentage: 0.0
    );
  }

  factory VendorCompliance.fromMap(Map<String, dynamic> map) {
    return VendorCompliance(
      livenessPassed: map['livenessCheckPassed'] ?? false,
      livenessBypass: map['livenessBypass'] ?? true,
      matchPercentage: (map['livenessMatchPercentage'] ?? 0.0).toDouble(),
    );
  }
}