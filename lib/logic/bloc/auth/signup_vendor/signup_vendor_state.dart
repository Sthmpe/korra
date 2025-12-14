import 'package:equatable/equatable.dart';
import 'signup_vendor_event.dart';

enum SignupStatus { initial, loading, success, failure }

class SignupVendorState extends Equatable {
  final int pageIndex; // 0..4
  final int totalPages; // 5
  final bool loading;

  // V1
  final bool registered;
  final String cac;
  final String legalName;

  // V2
  final String storeName;
  final Presence presence;
  final List<String> categories;

  // V3
  final String address;
  final String city;
  final String stateName;
  final String mapsLink;

  // V4
  final String firstName;
  final String lastName;
  final String otherName;
  final String phone;

  // New-V4
  final String email;
  final DateTime? dob;
  final Gender gender;  
  final bool emailChecking;
  final bool emailUnused;
  final String? emailError;

  // New-V5
  final String nin;
  final String bvn;

  // final String email;
  final String password;
  final String confirm;
  final bool hidePass;
  final bool hideConf;

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
  final String? signUpError;
  final SignupStatus status;
  final bool toggled;

  final String uid; // Added to hold the UID after successful signup

  // Social
 final String instagram;
final String twitter;
final String facebook;
final String tiktok;
final String website;
final String whatsappGroup;
final String otherLink;

final bool cacVerifying;
final bool cacVerified;
final String? cacError;
final String? lastVerifiedCac; // To prevent verifying same number twice
final String? selfiePath;

  const SignupVendorState({
    this.pageIndex = 0,
    this.totalPages = 7,
    this.loading = false,
    this.registered = false,
    this.cac = '',
    this.legalName = '',
    this.storeName = '',
    this.presence = Presence.online,
    this.categories = const [],
    this.address = '',
    this.city = '',
    this.stateName = '',
    this.mapsLink = '',
    this.firstName = '',
    this.lastName = '',
    this.otherName = '',
    this.phone = '',
    this.dob,
    this.gender = Gender.undisclosed,   
    this.emailChecking = false,
    this.emailUnused = false,
    this.emailError,
    this.nin = '',
    this.bvn = '',
    this.email = '',
    this.password = '',
    this.confirm = '',
    this.hidePass = true,
    this.hideConf = true,
    this.bvnVerifying = false,
    this.ninVerifying = false,
    this.bvnVerified = false,
    this.ninVerified = false,
    this.lastVerifiedNin,
    this.lastVerifiedBvn,
    this.ninError,
    this.bvnError,
    this.kycError,
    this.signUpError,
    this.status = SignupStatus.initial,
    this.instagram = '',
    this.twitter = '',
    this.facebook = '',
    this.tiktok = '',
    this.website = '',
    this.whatsappGroup = '',
    this.otherLink = '',
    this.toggled = false,
    this.uid = '',
    this.cacVerifying = false,
    this.cacVerified = false,
    this.cacError,
    this.lastVerifiedCac,
    this.selfiePath,
  });

