import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'forgot_password_event.dart';
import 'forgot_password_state.dart';

final FirebaseAuth auth = FirebaseAuth.instance;

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  ForgotPasswordBloc() : super(ForgotPasswordState.initial()) {
    on<FPEmailChanged>(_onEmailChanged);
    on<FPSubmit>(_onSubmit);
  }

  static final _emailRegex =
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$', caseSensitive: false);

  void _onEmailChanged(FPEmailChanged e, Emitter<ForgotPasswordState> emit) {
    final email = e.email.trim();
    emit(state.copyWith(
      email: email,
      isValid: _emailRegex.hasMatch(email),
      status: FPStatus.editing,
      error: null,
    ));
  }

  Future<void> _onSubmit(FPSubmit e, Emitter<ForgotPasswordState> emit) async {
    final email = state.email.trim();
    if (!state.isValid) {
      emit(state.copyWith(status: FPStatus.error, error: 'Enter a valid email.'));
      return;
    }
    emit(state.copyWith(status: FPStatus.submitting, error: null));
    auth.sendPasswordResetEmail(email: email);
    await Future<void>.delayed(const Duration(milliseconds: 250)); // UI-only shimmer
    emit(state.copyWith(status: FPStatus.sent));
  }
}
