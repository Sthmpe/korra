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

  // Kyc 
  final String? bvnInput;
  final String? ninInput;
  final bool isBvnVerified;
  final bool isNinVerified;
  final String? lastVerifiedBvn;
  final String? lastVerifiedNin;
  final String? bvnVerificationError;
  final String? ninVerificationError;
  final bool bvnVerificationInProgress;
  final bool ninVerificationInProgress;
  final DateTime? dob;
  final String? gender;
  final String phone;
  final bool isEditingPhone;
  final bool isUpdatingPhone;

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
    this.bvnInput,
    this.ninInput,
    this.isBvnVerified = false,
    this.isNinVerified = false,
    this.lastVerifiedBvn,
    this.lastVerifiedNin,
    this.bvnVerificationError,
    this.ninVerificationError,
    this.bvnVerificationInProgress = false,
    this.ninVerificationInProgress = false,
    this.dob,
    this.gender,
    this.phone = '',
    this.isEditingPhone = false,
    this.isUpdatingPhone = false
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
    bvnInput: null,
    ninInput: null,
    isBvnVerified: false,
    isNinVerified: false,
    lastVerifiedBvn: null,
    lastVerifiedNin: null,
    bvnVerificationError: null,
    ninVerificationError: null,
    bvnVerificationInProgress: false,
    ninVerificationInProgress: false,
    dob: null,
    gender: null,
    phone: '',
    isEditingPhone: false,
    isUpdatingPhone: false
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
    String? bvnInput,
    String? ninInput,
    bool? isBvnVerified,
    bool? isNinVerified,
    String? lastVerifiedBvn,
    String? lastVerifiedNin,
    String? bvnVerificationError,
    String? ninVerificationError,
    bool? bvnVerificationInProgress,
    bool? ninVerificationInProgress,
    DateTime? dob,
    String? gender,
    String? phone,
    bool? isEditingPhone,
    bool? isUpdatingPhone
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
      bvnInput: bvnInput ?? this.bvnInput,
      ninInput: ninInput ?? this.ninInput,
      isBvnVerified: isBvnVerified ?? this.isBvnVerified,
      isNinVerified: isNinVerified ?? this.isNinVerified,
      lastVerifiedBvn: lastVerifiedBvn ?? this.lastVerifiedBvn,
      lastVerifiedNin: lastVerifiedNin ?? this.lastVerifiedNin,
      bvnVerificationError: bvnVerificationError ?? this.bvnVerificationError,
      ninVerificationError: ninVerificationError ?? this.ninVerificationError,
      bvnVerificationInProgress: bvnVerificationInProgress ?? this.bvnVerificationInProgress,
      ninVerificationInProgress: ninVerificationInProgress ?? this.ninVerificationInProgress,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      isEditingPhone: isEditingPhone ?? this.isEditingPhone,
      isUpdatingPhone: isUpdatingPhone ?? this.isUpdatingPhone
    );
  }

  // Helper: Check if amount is valid
  bool get canWithdraw {
    // 1. If loading, disable button
    if (status == PayoutStatus.loading || step == PayoutStep.processing) return false;
    
    // 2. If input is empty
    if (amountInput.isEmpty) return false;

    // 3. Sanitize input (remove commas) before parsing
    final cleanInput = amountInput.replaceAll(',', '').trim();
    final amount = double.tryParse(cleanInput) ?? 0;

    // 4. Calculate EMTL Fee
    final emtlFee = amount >= 10000 ? 50.0 : 0.0;
    final totalRequired = amount + emtlFee;

    // 5. Check logic: Must be >= 1000 AND (Amount + Fee) <= Balance
    return amount >= 1000 && totalRequired <= withdrawableBalance;
  }

  @override
  List<Object?> get props => [
    status, step, errorMessage, withdrawableBalance, amountInput,
    bankName, accountNumber, hasPinSet, transactionRef, bankList,
    complianceStatus, blockMessage, isBvnVerified, isNinVerified,
    lastVerifiedBvn, lastVerifiedNin, bvnVerificationError, ninVerificationError,
    bvnVerificationInProgress, ninVerificationInProgress, bvnInput, ninInput, dob, gender, phone, isEditingPhone, isUpdatingPhone
  ];
}