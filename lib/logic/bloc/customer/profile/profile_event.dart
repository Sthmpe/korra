import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Load & Refresh
class ProfileStarted extends ProfileEvent {}
class ProfileRefreshed extends ProfileEvent {}

// Only keep the ONE active preference
class ChangeReminderCadence extends ProfileEvent {
  final String value;
  ChangeReminderCadence(this.value);
  @override List<Object?> get props => [value];
}

// Auth Actions
class LogoutRequested extends ProfileEvent {}
class DeleteAccountRequested extends ProfileEvent {}