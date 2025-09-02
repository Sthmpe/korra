import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../logic/bloc/auth/signup_vendor/signup_vendor_event.dart';
import '../../../logic/bloc/auth/signup_vendor/signup_vendor_state.dart';

class Vendor {
  final String uid;
  // business
  final bool registered;
  final String cac;
  final String legalName;

  // store
  final String storeName;
  final Presence presence;
  final List<String> categories;

  // location
  final String address;
  final String city;
  final String stateName;
  final String mapsLink;

  // owner/personal
  final String ownerFirst;
  final String ownerLast;
  final String ownerOther;
  final String ownerPhone;
  final String email;
  final DateTime? dob;
  final Gender gender;

  // kyc
  final String nin;
  final String bvn;
  final bool ninVerified;
  final bool bvnVerified;

  // monnify (optional)
  final String? walletReference;
  final String? accountNumber;
  final String? accountName;

  // meta
  final String status; // 'pending' | 'active' | 'suspended'
  final DateTime createdAt;
  final DateTime updatedAt;

  Vendor({
    required this.uid,
    required this.registered,
    required this.cac,
    required this.legalName,
    required this.storeName,
    required this.presence,
    required this.categories,
    required this.address,
    required this.city,
    required this.stateName,
    required this.mapsLink,
    required this.ownerFirst,
    required this.ownerLast,
    required this.ownerOther,
    required this.ownerPhone,
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
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Build Vendor from your SignupVendorState + new uid
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
      storeName: s.storeName.trim(),
      presence: s.presence,
      categories: List<String>.from(s.categories),
      address: s.address.trim(),
      city: s.city.trim(),
      stateName: s.stateName.trim(),
      mapsLink: s.mapsLink.trim(),
      ownerFirst: s.ownerFirst.trim(),
      ownerLast: s.ownerLast.trim(),
      ownerOther: s.ownerOther.trim(),
      ownerPhone: s.ownerPhone.trim(),
      email: s.email.trim().toLowerCase(),
      dob: s.dob,
      gender: s.gender,
      nin: s.nin.trim(),
      bvn: s.bvn.trim(),
      ninVerified: s.ninVerified,
      bvnVerified: s.bvnVerified,
      walletReference: null,
      accountNumber: null,
      accountName: null,
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
      storeName: storeName,
      presence: presence,
      categories: categories,
      address: address,
      city: city,
      stateName: stateName,
      mapsLink: mapsLink,
      ownerFirst: ownerFirst,
      ownerLast: ownerLast,
      ownerOther: ownerOther,
      ownerPhone: ownerPhone,
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
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // helper: empty string -> null
  static String? _nn(String s) => s.trim().isEmpty ? null : s.trim();

  // helper: remove null entries from a map (mutates)
  static Map<String, dynamic> _omitNulls(Map<String, dynamic> m) {
    m.removeWhere((k, v) => v == null);
    return m;
  }

  Map<String, dynamic> toMap() {
    final business = _omitNulls({
      'registered': registered, // required, keep
      'cac': _nn(cac), // optional -> null if ''
      'legalName': _nn(legalName), // optional -> null if ''
    });

    final store = {
      'storeName': storeName.trim(), // required (you validate it)
      'presence': presence.name,
      'categories': categories, // keep [] if empty
    };

    final location = _omitNulls({
      'address': _nn(address), // mark optional if you allow blank
      'city': _nn(city),
      'state': _nn(stateName),
      'mapsLink': _nn(mapsLink), // optional
    });

    final owner = _omitNulls({
      'first': _nn(ownerFirst),
      'last': _nn(ownerLast),
      'other': _nn(ownerOther), // optional
      'phone': _nn(ownerPhone),
      'email': _nn(email.toLowerCase()),
      'dob': dob == null ? null : Timestamp.fromDate(dob!),
      'gender': gender.name,
    });

    final kyc = _omitNulls({
      // consider masking these or moving to a protected collection
      'nin': _nn(nin),
      'bvn': _nn(bvn),
      'ninVerified': ninVerified,
      'bvnVerified': bvnVerified,
      'verifiedAt': (ninVerified || bvnVerified)
          ? Timestamp.fromDate(DateTime.now())
          : null,
    });

    final monnifyMap = _omitNulls({
      'walletReference': _nn(walletReference ?? ''),
      'accountNumber': _nn(accountNumber ?? ''),
      'accountName': _nn(accountName ?? ''),
    });

    return _omitNulls({
      'uid': uid,
      'business': business,
      'store': store,
      'location': location.isEmpty ? null : location,
      'owner': owner,
      'kyc': kyc,
      'monnify': monnifyMap.isEmpty ? null : monnifyMap,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    });
  }
}
