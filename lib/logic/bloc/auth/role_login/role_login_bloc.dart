import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'role_login_event.dart';
import 'role_login_state.dart';

class RoleLoginBloc extends Bloc<RoleLoginEvent, RoleLoginState> {
  RoleLoginBloc() : super(const RoleLoginState()) {
    on<RoleSelected>((e, emit) => emit(state.copyWith(role: e.role)));
    on<EmailChanged>((e, emit) => emit(state.copyWith(email: e.email)));
    on<PasswordChanged>((e, emit) => emit(state.copyWith(password: e.password)));
    on<TogglePasswordVisibility>(
      (e, emit) => emit(state.copyWith(passwordHidden: !state.passwordHidden)),
    );

    // UI-only submit (auth wiring comes later)
    on<SubmitPressed>(_onSubmitPressed);

    // UI-only biometrics animation
    on<BiometricsPressed>(_onBiometricsPressed);
  }

  Future<void> _onSubmitPressed(SubmitPressed e, Emitter<RoleLoginState> emit) async {
    if (state.loading || !state.isFormValid) return;
    emit(state.copyWith(loading: true));
    await Future.delayed(const Duration(milliseconds: 900));
    emit(state.copyWith(loading: false));
  }

  Future<void> _onBiometricsPressed(BiometricsPressed e, Emitter<RoleLoginState> emit) async {
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
