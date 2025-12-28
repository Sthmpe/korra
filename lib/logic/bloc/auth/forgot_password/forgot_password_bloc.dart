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

    try {
      // ✅ FIX 1: Add 'await' so we actually wait for Firebase to talk to the server
      await auth.sendPasswordResetEmail(email: email);
      
      // ✅ FIX 2: Only emit success if the line above didn't throw an error
      emit(state.copyWith(status: FPStatus.sent));
      
    } on FirebaseAuthException catch (e) {
      // ✅ FIX 3: Catch Firebase specific errors (like 'user-not-found' or 'too-many-requests')
      // Note: For security, some projects don't reveal if a user exists, 
      // but catching the error is essential for debugging.
      emit(state.copyWith(status: FPStatus.error, error: e.message ?? "An error occurred"));
      
    } catch (e) {
      // Catch any other errors (like the App Check error)
      emit(state.copyWith(status: FPStatus.error, error: "Failed to send reset email."));
    }
  }
}
