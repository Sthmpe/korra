// lib/logic/bloc/vendor/payout/payout_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korra/data/repository/vendors/bank_repository.dart';
import 'package:korra/data/repository/vendors/payout_repository.dart';

import '../../../../data/repository/vendors/vendor_repository.dart';
import 'payout_event.dart';
import 'payout_state.dart';

class PayoutBloc extends Bloc<PayoutEvent, PayoutState> {
  final String vendorUid;
  final VendorRepository vendors;

  PayoutBloc({required this.vendorUid, required this.vendors})
    : super(PayoutState.initial()) {
    on<PayoutStarted>(_onStarted);
    on<PayoutBankListLoaded>(_onBankListLoaded);
    on<AmountChanged>(_onAmountChanged);
    on<UpdateMethodTapped>(_onUpdateMethod);
    on<WithdrawTapped>(_onWithdrawTapped);
    on<PinSubmitted>(_onPinSubmitted);
    on<EditMethodToggled>(_onEditMethodToggled);
    on<BankSelected>(_onBankSelected);
    on<AccountNumberChanged>(_onAccountNumberChanged);
    on<ConfirmAndSaveMethodTapped>(_onConfirmAndSave);
    on<ResetPayoutFlow>(
      (event, emit) => emit(
        state.copyWith(
          payoutFlowStatus: PayoutFlowStatus.idle,
          createPinStep: CreatePinStep.idle,
          transactionStatusMessage: '',
        ),
      ),
    );
    on<NewPinCreated>(_onNewPinCreated);
  }

  Future<void> _onNewPinCreated(
    NewPinCreated event,
    Emitter<PayoutState> emit,
  ) async {
    // Here you can securely save PIN, trigger payout, etc.
    // For now, just update state.
    emit(
      state.copyWith(
        createPinStep: CreatePinStep.success,
        newPin: event.pin,
        createPinError: null,
      ),
    );

    // If you want to continue with payout flow:
    // emit(state.copyWith(payoutFlowStatus: PayoutFlowStatus.requiresPin));
  }

  void _onBankListLoaded(
    PayoutBankListLoaded event,
    Emitter<PayoutState> emit,
  ) {
    emit(state.copyWith(bankList: event.bankList));
  }

