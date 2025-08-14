import 'package:equatable/equatable.dart';

enum KorraRole { customer, vendor }

abstract class RoleLoginEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class RoleSelected extends RoleLoginEvent {
  final KorraRole role;
  RoleSelected(this.role);
  @override List<Object?> get props => [role];
}

class EmailChanged extends RoleLoginEvent {
  final String email;
  EmailChanged(this.email);
  @override List<Object?> get props => [email];
}

class PasswordChanged extends RoleLoginEvent {
  final String password;
  PasswordChanged(this.password);
  @override List<Object?> get props => [password];
}

class TogglePasswordVisibility extends RoleLoginEvent {}

class SubmitPressed extends RoleLoginEvent {}

class BiometricsPressed extends RoleLoginEvent {}
