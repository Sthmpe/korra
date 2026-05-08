import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korra/data/repository/vendors/bank_repository.dart';
import 'package:korra/data/repository/vendors/pin_repository.dart';
import 'package:korra/data/repository/vendors/transfer_repository.dart';
import 'package:korra/data/repository/vendors/verification_repository.dart';
import '../../../../data/models/vendor/payout/payout_details.dart';
import '../../../../data/models/vendor/vendor_setting.dart';
import '../../../../data/repository/vendors/vendor_repository.dart';
import 'bank.dart';
import 'payout_event.dart';
import 'payout_state.dart';

class PayoutBloc extends Bloc<PayoutEvent, PayoutState> {
  final VendorRepository repo;
  final String vendorUid;

  PayoutBloc({
    required this.repo,
    required this.vendorUid,
  }) : super(PayoutState.initial()) {
    on<PayoutStarted>(_onStarted);
    on<AmountChanged>(_onAmountChanged);
    on<BankDetailsUpdated>(_onBankUpdated);
    on<WithdrawClicked>(_onWithdrawClicked);
    on<PinSubmitted>(_onPinSubmitted);
    on<NewPinCreated>(_onNewPinCreated);
    on<PayoutReset>(_onReset);
    on<BvnInputChanged>(_onBvnChanged);
    on<NinInputChanged>(_onNinChanged);
    on<VerifyBvnClicked>(_onVerifyBvn);
    on<VerifyNinClicked>(_onVerifyNin);
    on<DobChanged>((event, emit) => emit(state.copyWith(dob: event.dob)));
    on<GenderChanged>((event, emit) => emit(state.copyWith(gender: event.gender)));
    on<EditPhoneToggled>((event, emit) => emit(state.copyWith(isEditingPhone: !state.isEditingPhone)));
  on<SavePhoneClicked>(_onSavePhone);
  }

  Future<void> _onStarted(PayoutStarted event, Emitter<PayoutState> emit) async {
    emit(state.copyWith(
      status: PayoutStatus.loading,
      withdrawableBalance: event.currentBalance,
      amountInput: '',
    ));

    try {
      // 🚀 LOAD EVERYTHING IN PARALLEL (4 Calls now)
      final results = await Future.wait([
        repo.getVendorSettings(vendorUid),  // 0: Settings/PIN
        repo.getBankList(),                 // 1: Banks
        repo.getComplianceStatus(vendorUid),// 2: Admin Compliance ('active', 'suspended')
        repo.getKycDetails(vendorUid),      // 3: KYC & Personal Maps
      ]);

      final settings = results[0] as VendorSettings;
      final banks = results[1] as List<Bank>;
      final compliance = results[2] as Map<String, String>; // 👈 Restored
      final vendorData = results[3] as Map<String, dynamic>; // 👈 KYC Data
      
      final details = settings.payoutDetails;

      final kycMap = vendorData['kyc'] as Map<String, dynamic>? ?? {};
      final personalMap = vendorData['personal'] as Map<String, dynamic>? ?? {};
      

      DateTime? parsedDob;
      final rawDob = personalMap['dob'];

      if (rawDob is Timestamp) {
        // If Firebase saved it as a Timestamp object
        parsedDob = rawDob.toDate();
      } else if (rawDob is String && rawDob.isNotEmpty) {
        // If it was saved as an ISO-8601 String
        parsedDob = DateTime.tryParse(rawDob);
      }

      emit(state.copyWith(
        status: PayoutStatus.success,
        hasPinSet: settings.isPinSet,
        bankName: details.bankName,
        accountNumber: details.bankAccountNumber,
        accountName: details.bankAccountName,
        bankCode: details.bankCode,
        bankList: banks,
        
        // 1. ADMIN COMPLIANCE
        complianceStatus: compliance['status'],
        blockMessage: compliance['message'],
        
        // 2. KYC FLAGS
        isBvnVerified: kycMap['bvnVerified'] ?? false,
        isNinVerified: kycMap['ninVerified'] ?? false,
        lastVerifiedBvn: kycMap['bvn'],
        lastVerifiedNin: kycMap['nin'],
        
        // 3. PERSONAL DETAILS & PHONE
        dob: parsedDob,
        gender: personalMap['gender'],
        phone: personalMap['phone'],
      ));
      
    } catch (e) {
      debugPrint('PayoutBloc _onStarted error: $e');
      emit(state.copyWith(status: PayoutStatus.failure, errorMessage: "Failed to load details"));
    }
  }