  Future<void> _onStarted(
    PayoutStarted event,
    Emitter<PayoutState> emit,
  ) async {
    emit(state.copyWith(status: PayoutStatus.loading));
    try {
      final details = await vendors.getPayoutDetails(vendorUid);
      vendors.getBankList().then((value) {
        add(PayoutBankListLoaded(value));
      });

      if (details != null) {
        emit(
          state.copyWith(status: PayoutStatus.loaded, payoutDetails: details),
        );
      } else {
        emit(
          state.copyWith(
            status: PayoutStatus.failure,
            errorMessage: 'Could not load payout details.',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: PayoutStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onAmountChanged(AmountChanged event, Emitter<PayoutState> emit) {
    final unformattedValue = event.amount.replaceAll(',', '');
    final amount = unformattedValue.isNotEmpty
        ? int.parse(unformattedValue)
        : 0;

    final available = state.payoutDetails.withdrawableBalance;


    if (amount == 0) {
      // Default state → show helper text
      emit(state.copyWith(amountToWithdraw: '', amountError: ''));
    } else if (amount > available) {
      // Invalid → show error
      emit(
        state.copyWith(
          amountToWithdraw: event.amount,
          amountError: 'Amount exceeds withdrawable balance',
        ),
      );
    } else {
      // Valid → no error, no helper
      emit(state.copyWith(amountToWithdraw: event.amount, amountError: ''));
    }
  }

  void _onUpdateMethod(UpdateMethodTapped event, Emitter<PayoutState> emit) {
    emit(state.copyWith(isEditingMethod: true));
  }

  Future<void> _onWithdrawTapped(
    WithdrawTapped event,
    Emitter<PayoutState> emit,
  ) async {
    // 1. Check if a PIN is required.
    final bool hasPin = false; // TODO: Replace with `await vendors.hasTransactionPin()`

    if (hasPin) {
      // If a PIN exists, we signal the UI to ask for it. This is unchanged.
      emit(state.copyWith(payoutFlowStatus: PayoutFlowStatus.requiresPin));
    } else {
      // ▼ THIS IS THE ARCHITECTURAL FIX ▼
      // Instead of navigating, the BLoC emits a state that signals
      // the navigation intent to the UI layer.
      emit(state.copyWith(payoutFlowStatus: PayoutFlowStatus.createPin));
    }
  }

  Future<void> _onPinSubmitted(
    PinSubmitted event,
    Emitter<PayoutState> emit,
  ) async {
    final bool isPinValid = event.pin == '1234'; // mock

    if (!isPinValid) {
      emit(state.copyWith(payoutFlowStatus: PayoutFlowStatus.pinInvalid));
      return;
    }

    emit(
      state.copyWith(
        payoutFlowStatus: PayoutFlowStatus.sending,
        transactionStatusMessage: 'Connecting with API...',
      ),
    );

    try {
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(transactionStatusMessage: 'Processing Transfer...'));

      // TODO: Make the actual API call here
      // await vendors.initiateTransfer(...)

      await Future.delayed(const Duration(seconds: 3));
      emit(
        state.copyWith(
          transactionStatusMessage: 'Checking Transaction Status...',
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(transactionStatusMessage: 'Done'));

      // 3. Emit the final success state.
      await Future.delayed(const Duration(milliseconds: 500));
      emit(state.copyWith(payoutFlowStatus: PayoutFlowStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          payoutFlowStatus: PayoutFlowStatus.failure,
          errorMessage: 'Transaction Failed.',
        ),
      );
    } finally {
      await Future.delayed(const Duration(seconds: 5));
      emit(state.copyWith(payoutFlowStatus: PayoutFlowStatus.idle));
    }
  }

  Future<void> _onEditMethodToggled(
    EditMethodToggled event,
    Emitter<PayoutState> emit,
  ) async {
    final currentlyEditing = state.isEditingMethod;
    emit(state.copyWith(isEditingMethod: !currentlyEditing));
  }

  void _onBankSelected(BankSelected event, Emitter<PayoutState> emit) {
    emit(state.copyWith(selectedBank: event.bank));
  }

  Future<void> _onAccountNumberChanged(
    AccountNumberChanged event,
    Emitter<PayoutState> emit,
  ) async {
    emit(
      state.copyWith(
        tempAccountNumber: event.accountNumber,
        bankDetailsVerificationStatus: BankDetailsVerificationStatus.idle,
        verifiedAccountName: '',
      ),
    );

    // Auto-verify when 10 digits are entered (standard for Nigeria)
    if (event.accountNumber.length == 10 && state.selectedBank != null) {
      emit(
        state.copyWith(
          bankDetailsVerificationStatus:
              BankDetailsVerificationStatus.verifying,
        ),
      );
      try {
        final accountName = await vendors.verifyBankAccount(
          accountNumber: event.accountNumber,
          bankCode: state.selectedBank!.code,
        );

        emit(
          state.copyWith(
            bankDetailsVerificationStatus:
                BankDetailsVerificationStatus.verified,
            verifiedAccountName: accountName,
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            bankDetailsVerificationStatus: BankDetailsVerificationStatus.error,
          ),
        );
      }
    }
  }

  /// Orchestrates the final, critical save operation after user confirmation.
  /// This method is engineered for clarity, security, and robust state management.
  Future<void> _onConfirmAndSave(
    ConfirmAndSaveMethodTapped event,
    Emitter<PayoutState> emit,
  ) async {
    // 1. Final Integrity Check: A world-class application never trusts; it verifies.
    //    We ensure the account has been successfully verified before proceeding.
    if (state.bankDetailsVerificationStatus !=
            BankDetailsVerificationStatus.verified ||
        state.selectedBank == null ||
        state.verifiedAccountName == null ||
        state.verifiedAccountName!.isEmpty) {
      // This is a programmatic error state; we do not proceed.
      return;
    }

    // 2. Intentional State Transition: 'updating'
    //    This provides a clear signal to the UI to enter a loading state,
    //    disabling the button and showing a progress indicator.
    emit(state.copyWith(status: PayoutStatus.updating));

    try {
      // 3. Create the Authoritative Data Model.
      //    This is the single source of truth for the new payout details.
      final updatedDetails = state.payoutDetails.copyWith(
        bankName: state.selectedBank!.name,
        bankCode: state.selectedBank!.code,
        bankAccountNumber: state.tempAccountNumber,
        bankAccountName: state.verifiedAccountName,
      );

      // 4. Persist to Backend.
      //    This is the point of commitment where the new data is saved.
      await vendors.savePayoutDetails(vendorUid, updatedDetails);

      // 5. Intentional Success Transition: 'loaded'
      //    On success, we perform a full state reset. This is critical for
      //    preventing stale data and ensuring the UI returns to a clean,
      //    predictable state.
      emit(
        state.copyWith(
          status: PayoutStatus.loaded,
          payoutDetails: updatedDetails,
          isEditingMethod: false, // Exit the editing UI
          // Reset all temporary and verification-related fields
          bankDetailsVerificationStatus: BankDetailsVerificationStatus.idle,
          verifiedAccountName: '',
          tempAccountNumber: '',
          selectedBank: null,
        ),
      );
    } catch (e) {
      // 6. Graceful Failure Handling.
      //    If the save operation fails, we provide a specific, user-facing
      //    error message and transition the UI back to a stable state.
      emit(
        state.copyWith(
          status: PayoutStatus.loaded, // Return to a non-loading state
          isEditingMethod:
              true, // Keep the user in the editing view to allow a retry
          errorMessage: 'Failed to save changes. Please try again.',
        ),
      );
    }
  }
}
