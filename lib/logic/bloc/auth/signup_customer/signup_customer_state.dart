import 'package:equatable/equatable.dart';
import 'signup_customer_event.dart';

enum SignupStatus { initial, loading, success, failure }

class SignupCustomerState extends Equatable {
  final int pageIndex;         // 0..1
  final int totalPages;        // 2
  final bool loading;

  // step 1
  final String firstName;
  final String lastName;
  final String otherName;
  final String phone;
  final String email;

  // Phone Verification State
  final bool phoneChecking; // True when checking database
  final bool phoneUnused;   // True if the number is safe to use
  final String? phoneError;
  
  final String? signUpError;
  final SignupStatus status;
  final String uid; // Added to hold the UID after successful signup

  final bool emailOtpVerified; // 🚀 New: Is the OTP confirmed?
  final bool sendingEmailOtp;  // 🚀 New: Are we currently sending the code?
  final String lastVerifiedEmail;

  const SignupCustomerState({
    this.pageIndex = 0,
    this.totalPages = 2,
    this.loading = false,

    this.firstName = '',
    this.lastName = '',
    this.otherName = '',
    this.phone = '',
    this.email = '',

    // Phone State
    this.phoneChecking = false,
    this.phoneUnused = false,
    this.phoneError,

    this.signUpError,
    this.status = SignupStatus.initial,
    this.uid = '',
    this.emailOtpVerified = false,
    this.sendingEmailOtp = false,
    this.lastVerifiedEmail = '',
  });

  SignupCustomerState copyWith({
    int? pageIndex, bool? loading,
    String? firstName, String? lastName, String? otherName,
    String? phone, String? email,
    bool? phoneChecking,
    bool? phoneUnused,
    String? phoneError,
    String? signUpError,
    SignupStatus? status,
    String? uid,
    bool? emailOtpVerified,
    bool? sendingEmailOtp,
    String? lastVerifiedEmail,
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
      phoneChecking: phoneChecking ?? this.phoneChecking,
      phoneUnused: phoneUnused ?? this.phoneUnused,
      phoneError: phoneError ?? this.phoneError,
      signUpError: signUpError ?? this.signUpError,
      status: status ?? this.status,
      uid: uid ?? this.uid,
      emailOtpVerified: emailOtpVerified ?? this.emailOtpVerified,
      sendingEmailOtp: sendingEmailOtp ?? this.sendingEmailOtp,
      lastVerifiedEmail: lastVerifiedEmail ?? this.lastVerifiedEmail,
    );
  }

  @override
  List<Object?> get props => [
    pageIndex,totalPages,loading,
    firstName,lastName,otherName,phone,email,
    phoneChecking,phoneUnused,phoneError,
    signUpError,
    status,
    uid,
    emailOtpVerified,
    sendingEmailOtp,
    lastVerifiedEmail,
  ];
}