  void _onAmountChanged(AmountChanged event, Emitter<PayoutState> emit) {
    // ✅ FIX: Store the input AS IS (with commas)
    // The validation logic in PayoutState will handle stripping commas.
    emit(state.copyWith(amountInput: event.input));
  }

  Future<void> _onBankUpdated(BankDetailsUpdated event, Emitter<PayoutState> emit) async {
    // 1. Update UI immediately
    emit(state.copyWith(
      bankName: event.bankName,
      accountNumber: event.accountNumber,
      accountName: event.accountName,
      bankCode: event.bankCode,
    ));

    // 2. Save to DB (Background)
    try {
      final details = PayoutDetails(
        bankName: event.bankName,
        bankCode: event.bankCode,
        bankAccountNumber: event.accountNumber,
        bankAccountName: event.accountName,
      );
      await repo.savePayoutDetails(vendorUid, details);
    } catch (e) {
      debugPrint("Failed to save bank: $e");
    }
  }

  void _onWithdrawClicked(WithdrawClicked event, Emitter<PayoutState> emit) {
    if (!state.canWithdraw) return;

    // 🛑 1. THE INSTANT BLOCKER
    // We check the local variable we loaded earlier. Zero network delay.
    if (state.complianceStatus != 'active') {
      emit(state.copyWith(
        status: PayoutStatus.failure,
        errorMessage: state.blockMessage, // Show the exact reason (e.g., "Video Call Required")
      ));
      return; 
    }

    if (state.hasPinSet) {
      emit(state.copyWith(step: PayoutStep.verifyPin));
    } else {
      emit(state.copyWith(step: PayoutStep.createPin));
    }
  }

  Future<void> _onNewPinCreated(NewPinCreated event, Emitter<PayoutState> emit) async {
    emit(state.copyWith(
      status: PayoutStatus.loading,
      step: PayoutStep.processing, // <--- CRITICAL CHANGE
    ));
    try {
      await repo.setTransactionPin(vendorUid, event.pin);
      // Seamlessly move to Verify
      emit(state.copyWith(
        status: PayoutStatus.success,
        hasPinSet: true,
        step: PayoutStep.verifyPin
      ));
    } catch (e) {
      emit(state.copyWith(status: PayoutStatus.failure, errorMessage: "Failed to create PIN"));
    }
  }

