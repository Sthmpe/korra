import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korra/data/repository/customer/customer_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/utils/korra_exception.dart';
import 'signup_customer_event.dart';
import 'signup_customer_state.dart';

typedef Emit = Emitter<SignupCustomerState>;

class SignupCustomerBloc
    extends Bloc<SignupCustomerEvent, SignupCustomerState> {
  // Gateways
  final CustomerRepository _customerRepo;
  final FunctionsClient fx;

  SignupCustomerBloc({
    CustomerRepository? customerRepo,
    FunctionsClient? functions,
  }) : _customerRepo = customerRepo ?? CustomerRepository(),
       fx = functions ?? Supabase.instance.client.functions,
       super(const SignupCustomerState()) {
    on<SignupCustomerInit>(_onInit);
    on<SignupCustomerNextPressed>(_onNext);
    on<SignupCustomerBackPressed>(_onBack);
    on<SignupCustomerSubmitPressed>(_onSubmit);

    // step 1
    on<FirstNameChanged>((e, emit) => emit(state.copyWith(firstName: e.value)));
    on<LastNameChanged>((e, emit) => emit(state.copyWith(lastName: e.value)));
    on<OtherNameChanged>((e, emit) => emit(state.copyWith(otherName: e.value)));
    on<PhoneChanged>((e, emit) => emit(state.copyWith(phone: e.value)));
    on<EmailChangedCU>(_onEmailChanged);
  }

  Future<void> _onSubmit(
    SignupCustomerSubmitPressed e,
    Emitter<SignupCustomerState> emit,
  ) async {
    emit(
      state.copyWith(
        loading: true,
        signUpError: null,
        status: SignupStatus.loading,
      ),
    );
    try {
      final uid = await _customerRepo.createCustomerFromState(state);

      await FirebaseAnalytics.instance.logEvent(
        name: 'sign_up',
        parameters: {'method': 'email', 'role': 'customer'},
      );

      emit(
        state.copyWith(loading: false, status: SignupStatus.success, uid: uid),
      );
    } catch (error) {
      debugPrint('❌ Error submitting customer (Technical): $error');

      // Use the professional message if it's a KorraException, otherwise generic.
      String userMessage = 'Account setup failed. Please try again.';
      if (error is KorraException) {
        userMessage = error.message;
      }

      await FirebaseAnalytics.instance.logEvent(
        name: 'signup_failed',
        parameters: {'role': 'customer', 'error_message': userMessage},
      );

      emit(
        state.copyWith(
          loading: false,
          signUpError: userMessage,
          status: SignupStatus.failure,
        ),
      );
    }
  }

  void _onInit(SignupCustomerInit event, Emit emit) {}


  void _onBack(SignupCustomerBackPressed event, Emit emit) {
    final prev = (state.pageIndex - 1).clamp(0, state.totalPages - 1);
    emit(state.copyWith(pageIndex: prev));
  }

  /// On Identity step, verify only fields that need it; otherwise just advance.
  Future<void> _onNext(SignupCustomerNextPressed event, Emit emit) async {
    final next = (state.pageIndex + 1).clamp(0, state.totalPages - 1);

    // --- STEP 0: PERSONAL DETAILS (Validation Logic) ---
     if (state.pageIndex == 0) {
      if (state.firstName.trim().isEmpty || state.lastName.trim().isEmpty) return;
      
      // Block if phone is empty or NOT verified
      if (state.phone.trim().isEmpty) return;
    }

    emit(state.copyWith(pageIndex: next));
  }

  void _onEmailChanged(EmailChangedCU event, Emitter<SignupCustomerState> emit) {
    emit(state.copyWith(email: event.value));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String? _formatDobForBvn(DateTime? date) {
    if (date == null) return null;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dd = date.day.toString().padLeft(2, '0');
    final mmm = months[date.month - 1];
    final yyyy = date.year.toString().padLeft(4, '0');
    return '$dd-$mmm-$yyyy'; // e.g., 03-Oct-1993
  }
}