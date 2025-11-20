import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

class HomeStarted extends HomeEvent {}
class PasteLinkSubmitted extends HomeEvent {
  final String value;
  final double balance;
  const PasteLinkSubmitted(this.value, this.balance);
  @override
  List<Object?> get props => [value, balance];
}

class WalletBalanceUpdated extends HomeEvent {
  final double balance;
  const WalletBalanceUpdated(this.balance);

  @override
  List<Object?> get props => [balance];
}

class ScanRequested extends HomeEvent {}
class RequestLinkSheetOpened extends HomeEvent {}
