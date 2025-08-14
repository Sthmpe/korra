import 'package:equatable/equatable.dart';

enum Presence { online, physical, both }

enum Gender { male, female, other, undisclosed }

abstract class SignupVendorEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// paging
class SignupVendorInit extends SignupVendorEvent {}
class SignupVendorNextPressed extends SignupVendorEvent {}
class SignupVendorBackPressed extends SignupVendorEvent {}
class SignupVendorSubmitPressed extends SignupVendorEvent {}

// V1 — business type
class RegisteredToggled extends SignupVendorEvent {
  final bool registered;
  RegisteredToggled(this.registered);
  @override List<Object?> get props => [registered];
}
class CacChanged extends SignupVendorEvent {
  final String value;
  CacChanged(this.value);
  @override List<Object?> get props => [value];
}
class LegalNameChanged extends SignupVendorEvent {
  final String value;
  LegalNameChanged(this.value);
  @override List<Object?> get props => [value];
}

// V2 — store details
class StoreNameChanged extends SignupVendorEvent {
  final String value;
  StoreNameChanged(this.value);
  @override List<Object?> get props => [value];
}
class PresenceChanged extends SignupVendorEvent {
  final Presence value;
  PresenceChanged(this.value);
  @override List<Object?> get props => [value];
}
class CategoryToggled extends SignupVendorEvent {
  final String category;
  CategoryToggled(this.category);
  @override List<Object?> get props => [category];
}

// V3 — location
class AddressChanged extends SignupVendorEvent {
  final String value;
  AddressChanged(this.value);
  @override List<Object?> get props => [value];
}
class CityChanged extends SignupVendorEvent {
  final String value;
  CityChanged(this.value);
  @override List<Object?> get props => [value];
}
class StateChangedVD extends SignupVendorEvent {
  final String value;
  StateChangedVD(this.value);
  @override List<Object?> get props => [value];
}
class MapsLinkChanged extends SignupVendorEvent {
  final String value;
  MapsLinkChanged(this.value);
  @override List<Object?> get props => [value];
}

// V4 — owner & login
class OwnerFirstChanged extends SignupVendorEvent {
  final String value;
  OwnerFirstChanged(this.value);
  @override List<Object?> get props => [value];
}
class OwnerLastChanged extends SignupVendorEvent {
  final String value;
  OwnerLastChanged(this.value);
  @override List<Object?> get props => [value];
}
class OwnerOtherChanged extends SignupVendorEvent {
  final String value;
  OwnerOtherChanged(this.value);
  @override List<Object?> get props => [value];
}
class OwnerPhoneChanged extends SignupVendorEvent {
  final String value;
  OwnerPhoneChanged(this.value);
  @override List<Object?> get props => [value];
}
class VendorEmailChanged extends SignupVendorEvent {
  final String value;
  VendorEmailChanged(this.value);
  @override List<Object?> get props => [value];
}

class DobChanged extends SignupVendorEvent {
  final DateTime? value;
  DobChanged(this.value);
  @override List<Object?> get props => [value];
}
class GenderChanged extends SignupVendorEvent {
  final Gender value;
  GenderChanged(this.value);
  @override List<Object?> get props => [value];
}


class NinChanged extends SignupVendorEvent {
  final String value;
  NinChanged(this.value);
  @override List<Object?> get props => [value];
}
class BvnChanged extends SignupVendorEvent {
  final String value;
  BvnChanged(this.value);
  @override List<Object?> get props => [value];
}

class VendorPasswordChanged extends SignupVendorEvent {
  final String value;
  VendorPasswordChanged(this.value);
  @override List<Object?> get props => [value];
}
class VendorConfirmChanged extends SignupVendorEvent {
  final String value;
  VendorConfirmChanged(this.value);
  @override List<Object?> get props => [value];
}
class ToggleVendorPassHidden extends SignupVendorEvent {}
class ToggleVendorConfHidden extends SignupVendorEvent {}

