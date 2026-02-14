import 'package:equatable/equatable.dart';

import 'bank.dart';

enum PayoutStatus { initial, loading, success, failure }
enum PayoutStep { input, createPin, verifyPin, creating, verifying, processing, completed }

class PayoutState extends Equatable {
  final PayoutStatus status;
  final PayoutStep step;
  final String? errorMessage;
  final String complianceStatus; // e.g., 'active', 'verification_pending', 'restricted'
  final String blockMessage;     // e.g., 'Video Verification Required'

  // 1. Money
  final double withdrawableBalance; // Passed in from Home
  final String amountInput;         // What user typed
  
  // 2. Destination (Bank Details)
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String bankCode;

  // 3. Security
  final bool hasPinSet; // Checked on load

  // 4. Result
  final String? transactionRef;
  final DateTime? transactionDate;

  final List<Bank> bankList;

  const PayoutState({
    required this.status,
    required this.step,
    this.errorMessage,
    required this.withdrawableBalance,
    required this.amountInput,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.bankCode,
    required this.hasPinSet,
    this.transactionRef,
    this.transactionDate,
    required this.bankList,
    this.complianceStatus = 'verification_pending', // Default to safe/blocked
    this.blockMessage = '',
  });

  factory PayoutState.initial() => const PayoutState(
    status: PayoutStatus.initial,
    step: PayoutStep.input,
    withdrawableBalance: 0.0,
    amountInput: '',
    bankName: '',
    accountNumber: '',
    accountName: '',
    bankCode: '',
    hasPinSet: false, 
    bankList: [],
  );

  PayoutState copyWith({
    PayoutStatus? status,
    PayoutStep? step,
    String? errorMessage,
    double? withdrawableBalance,
    String? amountInput,
    String? bankName,
    String? accountNumber,
    String? accountName,
    String? bankCode,
    bool? hasPinSet,
    String? transactionRef,
    DateTime? transactionDate,
    List<Bank>? bankList,
    String? complianceStatus,
    String? blockMessage,
  }) {
    return PayoutState(
      status: status ?? this.status,
      step: step ?? this.step,
      errorMessage: errorMessage, // Clear error on update usually
      withdrawableBalance: withdrawableBalance ?? this.withdrawableBalance,
      amountInput: amountInput ?? this.amountInput,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      bankCode: bankCode ?? this.bankCode,
      hasPinSet: hasPinSet ?? this.hasPinSet,
      transactionRef: transactionRef ?? this.transactionRef,
      transactionDate: transactionDate ?? this.transactionDate,
      bankList: bankList ?? this.bankList,
      complianceStatus: complianceStatus ?? this.complianceStatus,
      blockMessage: blockMessage ?? this.blockMessage,
    );
  }

  // Helper: Check if amount is valid
  bool get isAmountValid {
    final amt = double.tryParse(amountInput.replaceAll(',', '')) ?? 0.0;
    return amt > 0 && amt <= withdrawableBalance;
  }

  // Helper: Check if ready to submit
  bool get canWithdraw {
    // 1. If loading, disable button
    if (status == PayoutStatus.loading || step == PayoutStep.processing) return false;
    
    // 2. If input is empty
    if (amountInput.isEmpty) return false;

    // 3. Sanitize input (remove commas) before parsing
    final cleanInput = amountInput.replaceAll(',', '').trim();
    final amount = double.tryParse(cleanInput) ?? 0;

    // 4. Check logic: Must be > 0 AND <= Balance
    return amount > 0 && amount <= withdrawableBalance;
  }

  @override
  List<Object?> get props => [
    status, step, errorMessage, withdrawableBalance, amountInput,
    bankName, accountNumber, hasPinSet, transactionRef, bankList
  ];
}