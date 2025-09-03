import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../data/repository/vendors/vendor_repository.dart';
import 'signup_vendor_event.dart';
import 'signup_vendor_state.dart';

typedef Emit = Emitter<SignupVendorState>;

class SignupVendorBloc extends Bloc<SignupVendorEvent, SignupVendorState> {
  // Gateways
  final VendorRepository vendors;
  final FunctionsClient fx;

  SignupVendorBloc({VendorRepository? vendorRepo, FunctionsClient? functions})
      : vendors = vendorRepo ?? VendorRepository(),
        fx = functions ?? Supabase.instance.client.functions,
        super(const SignupVendorState()) {
    // Navigation
    on<SignupVendorInit>(_onInit);
    on<SignupVendorNextPressed>(_onNext);
    on<SignupVendorBackPressed>(_onBack);
    on<SignupVendorSubmitPressed>(_onSubmit);

    // V1 — Business type
    on<RegisteredToggled>((e, emit) => emit(state.copyWith(registered: e.registered)));
    on<CacChanged>((e, emit) => emit(state.copyWith(cac: e.value)));
    on<LegalNameChanged>((e, emit) => emit(state.copyWith(legalName: e.value)));

    // V2 — Store details
    on<StoreNameChanged>((e, emit) => emit(state.copyWith(storeName: e.value)));
    on<PresenceChanged>((e, emit) => emit(state.copyWith(presence: e.value)));
    on<CategoryToggled>(_onCategoryToggled);

    // V3 — Location
    on<AddressChanged>((e, emit) => emit(state.copyWith(address: e.value)));
    on<CityChanged>((e, emit) => emit(state.copyWith(city: e.value)));
    on<StateChangedVD>((e, emit) => emit(state.copyWith(stateName: e.value)));
    on<MapsLinkChanged>((e, emit) => emit(state.copyWith(mapsLink: e.value)));

    // V4 — Personal
    on<OwnerFirstChanged>((e, emit) => emit(state.copyWith(ownerFirst: e.value)));
    on<OwnerLastChanged>((e, emit) => emit(state.copyWith(ownerLast: e.value)));
    on<OwnerOtherChanged>((e, emit) => emit(state.copyWith(ownerOther: e.value)));
    on<OwnerPhoneChanged>((e, emit) => emit(state.copyWith(ownerPhone: e.value)));
    on<DobChanged>((e, emit) => emit(state.copyWith(dob: e.value)));
    on<GenderChanged>((e, emit) => emit(state.copyWith(gender: e.value)));

    // V5 — Identity & security
    on<NinChanged>(_onNinChanged);
    on<BvnChanged>(_onBvnChanged);
    on<VendorEmailChanged>((e, emit) => emit(state.copyWith(email: e.value)));
    on<VendorPasswordChanged>((e, emit) => emit(state.copyWith(password: e.value)));
    on<VendorConfirmChanged>((e, emit) => emit(state.copyWith(confirm: e.value)));
    on<ToggleVendorPassHidden>((_, emit) => emit(state.copyWith(hidePass: !state.hidePass)));
    on<ToggleVendorConfHidden>((_, emit) => emit(state.copyWith(hideConf: !state.hideConf)));

    // KYC (explicit triggers if you keep standalone Verify buttons)
    on<VerifyBvnRequested>(_onVerifyBvn);
    on<VerifyNinRequested>(_onVerifyNin);
    on<ClearKycError>((_, emit) => emit(state.copyWith(kycError: null)));
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  void _onInit(SignupVendorInit event, Emit emit) {}

  void _onBack(SignupVendorBackPressed event, Emit emit) {
    final prev = (state.pageIndex - 1).clamp(0, state.totalPages - 1);
    emit(state.copyWith(pageIndex: prev));
  }

  /// On Identity step, verify only fields that need it; otherwise just advance.
  Future<void> _onNext(SignupVendorNextPressed event, Emit emit) async {
    const identityStepIndex = 4;
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

    if (state.ownerFirst.isEmpty || state.ownerLast.isEmpty || state.dob == null) {
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
        await _verifyNinViaFx(state.nin.trim());
        emit(state.copyWith(
          ninVerifying: false,
          ninVerified: true,
          lastVerifiedNin: state.nin.trim(),
        ));
      }

      if (bvnNeedsVerification) {
        emit(state.copyWith(bvnVerifying: true, bvnError: null, kycError: null));
        final fullName = '${state.ownerFirst} ${state.ownerLast}'.trim();
        final dobForBvn = _formatDobForBvn(state.dob);
        final localPhone = _normalizeNigerianMsisdn(state.ownerPhone);

        if (dobForBvn == null) {
          emit(state.copyWith(kycError: 'Date of birth is missing'));
          return;
        }

        await _verifyBvnViaFx(
          bvn: state.bvn.trim(),
          name: fullName,
          dateOfBirthIso: dobForBvn,
          mobileNo: localPhone,
        );
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

  // ── Submit (final) ─────────────────────────────────────────────────────────

  Future<void> _onSubmit(SignupVendorSubmitPressed event, Emit emit) async {
    if (!state.ninVerified || !state.bvnVerified) {
      emit(state.copyWith(kycError: 'Please verify both NIN and BVN first.'));
      return;
    }

    emit(state.copyWith(loading: true, kycError: null));
    try {
      await vendors.createVendorFromState(state);
      emit(state.copyWith(loading: false));
    } catch (error) {
      debugPrint('Error submitting vendor: $error');
      emit(state.copyWith(loading: false, kycError: error.toString()));
    }
  }

  // ── V2: categories (toggle, max 5) ─────────────────────────────────────────

  void _onCategoryToggled(CategoryToggled event, Emit emit) {
    final list = List<String>.from(state.categories);
    if (list.contains(event.category)) {
      list.remove(event.category);
    } else if (list.length < 5) {
      list.add(event.category);
    }
    emit(state.copyWith(categories: List.unmodifiable(list)));
  }

  // ── Identity field changes: reset verification when edited ─────────────────

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
    if (state.ownerFirst.isEmpty || state.ownerLast.isEmpty || state.dob == null) {
      emit(state.copyWith(kycError: 'Fill first name, last name, and date of birth.'));
      return;
    }

    emit(state.copyWith(ninVerifying: true, kycError: null));
    try {
      await _verifyNinViaFx(state.nin.trim());
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
    if (state.ownerFirst.isEmpty || state.ownerLast.isEmpty || state.dob == null) {
      emit(state.copyWith(kycError: 'Fill first name, last name, and date of birth.'));
      return;
    }

    emit(state.copyWith(bvnVerifying: true, kycError: null));
    try {
      final fullName = '${state.ownerFirst} ${state.ownerLast}'.trim();
      final dobIso = _formatDobForBvn(state.dob);
      final localPhone = _normalizeNigerianMsisdn(state.ownerPhone);

      if (dobIso == null) {
        emit(state.copyWith(kycError: 'Date of birth is missing'));
        return;
      }

      await _verifyBvnViaFx(
        bvn: state.bvn.trim(),
        name: fullName,
        dateOfBirthIso: dobIso,
        mobileNo: localPhone,
      );
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

  // ── Supabase Functions calls ───────────────────────────────────────────────
  Future<void> _verifyNinViaFx(String nin) async {
    // final res = await fx.invoke('nin-verify', body: {'nin': nin});
    // final data = res.data;
    // if (data is Map && data['ok'] == true) return;
    // throw Exception(
    //   (data is Map ? data['message'] ?? data['error'] : null) ??
    //       'NIN verification failed',
    // );
  }

  Future<void> _verifyBvnViaFx({
    required String bvn,
    required String name,
    required String dateOfBirthIso, // "YYYY-MM-DD"
    required String mobileNo,
  }) async {
    // final res = await fx.invoke(
    //   'bvn-verify',
    //   body: {
    //     'bvn': bvn,
    //     'name': name,
    //     'dateOfBirth': dateOfBirthIso, // function will convert to "DD-MMM-YYYY"
    //     'mobileNo': mobileNo,
    //   },
    // );
    // final data = res.data;
    // if (data is Map && data['ok'] == true) return;
    // throw Exception(
    //   (data is Map ? data['message'] ?? data['error'] : null) ??
    //       'BVN verification failed',
    // );
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