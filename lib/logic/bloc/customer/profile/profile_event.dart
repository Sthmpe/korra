import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProfileStarted extends ProfileEvent {}
class ProfileRefreshed extends ProfileEvent {}

class ToggleAutopayDefault extends ProfileEvent {
  final bool value;
  ToggleAutopayDefault(this.value);
  @override List<Object?> get props => [value];
}

class ToggleBiometrics extends ProfileEvent {
  final bool value;
  ToggleBiometrics(this.value);
  @override List<Object?> get props => [value];
}

class TogglePushNotif extends ProfileEvent {
  final bool value;
  TogglePushNotif(this.value);
  @override List<Object?> get props => [value];
}

class ToggleEmailNotif extends ProfileEvent {
  final bool value;
  ToggleEmailNotif(this.value);
  @override List<Object?> get props => [value];
}

class ToggleSmsNotif extends ProfileEvent {
  final bool value;
  ToggleSmsNotif(this.value);
  @override List<Object?> get props => [value];
}

class ChangeReminderCadence extends ProfileEvent {
  final String value;
  ChangeReminderCadence(this.value);
  @override List<Object?> get props => [value];
}

class LogoutRequested extends ProfileEvent {}
class DeleteAccountRequested extends ProfileEvent {}
