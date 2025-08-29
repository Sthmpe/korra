import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/repository/monnify_repository.dart';
import 'signup_vendor_event.dart';
import 'signup_vendor_state.dart';

typedef Emit = Emitter<SignupVendorState>;

class SignupVendorBloc extends Bloc<SignupVendorEvent, SignupVendorState> {
  final MonnifyRepository monnify;
  

  SignupVendorBloc({MonnifyRepository? monnifyRepo})
    : monnify = monnifyRepo ?? MonnifyRepository(),
      super(const SignupVendorState()) {
    on<SignupVendorInit>((e, emit) {});
    on<SignupVendorNextPressed>(_onNext);
    on<SignupVendorBackPressed>((e, emit) {
      final prev = (state.pageIndex - 1).clamp(0, state.totalPages - 1);
      emit(state.copyWith(pageIndex: prev));
    });
    on<SignupVendorSubmitPressed>(_onSubmit);

    // V1
    on<RegisteredToggled>(
      (e, emit) => emit(state.copyWith(registered: e.registered)),
    );
    on<CacChanged>((e, emit) => emit(state.copyWith(cac: e.value)));
    on<LegalNameChanged>((e, emit) => emit(state.copyWith(legalName: e.value)));

    // V2
    on<StoreNameChanged>((e, emit) => emit(state.copyWith(storeName: e.value)));
    on<PresenceChanged>((e, emit) => emit(state.copyWith(presence: e.value)));
    on<CategoryToggled>((e, emit) {
      final list = List<String>.from(state.categories);
      if (list.contains(e.category)) {
        list.remove(e.category);
      } else if (list.length < 5) {
        list.add(e.category);
      }
      emit(state.copyWith(categories: List.unmodifiable(list)));
    });

    // V3
    on<AddressChanged>((e, emit) => emit(state.copyWith(address: e.value)));
    on<CityChanged>((e, emit) => emit(state.copyWith(city: e.value)));
    on<StateChangedVD>((e, emit) => emit(state.copyWith(stateName: e.value)));
    on<MapsLinkChanged>((e, emit) => emit(state.copyWith(mapsLink: e.value)));

    // V4
    on<OwnerFirstChanged>(
      (e, emit) => emit(state.copyWith(ownerFirst: e.value)),
    );
    on<OwnerLastChanged>((e, emit) => emit(state.copyWith(ownerLast: e.value)));
    on<OwnerOtherChanged>(
      (e, emit) => emit(state.copyWith(ownerOther: e.value)),
    );
    on<OwnerPhoneChanged>(
      (e, emit) => emit(state.copyWith(ownerPhone: e.value)),
    );

    on<DobChanged>((e, emit) => emit(state.copyWith(dob: e.value)));
    on<GenderChanged>((e, emit) => emit(state.copyWith(gender: e.value)));

    
on<NinChanged>((e, emit) {
  final changed = e.value != state.nin;
  emit(state.copyWith(
    nin: e.value,
    ninError: null,
    // if value changed, we must re-verify NIN later
    ninVerified: changed ? false : state.ninVerified,
    // and forget last verified value for NIN
    lastVerifiedNin: changed ? null : state.lastVerifiedNin,
  ));
});

on<BvnChanged>((e, emit) {
  final changed = e.value != state.bvn;
  emit(state.copyWith(
    bvn: e.value,
    bvnError: null,
    bvnVerified: changed ? false : state.bvnVerified,
    lastVerifiedBvn: changed ? null : state.lastVerifiedBvn,
  ));
});
    on<VendorEmailChanged>((e, emit) => emit(state.copyWith(email: e.value)));
    on<VendorPasswordChanged>(
      (e, emit) => emit(state.copyWith(password: e.value)),
    );
    on<VendorConfirmChanged>(
      (e, emit) => emit(state.copyWith(confirm: e.value)),
    );
    on<ToggleVendorPassHidden>(
      (e, emit) => emit(state.copyWith(hidePass: !state.hidePass)),
    );
    on<ToggleVendorConfHidden>(
      (e, emit) => emit(state.copyWith(hideConf: !state.hideConf)),
    );

    on<VerifyBvnRequested>(_onVerifyBvn);
    on<VerifyNinRequested>(_onVerifyNin);
    on<ClearKycError>((e, emit) => emit(state.copyWith(kycError: null)));
  }

  Future<void> _onSubmit(
    SignupVendorSubmitPressed e,
    Emitter<SignupVendorState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    await Future.delayed(const Duration(milliseconds: 900)); // UI-only
    emit(state.copyWith(loading: false));
  }

