// lib/logic/bloc/vendor/payout/payout_bloc.dart
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../data/repository/vendors/vendor_repository.dart';
import 'bank.dart';
import 'payout_event.dart';
import 'payout_state.dart';

class PayoutBloc extends Bloc<PayoutEvent, PayoutState> {
  final String vendorUid;
  final VendorRepository vendors;

  PayoutBloc({required this.vendorUid, required this.vendors})
      : super(PayoutState.initial()) {
    on<PayoutStarted>(_onStarted);
    on<AmountChanged>(_onAmountChanged);
    on<UpdateMethodTapped>(_onUpdateMethod);
    on<WithdrawTapped>(_onWithdraw);
    on<EditMethodToggled>(_onEditMethodToggled);
    on<BankSelected>(_onBankSelected);
    on<AccountNumberChanged>(_onAccountNumberChanged);
    on<ConfirmAndSaveMethodTapped>(_onConfirmAndSave);
  }

  Future<void> _onStarted(PayoutStarted event, Emitter<PayoutState> emit) async {
    emit(state.copyWith(status: PayoutStatus.loading));
    debugPrint('PayoutStarted: $event');
    try {
      final details = await vendors.getPayoutDetails(vendorUid);
      debugPrint('Details: $details');
      if (details != null) {
        emit(state.copyWith(status: PayoutStatus.loaded, payoutDetails: details));
      } else {
        emit(state.copyWith(
            status: PayoutStatus.failure, errorMessage: 'Could not load payout details.'));
      }
    } catch (e) {
      emit(state.copyWith(status: PayoutStatus.failure, errorMessage: e.toString()));
    }
  }

  void _onAmountChanged(AmountChanged event, Emitter<PayoutState> emit) {
    emit(state.copyWith(amountToWithdraw: event.amount));
  }

  void _onUpdateMethod(UpdateMethodTapped event, Emitter<PayoutState> emit) {
    emit(state.copyWith(isEditingMethod: true));
  }

  void _onWithdraw(WithdrawTapped event, Emitter<PayoutState> emit) {
    // TODO: Add validation and call the repository to initiate the payout.
    // This would call your 'transfer-single' Supabase function.
    final amount = state.amountToWithdraw;
    Get.snackbar('Payout Initiated', 'Withdrawing ₦$amount...');
  }
  
  Future<void> _onEditMethodToggled(EditMethodToggled event, Emitter<PayoutState> emit) async {
    final currentlyEditing = state.isEditingMethod;
    // When entering edit mode, fetch the bank list.
    if (!currentlyEditing) {
      // TODO: Fetch bank list from repository
      // final banks = await vendors.getBankList();
      // For now, we'll use mock data.
      const banks = [Bank(name: 'Kuda Bank', code: '090267'), Bank(name: 'GTBank', code: '000013')];
      
      emit(state.copyWith(
        isEditingMethod: true,
        bankList: banks,
        selectedBank: null,
        tempAccountNumber: '',
        bankDetailsVerificationStatus: BankDetailsVerificationStatus.idle,
        verifiedAccountName: '',
      ));
    } else {
      // Exiting edit mode resets everything.
      emit(state.copyWith(isEditingMethod: false));
    }
  }

  void _onBankSelected(BankSelected event, Emitter<PayoutState> emit) {
    emit(state.copyWith(selectedBank: event.bank));
  }

  Future<void> _onAccountNumberChanged(AccountNumberChanged event, Emitter<PayoutState> emit) async {
    emit(state.copyWith(
      tempAccountNumber: event.accountNumber,
      bankDetailsVerificationStatus: BankDetailsVerificationStatus.idle,
      verifiedAccountName: '',
    ));

    // Auto-verify when 10 digits are entered (standard for Nigeria)
    if (event.accountNumber.length == 10 && state.selectedBank != null) {
      emit(state.copyWith(bankDetailsVerificationStatus: BankDetailsVerificationStatus.verifying));
      try {
        // TODO: Call repository to verify account
        // final accountName = await vendors.verifyBankAccount(
        //   accountNumber: event.accountNumber,
        //   bankCode: state.selectedBank!.code,
        // );
        
        // Simulate a successful verification
        await Future.delayed(const Duration(milliseconds: 1500));
        const accountName = 'JOHN DOE'; // Mocked name

        emit(state.copyWith(
          bankDetailsVerificationStatus: BankDetailsVerificationStatus.verified,
          verifiedAccountName: accountName,
        ));
      } catch (e) {
        emit(state.copyWith(bankDetailsVerificationStatus: BankDetailsVerificationStatus.error));
      }
    }
  }
  
  /// Orchestrates the final save operation after user confirmation.
  Future<void> _onConfirmAndSave(
    ConfirmAndSaveMethodTapped event,
    Emitter<PayoutState> emit,
  ) async {
    // 1. Final validation before proceeding. This check ensures data integrity.
    if (state.selectedBank == null ||
        state.verifiedAccountName == null ||
        state.tempAccountNumber.isEmpty) {
      emit(state.copyWith(
        status: PayoutStatus.failure,
        errorMessage: 'Verification data is missing. Please try again.',
      ));
      return;
    }

    // 2. Emit 'updating' status to show loading feedback on the "Confirm" button.
    emit(state.copyWith(status: PayoutStatus.updating));

    try {
      // 3. Create the new, updated PayoutDetails object from the verified state data.
      final updatedDetails = state.payoutDetails.copyWith(
        bankName: state.selectedBank!.name,
        bankCode: state.selectedBank!.code,
        bankAccountNumber: state.tempAccountNumber,
        bankAccountName: state.verifiedAccountName,
        // Any other relevant fields from verification would be mapped here.
      );

      // 4. Persist the updated details to your backend (Firestore).
      //await vendors.savePayoutDetails(vendorUid, updatedDetails);

      // 5. Success: Transition UI back to display mode.
      // We emit the 'loaded' status, set 'isEditingMethod' to false,
      // pass the new details to update the UI, and reset temporary fields.
      emit(state.copyWith(
        status: PayoutStatus.loaded,
        isEditingMethod: false,
        payoutDetails: updatedDetails,
        bankDetailsVerificationStatus: BankDetailsVerificationStatus.idle,
        verifiedAccountName: '',
        tempAccountNumber: '',
      ));
      
    } catch (e) {
      // 6. Failure: Report the error to the user.
      emit(state.copyWith(
        status: PayoutStatus.failure,
        errorMessage: 'Failed to save changes. Please try again.',
      ));
    }
  }
}