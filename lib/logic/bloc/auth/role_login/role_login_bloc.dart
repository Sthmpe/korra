import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'role_login_event.dart';
import 'role_login_state.dart';

class RoleLoginBloc extends Bloc<RoleLoginEvent, RoleLoginState> {
  RoleLoginBloc() : super(const RoleLoginState()) {
    on<RoleSelected>((e, emit) => emit(state.copyWith(role: e.role, failure: null, status: LoginStatus.idle)));
    on<EmailChanged>((e, emit) => emit(state.copyWith(email: e.email, failure: null, status: LoginStatus.idle)));
    on<PasswordChanged>((e, emit) => emit(state.copyWith(password: e.password, failure: null, status: LoginStatus.idle)));
    on<TogglePasswordVisibility>((e, emit) => emit(state.copyWith(passwordHidden: !state.passwordHidden)));

    on<SubmitPressed>(_onSubmitPressed);
    on<BiometricsPressed>(_onBiometricsPressed);
    on<FailureAcknowledged>((e, emit) => emit(state.copyWith(failure: null, status: LoginStatus.idle)));
  }

  Future<void> _onSubmitPressed(SubmitPressed e, Emitter<RoleLoginState> emit) async {
    if (state.loading || !state.isFormValid) return;
    emit(state.copyWith(loading: true, status: LoginStatus.submitting, failure: null));

    await Future.delayed(const Duration(milliseconds: 900));

    final email = state.email.toLowerCase();

    if (email.contains('fail')) {
      emit(state.copyWith(
        loading: false,
        status: LoginStatus.failure,
        failure: const KorraFailure(
          code: 'invalid_credentials',
          title: 'We couldn’t sign you in',
          message: 'Your email or password is incorrect. Double-check and try again, or reset your password.',
        ),
      ));
      return;
    }

    if (email.contains('offline')) {
      emit(state.copyWith(
        loading: false,
        status: LoginStatus.failure,
        failure: const KorraFailure(
          code: 'network_unavailable',
          title: 'No connection',
          message: 'We can’t reach Korra right now. Check your internet connection and try again.',
        ),
      ));
      return;
    }

    if (email.contains('blocked')) {
      emit(state.copyWith(
        loading: false,
        status: LoginStatus.failure,
        failure: const KorraFailure(
          code: 'too_many_attempts',
          title: 'Account temporarily locked',
          message: 'For your security, sign-in is paused. Try again in a few minutes or reset your password.',
        ),
      ));
      return;
    }

    // success
    emit(state.copyWith(loading: false, status: LoginStatus.success));
  }

  Future<void> _onBiometricsPressed(BiometricsPressed e, Emitter<RoleLoginState> emit) async {
    if (state.bioUi == BiometricUi.inProgress) return;
    emit(state.copyWith(bioUi: BiometricUi.pressed));
    await Future.delayed(const Duration(milliseconds: 120));
    emit(state.copyWith(bioUi: BiometricUi.inProgress));
    await Future.delayed(const Duration(milliseconds: 700));

    // mock success for now
    emit(state.copyWith(bioUi: BiometricUi.success));
    await Future.delayed(const Duration(milliseconds: 600));
    emit(state.copyWith(bioUi: BiometricUi.idle));
  }
}
