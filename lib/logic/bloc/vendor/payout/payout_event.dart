import 'package:equatable/equatable.dart';

abstract class PayoutEvent extends Equatable {
  const PayoutEvent();
  @override
  List<Object?> get props => [];
}

// ✅ FIXED: Added currentBalance
class PayoutStarted extends PayoutEvent {
  final double currentBalance;
  const PayoutStarted(this.currentBalance);
  @override
  List<Object?> get props => [currentBalance];
}

class AmountChanged extends PayoutEvent {
  final String input;
  const AmountChanged(this.input);
  @override
  List<Object?> get props => [input];
}

class BankDetailsUpdated extends PayoutEvent {
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String bankCode;

  const BankDetailsUpdated({
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.bankCode,
  });
  @override
  List<Object?> get props => [bankName, accountNumber, accountName, bankCode];
}

class WithdrawClicked extends PayoutEvent {}

class PinSubmitted extends PayoutEvent {
  final String pin;
  const PinSubmitted(this.pin);
  @override
  List<Object?> get props => [pin];
}

class NewPinCreated extends PayoutEvent {
  final String pin;
  const NewPinCreated(this.pin);
  @override
  List<Object?> get props => [pin];
}

class PayoutReset extends PayoutEvent {}