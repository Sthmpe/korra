import 'package:cloud_firestore/cloud_firestore.dart';
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
  final Gender gender;

  // --- KYC ---
  final String nin;
  final String bvn;
  final bool ninVerified;
  final bool bvnVerified;

  // --- Monnify ---
  final String? walletReference;
  final String? accountNumber;
  final String? accountName;

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
    this.walletReference,
    this.accountNumber,
    this.accountName,
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
      registered: s.registered,
      cac: s.cac.trim(),
      legalName: s.legalName.trim(),
      logoUrl: '',
      storeName: s.storeName.trim(),
      presence: s.presence,
      categories: List<String>.from(s.categories),
      address: s.address.trim(),
      city: s.city.trim(),
      stateName: s.stateName.trim(),
      mapsLink: s.mapsLink.trim(),
      firstName: s.firstName.trim(),
      lastName: s.lastName.trim(),
      otherName: s.otherName.trim(),
      phone: s.phone.trim(),
      email: s.email.trim().toLowerCase(),
      dob: s.dob,
      gender: s.gender,
      nin: s.nin.trim(),
      bvn: s.bvn.trim(),
      ninVerified: s.ninVerified,
      bvnVerified: s.bvnVerified,
      
      // Socials start empty during signup
      whatsappGroup: s.whatsappGroup,
      instagram: s.instagram,
      website: s.website,
      tiktok: s.tiktok,
      facebook: s.facebook,
      twitter: s.twitter,
      otherLink: s.otherLink,

      status: status,
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
      walletReference: walletReference ?? this.walletReference,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
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
    // Safely extract nested maps
    final business = map['business'] as Map<String, dynamic>? ?? {};
    final store = map['store'] as Map<String, dynamic>? ?? {};
    final location = map['location'] as Map<String, dynamic>? ?? {};
    final personal = map['personal'] as Map<String, dynamic>? ?? {};
    final kyc = map['kyc'] as Map<String, dynamic>? ?? {};
    final monnify = map['monnify'] as Map<String, dynamic>? ?? {};
    // Extract Socials Map
    final socials = map['socials'] as Map<String, dynamic>? ?? {};

    return Vendor(
      uid: map['uid'] ?? '',
      
      // Business
      registered: business['registered'] ?? false,
      cac: business['cac'] ?? '',
      legalName: business['legalName'] ?? '',

      // Store
      logoUrl: store['logoUrl'],
      storeName: store['storeName'] ?? '',
      presence: Presence.values.firstWhere(
        (e) => e.name == (store['presence'] ?? 'online'),
        orElse: () => Presence.online,
      ),
      categories: List<String>.from(store['categories'] ?? []),

      // Location
      address: location['address'] ?? '',
      city: location['city'] ?? '',
      stateName: location['state'] ?? '',
      mapsLink: location['mapsLink'] ?? '',

      // Personal
      firstName: personal['first'] ?? '',
      lastName: personal['last'] ?? '',
      otherName: personal['other'] ?? '',
      phone: personal['phone'] ?? '',
      email: personal['email'] ?? '',
      dob: personal['dob'] != null ? (personal['dob'] as Timestamp).toDate() : null,
      gender: Gender.values.firstWhere(
        (e) => e.name == (personal['gender'] ?? 'male'),
        orElse: () => Gender.male,
      ),

      // KYC
      nin: kyc['nin'] ?? '',
      bvn: kyc['bvn'] ?? '',
      ninVerified: kyc['ninVerified'] ?? false,
      bvnVerified: kyc['bvnVerified'] ?? false,

      // Monnify
      walletReference: monnify['walletReference'],
      accountNumber: monnify['accountNumber'],
      accountName: monnify['accountName'],

      // Socials (Mapped directly from the 'socials' object)
      whatsappGroup: socials['whatsappGroup'],
      instagram: socials['instagram'],
      website: socials['website'],
      tiktok: socials['tiktok'],
      twitter: socials['twitter'],
      facebook: socials['facebook'],
      otherLink: socials['otherLink'],

      // Meta
      status: map['status'] ?? 'pending',
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
      'store': {
        'logoUrl': logoUrl,
        'storeName': storeName,
        'presence': presence.name,
        'categories': categories,
      },
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
        'gender': gender.name,
      }),
      'kyc': omitNulls({
        'nin': nin,
        'bvn': bvn,
        'ninVerified': ninVerified,
        'bvnVerified': bvnVerified,
      }),
      'monnify': omitNulls({
        'walletReference': walletReference,
        'accountNumber': accountNumber,
        'accountName': accountName,
      }),
      
      // Inject Socials
      'socials': socialsMap.isEmpty ? null : socialsMap,

      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    });
  }
}