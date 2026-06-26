import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:korra/data/repository/customer/customer_repository.dart';
import 'package:korra/data/repository/customer/verification_repository.dart';

import 'customer_kyc_event.dart';
import 'customer_kyc_state.dart';

class CustomerKycBloc extends Bloc<CustomerKycEvent, CustomerKycState> {
  final CustomerRepository repo;
  final String customerUid;

  CustomerKycBloc({
    required this.repo,
    required this.customerUid,
  }) : super(const CustomerKycState()) {
    on<BvnInputChanged>((event, emit) => emit(state.copyWith(bvnInput: event.bvn, clearBvnError: true)));
    on<NinInputChanged>((event, emit) => emit(state.copyWith(ninInput: event.nin, clearNinError: true)));
    on<GenderChanged>((event, emit) => emit(state.copyWith(gender: event.gender)));
    on<DobChanged>((event, emit) => emit(state.copyWith(dob: event.dob)));
    on<EditPhoneToggled>((event, emit) => emit(state.copyWith(isEditingPhone: !state.isEditingPhone)));
    
    on<SavePhoneClicked>(_onSavePhone);
    on<VerifyBvnClicked>(_onVerifyBvn);
    on<VerifyNinClicked>(_onVerifyNin);
  }

  Future<void> _onVerifyBvn(VerifyBvnClicked event, Emitter<CustomerKycState> emit) async {
    if (state.dob == null || state.gender == null) {
      emit(state.copyWith(bvnVerificationError: "Please select your Date of Birth and Gender first."));
      return;
    }

    emit(state.copyWith(bvnVerificationInProgress: true, clearBvnError: true));

    try {
      final exists = await repo.checkIdentityExists(bvn: event.bvn);
      if (exists) {
        emit(state.copyWith(bvnVerificationInProgress: false, bvnVerificationError: "BVN already registered."));
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('customers').doc(customerUid).get();
      debugPrint('🔍 Retrieving customer data for UID: $customerUid');
      debugPrint('📄 Customer document data: ${doc.data()}');
      final data = doc.data() ?? {};
      final personalData = data['personal'] as Map<String, dynamic>? ?? {};
      final firstName = (personalData['first'] ?? '').toString().trim();
      final lastName = (personalData['last'] ?? '').toString().trim();
      final otherName = (personalData['other'] ?? '').toString().trim();

      final fullName = '$firstName $lastName $otherName'.trim();

      debugPrint('🔍 Verifying BVN for $fullName with DOB ${state.dob}');

      if (fullName.isEmpty) {
        emit(state.copyWith(bvnVerificationInProgress: false, bvnVerificationError: "Profile name missing. Please contact support."));
        return;
      }

      // API CALL
      await repo.verifyBvn(
        bvn: event.bvn,
        name: fullName,
        dateOfBirthIso: _formatDobForBvn(state.dob)!, 
        mobileNo: state.phone, 
      );

      // SUCCESS: Update Firestore
      await FirebaseFirestore.instance.collection('customers').doc(customerUid).update({
        'kyc.bvn': event.bvn,
        'kyc.bvnVerified': true,
        'personal.dob': Timestamp.fromDate(state.dob!),
        'personal.gender': state.gender,
      });

      await FirebaseAnalytics.instance.logEvent(
        name: 'kyc_bvn_verified',
        parameters: {'customer_uid': customerUid},
      );

      emit(state.copyWith(bvnVerificationInProgress: false, isBvnVerified: true));

    } catch (e) {
      emit(state.copyWith(bvnVerificationInProgress: false, bvnVerificationError: e.toString()));
    }
  }

  Future<void> _onVerifyNin(VerifyNinClicked event, Emitter<CustomerKycState> emit) async {
    if (state.dob == null || state.gender == null) {
      emit(state.copyWith(ninVerificationError: "Please select your Date of Birth and Gender first."));
      return;
    }

    emit(state.copyWith(ninVerificationInProgress: true, clearNinError: true));

    try {
      final exists = await repo.checkIdentityExists(nin: event.nin);
      if (exists) {
        emit(state.copyWith(ninVerificationInProgress: false, ninVerificationError: "NIN already registered."));
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('customers').doc(customerUid).get();
      final data = doc.data() ?? {};
      final personalData = data['personal'] as Map<String, dynamic>? ?? {};
      final firstName = (personalData['first'] ?? '').toString().trim();
      final lastName = (personalData['last'] ?? '').toString().trim();
      final otherName = (personalData['other'] ?? '').toString().trim();

      if (firstName.isEmpty || lastName.isEmpty) {
        emit(state.copyWith(ninVerificationInProgress: false, ninVerificationError: "Profile name incomplete."));
        return;
      }

      // API CALL
      await repo.verifyNin(
        event.nin,
        firstName,
        lastName,
        otherName,
        state.dob!.toIso8601String(), 
        state.phone, 
      );

      // SUCCESS: Update Firestore
      await FirebaseFirestore.instance.collection('customers').doc(customerUid).update({
        'kyc.nin': event.nin,
        'kyc.ninVerified': true,
        'personal.dob': Timestamp.fromDate(state.dob!),
        'personal.gender': state.gender,
      });

      await FirebaseAnalytics.instance.logEvent(
        name: 'kyc_nin_verified',
        parameters: {'customer_uid': customerUid},
      );

      emit(state.copyWith(ninVerificationInProgress: false, isNinVerified: true));

    } catch (e) {
      emit(state.copyWith(ninVerificationInProgress: false, ninVerificationError: e.toString()));
    }
  }

  Future<void> _onSavePhone(SavePhoneClicked event, Emitter<CustomerKycState> emit) async {
    if (event.phone.trim().length < 10) return;
    
    emit(state.copyWith(isUpdatingPhone: true));
    try {      
      await FirebaseFirestore.instance.collection('customers').doc(customerUid).update({
        'personal.phone': event.phone.trim(),
      });
      emit(state.copyWith(phone: event.phone.trim(), isUpdatingPhone: false, isEditingPhone: false));
    } catch (e) {
      emit(state.copyWith(isUpdatingPhone: false)); 
    }
  }

  String? _formatDobForBvn(DateTime? date) {
    if (date == null) return null;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dd = date.day.toString().padLeft(2, '0');
    final mmm = months[date.month - 1];
    final yyyy = date.year.toString().padLeft(4, '0');
    return '$dd-$mmm-$yyyy'; 
  }
}