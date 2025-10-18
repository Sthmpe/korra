import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'signup_customer_event.dart';
import 'signup_customer_state.dart';

typedef Emit = Emitter<SignupCustomerState>;

class SignupCustomerBloc extends Bloc<SignupCustomerEvent, SignupCustomerState> {
  SignupCustomerBloc() : super(const SignupCustomerState()) {
    on<SignupCustomerInit>(_onInit);
    on<SignupCustomerNextPressed>(_onNext);
    on<SignupCustomerBackPressed>(_onBack);
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
    on<NinChanged>(_onNinChanged);
    on<BvnChanged>(_onBvnChanged);

    // step 3
    on<PasswordChangedCU>((e, emit) => emit(state.copyWith(password: e.value)));
    on<ConfirmPasswordChangedCU>((e, emit) => emit(state.copyWith(confirm: e.value)));
    on<TogglePasswordVisibilityCU>((e, emit) =>
        emit(state.copyWith(hidePassword: !state.hidePassword)));
    on<ToggleConfirmVisibilityCU>((e, emit) =>
        emit(state.copyWith(hideConfirm: !state.hideConfirm)));

    // KYC (explicit triggers if you keep standalone Verify buttons)
    on<VerifyBvnRequested>(_onVerifyBvn);
    on<VerifyNinRequested>(_onVerifyNin);
    on<ClearKycError>((_, emit) => emit(state.copyWith(kycError: null)));
  }

  Future<void> _onSubmit(SignupCustomerSubmitPressed e, Emitter<SignupCustomerState> emit) async {
    if (!state.ninVerified && !state.bvnVerified) {
      emit(state.copyWith(kycError: 'Please verify either NIN or BVN first.'));
      return;
    }

    emit(state.copyWith(loading: true));
    await Future.delayed(const Duration(milliseconds: 900)); // UI-only
    emit(state.copyWith(loading: false));
  }

  void _onInit(SignupCustomerInit event, Emit emit) {}

  void _onBack(SignupCustomerBackPressed event, Emit emit) {
    final prev = (state.pageIndex - 1).clamp(0, state.totalPages - 1);
    emit(state.copyWith(pageIndex: prev));
  }

  /// On Identity step, verify only fields that need it; otherwise just advance.
  Future<void> _onNext(SignupCustomerNextPressed event, Emit emit) async {
    const identityStepIndex = 1;
    final next = (state.pageIndex + 1).clamp(0, state.totalPages - 1);

    if (state.pageIndex != identityStepIndex) {
      emit(state.copyWith(pageIndex: next));
      return;
    }

    final ninNeedsVerification = !(state.ninVerified && state.lastVerifiedNin == state.nin);
    final bvnNeedsVerification = !(state.bvnVerified && state.lastVerifiedBvn == state.bvn);

    if (!ninNeedsVerification && !bvnNeedsVerification) {
      emit(state.copyWith(pageIndex: next));
      return;
    }

    if (state.firstName.isEmpty || state.lastName.isEmpty || state.dob == null) {
      emit(state.copyWith(kycError: 'Fill first name, last name, and date of birth.'));
      return;
    }

    if (ninNeedsVerification && state.nin.trim().length != 11) {
      emit(state.copyWith(ninError: 'Enter a valid 11-digit NIN'));
      return;
    }

    if (bvnNeedsVerification && state.bvn.trim().length != 11) {
      emit(state.copyWith(bvnError: 'Enter a valid 11-digit BVN'));
      return;
    }

    try {
      if (ninNeedsVerification) {
        emit(state.copyWith(ninVerifying: true, ninError: null, kycError: null));
        
        // await vendors.verifyNin(state.nin.trim());
        emit(state.copyWith(
          ninVerifying: false,
          ninVerified: true,
          lastVerifiedNin: state.nin.trim(),
        ));
      }

      if (bvnNeedsVerification) {
        emit(state.copyWith(bvnVerifying: true, bvnError: null, kycError: null));
        // final fullName = '${state.ownerFirst} ${state.ownerLast}'.trim();
        final dobForBvn = _formatDobForBvn(state.dob);
        // final localPhone = _normalizeNigerianMsisdn(state.ownerPhone);

        if (dobForBvn == null) {
          emit(state.copyWith(kycError: 'Date of birth is missing'));
          return;
        }

        // await vendors.verifyBvn(
        //   bvn: state.bvn.trim(),
        //   name: fullName,
        //   dateOfBirthIso: dobForBvn,
        //   mobileNo: localPhone,
        // );
        emit(state.copyWith(
          bvnVerifying: false,
          bvnVerified: true,
          lastVerifiedBvn: state.bvn.trim(),
        ));
      }

      emit(state.copyWith(pageIndex: next));
    } catch (error) {
      debugPrint('Error during KYC verification: $error');
      if (state.ninVerifying) {
        emit(state.copyWith(
          ninVerifying: false,
          ninVerified: false,
          ninError: error.toString(),
        ));
      } else if (state.bvnVerifying) {
        emit(state.copyWith(
          bvnVerifying: false,
          bvnVerified: false,
          bvnError: error.toString(),
        ));
      } else {
        emit(state.copyWith(kycError: error.toString()));
      }
    }
  }

