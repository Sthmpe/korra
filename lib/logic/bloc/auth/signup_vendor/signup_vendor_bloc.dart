import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/utils/korra_exception.dart';
import '../../../../data/repository/vendors/vendor_repository.dart';
import 'signup_vendor_event.dart';
import 'signup_vendor_state.dart';

typedef Emit = Emitter<SignupVendorState>;

class SignupVendorBloc extends Bloc<SignupVendorEvent, SignupVendorState> {
  // Gateways
  final VendorRepository _vendorsRepo;
  final FunctionsClient fx;

  SignupVendorBloc({VendorRepository? vendorRepo, FunctionsClient? functions})
      : _vendorsRepo = vendorRepo ?? VendorRepository(),
        fx = functions ?? Supabase.instance.client.functions,
        super(const SignupVendorState()) {
    // Navigation
    on<SignupVendorInit>((_, emit) {});
    on<SignupVendorNextPressed>(_onNext);
    on<SignupVendorBackPressed>(_onBack);
    on<SignupVendorSubmitPressed>(_onSubmit);

    
    // Step 1: Personal
    on<OwnerFirstChanged>((e, emit) => emit(state.copyWith(firstName: e.value)));
    on<OwnerLastChanged>((e, emit) => emit(state.copyWith(lastName: e.value)));
    on<OwnerOtherChanged>((e, emit) => emit(state.copyWith(otherName: e.value)));
    on<OwnerPhoneChanged>(_onPhoneChanged);

    // Step 2: Store Details
    on<StoreNameChanged>((e, emit) => emit(state.copyWith(storeName: e.value)));
    on<PresenceChanged>((e, emit) => emit(state.copyWith(presence: e.value)));
    on<CategoryToggled>(_onCategoryToggled);

    // Step 3: Socials & Terms
    on<TermsAgreementToggled>((e, emit) => emit(state.copyWith(toggled: e.value)));
    on<InstagramChanged>((e, emit) => emit(state.copyWith(instagram: e.value)));
    on<TwitterChanged>((e, emit) => emit(state.copyWith(twitter: e.value)));
    on<FacebookChanged>((e, emit) => emit(state.copyWith(facebook: e.value)));
    on<TiktokChanged>((e, emit) => emit(state.copyWith(tiktok: e.value)));
    on<WebsiteChanged>((e, emit) => emit(state.copyWith(website: e.value)));
    on<WhatsappGroupChanged>((e, emit) => emit(state.copyWith(whatsappGroup: e.value)));
    on<OtherLinkChanged>((e, emit) => emit(state.copyWith(otherLink: e.value)));
  }

  // ── Navigation & Validation ────────────────────────────────────────────────
  void _onBack(SignupVendorBackPressed event, Emit emit) {
    final prev = (state.pageIndex - 1).clamp(0, state.totalPages - 1);
    emit(state.copyWith(pageIndex: prev));
  }

  void _onNext(SignupVendorNextPressed event, Emit emit) {
    final next = (state.pageIndex + 1).clamp(0, state.totalPages - 1);

    // --- STEP 1: PERSONAL DETAILS ---
    if (state.pageIndex == 0) {
      if (state.firstName.trim().isEmpty || state.lastName.trim().isEmpty) return;
      
      // Block if phone is empty or NOT verified
      if (state.phone.trim().isEmpty) return;
    }

    // --- STEP 2: STORE DETAILS ---
    if (state.pageIndex == 1) {
      if (state.storeName.trim().isEmpty) return;
      if (state.categories.isEmpty) return;
    }

    emit(state.copyWith(pageIndex: next));
  }

  // ── Phone Verification Logic ───────────────────────────────────────────────
  Future<void> _onPhoneChanged(OwnerPhoneChanged event, Emit emit) async {
    final phone = event.value.trim();
    
    // Reset verification state if they edit the number
    emit(state.copyWith(
      phone: phone,
    ));

    // Only check DB if it looks like a full Nigerian number (10 or 11 digits)
    if (phone.length == 11) {
      emit(state.copyWith(phoneChecking: true));
      try {
        // NOTE: Ensure your repo has `checkCollectionForPhone` matching the email one
        final inVendors = await _vendorsRepo.checkCollectionForPhone('vendors', phone);

        if (inVendors) {
          emit(state.copyWith(
            phoneChecking: false,
            phoneError: 'Phone number already registered as a Merchant.',
          ));
        } else {
          emit(state.copyWith(phoneChecking: false, phoneUnused: true));
        }
      } catch (e) {
        emit(state.copyWith(phoneChecking: false, phoneError: 'Error checking number.'));
      }
    }
  }

  // ── Store Logic ────────────────────────────────────────────────────────────
  void _onCategoryToggled(CategoryToggled event, Emit emit) {
    final list = List<String>.from(state.categories);
    if (list.contains(event.category)) {
      list.remove(event.category);
    } else if (list.length < 5) {
      list.add(event.category);
    }
    emit(state.copyWith(categories: List.unmodifiable(list)));
  }

  // ── Final Submit ───────────────────────────────────────────────────────────
  Future<void> _onSubmit(SignupVendorSubmitPressed event, Emit emit) async {
    emit(state.copyWith(loading: true, signUpError: null, status: SignupStatus.loading));
    try {
      final uid = await _vendorsRepo.createVendorFromState(state);
      emit(state.copyWith(loading: false, status: SignupStatus.success, uid: uid));
    } catch (error) {
      debugPrint('❌ Error submitting customer (Technical): $error');

      // Use the professional message if it's a KorraException, otherwise generic.
      String userMessage = 'Account setup failed. Please try again.';
      if (error is KorraException) {
        userMessage = error.message;
      }
      emit(state.copyWith(loading: false, signUpError: userMessage, status: SignupStatus.failure));
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

}