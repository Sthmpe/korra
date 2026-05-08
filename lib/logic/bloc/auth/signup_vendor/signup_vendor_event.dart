import 'package:equatable/equatable.dart';

enum Presence { online, physical, both }

abstract class SignupVendorEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// --- Navigation ---
class SignupVendorInit extends SignupVendorEvent {}
class SignupVendorNextPressed extends SignupVendorEvent {}
class SignupVendorBackPressed extends SignupVendorEvent {}
class SignupVendorSubmitPressed extends SignupVendorEvent {}

// --- STEP 1: Personal Details ---
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

// --- STEP 2: Store Details & Social ---
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
class InstagramChanged extends SignupVendorEvent {
  final String value;
  InstagramChanged(this.value);
}
class TwitterChanged extends SignupVendorEvent {
  final String value;
  TwitterChanged(this.value);
}
class FacebookChanged extends SignupVendorEvent {
  final String value;
  FacebookChanged(this.value);
}
class TiktokChanged extends SignupVendorEvent {
  final String value;
  TiktokChanged(this.value);
}
class WebsiteChanged extends SignupVendorEvent {
  final String value;
  WebsiteChanged(this.value);
}
class WhatsappGroupChanged extends SignupVendorEvent {
  final String value;
  WhatsappGroupChanged(this.value);
}
class OtherLinkChanged extends SignupVendorEvent {
  final String value;
  OtherLinkChanged(this.value);
}

// --- STEP 3: Review ---
class TermsAgreementToggled extends SignupVendorEvent {
  final bool value;
  TermsAgreementToggled(this.value);
}