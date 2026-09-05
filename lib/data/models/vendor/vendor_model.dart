import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/utils/date_formatters.dart';
import '../../../logic/bloc/auth/signup_vendor/signup_vendor_event.dart';
import '../../../logic/bloc/auth/signup_vendor/signup_vendor_state.dart';

class Vendor {
  final String uid;
  
  // --- Business ---
  final bool registered;
  final String cac;
  final String legalName;

  // --- Store ---
  final String logoUrl;
  final String storeName;
  final String description;
  final Presence presence;
  final List<String> categories;

  // --- Location ---
  final String address;
  final String city;
  final String stateName;
  final String mapsLink;

  // --- Personal ---
  final String firstName;
  final String lastName;
  final String otherName;
  final String phone;
  final String email;
  final DateTime? dob;
  final String gender;

  // --- KYC ---
  final String nin;
  final String bvn;
  final bool ninVerified;
  final bool bvnVerified;

  // --- Socials (New) ---
  final String? whatsappGroup;
  final String? instagram;
  final String? website;
  final String? tiktok;
  final String? otherLink;
  final String? twitter;
  final String? facebook;

  // --- Meta ---
  final String status; 
  final DateTime createdAt;
  final DateTime updatedAt;

  Vendor({
    required this.uid,
    required this.registered,
    required this.cac,
    required this.legalName,
    required this.logoUrl,
    required this.storeName,
    this.description = '',
    required this.presence,
    required this.categories,
    required this.address,
    required this.city,
    required this.stateName,
    required this.mapsLink,
    required this.firstName,
    required this.lastName,
    required this.otherName,
    required this.phone,
    required this.email,
    required this.dob,
    required this.gender,
    required this.nin,
    required this.bvn,
    required this.ninVerified,
    required this.bvnVerified,

    // New Socials
    this.whatsappGroup,
    this.instagram,
    this.website,
    this.tiktok,
    this.facebook,
    this.twitter,
    this.otherLink,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // --- FACTORY: From Signup State ---
  factory Vendor.fromState(
    SignupVendorState s,
    String uid, {
    String status = 'pending',
  }) {
    return Vendor(
      uid: uid,
      registered: false,
      cac: '',
      legalName: '',
      logoUrl: '',
      address: '',
      city: '',
      stateName: '',
      mapsLink: '',
      dob: null,
      gender: '',
      nin: '',
      bvn: '',
      ninVerified: false,
      bvnVerified: false,
      status: status,
      storeName: s.storeName.trim(),
      presence: s.presence,
      categories: List<String>.from(s.categories),
      firstName: s.firstName.trim(),
      lastName: s.lastName.trim(),
      otherName: s.otherName.trim(),
      phone: s.phone.trim(),
      email: s.email.trim().toLowerCase(),

      // ✅ Map the optional socials here
      whatsappGroup: s.whatsappGroup.trim(),
      instagram: s.instagram.trim(),
      website: s.website.trim(),
      tiktok: s.tiktok.trim(),
      facebook: s.facebook.trim(),
      twitter: s.twitter.trim(),
      otherLink: s.otherLink.trim(),

      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Vendor copyWithMonnify({
    String? walletReference,
    String? accountNumber,
    String? accountName,
    String? status,
  }) {
    return Vendor(
      uid: uid,
      registered: registered,
      cac: cac,
      legalName: legalName,
      logoUrl: logoUrl,
      storeName: storeName,
      description: description,
      presence: presence,
      categories: categories,
      address: address,
      city: city,
      stateName: stateName,
      mapsLink: mapsLink,
      firstName: firstName,
      lastName: lastName,
      otherName: otherName,
      phone: phone,
      email: email,
      dob: dob,
      gender: gender,
      nin: nin,
      bvn: bvn,
      ninVerified: ninVerified,
      bvnVerified: bvnVerified,
      whatsappGroup: whatsappGroup,
      instagram: instagram,
      tiktok: tiktok,
      facebook: facebook,
      twitter: twitter,
      otherLink: otherLink,
      website: website,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // --- FACTORY: From Firestore Map ---
  factory Vendor.fromMap(Map<String, dynamic> map) {
    // 1. Safely extract nested maps (defaults to empty map if missing)
    final business = map['business'] as Map<String, dynamic>? ?? {};
    final store = map['store'] as Map<String, dynamic>? ?? {};
    final location = map['location'] as Map<String, dynamic>? ?? {};
    final personal = map['personal'] as Map<String, dynamic>? ?? {};
    final kyc = map['kyc'] as Map<String, dynamic>? ?? {};
    final socials = map['socials'] as Map<String, dynamic>? ?? {};

    return Vendor(
      uid: map['uid']?.toString() ?? '',
      
      // Business
      registered: business['registered'] ?? false,
      cac: business['cac']?.toString() ?? '',
      legalName: business['legalName']?.toString() ?? '',

      // Store
      // FIX: Added '?? ""' to logoUrl to prevent crash if missing
      logoUrl: store['logoUrl']?.toString() ?? '',
      storeName: store['storeName']?.toString() ?? '',
      description: store['description']?.toString() ?? '',
      presence: Presence.values.firstWhere(
        (e) => e.name == (store['presence'] ?? 'online'),
        orElse: () => Presence.online,
      ),
      categories: List<String>.from(store['categories'] ?? []),

      // Location
      address: location['address']?.toString() ?? '',
      city: location['city']?.toString() ?? '',
      stateName: location['state']?.toString() ?? '',
      mapsLink: location['mapsLink']?.toString() ?? '',

      // Personal
      firstName: personal['first']?.toString() ?? '',
      lastName: personal['last']?.toString() ?? '',
      otherName: personal['other']?.toString() ?? '',
      phone: personal['phone']?.toString() ?? '',
      email: personal['email']?.toString() ?? '',
      dob: parseSmartDate(personal['dob']),
      gender: personal['gender'] ?? '',

      // KYC
      nin: kyc['nin']?.toString() ?? '',
      bvn: kyc['bvn']?.toString() ?? '',
      ninVerified: kyc['ninVerified'] ?? false,
      bvnVerified: kyc['bvnVerified'] ?? false,

      // Socials (Nullable strings are fine, but let's cast safely)
      whatsappGroup: socials['whatsappGroup']?.toString(),
      instagram: socials['instagram']?.toString(),
      website: socials['website']?.toString(),
      tiktok: socials['tiktok']?.toString(),
      twitter: socials['twitter']?.toString(),
      facebook: socials['facebook']?.toString(),
      otherLink: socials['otherLink']?.toString(),

      // Meta
      status: map['status']?.toString() ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // --- SERIALIZATION: To Firestore ---
  Map<String, dynamic> toMap() {
    // 1. Helper to clean nulls
    Map<String, dynamic> omitNulls(Map<String, dynamic> m) {
      m.removeWhere((k, v) => v == null);
      return m;
    }

    // 2. Construct Socials Map
    final socialsMap = omitNulls({
      'whatsappGroup': whatsappGroup,
      'instagram': instagram,
      'website': website,
      'tiktok': tiktok,
      'twitter': twitter,
      'facebook': facebook,
      'otherLink': otherLink,
    });

    // 3. Construct Main Map
    return omitNulls({
      'uid': uid,
      'business': omitNulls({
        'registered': registered,
        'cac': cac.isEmpty ? null : cac,
        'legalName': legalName.isEmpty ? null : legalName,
      }),
      'store': omitNulls({
        'logoUrl': logoUrl,
        'storeName': storeName,
        'description': description.isEmpty ? null : description,
        'presence': presence.name,
        'categories': categories,
      }),
      'location': omitNulls({
        'address': address.isEmpty ? null : address,
        'city': city,
        'state': stateName,
        'mapsLink': mapsLink.isEmpty ? null : mapsLink,
      }),
      'personal': omitNulls({
        'first': firstName,
        'last': lastName,
        'other': otherName.isEmpty ? null : otherName,
        'phone': phone,
        'email': email,
        'dob': dob == null ? null : Timestamp.fromDate(dob!),
        'gender': gender,
      }),
      'kyc': omitNulls({
        'nin': nin,
        'bvn': bvn,
        'ninVerified': ninVerified,
        'bvnVerified': bvnVerified,
      }),
      
       // Inject Socials
      'socials': socialsMap.isEmpty ? null : socialsMap,

      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    });
  }
}