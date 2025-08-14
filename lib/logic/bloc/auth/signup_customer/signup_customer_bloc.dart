import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'signup_customer_event.dart';
import 'signup_customer_state.dart';

class SignupCustomerBloc extends Bloc<SignupCustomerEvent, SignupCustomerState> {
  SignupCustomerBloc() : super(const SignupCustomerState()) {
    on<SignupCustomerInit>((e, emit) { /* no-op for now */ });

    on<SignupCustomerNextPressed>((e, emit) {
      final next = (state.pageIndex + 1).clamp(0, state.totalPages - 1);
      emit(state.copyWith(pageIndex: next));
    });

    on<SignupCustomerBackPressed>((e, emit) {
      final prev = (state.pageIndex - 1).clamp(0, state.totalPages - 1);
      emit(state.copyWith(pageIndex: prev));
    });

    on<SignupCustomerSubmitPressed>(_onSubmit);

    // step 1
    on<FirstNameChanged>((e, emit) => emit(state.copyWith(firstName: e.value)));
    on<LastNameChanged>((e, emit) => emit(state.copyWith(lastName: e.value)));
    on<OtherNameChanged>((e, emit) => emit(state.copyWith(otherName: e.value)));
    on<PhoneChanged>((e, emit) => emit(state.copyWith(phone: e.value)));
    on<EmailChangedCU>((e, emit) => emit(state.copyWith(email: e.value)));
    on<DobChanged>((e, emit) => emit(state.copyWith(dob: e.value)));
    on<GenderChanged>((e, emit) => emit(state.copyWith(gender: e.value)));

    // step 2
    on<NinChanged>((e, emit) => emit(state.copyWith(nin: e.value)));
    on<BvnChanged>((e, emit) => emit(state.copyWith(bvn: e.value)));

    // step 3
    on<PasswordChangedCU>((e, emit) => emit(state.copyWith(password: e.value)));
    on<ConfirmPasswordChangedCU>((e, emit) => emit(state.copyWith(confirm: e.value)));
    on<TogglePasswordVisibilityCU>((e, emit) =>
        emit(state.copyWith(hidePassword: !state.hidePassword)));
    on<ToggleConfirmVisibilityCU>((e, emit) =>
        emit(state.copyWith(hideConfirm: !state.hideConfirm)));
  }

  Future<void> _onSubmit(SignupCustomerSubmitPressed e, Emitter<SignupCustomerState> emit) async {
    emit(state.copyWith(loading: true));
    await Future.delayed(const Duration(milliseconds: 900)); // UI-only
    emit(state.copyWith(loading: false));
  }
}
