import 'package:equatable/equatable.dart';
import 'signup_customer_event.dart';

enum SignupStatus { initial, loading, success, failure }

class SignupCustomerState extends Equatable {
  final int pageIndex;         // 0..3
  final int totalPages;        // 4
  final bool loading;

  // step 1
  final String firstName;
  final String lastName;
  final String otherName;
  final String phone;
  final String email;
  final DateTime? dob;
  final Gender gender;
  final bool emailChecking;
  final bool emailUnused;
  final String? emailError;

  // step 2
  final String nin;
  final String bvn;

  // step 3
  final String password;
  final String confirm;
  final bool hidePassword;
  final bool hideConfirm;

  // KYC flags
  final bool bvnVerifying;
  final bool ninVerifying;
  final bool bvnVerified;
  final bool ninVerified;

  // NEW: remember which exact values passed verification
  final String? lastVerifiedNin;
  final String? lastVerifiedBvn;

  // NEW: per-field server errors (to show next to inputs)
  final String? ninError;
  final String? bvnError;
  final String? kycError;
  final String address;
  final String city;
  final String stateName;
  final String? signUpError;
  final SignupStatus status;
  final String uid; // Added to hold the UID after successful signup

  const SignupCustomerState({
    this.pageIndex = 0,
    this.totalPages = 4,
    this.loading = false,
    this.firstName = '',
    this.lastName = '',
    this.otherName = '',
    this.phone = '',
    this.email = '',
    this.dob,
    this.gender = Gender.undisclosed,
    this.emailChecking = false,
    this.emailUnused = false,
    this.emailError,
    this.nin = '',
    this.bvn = '',
    this.password = '',
    this.confirm = '',
    this.hidePassword = true,
    this.hideConfirm = true, 
    this.bvnVerifying = false,
    this.ninVerifying = false,
    this.bvnVerified = false,
    this.ninVerified = false,
    this.lastVerifiedNin,
    this.lastVerifiedBvn,
    this.ninError,
    this.bvnError,
    this.kycError,
    this.address = '',
    this.city = '',
    this.stateName = '',
    this.signUpError,
    this.status = SignupStatus.initial,
    this.uid = '',
  });

  SignupCustomerState copyWith({
    int? pageIndex, bool? loading,
    String? firstName, String? lastName, String? otherName,
    String? phone, String? email, DateTime? dob, Gender? gender,
    bool? emailChecking,
    bool? emailUnused,
    String? emailError,
    String? nin, String? bvn,
    String? password, String? confirm, bool? hidePassword, bool? hideConfirm,
    bool? bvnVerifying,
    bool? ninVerifying,
    bool? bvnVerified,
    bool? ninVerified,
    String? lastVerifiedNin, 
    String? lastVerifiedBvn,
    String? ninError, 
    String? bvnError,
    String? kycError,
    String? address, String? city, String? stateName,
    String? signUpError,
    SignupStatus? status,
    String? uid,
  }) {
    return SignupCustomerState(
      pageIndex: pageIndex ?? this.pageIndex,
      totalPages: totalPages,
      loading: loading ?? this.loading,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      otherName: otherName ?? this.otherName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      emailChecking: emailChecking ?? this.emailChecking,
      emailUnused: emailUnused ?? this.emailUnused,
      emailError: emailError ?? this.emailError,
      nin: nin ?? this.nin,
      bvn: bvn ?? this.bvn,
      password: password ?? this.password,
      confirm: confirm ?? this.confirm,
      hidePassword: hidePassword ?? this.hidePassword,
      hideConfirm: hideConfirm ?? this.hideConfirm,    
      bvnVerifying: bvnVerifying ?? this.bvnVerifying,
      ninVerifying: ninVerifying ?? this.ninVerifying,
      bvnVerified: bvnVerified ?? this.bvnVerified,
      ninVerified: ninVerified ?? this.ninVerified,
      lastVerifiedNin: lastVerifiedNin ?? this.lastVerifiedNin,
      lastVerifiedBvn: lastVerifiedBvn ?? this.lastVerifiedBvn,
      ninError: ninError ?? this.ninError,
      bvnError: bvnError ?? this.bvnError,
      kycError: kycError ?? this.kycError,
      address: address ?? this.address,
      city: city ?? this.city,
      stateName: stateName ?? this.stateName,
      signUpError: signUpError ?? this.signUpError,
      status: status ?? this.status,
      uid: uid ?? this.uid
    );
  }

  @override
  List<Object?> get props => [
    pageIndex,totalPages,loading,
    firstName,lastName,otherName,phone,email,dob,gender,
    emailChecking, emailUnused, emailError,
    nin,bvn,password,confirm,hidePassword,hideConfirm,
    bvnVerifying,
    ninVerifying,
    bvnVerified,
    ninVerified,
    lastVerifiedNin,
    lastVerifiedBvn,
    ninError,
    bvnError,
    kycError,
    address,
    city,
    stateName,
    signUpError,
    status,
    uid
  ];
}