  // Format "03-Oct-1993" for Monnify
  String _fmtDob(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day.toString().padLeft(2,'0')}-${months[d.month-1]}-${d.year}';
  }

  // Normalize phone to 11-digit local (Monnify BVN match often expects that)
  String _normalizeNgLocal(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('234')) return '0${digits.substring(3)}'; // 23480... -> 080...
    if (digits.length == 10) return '0$digits';
    if (digits.length == 11 && digits.startsWith('0')) return digits;
    return digits; // fallback
  }

  Future<void> _onNext(SignupVendorNextPressed e, Emit emit) async {
  const identityIndex = 4; // StepIdentity index in your PageView

  // If not on Identity, normal next
  if (state.pageIndex != identityIndex) {
    final next = (state.pageIndex + 1).clamp(0, state.totalPages - 1);
    emit(state.copyWith(pageIndex: next));
    return;
  }

  // Identity: verify only what’s needed (unchanged + already-verified are skipped)
  final ninNeeded = !(state.ninVerified && state.lastVerifiedNin == state.nin);
  final bvnNeeded = !(state.bvnVerified && state.lastVerifiedBvn == state.bvn);

  // If nothing needed, just go next
  if (!ninNeeded && !bvnNeeded) {
    final next = (state.pageIndex + 1).clamp(0, state.totalPages - 1);
    emit(state.copyWith(pageIndex: next));
    return;
  }

  // Basic guards
  if (state.ownerFirst.isEmpty || state.ownerLast.isEmpty || state.dob == null) {
    emit(state.copyWith(kycError: 'Fill first/last name and DOB first'));
    return;
  }
  if (ninNeeded && state.nin.trim().length != 11) {
    emit(state.copyWith(ninError: 'Enter valid 11-digit NIN')); return;
  }
  if (bvnNeeded && state.bvn.trim().length != 11) {
    emit(state.copyWith(bvnError: 'Enter valid 11-digit BVN')); return;
  }

  try {
    // 1) NIN
    if (ninNeeded) {
      emit(state.copyWith(ninVerifying: true, ninError: null, kycError: null));
      await monnify.verifyNIN(state.nin.trim());
      emit(state.copyWith(
        ninVerifying: false,
        ninVerified: true,
        lastVerifiedNin: state.nin.trim(),
      ));
    }

    // 2) BVN
    if (bvnNeeded) {
      emit(state.copyWith(bvnVerifying: true, bvnError: null, kycError: null));

      final name  = '${state.ownerFirst} ${state.ownerLast}'.trim();
      final dob   = _fmtDob(state.dob!);
      final phone = _normalizeNgLocal(state.ownerPhone);

      await monnify.verifyBVN(
        bvn: state.bvn.trim(),
        name: name,
        dateOfBirth: dob,
        mobileNo: phone,
      );

      emit(state.copyWith(
        bvnVerifying: false,
        bvnVerified: true,
        lastVerifiedBvn: state.bvn.trim(),
      ));
    }

    // Success → advance
    final next = (state.pageIndex + 1).clamp(0, state.totalPages - 1);
    emit(state.copyWith(pageIndex: next));
  } catch (ex) {
    // Fail the one that was running; keep the other intact
    if (state.ninVerifying) {
      emit(state.copyWith(
        ninVerifying: false,
        ninVerified: false,
        ninError: ex.toString(),
      ));
    } else if (state.bvnVerifying) {
      emit(state.copyWith(
        bvnVerifying: false,
        bvnVerified: false,
        bvnError: ex.toString(),
      ));
    } else {
      emit(state.copyWith(kycError: ex.toString()));
    }
  }
}

  Future<void> _onVerifyBvn(VerifyBvnRequested e, Emitter<SignupVendorState> emit) async {
    if (state.bvn.trim().isEmpty)  { emit(state.copyWith(kycError: 'Enter BVN')); return; }
    if (state.ownerFirst.isEmpty || state.ownerLast.isEmpty || state.dob == null) {
      emit(state.copyWith(kycError: 'Fill first/last name and DOB first')); return;
    }
    emit(state.copyWith(bvnVerifying: true, kycError: null));
    try {
      final name = '${state.ownerFirst} ${state.ownerLast}';
      final dob  = _fmtDob(state.dob!);
      final phone = _normalizeNgLocal(state.ownerPhone);

      await monnify.verifyBVN(
        bvn: state.bvn.trim(),
        name: name,
        dateOfBirth: dob,
        mobileNo: phone,
      );

      emit(state.copyWith(bvnVerifying: false, bvnVerified: true));
    } catch (ex) {
      emit(state.copyWith(bvnVerifying: false, bvnVerified: false, kycError: ex.toString()));
    }
  }

  Future<void> _onVerifyNin(VerifyNinRequested e, Emitter<SignupVendorState> emit) async {
    if (state.nin.trim().isEmpty)  { emit(state.copyWith(kycError: 'Enter NIN')); return; }
    if (state.ownerFirst.isEmpty || state.ownerLast.isEmpty || state.dob == null) {
      emit(state.copyWith(kycError: 'Fill first/last name and DOB first')); return;
    }
    emit(state.copyWith(ninVerifying: true, kycError: null));
    try {
      await monnify.verifyNIN(state.nin.trim());
      emit(state.copyWith(ninVerifying: false, ninVerified: true));
    } catch (ex) {
      emit(state.copyWith(ninVerifying: false, ninVerified: false, kycError: ex.toString()));
    }
  }
}
















