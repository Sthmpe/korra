import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korra/data/repository/customer/customer_repository.dart';
import 'package:korra/data/repository/customer/verification_repository.dart';
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
    on<DobChanged>((e, emit) => emit(state.copyWith(dob: e.value)));
    on<GenderChanged>((e, emit) => emit(state.copyWith(gender: e.value)));

    // step 2
    on<NinChanged>(_onNinChanged);
    on<BvnChanged>(_onBvnChanged);

    // step 3
    on<PasswordChangedCU>((e, emit) => emit(state.copyWith(password: e.value)));
    on<ConfirmPasswordChangedCU>(
      (e, emit) => emit(state.copyWith(confirm: e.value)),
    );
    on<TogglePasswordVisibilityCU>(
      (e, emit) => emit(state.copyWith(hidePassword: !state.hidePassword)),
    );
    on<ToggleConfirmVisibilityCU>(
      (e, emit) => emit(state.copyWith(hideConfirm: !state.hideConfirm)),
    );

    // KYC (explicit triggers if you keep standalone Verify buttons)
    on<VerifyBvnRequested>(_onVerifyBvn);
    on<VerifyNinRequested>(_onVerifyNin);
    on<ClearKycError>((_, emit) => emit(state.copyWith(kycError: null)));
  }

  Future<void> _onSubmit(
    SignupCustomerSubmitPressed e,
    Emitter<SignupCustomerState> emit,
  ) async {
    if (!state.ninVerified || !state.bvnVerified) {
      emit(
        state.copyWith(
          signUpError: 'Please verify both NIN and BVN first.',
          status: SignupStatus.failure,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        loading: true,
        signUpError: null,
        status: SignupStatus.loading,
      ),
    );
    try {
      final uid = await _customerRepo.createCustomerFromState(state);

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

  // Email verification
  Future<void> _onEmailChanged(
    EmailChangedCU event,
    Emitter<SignupCustomerState> emit,
  ) async {
    final email = event.value.trim();

    emit(
      state.copyWith(emailChecking: true, emailError: null, emailUnused: false),
    );

    if (email.isEmpty) {
      emit(
        state.copyWith(
          emailChecking: false,
          emailError: 'Email is required',
          emailUnused: false,
        ),
      );
      return;
    }

    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);

    debugPrint("Reg result bloc: $ok");
    debugPrint(
      "Reg result inline: ${RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)}",
    );

    if (!ok) {
      emit(
        state.copyWith(
          emailChecking: false,
          emailError: 'Enter a valid email',
          emailUnused: false,
        ),
      );
      return;
    }

    try {
      final existsInVendors = await _customerRepo.checkCollectionForEmail(
        'vendors',
        email,
      );
      final existsInCustomer = await _customerRepo.checkCollectionForEmail(
        'customers',
        email,
      );
      debugPrint("Email exist in customers: $existsInCustomer");
      debugPrint("Email exist in vendors: $existsInVendors");
      if (existsInCustomer || existsInVendors) {
        emit(
          state.copyWith(
            emailChecking: false,
            emailUnused: false,
            emailError: 'Email is already in use.',
          ),
        );
      } else {
        debugPrint("Email exist false: ${existsInCustomer || existsInVendors}");
        emit(
          state.copyWith(
            email: email,
            emailChecking: false,
            emailUnused: email.isEmpty ? false : true,
            emailError: '',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          emailChecking: false,
          emailUnused: false,
          emailError: 'Error checking email.',
        ),
      );
    }
  }

  void _onBack(SignupCustomerBackPressed event, Emit emit) {
    final prev = (state.pageIndex - 1).clamp(0, state.totalPages - 1);
    emit(state.copyWith(pageIndex: prev));
  }

  /// On Identity step, verify only fields that need it; otherwise just advance.
  Future<void> _onNext(SignupCustomerNextPressed event, Emit emit) async {
    const personalStepIndex = 0;
    const identityStepIndex = 1;
    final next = (state.pageIndex + 1).clamp(0, state.totalPages - 1);

    // --- STEP 0: PERSONAL DETAILS (Validation Logic) ---
    if (state.pageIndex == personalStepIndex) {
      // 1. Check Empty Text Fields
      if (state.firstName.trim().isEmpty || 
          state.lastName.trim().isEmpty || 
          state.phone.trim().isEmpty || 
          state.email.trim().isEmpty) {
        debugPrint("Debug: One or more required fields are empty.");
        return;
      }

      // 2. Check Date of Birth
      if (state.dob == null) {
        debugPrint("Debug: Date of birth is not selected.");
        return;
      }
      
      // 3. Check Age (Optional but recommended)
      final age = DateTime.now().year - state.dob!.year;
      if (age < 18) {
        debugPrint("Debug: User is under 18 years old.");
         return;
      }

      // 4. Check Gender
      if (state.gender == Gender.undisclosed) { 
        debugPrint("Debug: Gender is not selected."); 
        return;
      }

      // 5. Check Email Validity (If typed but not verified via regex)
      if (state.emailError != null && state.emailError!.isNotEmpty) {
          debugPrint("Debug: Email format is invalid.");
         // The UI already shows the error under the field, but we block here too
         return; 
      }
      
      // 6. Check Email Availability (If we haven't checked yet or it failed)
      // If user typed fast and clicked next before debounce finished
      if (!state.emailUnused) {
          debugPrint("Debug: Email availability not confirmed.");
         // Trigger the check manually here to be safe
         add(EmailChangedCU(state.email)); 
         return;
      }
    }

    if (state.pageIndex != identityStepIndex) {
      emit(state.copyWith(pageIndex: next));
      return;
    }

    final ninNeedsVerification =
        !(state.ninVerified && state.lastVerifiedNin == state.nin);
    final bvnNeedsVerification =
        !(state.bvnVerified && state.lastVerifiedBvn == state.bvn);

    if (!ninNeedsVerification && !bvnNeedsVerification) {
      emit(state.copyWith(pageIndex: next));
      return;
    }

    if (state.firstName.isEmpty ||
        state.lastName.isEmpty ||
        state.dob == null) {
      emit(
        state.copyWith(
          kycError: 'Fill first name, last name, and date of birth.',
        ),
      );
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
        emit(
          state.copyWith(ninVerifying: true, ninError: null, kycError: null),
        );

        final ninExists = await _customerRepo.checkIdentityExists(
          nin: state.nin.trim(),
        );
        if (ninExists) {
          emit(
            state.copyWith(
              ninVerifying: false,
              ninError:
                  'This NIN is linked to another account.', // Fraud Message
            ),
          );
          return; // Stop here
        }
      }

      if (bvnNeedsVerification) {
        emit(
          state.copyWith(bvnVerifying: true, bvnError: null, kycError: null),
        );

        final bvnExists = await _customerRepo.checkIdentityExists(
          bvn: state.bvn.trim(),
        );
        if (bvnExists) {
          emit(
            state.copyWith(
              bvnVerifying: false,
              bvnError:
                  'This BVN is linked to another account.', // Fraud Message
            ),
          );
          return; // Stop here
        }
      }

      if (ninNeedsVerification) {
        emit(
          state.copyWith(ninVerifying: true, ninError: null, kycError: null),
        );

        await _customerRepo.verifyNin(state.nin.trim());
        emit(
          state.copyWith(
            ninVerifying: false,
            ninVerified: true,
            lastVerifiedNin: state.nin.trim(),
          ),
        );
      }

      if (bvnNeedsVerification) {
        emit(
          state.copyWith(bvnVerifying: true, bvnError: null, kycError: null),
        );
        final fullName = '${state.firstName} ${state.lastName}'.trim();
        final dobForBvn = _formatDobForBvn(state.dob);
        final localPhone = _normalizeNigerianMsisdn(state.phone);

        if (dobForBvn == null) {
          emit(state.copyWith(kycError: 'Date of birth is missing'));
          return;
        }

        await _customerRepo.verifyBvn(
          bvn: state.bvn.trim(),
          name: fullName,
          dateOfBirthIso: dobForBvn,
          mobileNo: localPhone,
        );
        emit(
          state.copyWith(
            bvnVerifying: false,
            bvnVerified: true,
            lastVerifiedBvn: state.bvn.trim(),
          ),
        );
      }

      emit(state.copyWith(pageIndex: next));
    } catch (error) {
      debugPrint('❌ Error during KYC verification (Technical): $error');

      // Use professional message
      String userMessage =
          'Identity verification failed. Please check your data.';
      if (error is KorraException) {
        userMessage = error.message;
      }

      // Set the clean user message to the appropriate field:
      if (state.ninVerifying) {
        emit(
          state.copyWith(
            ninVerifying: false,
            ninVerified: false,
            ninError: userMessage,
          ),
        );
      } else if (state.bvnVerifying) {
        emit(
          state.copyWith(
            bvnVerifying: false,
            bvnVerified: false,
            bvnError: userMessage,
          ),
        );
      } else {
        emit(state.copyWith(kycError: userMessage));
      }
    }
  }

  void _onNinChanged(NinChanged event, Emit emit) {
    final changed = event.value != state.nin;
    emit(
      state.copyWith(
        nin: event.value,
        ninError: null,
        ninVerified: changed ? false : state.ninVerified,
        lastVerifiedNin: changed ? null : state.lastVerifiedNin,
      ),
    );
  }

  void _onBvnChanged(BvnChanged event, Emit emit) {
    final changed = event.value != state.bvn;
    emit(
      state.copyWith(
        bvn: event.value,
        bvnError: null,
        bvnVerified: changed ? false : state.bvnVerified,
        lastVerifiedBvn: changed ? null : state.lastVerifiedBvn,
      ),
    );
  }

  // ── Optional explicit KYC triggers (if you keep buttons) ───────────────────
  Future<void> _onVerifyNin(VerifyNinRequested event, Emit emit) async {
    if (state.nin.trim().isEmpty) {
      emit(state.copyWith(kycError: 'Enter NIN'));
      return;
    }
    if (state.firstName.isEmpty ||
        state.lastName.isEmpty ||
        state.dob == null) {
      emit(
        state.copyWith(
          kycError: 'Fill first name, last name, and date of birth.',
        ),
      );
      return;
    }

    emit(state.copyWith(ninVerifying: true, kycError: null));
    try {
      await _customerRepo.verifyNin(state.nin.trim());
      emit(
        state.copyWith(
          ninVerifying: false,
          ninVerified: true,
          lastVerifiedNin: state.nin.trim(),
        ),
      );
    } catch (error) {
      debugPrint('Error verifying NIN: $error');
      emit(
        state.copyWith(
          ninVerifying: false,
          ninVerified: false,
          kycError: error.toString(),
        ),
      );
    }
  }

  Future<void> _onVerifyBvn(VerifyBvnRequested event, Emit emit) async {
    if (state.bvn.trim().isEmpty) {
      emit(state.copyWith(kycError: 'Enter BVN'));
      return;
    }
    if (state.firstName.isEmpty ||
        state.lastName.isEmpty ||
        state.dob == null) {
      emit(
        state.copyWith(
          kycError: 'Fill first name, last name, and date of birth.',
        ),
      );
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

      await _customerRepo.verifyBvn(
        bvn: state.bvn.trim(),
        name: fullName,
        dateOfBirthIso: dobIso,
        mobileNo: localPhone,
      );
      emit(
        state.copyWith(
          bvnVerifying: false,
          bvnVerified: true,
          lastVerifiedBvn: state.bvn.trim(),
        ),
      );
    } catch (error) {
      debugPrint('Error verifying BVN: $error');
      emit(
        state.copyWith(
          bvnVerifying: false,
          bvnVerified: false,
          kycError: error.toString(),
        ),
      );
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
