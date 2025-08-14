import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'signup_vendor_event.dart';
import 'signup_vendor_state.dart';

class SignupVendorBloc extends Bloc<SignupVendorEvent, SignupVendorState> {
  SignupVendorBloc() : super(const SignupVendorState()) {
    on<SignupVendorInit>((e, emit) {});
    on<SignupVendorNextPressed>((e, emit) {
      final next = (state.pageIndex + 1).clamp(0, state.totalPages - 1);
      emit(state.copyWith(pageIndex: next));
    });
    on<SignupVendorBackPressed>((e, emit) {
      final prev = (state.pageIndex - 1).clamp(0, state.totalPages - 1);
      emit(state.copyWith(pageIndex: prev));
    });
    on<SignupVendorSubmitPressed>(_onSubmit);

    // V1
    on<RegisteredToggled>((e, emit) => emit(state.copyWith(registered: e.registered)));
    on<CacChanged>((e, emit) => emit(state.copyWith(cac: e.value)));
    on<LegalNameChanged>((e, emit) => emit(state.copyWith(legalName: e.value)));

    // V2
    on<StoreNameChanged>((e, emit) => emit(state.copyWith(storeName: e.value)));
    on<PresenceChanged>((e, emit) => emit(state.copyWith(presence: e.value)));
    on<CategoryToggled>((e, emit) {
      final list = List<String>.from(state.categories);
      list.contains(e.category) ? list.remove(e.category) : list.add(e.category);
      emit(state.copyWith(categories: list));
    });

    // V3
    on<AddressChanged>((e, emit) => emit(state.copyWith(address: e.value)));
    on<CityChanged>((e, emit) => emit(state.copyWith(city: e.value)));
    on<StateChangedVD>((e, emit) => emit(state.copyWith(stateName: e.value)));
    on<MapsLinkChanged>((e, emit) => emit(state.copyWith(mapsLink: e.value)));

    // V4
    on<OwnerFirstChanged>((e, emit) => emit(state.copyWith(ownerFirst: e.value)));
    on<OwnerLastChanged>((e, emit) => emit(state.copyWith(ownerLast: e.value)));
    on<OwnerOtherChanged>((e, emit) => emit(state.copyWith(ownerOther: e.value)));
    on<OwnerPhoneChanged>((e, emit) => emit(state.copyWith(ownerPhone: e.value)));
    
    on<DobChanged>((e, emit) => emit(state.copyWith(dob: e.value)));
    on<GenderChanged>((e, emit) => emit(state.copyWith(gender: e.value)));

    
    on<NinChanged>((e, emit) => emit(state.copyWith(nin: e.value)));
    on<BvnChanged>((e, emit) => emit(state.copyWith(bvn: e.value)));
    on<VendorEmailChanged>((e, emit) => emit(state.copyWith(email: e.value)));
    on<VendorPasswordChanged>((e, emit) => emit(state.copyWith(password: e.value)));
    on<VendorConfirmChanged>((e, emit) => emit(state.copyWith(confirm: e.value)));
    on<ToggleVendorPassHidden>((e, emit) => emit(state.copyWith(hidePass: !state.hidePass)));
    on<ToggleVendorConfHidden>((e, emit) => emit(state.copyWith(hideConf: !state.hideConf)));
  }

  Future<void> _onSubmit(SignupVendorSubmitPressed e, Emitter<SignupVendorState> emit) async {
    emit(state.copyWith(loading: true));
    await Future.delayed(const Duration(milliseconds: 900)); // UI-only
    emit(state.copyWith(loading: false));
  }
}