  void _onNinChanged(NinChanged event, Emit emit) {
    final changed = event.value != state.nin;
    emit(state.copyWith(
      nin: event.value,
      ninError: null,
      ninVerified: changed ? false : state.ninVerified,
      lastVerifiedNin: changed ? null : state.lastVerifiedNin,
    ));
  }

  void _onBvnChanged(BvnChanged event, Emit emit) {
    final changed = event.value != state.bvn;
    emit(state.copyWith(
      bvn: event.value,
      bvnError: null,
      bvnVerified: changed ? false : state.bvnVerified,
      lastVerifiedBvn: changed ? null : state.lastVerifiedBvn,
    ));
  }

  // ── Optional explicit KYC triggers (if you keep buttons) ───────────────────
  Future<void> _onVerifyNin(VerifyNinRequested event, Emit emit) async {
    if (state.nin.trim().isEmpty) {
      emit(state.copyWith(kycError: 'Enter NIN'));
      return;
    }
    if (state.firstName.isEmpty || state.lastName.isEmpty || state.dob == null) {
      emit(state.copyWith(kycError: 'Fill first name, last name, and date of birth.'));
      return;
    }

    emit(state.copyWith(ninVerifying: true, kycError: null));
    try {
      // await vendors.verifyNin(state.nin.trim());
      emit(state.copyWith(
        ninVerifying: false,
        ninVerified: true,
        lastVerifiedNin: state.nin.trim(),
      ));
    } catch (error) {
      debugPrint('Error verifying NIN: $error');
      emit(state.copyWith(
        ninVerifying: false,
        ninVerified: false,
        kycError: error.toString(),
      ));
    }
  }

  Future<void> _onVerifyBvn(VerifyBvnRequested event, Emit emit) async {
    if (state.bvn.trim().isEmpty) {
      emit(state.copyWith(kycError: 'Enter BVN'));
      return;
    }
    if (state.firstName.isEmpty || state.lastName.isEmpty || state.dob == null) {
      emit(state.copyWith(kycError: 'Fill first name, last name, and date of birth.'));
      return;
    }

    emit(state.copyWith(bvnVerifying: true, kycError: null));
    try {
      final fullName = '${state.firstName} ${state.lastName}'.trim();
      final dobIso = _formatDobForBvn(state.dob);
      final localPhone = _normalizeNigerianMsisdn(state.phone);

      if (dobIso == null) {
        emit(state.copyWith(kycError: 'Date of birth is missing'));
        return;
      }

      // await vendors.verifyBvn(
      //   bvn: state.bvn.trim(),
      //   name: fullName,
      //   dateOfBirthIso: dobIso,
      //   mobileNo: localPhone,
      // );
      emit(state.copyWith(
        bvnVerifying: false,
        bvnVerified: true,
        lastVerifiedBvn: state.bvn.trim(),
      ));
    } catch (error) {
      debugPrint('Error verifying BVN: $error');
      emit(state.copyWith(
        bvnVerifying: false,
        bvnVerified: false,
        kycError: error.toString(),
      ));
    }
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

  String _normalizeNigerianMsisdn(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('234')) return '0${digits.substring(3)}';
    if (digits.length == 10) return '0$digits';
    if (digits.length == 11 && digits.startsWith('0')) return digits;
    return digits;
  }
}
