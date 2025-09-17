import 'package:equatable/equatable.dart';

import 'bank.dart';

abstract class PayoutEvent extends Equatable {
  const PayoutEvent();
  @override
  List<Object?> get props => [];
}

class PayoutStarted extends PayoutEvent {
  const PayoutStarted();
}

class PayoutBankListLoaded extends PayoutEvent {
  final List<Bank> bankList;
  
  const PayoutBankListLoaded(this.bankList);
}

class AmountChanged extends PayoutEvent {
  final String amount;
  const AmountChanged(this.amount);
  @override
  List<Object?> get props => [amount];
}

class UpdateMethodTapped extends PayoutEvent {}

class WithdrawTapped extends PayoutEvent {}

class EditMethodToggled extends PayoutEvent {}

// ▼ NEW events for the advanced flow
class BankSelected extends PayoutEvent {
  final Bank bank;
  const BankSelected(this.bank);
  @override List<Object?> get props => [bank];
}

class AccountNumberChanged extends PayoutEvent {
  final String accountNumber;
  const AccountNumberChanged(this.accountNumber);
  @override List<Object?> get props => [accountNumber];
}

class ConfirmAndSaveMethodTapped extends PayoutEvent {}

class PinSubmitted extends PayoutEvent {
  final String pin;
  const PinSubmitted(this.pin);
  @override
  List<Object?> get props => [pin];
}

class ResetPayoutFlow extends PayoutEvent {}

class NewPinCreated extends PayoutEvent {
  final String pin;

  const NewPinCreated(this.pin);

  @override
  List<Object?> get props => [pin];
}