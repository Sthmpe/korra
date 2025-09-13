import 'package:equatable/equatable.dart';

import '../../../../data/models/vendor/payout/payout_details.dart';
import '../../../../data/models/vendor/payout/payout_history.dart';
import 'bank.dart';

enum PayoutStatus { initial, loading, loaded, updating, success, failure }

enum BankDetailsVerificationStatus { idle, verifying, verified, error }

enum PayoutNavigation { none, toCreatePin }

enum PayoutFlowStatus {
  idle,          // The default, ready state
  requiresPin,   // The UI must now ask for the user's PIN
  pinInvalid,    // The entered PIN was incorrect
  sending,       // The transaction is in progress (controls the overlay)
  success,       // The transaction is complete and successful
  failure,       // The transaction has failed
}

enum CreatePinStep { idle, entering, confirming, success, error }

class PayoutState extends Equatable {
  final PayoutStatus status;
  final PayoutDetails payoutDetails;
  final String amountToWithdraw;
  final String? errorMessage;
  final List<PayoutHistory> history;
  final bool isEditingMethod;
  final List<Bank> bankList;
  final Bank? selectedBank;
  final String tempAccountNumber;
  final BankDetailsVerificationStatus bankDetailsVerificationStatus;
  final String? verifiedAccountName;
  final PayoutFlowStatus payoutFlowStatus;
  final String transactionStatusMessage;
  final PayoutNavigation navigateTo;
  final String? amountError;
  final CreatePinStep createPinStep;
  final String newPin;
  final String confirmPin;
  final String? createPinError;


  const PayoutState({
    required this.status,
    required this.payoutDetails,
    this.amountToWithdraw = '',
    this.errorMessage,
    required this.history,
    this.isEditingMethod = false,
    this.bankList = const [],
    this.selectedBank,
    this.tempAccountNumber = '',
    this.bankDetailsVerificationStatus = BankDetailsVerificationStatus.idle,
    this.verifiedAccountName,
    this.payoutFlowStatus = PayoutFlowStatus.idle,
    this.transactionStatusMessage = '',
    this.navigateTo = PayoutNavigation.none,
    this.amountError,
    this.createPinStep = CreatePinStep.idle,
    this.newPin = '',
    this.confirmPin = '',
    this.createPinError,
  });

  factory PayoutState.initial() => PayoutState(
    status: PayoutStatus.initial,
    payoutDetails: PayoutDetails.empty(),
    history: const [],
  );

  PayoutState copyWith({
    PayoutStatus? status,
    PayoutDetails? payoutDetails,
    String? amountToWithdraw,
    String? errorMessage,
    List<PayoutHistory>? history,
    bool? isEditingMethod,
    List<Bank>? bankList,
    Bank? selectedBank,
    String? tempAccountNumber,
    BankDetailsVerificationStatus? bankDetailsVerificationStatus,
    String? verifiedAccountName,
    PayoutFlowStatus? payoutFlowStatus,
    String? transactionStatusMessage,
    PayoutNavigation? navigateTo,
    String? amountError,
    CreatePinStep? createPinStep,
    String? newPin,
    String? confirmPin,
    String? createPinError,
  }) {
    return PayoutState(
      status: status ?? this.status,
      payoutDetails: payoutDetails ?? this.payoutDetails,
      amountToWithdraw: amountToWithdraw ?? this.amountToWithdraw,
      errorMessage: errorMessage ?? this.errorMessage,
      history: history ?? this.history,
      isEditingMethod: isEditingMethod ?? this.isEditingMethod,
      bankList: bankList ?? this.bankList,
      selectedBank: selectedBank ?? this.selectedBank,
      tempAccountNumber: tempAccountNumber ?? this.tempAccountNumber,
      bankDetailsVerificationStatus: bankDetailsVerificationStatus ?? this.bankDetailsVerificationStatus,
      verifiedAccountName: verifiedAccountName ?? this.verifiedAccountName,
      payoutFlowStatus: payoutFlowStatus ?? this.payoutFlowStatus,
      transactionStatusMessage: transactionStatusMessage ?? this.transactionStatusMessage,
      navigateTo: navigateTo ?? this.navigateTo,
      amountError: amountError ?? this.amountError,
      createPinStep: createPinStep ?? this.createPinStep,
      newPin: newPin ?? this.newPin,
      confirmPin: confirmPin ?? this.confirmPin,
      createPinError: createPinError ?? this.createPinError,
    );
  }


  @override
  List<Object?> get props => [
    status,
    payoutDetails,
    amountToWithdraw,
    errorMessage,
    history,
    isEditingMethod,
    bankList,
    selectedBank,
    tempAccountNumber,
    bankDetailsVerificationStatus,
    verifiedAccountName,
    payoutFlowStatus,
    transactionStatusMessage,
    navigateTo,
    amountError,
    createPinStep,
    newPin,
    confirmPin,
    createPinError,
  ];
}



