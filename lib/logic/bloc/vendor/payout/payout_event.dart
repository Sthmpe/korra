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

// KYC Events
class BvnInputChanged extends PayoutEvent {
  final String bvn;
  const BvnInputChanged(this.bvn);
}

class NinInputChanged extends PayoutEvent {
  final String nin;
  const NinInputChanged(this.nin);
}

class VerifyBvnClicked extends PayoutEvent {
  final String bvn;
  const VerifyBvnClicked(this.bvn);
}

class VerifyNinClicked extends PayoutEvent {
  final String nin;
  const VerifyNinClicked(this.nin);
}

class DobChanged extends PayoutEvent {
  final DateTime dob;
  const DobChanged(this.dob);
}

class GenderChanged extends PayoutEvent {
  final String gender;
  const GenderChanged(this.gender);
}

class EditPhoneToggled extends PayoutEvent {}
class SavePhoneClicked extends PayoutEvent {
  final String newPhone;
  const SavePhoneClicked(this.newPhone);
}