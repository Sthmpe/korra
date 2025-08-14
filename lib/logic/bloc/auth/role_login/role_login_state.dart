import 'package:equatable/equatable.dart';
import 'role_login_event.dart';

enum BiometricUi { idle, pressed, inProgress, success, failure }

class RoleLoginState extends Equatable {
  final String email;
  final String password;
  final KorraRole role;
  final bool passwordHidden;
  final bool loading;
  final BiometricUi bioUi;

  const RoleLoginState({
    this.email = '',
    this.password = '',
    this.role = KorraRole.customer,
    this.passwordHidden = true,
    this.loading = false,
    this.bioUi = BiometricUi.idle,
  });

  bool get isValidEmail =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim());
  bool get isFormValid => isValidEmail && password.length >= 6;

  RoleLoginState copyWith({
    String? email,
    String? password,
    KorraRole? role,
    bool? passwordHidden,
    bool? loading,
    BiometricUi? bioUi,
  }) {
    return RoleLoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      passwordHidden: passwordHidden ?? this.passwordHidden,
      loading: loading ?? this.loading,
      bioUi: bioUi ?? this.bioUi,
    );
  }

  @override
  List<Object?> get props => [email, password, role, passwordHidden, loading, bioUi];
}
