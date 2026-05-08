import 'package:equatable/equatable.dart';

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

