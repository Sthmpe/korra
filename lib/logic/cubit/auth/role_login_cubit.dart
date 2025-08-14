import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum KorraRole { customer, vendor }
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

class RoleLoginCubit extends Cubit<RoleLoginState> {
  RoleLoginCubit() : super(const RoleLoginState());

  void setRole(KorraRole r) => emit(state.copyWith(role: r));
  void setEmail(String v) => emit(state.copyWith(email: v));
  void setPassword(String v) => emit(state.copyWith(password: v));
  void togglePassword() => emit(state.copyWith(passwordHidden: !state.passwordHidden));

  // UI-only “loading” to simulate submit; real auth later
  Future<void> submit() async {
    if (state.loading) return;
    emit(state.copyWith(loading: true));
    await Future.delayed(const Duration(milliseconds: 900));
    emit(state.copyWith(loading: false));
  }

  // Biometric button UI feedback only; hook real auth later
  Future<void> biometrics() async {
    if (state.bioUi == BiometricUi.inProgress) return;
    emit(state.copyWith(bioUi: BiometricUi.pressed));
    await Future.delayed(const Duration(milliseconds: 120));
    emit(state.copyWith(bioUi: BiometricUi.inProgress));
    await Future.delayed(const Duration(milliseconds: 700));
    emit(state.copyWith(bioUi: BiometricUi.success));
    await Future.delayed(const Duration(milliseconds: 600));
    emit(state.copyWith(bioUi: BiometricUi.idle));
  }
}
