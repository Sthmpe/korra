import 'package:equatable/equatable.dart';

abstract class CustomerKycEvent extends Equatable {
  const CustomerKycEvent();
  @override
  List<Object?> get props => [];
}

class BvnInputChanged extends CustomerKycEvent {
  final String bvn;
  const BvnInputChanged(this.bvn);
  @override
  List<Object?> get props => [bvn];
}

class NinInputChanged extends CustomerKycEvent {
  final String nin;
  const NinInputChanged(this.nin);
  @override
  List<Object?> get props => [nin];
}

class VerifyBvnClicked extends CustomerKycEvent {
  final String bvn;
  const VerifyBvnClicked(this.bvn);
  @override
  List<Object?> get props => [bvn];
}

class VerifyNinClicked extends CustomerKycEvent {
  final String nin;
  const VerifyNinClicked(this.nin);
  @override
  List<Object?> get props => [nin];
}

class GenderChanged extends CustomerKycEvent {
  final String gender;
  const GenderChanged(this.gender);
  @override
  List<Object?> get props => [gender];
}

class DobChanged extends CustomerKycEvent {
  final DateTime dob;
  const DobChanged(this.dob);
  @override
  List<Object?> get props => [dob];
}

class EditPhoneToggled extends CustomerKycEvent {}

class SavePhoneClicked extends CustomerKycEvent {
  final String phone;
  const SavePhoneClicked(this.phone);
  @override
  List<Object?> get props => [phone];
}