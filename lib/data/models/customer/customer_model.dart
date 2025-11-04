import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../logic/bloc/auth/signup_customer/signup_customer_event.dart';
import '../../../logic/bloc/auth/signup_customer/signup_customer_state.dart';

class Customer {
  final String uid;

  // Personal
  final String firstName;
  final String lastName;
  final String otherName;
  final String phone;
  final String email;
  final DateTime? dob;
  final Gender gender;

  // Address
  final String address;
  final String city;
  final String stateName;

  // KYC
  final String nin;
  final String bvn;
  final bool ninVerified;
  final bool bvnVerified;

  // Monnify / wallet (optional)
  final String? walletReference;
  final String? accountNumber;
  final String? accountName;

  // Meta
  final String status; // 'pending' | 'active' | 'suspended'
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.otherName,
    required this.phone,
    required this.email,
    required this.dob,
    required this.gender,
    required this.address,
    required this.city,
    required this.stateName,
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

  /// Construct from signup state (you’ll make your own SignupCustomerState)
  factory Customer.fromState(SignupCustomerState s, String uid, {String status = 'pending'}) {
    return Customer(
      uid: uid,
      firstName: s.firstName.trim(),
      lastName: s.lastName.trim(),
      otherName: s.otherName.trim(),
      phone: s.phone.trim(),
      email: s.email.trim().toLowerCase(),
      dob: s.dob,
      gender: s.gender,
      address: s.address.trim(),
      city: s.city.trim(),
      stateName: s.stateName.trim(),
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

  Customer copyWithMonnify({
    String? walletReference,
    String? accountNumber,
    String? accountName,
    String? status,
  }) {
    return Customer(
      uid: uid,
      firstName: firstName,
      lastName: lastName,
      otherName: otherName,
      phone: phone,
      email: email,
      dob: dob,
      gender: gender,
      address: address,
      city: city,
      stateName: stateName,
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

  // Helper: empty string -> null
  static String? _nn(String s) => s.trim().isEmpty ? null : s.trim();

  // Helper: remove null entries
  static Map<String, dynamic> _omitNulls(Map<String, dynamic> m) {
    m.removeWhere((k, v) => v == null);
    return m;
  }

  Map<String, dynamic> toMap() {
    final personal = _omitNulls({
      'first': _nn(firstName),
      'last': _nn(lastName),
      'other': _nn(otherName),
      'phone': _nn(phone),
      'email': _nn(email),
      'dob': dob == null ? null : Timestamp.fromDate(dob!),
      'gender': gender.name,
    });

    final addressMap = _omitNulls({
      'address': _nn(address),
      'city': _nn(city),
      'state': _nn(stateName),
    });

    final kyc = _omitNulls({
      'nin': _nn(nin),
      'bvn': _nn(bvn),
      'ninVerified': ninVerified,
      'bvnVerified': bvnVerified,
      'verifiedAt': (ninVerified || bvnVerified)
          ? Timestamp.fromDate(DateTime.now())
          : null,
    });

    final monnify = _omitNulls({
      'walletReference': _nn(walletReference ?? ''),
      'accountNumber': _nn(accountNumber ?? ''),
      'accountName': _nn(accountName ?? ''),
    });

    return _omitNulls({
      'uid': uid,
      'personal': personal,
      'address': addressMap,
      'kyc': kyc,
      'monnify': monnify.isEmpty ? null : monnify,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    });
  }
}