  SignupVendorState copyWith({
    int? pageIndex,
    bool? loading,
    bool? registered,
    String? cac,
    String? legalName,
    String? storeName,
    Presence? presence,
    List<String>? categories,
    String? address,
    String? city,
    String? stateName,
    String? mapsLink,
    String? firstName,
    String? lastName,
    String? phone,
    String? otherName,
    String? email,
    DateTime? dob,
    Gender? gender,
    bool? emailChecking,
    bool? emailUnused,
    String? emailError,
    String? nin,
    String? bvn,
    String? password,
    String? confirm,
    bool? hidePass,
    bool? hideConf,
    bool? bvnVerifying,
    bool? ninVerifying,
    bool? bvnVerified,
    bool? ninVerified,
    String? lastVerifiedNin, 
    String? lastVerifiedBvn,
    String? ninError, 
    String? bvnError,
    String? kycError,
    String? signUpError,
    SignupStatus? status,
    String? instagram,
    String? twitter,
    String? facebook,
    String? tiktok,
    String? website,
    String? whatsappGroup,
    String? otherLink,
    bool? toggled,
    String? uid,
    bool? cacVerifying,
    bool? cacVerified,
    String? cacError,
    String? lastVerifiedCac,
    String? selfiePath,
  }) {
    return SignupVendorState(
      pageIndex: pageIndex ?? this.pageIndex,
      totalPages: totalPages,
      loading: loading ?? this.loading,
      registered: registered ?? this.registered,
      cac: cac ?? this.cac,
      legalName: legalName ?? this.legalName,
      storeName: storeName ?? this.storeName,
      presence: presence ?? this.presence,
      categories: categories ?? this.categories,
      address: address ?? this.address,
      city: city ?? this.city,
      stateName: stateName ?? this.stateName,
      mapsLink: mapsLink ?? this.mapsLink,
      email: email ?? this.email,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender, 
      emailChecking: emailChecking ?? this.emailChecking,
      emailUnused: emailUnused ?? this.emailUnused,
      emailError: emailError ?? this.emailError,
      nin: nin ?? this.nin,
      bvn: bvn ?? this.bvn,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      otherName: otherName ?? this.otherName,
      password: password ?? this.password,
      confirm: confirm ?? this.confirm,
      hidePass: hidePass ?? this.hidePass,
      hideConf: hideConf ?? this.hideConf,
      bvnVerifying: bvnVerifying ?? this.bvnVerifying,
      ninVerifying: ninVerifying ?? this.ninVerifying,
      bvnVerified: bvnVerified ?? this.bvnVerified,
      ninVerified: ninVerified ?? this.ninVerified,
      lastVerifiedNin: lastVerifiedNin ?? this.lastVerifiedNin,
      lastVerifiedBvn: lastVerifiedBvn ?? this.lastVerifiedBvn,
      ninError: ninError ?? this.ninError,
      bvnError: bvnError ?? this.bvnError,
      kycError: kycError ?? this.kycError,
      signUpError: signUpError ?? this.signUpError,
      status: status ?? this.status,
      instagram: instagram ?? this.instagram,
      twitter: twitter ?? this.twitter,
      facebook: facebook ?? this.facebook,
      tiktok: tiktok ?? this.tiktok,
      website: website ?? this.website,
      whatsappGroup: whatsappGroup ?? this.whatsappGroup,
      otherLink: otherLink ?? this.otherLink,
      toggled: toggled ?? this.toggled,
      uid: uid ?? this.uid,
      cacVerifying: cacVerifying ?? this.cacVerifying,
      cacVerified: cacVerified ?? this.cacVerified,
      cacError: cacError ?? this.cacError,
      lastVerifiedCac: lastVerifiedCac ?? this.lastVerifiedCac,
      selfiePath: selfiePath ?? this.selfiePath,
    );
  }

  @override
  List<Object?> get props => [
    toggled,
    pageIndex,
    totalPages,
    loading,
    registered,
    cac,
    legalName,
    storeName,
    presence,
    categories,
    address,
    city,
    stateName,
    mapsLink,
    firstName,
    lastName,
    otherName,
    phone,
    email,
    dob,
    gender,
    emailChecking, emailUnused, emailError,
    nin,
    bvn,
    password,
    confirm,
    hidePass,
    hideConf,
    bvnVerifying,
    ninVerifying,
    bvnVerified,
    ninVerified,
    lastVerifiedNin,
    lastVerifiedBvn,
    ninError,
    bvnError,
    kycError,
    signUpError,
    status,
    whatsappGroup,
    instagram,
    facebook,
    twitter,
    otherLink,
    website,
    uid,
    cacVerifying,
    cacVerified,
    cacError,
    lastVerifiedCac,
    selfiePath,
  ];
}
