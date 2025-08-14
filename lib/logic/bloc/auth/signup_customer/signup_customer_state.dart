import 'package:equatable/equatable.dart';
import 'signup_customer_event.dart';

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

  // step 2
  final String nin;
  final String bvn;

  // step 3
  final String password;
  final String confirm;
  final bool hidePassword;
  final bool hideConfirm;

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
    this.nin = '',
    this.bvn = '',
    this.password = '',
    this.confirm = '',
    this.hidePassword = true,
    this.hideConfirm = true,
  });

  SignupCustomerState copyWith({
    int? pageIndex, bool? loading,
    String? firstName, String? lastName, String? otherName,
    String? phone, String? email, DateTime? dob, Gender? gender,
    String? nin, String? bvn,
    String? password, String? confirm, bool? hidePassword, bool? hideConfirm,
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
      nin: nin ?? this.nin,
      bvn: bvn ?? this.bvn,
      password: password ?? this.password,
      confirm: confirm ?? this.confirm,
      hidePassword: hidePassword ?? this.hidePassword,
      hideConfirm: hideConfirm ?? this.hideConfirm,
    );
  }

  @override
  List<Object?> get props => [
    pageIndex,totalPages,loading,
    firstName,lastName,otherName,phone,email,dob,gender,
    nin,bvn,password,confirm,hidePassword,hideConfirm
  ];
}
