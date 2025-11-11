import 'package:equatable/equatable.dart';

abstract class TopUpEvent extends Equatable {
  const TopUpEvent();

  @override
  List<Object?> get props => [];
}

/// When the top-up screen is opened
class TopUpStarted extends TopUpEvent {
  const TopUpStarted();

  @override
  List<Object?> get props => [];
}

/// When the user presses "I've made payment"
class TopUpRefreshRequested extends TopUpEvent {
  const TopUpRefreshRequested();

  @override
  List<Object?> get props => [];
}

class VerifyPaymentPressed extends TopUpEvent {
  const VerifyPaymentPressed();

  @override
  List<Object?> get props => [];
}