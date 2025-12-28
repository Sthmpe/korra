import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../../../../config/constants/prefs_keys.dart';
import '../../../../data/repository/customer/customer_repository.dart';
import '../../../../data/repository/vendors/vendor_repository.dart';
import 'role_login_event.dart';
import 'role_login_state.dart';

class RoleLoginBloc extends Bloc<RoleLoginEvent, RoleLoginState> {
  final VendorRepository _vendorRepo;
  final CustomerRepository _customerRepo;

  RoleLoginBloc({VendorRepository? vendorRepo, CustomerRepository? customerRepo})
    : _vendorRepo = vendorRepo ?? VendorRepository(),
      _customerRepo = customerRepo ?? CustomerRepository(),
      super(const RoleLoginState()) {
    on<RoleSelected>(
      (e, emit) => emit(
        state.copyWith(role: e.role, failure: null, status: LoginStatus.idle),
      ),
    );

    on<EmailChanged>(
      (e, emit) => emit(
        state.copyWith(email: e.email, failure: null, status: LoginStatus.idle),
      ),
    );

    on<PasswordChanged>(
      (e, emit) => emit(
        state.copyWith(
          password: e.password,
          failure: null,
          status: LoginStatus.idle,
        ),
      ),
    );

    on<TogglePasswordVisibility>(
      (e, emit) => emit(state.copyWith(passwordHidden: !state.passwordHidden)),
    );

    on<SubmitPressed>(_onSubmitPressed);
    on<BiometricsPressed>(_onBiometricsPressed);
    on<FailureAcknowledged>(
      (e, emit) =>
          emit(state.copyWith(failure: null, status: LoginStatus.idle)),
    );
  }

  Future<void> _onSubmitPressed(
    SubmitPressed e,
    Emitter<RoleLoginState> emit,
  ) async {
    if (state.loading || !state.isFormValid) return;

    emit(
      state.copyWith(
        loading: true,
        status: LoginStatus.submitting,
        failure: null,
      ),
    );

    try {
      if (state.role == KorraRole.vendor) {
        final existsInCustomer = await _customerRepo.checkCollectionForEmail('customers', state.email.trim());
        
        if (existsInCustomer) {
          throw Exception('customer');
        }

        final uid = await _vendorRepo.signInVendor(
          state.email.trim(),
          state.password.trim(),
        );
        if (uid.isNotEmpty) {
          emit(
            state.copyWith(
              uid: uid,
              loading: false,
              status: LoginStatus.success,
              role: KorraRole.vendor,
            ),
          );
          await _persistUserSession(uid, 'vendor');
          return;
        }
      } else {
        final existsInVendors = await _customerRepo.checkCollectionForEmail('vendors', state.email.trim());
        
        if (existsInVendors) {
          throw Exception('vendor');
        }

        final uid = await _customerRepo.signInCustomer(
          state.email.trim(),
          state.password.trim(),
        );
        if (uid.isNotEmpty) {
          emit(
            state.copyWith(
              uid: uid,
              loading: false,
              status: LoginStatus.success,
              role: KorraRole.customer,
            ),
          );
          await _persistUserSession(uid, 'customer');
          return;
        }
      }
    } on FirebaseAuthException catch (ex) {
      emit(
        state.copyWith(
          loading: false,
          status: LoginStatus.failure,
          failure: _mapAuthError(ex),
        ),
      );
    } on Exception catch (err) {
      final msg = err.toString();
      if (msg.contains('customer')) {
        emit(
          state.copyWith(
            loading: false,
            status: LoginStatus.failure,
            failure: const KorraFailure(
              code: 'role_mismatch',
              title: 'Check role selected',
              message: 'This account is not registered as a vendor.',
            ),
          ),
        );
      } else if (msg.contains('vendor')) {
        emit(
          state.copyWith(
            loading: false,
            status: LoginStatus.failure,
            failure: const KorraFailure(
              code: 'role_mismatch',
              title: 'Check role selected',
              message: 'This account is not registered as a customer.',
            ),
          ),
        );
      } else {
        emit(
          state.copyWith(
            loading: false,
            status: LoginStatus.failure,
            failure: const KorraFailure(
              code: 'unknown',
              title: 'We couldn’t sign you in',
              message: 'Please try again in a moment.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _persistUserSession(String uid, String role) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(PrefsKeys.userUid, uid);
    await prefs.setString(PrefsKeys.userRole, role);
  }

  Future<void> _onBiometricsPressed(
    BiometricsPressed e,
    Emitter<RoleLoginState> emit,
  ) async {
    if (state.bioUi == BiometricUi.inProgress) return;
    emit(state.copyWith(bioUi: BiometricUi.pressed));
    await Future.delayed(const Duration(milliseconds: 120));
    emit(state.copyWith(bioUi: BiometricUi.inProgress));
    await Future.delayed(const Duration(milliseconds: 700));

    // mock success for now
    emit(state.copyWith(bioUi: BiometricUi.success));
    await Future.delayed(const Duration(milliseconds: 600));
    emit(state.copyWith(bioUi: BiometricUi.idle));
  }

  KorraFailure _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
      case 'user-not-found':
      case 'wrong-password':
        return const KorraFailure(
          code: 'invalid_credentials',
          title: 'Incorrect email or password',
          message: 'Double-check your credentials and try again.',
        );
      case 'user-disabled':
        return const KorraFailure(
          code: 'user_disabled',
          title: 'Account disabled',
          message: 'Contact support if this is unexpected.',
        );
      case 'too-many-requests':
        return const KorraFailure(
          code: 'too_many_requests',
          title: 'Too many attempts',
          message: 'Try again in a little while.',
        );
      default:
        return KorraFailure(
          code: e.code,
          title: 'Authentication Failed',
          message: e.message ?? 'An unknown error occurred. Please try again.',
        );
    }
  }
}