  Future<void> _onPinSubmitted(PinSubmitted event, Emitter<PayoutState> emit) async {
    emit(state.copyWith(
      status: PayoutStatus.loading,
      step: PayoutStep.processing, // <--- CRITICAL CHANGE
    ));

    try {
      // ✅ STRIP COMMAS HERE for API
      final amount = double.parse(state.amountInput.replaceAll(',', ''));
      
      final response = await repo.requestPayout(
        uid: vendorUid,
        amount: amount,
        pin: event.pin,
        bankCode: state.bankCode,
        accountNumber: state.accountNumber,
        accountName: state.accountName,
      );

      emit(state.copyWith(
        step: PayoutStep.completed,
        transactionRef: response['reference'],
        transactionDate: DateTime.now(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PayoutStatus.failure,
        step: PayoutStep.input, 
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      ));
    }
  }

  void _onReset(PayoutReset event, Emitter<PayoutState> emit) {
    emit(state.copyWith(
      // 1. Go back to the Input Step (closes PIN logic in logic)
      step: PayoutStep.input, 
      
      // 2. IMPORTANT: Set status to 'success' so the Form shows, not the Spinner
      status: PayoutStatus.success, 
      
      // 3. Optional: Decide if you want to clear the amount or keep it
      // amountInput: '', // Uncomment if you want to wipe the amount
    ));
  }

  void _onBvnChanged(BvnInputChanged event, Emitter<PayoutState> emit) {
    emit(state.copyWith(
      bvnInput: event.bvn,
      bvnVerificationError: null, // Clear error when they start typing again
    ));
  }

  void _onNinChanged(NinInputChanged event, Emitter<PayoutState> emit) {
    emit(state.copyWith(
      ninInput: event.nin,
      ninVerificationError: null,
    ));
  }

  Future<void> _onVerifyBvn(VerifyBvnClicked event, Emitter<PayoutState> emit) async {
    if (state.dob == null || state.gender == null) {
      emit(state.copyWith(bvnVerificationError: "Please select your Date of Birth and Gender first."));
      return;
    }

    emit(state.copyWith(bvnVerificationInProgress: true, bvnVerificationError: null));

    try {
      final exists = await repo.checkIdentityExists(bvn: event.bvn);
      if (exists) {
        emit(state.copyWith(bvnVerificationInProgress: false, bvnVerificationError: "BVN already registered."));
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('vendors').doc(vendorUid).get();
      final data = doc.data() ?? {};
      final personal = data['personal'] ?? {};
      
      final fullName = "${personal['first'] ?? ''} ${personal['last'] ?? ''}".trim();

      if (fullName.isEmpty) {
        emit(state.copyWith(
          bvnVerificationInProgress: false, 
          bvnVerificationError: "Profile name missing. Please contact support."
        ));
        return;
      }

      // 4. API CALL
      await repo.verifyBvn(
        bvn: event.bvn,
        name: fullName,
        dateOfBirthIso: _formatDobForBvn(state.dob)!, // Using your custom DD-MMM-YYYY helper
        mobileNo: state.phone, // 🚀 Uses the phone from STATE (catches fresh edits!)
      );

      // 5. SUCCESS: Update Firestore
      await FirebaseFirestore.instance.collection('vendors').doc(vendorUid).update({
        'kyc.bvn': event.bvn,
        'kyc.bvnVerified': true,
        'personal.dob': Timestamp.fromDate(state.dob!),
        'personal.gender': state.gender,
      });

      // 6. UPDATE UI
      emit(state.copyWith(
        bvnVerificationInProgress: false, 
        isBvnVerified: true, 
        lastVerifiedBvn: event.bvn
      ));

    } catch (e) {
      emit(state.copyWith(
        bvnVerificationInProgress: false, 
        bvnVerificationError: e.toString()
      ));
    }
  }

  Future<void> _onVerifyNin(VerifyNinClicked event, Emitter<PayoutState> emit) async {
    if (state.dob == null || state.gender == null) {
      emit(state.copyWith(ninVerificationError: "Please select your Date of Birth and Gender first."));
      return;
    }

    emit(state.copyWith(ninVerificationInProgress: true, ninVerificationError: null));

    try {
      final exists = await repo.checkIdentityExists(nin: event.nin);
      if (exists) {
        emit(state.copyWith(ninVerificationInProgress: false, ninVerificationError: "NIN already registered."));
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('vendors').doc(vendorUid).get();
      final data = doc.data() ?? {};
      final personal = data['personal'] ?? {};

      final first = personal['first']?.toString().trim() ?? '';
      final last = personal['last']?.toString().trim() ?? '';
      final other = personal['other']?.toString().trim() ?? '';

      if (first.isEmpty || last.isEmpty) {
        emit(state.copyWith(
          ninVerificationInProgress: false, 
          ninVerificationError: "Profile name missing. Please contact support."
        ));
        return;
      }

      // 4. API CALL
      await repo.verifyNin(
        event.nin,
        first,
        last,
        other,
        state.dob!.toIso8601String(), // 🚀 NIN usually requires strictly ISO8601
        state.phone, // Uses state phone
      );

      // 5. SUCCESS: Update Firestore
      await FirebaseFirestore.instance.collection('vendors').doc(vendorUid).update({
        'kyc.nin': event.nin,
        'kyc.ninVerified': true,
        'personal.dob': Timestamp.fromDate(state.dob!),
        'personal.gender': state.gender,
      });

      // 6. UPDATE UI
      emit(state.copyWith(
        ninVerificationInProgress: false, 
        isNinVerified: true, 
        lastVerifiedNin: event.nin
      ));

    } catch (e) {
      debugPrint('NIN Verification Error: $e');
      emit(state.copyWith(
        ninVerificationInProgress: false, 
        ninVerificationError: e.toString()
      ));
    }
  }

  Future<void> _onSavePhone(SavePhoneClicked event, Emitter<PayoutState> emit) async {
    if (event.newPhone.trim().length < 10) return; // Basic validation
    
    emit(state.copyWith(isUpdatingPhone: true));
    
    try {      
      // 🚀 Update Firestore permanently
      await FirebaseFirestore.instance.collection('vendors').doc(vendorUid).update({
        'personal.phone': event.newPhone.trim(),
      });

      // Update state and close the editor
      emit(state.copyWith(
        phone: event.newPhone.trim(),
        isUpdatingPhone: false,
        isEditingPhone: false, // Hide the text field
      ));
    } catch (e) {
      emit(state.copyWith(isUpdatingPhone: false)); // Handle error if needed
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String? _formatDobForBvn(DateTime? date) {
    if (date == null) return null;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dd = date.day.toString().padLeft(2, '0');
    final mmm = months[date.month - 1];
    final yyyy = date.year.toString().padLeft(4, '0');
    return '$dd-$mmm-$yyyy'; 
  }
}