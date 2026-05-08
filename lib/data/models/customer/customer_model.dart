import 'package:cloud_firestore/cloud_firestore.dart';
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
  final String? gender;

  // Address
  final String address;
  final String city;
  final String stateName;

  // KYC
  final String nin;
  final String bvn;
  final bool ninVerified;
  final bool bvnVerified;

  // Monnify / Wallet
  final String? walletReference;
  final String? accountNumber;
  final String? accountName;
  final String? bankName;        // <--- NEW: Needed for UI
  final double availableBalance; // <--- NEW: Needed for UI

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
    this.bankName,           // <--- Added to constructor
    this.availableBalance = 0.0, // <--- Default to 0
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // ---------------------------------------------------------------------------
  // FACTORY: FROM FIRESTORE MAP (The Missing Piece)
  // ---------------------------------------------------------------------------
  factory Customer.fromMap(Map<String, dynamic> data) {
    // 1. Safely extract nested maps (default to empty if missing)
    final personal = data['personal'] as Map<String, dynamic>? ?? {};
    final addressMap = data['address'] as Map<String, dynamic>? ?? {};
    final kyc = data['kyc'] as Map<String, dynamic>? ?? {};
    final monnify = data['monnify'] as Map<String, dynamic>? ?? {};

    return Customer(
      uid: data['uid'] ?? '',
      
      // Personal
      firstName: personal['first'] ?? '',
      lastName: personal['last'] ?? '',
      otherName: personal['other'] ?? '',
      phone: personal['phone'] ?? '',
      email: personal['email'] ?? '',
      dob: (personal['dob'] as Timestamp?)?.toDate(),
      gender: personal['gender'] ?? '',

      // Address
      address: addressMap['address'] ?? '',
      city: addressMap['city'] ?? '',
      stateName: addressMap['state'] ?? '',

      // KYC
      nin: kyc['nin'] ?? '',
      bvn: kyc['bvn'] ?? '',
      ninVerified: kyc['ninVerified'] ?? false,
      bvnVerified: kyc['bvnVerified'] ?? false,

      //Monnify / Wallet
      walletReference: monnify['walletReference'] ?? '',
      accountNumber: monnify['accountNumber'] ?? '',
      accountName: monnify['accountName'] ?? '',
      bankName: monnify['bankName'] ?? '', // Now we can read this!
      availableBalance: (monnify['availableBalance'] ?? 0).toDouble(), // Now we can read this!

      // Meta
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // FACTORY: FROM SIGNUP STATE
  // ---------------------------------------------------------------------------
  factory Customer.fromState(SignupCustomerState s, String uid, {String status = 'pending'}) {
    return Customer(
      uid: uid,
      firstName: s.firstName.trim(),
      lastName: s.lastName.trim(),
      otherName: s.otherName.trim(),
      phone: s.phone.trim(),
      email: s.email.trim().toLowerCase(),
      dob: null,
      gender: null,
      address: '',
      city: '',
      stateName: '',
      nin: '',
      bvn: '',
      ninVerified: false,
      bvnVerified: false,

      walletReference: null,
      accountNumber: null,
      accountName: null,
      bankName: null,
      availableBalance: 0.0,
      status: status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // COPY WITH (Updated)
  // ---------------------------------------------------------------------------
  Customer copyWithMonnify({
    String? walletReference,
    String? accountNumber,
    String? accountName,
    String? bankName,
    double? availableBalance,
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
      // Wallet updates
      walletReference: walletReference ?? this.walletReference,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      bankName: bankName ?? this.bankName,
      availableBalance: availableBalance ?? this.availableBalance,
      
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

  // ---------------------------------------------------------------------------
  // TO MAP (Updated to include Balance & BankName)
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toMap() {
    final personal = _omitNulls({
      'first': _nn(firstName),
      'last': _nn(lastName),
      'other': _nn(otherName),
      'phone': _nn(phone),
      'email': _nn(email),
      'dob': dob == null ? null : Timestamp.fromDate(dob!),
      'gender': _nn(gender ?? ''),
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
      'bankName': _nn(bankName ?? ''),
      'availableBalance': availableBalance, // Always save balance
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