// models/customer/vendor_profile.dart

class VendorProfile {
  final String vendorId;
  final String storeName;
  final String? logoUrl;
  final String city;
  final String state;
  final bool isVerified;
  
  // Social Handles (For contact)
  final String? whatsapp;
  final String? instagram;
  final String? website;
  final String? tiktok;
  final String? businessPhone;

  const VendorProfile({
    required this.vendorId,
    required this.storeName,
    this.logoUrl,
    required this.city,
    required this.state,
    required this.isVerified,
    this.whatsapp,
    this.instagram,
    this.website,
    this.tiktok,
    this.businessPhone,
  });

  factory VendorProfile.fromMap(Map<String, dynamic> map, String id) {
    final store = map['store'] ?? {};
    final location = map['location'] ?? {};
    final socials = map['socials'] ?? {};
    final personal = map['personal'] ?? {};

    return VendorProfile(
      vendorId: id, // The Doc ID is the Vendor ID
      storeName: store['storeName'] ?? 'Unknown Store',
      logoUrl: store['logoUrl'], // Ensure you add this to Vendor model later if needed
      city: location['city'] ?? '',
      state: location['state'] ?? '',
      isVerified: map['isVerified'] ?? false, // You might add this flag later
      
      // Map Socials safely
      whatsapp: socials['whatsapp'],
      instagram: socials['instagram'],
      website: socials['website'],
      tiktok: socials['tiktok'],
      
      // Fallback to personal phone if business line not set
      businessPhone: socials['businessLine'] ?? personal['phone'],
    );
  }
}