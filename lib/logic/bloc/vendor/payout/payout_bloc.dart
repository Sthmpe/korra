import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korra/data/repository/vendors/bank_repository.dart';
import 'package:korra/data/repository/vendors/pin_repository.dart';
import 'package:korra/data/repository/vendors/transfer_repository.dart';
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
  }

  Future<void> _onStarted(PayoutStarted event, Emitter<PayoutState> emit) async {
    emit(state.copyWith(
      status: PayoutStatus.loading,
      withdrawableBalance: event.currentBalance,
      amountInput: '', // ✅ FORCE CLEAR AMOUNT ON START
    ));

    try {
      // The Repo will now use Cache, making this part instant on 2nd try!
      final results = await Future.wait([
        repo.getVendorSettings(vendorUid),
        repo.getBankList(),
      ]);

      final settings = results[0] as VendorSettings;
      final banks = results[1] as List<Bank>;
      final details = settings.payoutDetails;

      emit(state.copyWith(
        status: PayoutStatus.success, // Use 'success' or 'loaded' enum
        hasPinSet: settings.isPinSet,
        bankName: details.bankName,
        accountNumber: details.bankAccountNumber,
        accountName: details.bankAccountName,
        bankCode: details.bankCode,
        bankList: banks,
      ));
    } catch (e) {
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
}