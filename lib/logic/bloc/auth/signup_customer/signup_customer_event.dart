import 'package:equatable/equatable.dart';

enum Gender { male, female, other, undisclosed }

abstract class SignupCustomerEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// page control
class SignupCustomerInit extends SignupCustomerEvent {}
class SignupCustomerNextPressed extends SignupCustomerEvent {}
class SignupCustomerBackPressed extends SignupCustomerEvent {}
class SignupCustomerSubmitPressed extends SignupCustomerEvent {}

// field changes — step 1
class FirstNameChanged extends SignupCustomerEvent {
  final String value;
  FirstNameChanged(this.value);
  @override List<Object?> get props => [value];
}
class LastNameChanged extends SignupCustomerEvent {
  final String value;
  LastNameChanged(this.value);
  @override List<Object?> get props => [value];
}
class OtherNameChanged extends SignupCustomerEvent {
  final String value;
  OtherNameChanged(this.value);
  @override List<Object?> get props => [value];
}
class PhoneChanged extends SignupCustomerEvent {
  final String value;
  PhoneChanged(this.value);
  @override List<Object?> get props => [value];
}
class EmailChangedCU extends SignupCustomerEvent {
  final String value;
  EmailChangedCU(this.value);
  @override List<Object?> get props => [value];
}
class DobChanged extends SignupCustomerEvent {
  final DateTime? value;
  DobChanged(this.value);
  @override List<Object?> get props => [value];
}
class GenderChanged extends SignupCustomerEvent {
  final Gender value;
  GenderChanged(this.value);
  @override List<Object?> get props => [value];
}

// step 2
class NinChanged extends SignupCustomerEvent {
  final String value;
  NinChanged(this.value);
  @override List<Object?> get props => [value];
}
class BvnChanged extends SignupCustomerEvent {
  final String value;
  BvnChanged(this.value);
  @override List<Object?> get props => [value];
}

// step 3
class PasswordChangedCU extends SignupCustomerEvent {
  final String value;
  PasswordChangedCU(this.value);
  @override List<Object?> get props => [value];
}
class ConfirmPasswordChangedCU extends SignupCustomerEvent {
  final String value;
  ConfirmPasswordChangedCU(this.value);
  @override List<Object?> get props => [value];
}
class TogglePasswordVisibilityCU extends SignupCustomerEvent {}
class ToggleConfirmVisibilityCU extends SignupCustomerEvent {}
