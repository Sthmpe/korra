import 'package:equatable/equatable.dart';
import 'signup_vendor_event.dart';

enum SignupStatus { initial, loading, success, failure }

class SignupVendorState extends Equatable {
  // --- 1. META & NAVIGATION ---
  final int pageIndex; // 0..2
  final int totalPages; // 3
  final bool loading;
  final SignupStatus status;
  final String? signUpError;
  final bool toggled; // Terms & Conditions
  final String uid;

  // --- 2. STEP 1: PERSONAL ---
  final String firstName;
  final String lastName;
  final String otherName;
  final String phone;
  final String email;

  // Phone Verification State
  final bool phoneChecking; // True when checking database
  final bool phoneUnused;   // True if the number is safe to use
  final String? phoneError; 
  
  // --- 3. STEP 2: STORE DETAILS ---
  final String storeName;
  final Presence presence;
  final List<String> categories;

  // Social
  final String instagram;
  final String twitter;
  final String facebook;
  final String tiktok;
  final String website;
  final String whatsappGroup;
  final String otherLink;

  const SignupVendorState({
    this.pageIndex = 0,
    this.totalPages = 3,
    this.loading = false,
    this.status = SignupStatus.initial,
    this.signUpError,
    this.toggled = false,
    this.uid = '',

    // Personal
    this.firstName = '',
    this.lastName = '',
    this.otherName = '',
    this.phone = '',
    this.email = '',

    // Phone State
    this.phoneChecking = false,
    this.phoneUnused = false,
    this.phoneError,

    // Store Details
    this.storeName = '',
    this.presence = Presence.online,
    this.categories = const [],
    this.instagram = '',
    this.twitter = '',
    this.facebook = '',
    this.tiktok = '',
    this.website = '',
    this.whatsappGroup = '',
    this.otherLink = '',
  });

  SignupVendorState copyWith({
    int? pageIndex,
    bool? loading,
    SignupStatus? status,
    String? signUpError,
    bool? toggled,
    String? uid,
    String? firstName,
    String? lastName,
    String? otherName,
    String? phone,
    String? email,
    bool? phoneChecking,
    bool? phoneUnused,
    String? phoneError,
    String? storeName,
    Presence? presence,
    List<String>? categories,
    String? instagram,
    String? twitter,
    String? facebook,
    String? tiktok,
    String? website,
    String? whatsappGroup,
    String? otherLink,
  }) {
    return SignupVendorState(
      pageIndex: pageIndex ?? this.pageIndex,
      totalPages: totalPages,
      loading: loading ?? this.loading,
      status: status ?? this.status,
      signUpError: signUpError ?? this.signUpError,
      toggled: toggled ?? this.toggled,
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      otherName: otherName ?? this.otherName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      phoneChecking: phoneChecking ?? this.phoneChecking,
      phoneUnused: phoneUnused ?? this.phoneUnused,
      phoneError: phoneError ?? this.phoneError,
      storeName: storeName ?? this.storeName,
      presence: presence ?? this.presence,
      categories: categories ?? this.categories,
      instagram: instagram ?? this.instagram,
      twitter: twitter ?? this.twitter,
      facebook: facebook ?? this.facebook,
      tiktok: tiktok ?? this.tiktok,
      website: website ?? this.website,
      whatsappGroup: whatsappGroup ?? this.whatsappGroup,
      otherLink: otherLink ?? this.otherLink,
    );
  }

  @override
  List<Object?> get props => [
    pageIndex,
    totalPages,
    loading,
    status,
    signUpError,
    toggled,
    uid,
    firstName,
    lastName,
    otherName,
    phone,
    email,
    phoneChecking,
    phoneUnused,
    phoneError,
    storeName,
    presence,
    categories,
    whatsappGroup,
    instagram,
    facebook,
    twitter,
    otherLink,
    website,
  ];
}
