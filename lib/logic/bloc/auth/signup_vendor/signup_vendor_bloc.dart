import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korra/data/repository/vendors/verification_repository.dart';
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
    on<SignupVendorInit>(_onInit);
    on<SignupVendorNextPressed>(_onNext);
    on<SignupVendorBackPressed>(_onBack);
    on<SignupVendorSubmitPressed>(_onSubmit);

    // V1 — Business type
    on<RegisteredToggled>((e, emit) => emit(state.copyWith(registered: e.registered)));
    on<CacChanged>(_onCacChanged);
    on<LegalNameChanged>((e, emit) => emit(state.copyWith(legalName: e.value)));
    on<VerifyCacRequested>(_onVerifyCac);

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
    on<OwnerFirstChanged>((e, emit) => emit(state.copyWith(firstName: e.value)));
    on<OwnerLastChanged>((e, emit) => emit(state.copyWith(lastName: e.value)));
    on<OwnerOtherChanged>((e, emit) => emit(state.copyWith(otherName: e.value)));
    on<OwnerPhoneChanged>((e, emit) => emit(state.copyWith(phone: e.value)));
    on<DobChanged>((e, emit) => emit(state.copyWith(dob: e.value)));
    on<GenderChanged>((e, emit) => emit(state.copyWith(gender: e.value)));

    // V5 — Identity & security
    on<NinChanged>(_onNinChanged);
    on<BvnChanged>(_onBvnChanged);
    on<VendorEmailChanged>(_onEmailChanged);
    on<VendorPasswordChanged>((e, emit) => emit(state.copyWith(password: e.value)));
    on<VendorConfirmChanged>((e, emit) => emit(state.copyWith(confirm: e.value)));
    on<ToggleVendorPassHidden>((_, emit) => emit(state.copyWith(hidePass: !state.hidePass)));
    on<ToggleVendorConfHidden>((_, emit) => emit(state.copyWith(hideConf: !state.hideConf)));
    on<TermsAgreementToggled>((e, emit) => emit(state.copyWith(toggled: e.value)));

    // KYC (explicit triggers if you keep standalone Verify buttons)
    on<VerifyBvnRequested>(_onVerifyBvn);
    on<VerifyNinRequested>(_onVerifyNin);
    on<ClearKycError>((_, emit) => emit(state.copyWith(kycError: null)));

    // --- NEW: Social Media Handlers ---
    on<InstagramChanged>((e, emit) => emit(state.copyWith(instagram: e.value)));
    on<TwitterChanged>((e, emit) => emit(state.copyWith(twitter: e.value)));
    on<FacebookChanged>((e, emit) => emit(state.copyWith(facebook: e.value)));
    on<TiktokChanged>((e, emit) => emit(state.copyWith(tiktok: e.value)));
    on<WebsiteChanged>((e, emit) => emit(state.copyWith(website: e.value)));
    on<WhatsappGroupChanged>((e, emit) => emit(state.copyWith(whatsappGroup: e.value)));
    on<OtherLinkChanged>((e, emit) => emit(state.copyWith(otherLink: e.value)));
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  void _onInit(SignupVendorInit event, Emit emit) {}

  void _onBack(SignupVendorBackPressed event, Emit emit) {
    final prev = (state.pageIndex - 1).clamp(0, state.totalPages - 1);
    emit(state.copyWith(pageIndex: prev));
  }

  /// On Identity step, verify only fields that need it; otherwise just advance.
  Future<void> _onNext(SignupVendorNextPressed event, Emit emit) async {
    const businessStepIndex = 0;
    const personalStepIndex = 3;
    const identityStepIndex = 4;
    final next = (state.pageIndex + 1).clamp(0, state.totalPages - 1);

    if (state.pageIndex == businessStepIndex) {
      // 1. If Registered is selected, MUST be verified
      if (state.registered) {
         if (!state.cacVerified || state.cac != state.lastVerifiedCac) {
            emit(state.copyWith(cacError: "Please verify your CAC number to continue."));
            return;
         }
      }
    }

    // --- STEP 3: PERSONAL DETAILS (Validation Logic) ---
    if (state.pageIndex == personalStepIndex) {
      // 1. Check Empty Text Fields
      if (state.firstName.trim().isEmpty || 
          state.lastName.trim().isEmpty || 
          state.phone.trim().isEmpty || 
          state.email.trim().isEmpty) {
        return;
      }

      // 2. Check Date of Birth
      if (state.dob == null) {
        return;
      }
      
      // 3. Check Age (Optional but recommended)
      final age = DateTime.now().year - state.dob!.year;
      if (age < 18) {
         return;
      }

      // 4. Check Gender
      if (state.gender == Gender.undisclosed) { 
        return;
      }

      // 5. Check Email Validity (If typed but not verified via regex)
      if (state.emailError != null && state.emailError!.isNotEmpty) {
         // The UI already shows the error under the field, but we block here too
         return; 
      }
      
      // 6. Check Email Availability (If we haven't checked yet or it failed)
      // If user typed fast and clicked next before debounce finished
      if (!state.emailUnused) {
         // Trigger the check manually here to be safe
         add(VendorEmailChanged(state.email)); 
         return;
      }
    }

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
      // --- 1. FRAUD CHECK (UNIQUENESS) ---
      // We check DB before calling external APIs to save money and prevent duplicates.
      
      if (ninNeedsVerification) {
        emit(state.copyWith(ninVerifying: true, ninError: null, kycError: null));
        
        final ninExists = await _vendorsRepo.checkIdentityExists(nin: state.nin.trim());
        if (ninExists) {
           emit(state.copyWith(
            ninVerifying: false,
            ninError: 'This NIN is linked to another account.', // Fraud Message
          ));
          return; // Stop here
        }
      }

      if (bvnNeedsVerification) {
        emit(state.copyWith(bvnVerifying: true, bvnError: null, kycError: null));

        final bvnExists = await _vendorsRepo.checkIdentityExists(bvn: state.bvn.trim());
        if (bvnExists) {
           emit(state.copyWith(
            bvnVerifying: false,
            bvnError: 'This BVN is linked to another account.', // Fraud Message
          ));
          return; // Stop here
        }
      }

      if (ninNeedsVerification) {
        emit(state.copyWith(ninVerifying: true, ninError: null, kycError: null));
        
        await _vendorsRepo.verifyNin(state.nin.trim());
        emit(state.copyWith(
          ninVerifying: false,
          ninVerified: true,
          lastVerifiedNin: state.nin.trim(),
        ));
      }

      if (bvnNeedsVerification) {
        emit(state.copyWith(bvnVerifying: true, bvnError: null, kycError: null));
        final fullName = '${state.firstName} ${state.lastName}'.trim();
        final dobForBvn = _formatDobForBvn(state.dob);
        final localPhone = _normalizeNigerianMsisdn(state.phone);

        if (dobForBvn == null) {
          emit(state.copyWith(kycError: 'Date of birth is missing'));
          return;
        }

          await _vendorsRepo.verifyBvn(
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

  void _onCacChanged(CacChanged event, Emit emit) {
     emit(state.copyWith(
       cac: event.value,
       cacVerified: false, // Reset!
       cacError: null,
     ));
  }

  // --- LOGIC: VERIFY CAC ---
  Future<void> _onVerifyCac(VerifyCacRequested event, Emit emit) async {
    debugPrint("🚀 Bloc: Verifying CAC: ${state.cac}");
    
    // 1. Validation
    if (state.cac.trim().isEmpty) {
      emit(state.copyWith(cacError: "Enter RC Number"));
      return;
    }

    // 2. Loading State
    emit(state.copyWith(cacVerifying: true, cacError: null));

    try {
      // 3. Call Repo
      final companyName = await _vendorsRepo.verifyCac(state.cac);
      
      debugPrint("✅ Bloc: Verification Success. Name: $companyName");

      // 4. Success State
      emit(state.copyWith(
        cacVerifying: false,
        cacVerified: true,
        lastVerifiedCac: state.cac,
        legalName: companyName.isNotEmpty ? companyName : state.legalName,
        cacError: null, // Clear error
      ));
    } catch (e) {
      debugPrint("❌ Bloc: Verification Failed: $e");
      
      // 5. Error Extraction
      String msg = "Verification failed. Please try again.";
      
      if (e is KorraException) {
        msg = e.message;
      } else {
        // Strip "Exception: " prefix if present from generic errors
        msg = e.toString().replaceAll("Exception: ", "");
      }
      
      // 6. Error State (Make sure verify flag is false)
      emit(state.copyWith(
        cacVerifying: false,
        cacVerified: false, 
        cacError: msg, // Pass clean message to UI
      ));
    }
  }

  // Email verification
  Future<void> _onEmailChanged(
    VendorEmailChanged event,
    Emitter<SignupVendorState> emit,
  ) async {
    final email = event.value.trim();

    emit(state.copyWith(emailChecking: true, emailError: null, emailUnused: false));
    
    if (email.isEmpty) {
      emit(state.copyWith(
        emailChecking: false,
        emailError: 'Email is required',
        emailUnused: false,
      ));
      return;
    }

    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);


    debugPrint("Reg result bloc: $ok");
    debugPrint("Reg result inline: ${RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)}");

    if (!ok) {
      emit(state.copyWith(
        emailChecking: false,
        emailError: 'Enter a valid email',
        emailUnused: false
      ));
      return;
    }

    try {
      final existsInVendors = await _vendorsRepo.checkCollectionForEmail('vendors', email);
      final existsInCustomer = await _vendorsRepo.checkCollectionForEmail('customers', email);
      debugPrint("Email exist in customers: $existsInCustomer");
      debugPrint("Email exist in vendors: $existsInVendors");
      if (existsInCustomer || existsInVendors) {
        emit(state.copyWith(
          emailChecking: false,
          emailUnused: false,
          emailError: 'Email is already in use.',
        ));
      } else {
        debugPrint("Email exist false: ${existsInCustomer || existsInVendors}");
        emit(state.copyWith(
          email: email,
          emailChecking: false,
          emailUnused: email.isEmpty ? false : true,
          emailError: '',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        emailChecking: false,
        emailUnused: false,
        emailError: 'Error checking email.',
      ));
    }
  }

  // ── Submit (final) ─────────────────────────────────────────────────────────
  Future<void> _onSubmit(SignupVendorSubmitPressed event, Emit emit) async {
    if (!state.ninVerified || !state.bvnVerified) {
      emit(state.copyWith(signUpError: 'Please verify both NIN and BVN first.', status: SignupStatus.failure));
      return;
    }

    emit(state.copyWith(loading: true, signUpError: null, status: SignupStatus.loading));
    try {
      final uid = await _vendorsRepo.createVendorFromState(state);

      emit(state.copyWith(loading: false, status: SignupStatus.success, uid: uid));
    } catch (error) {
      debugPrint('Error submitting vendor: $error');
      emit(state.copyWith(loading: false, signUpError: error.toString(), status: SignupStatus.failure));
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
    if (state.firstName.isEmpty || state.lastName.isEmpty || state.dob == null) {
      emit(state.copyWith(kycError: 'Fill first name, last name, and date of birth.'));
      return;
    }

    emit(state.copyWith(ninVerifying: true, kycError: null));
    try {
      await _vendorsRepo.verifyNin(state.nin.trim());

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

      await _vendorsRepo.verifyBvn(
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