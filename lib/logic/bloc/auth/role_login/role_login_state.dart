import 'package:equatable/equatable.dart';
import 'role_login_event.dart';

enum BiometricUi { idle, pressed, inProgress, success, failure }
enum LoginStatus { idle, submitting, success, failure }

class KorraFailure extends Equatable {
  final String code;     // e.g. invalid_credentials
  final String title;    // e.g. “We couldn’t sign you in”
  final String message;  // user-facing explanation
  const KorraFailure({required this.code, required this.title, required this.message});
  @override
  List<Object?> get props => [code, title, message];
}

class RoleLoginState extends Equatable {
  final String email;
  final String password;
  final KorraRole role;
  final bool passwordHidden;

  /// keep your old flag so existing widgets don’t break
  final bool loading;

  /// new status machine
  final LoginStatus status;

  /// premium error info (null when none)
  final KorraFailure? failure;

  final BiometricUi bioUi;

  const RoleLoginState({
    this.email = '',
    this.password = '',
    this.role = KorraRole.customer,
    this.passwordHidden = true,
    this.loading = false,
    this.status = LoginStatus.idle,
    this.failure,
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
    LoginStatus? status,
    KorraFailure? failure,
    BiometricUi? bioUi,
  }) {
    return RoleLoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      passwordHidden: passwordHidden ?? this.passwordHidden,
      loading: loading ?? this.loading,
      status: status ?? this.status,
      failure: failure,
      bioUi: bioUi ?? this.bioUi,
    );
  }

  @override
  List<Object?> get props =>
      [email, password, role, passwordHidden, loading, status, failure, bioUi];
}
