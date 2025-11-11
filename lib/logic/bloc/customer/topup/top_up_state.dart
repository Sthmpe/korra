import 'package:equatable/equatable.dart';

import '../../../../data/models/customer/topup/topup_details.dart';

enum TopUpStatus { initial, loading, loaded, verifying, failure }

class TopUpState extends Equatable {
  final TopUpStatus status;
  final TopUpDetails details;
  final String? errorMessage;

  const TopUpState({
    this.status = TopUpStatus.initial,
    required this.details,
    this.errorMessage,
  });

  factory TopUpState.initial() => TopUpState(
    status: TopUpStatus.initial,
    details: TopUpDetails(
      availableBalance: 0,
      walletAccountNumber: '__',
      walletAccountName: '__',
      walletAccountReference: '__',
      fundingSource: '__',
      lastTopUpMethod: '__',
    ),
  );

  TopUpState copyWith({
    TopUpStatus? status,
    TopUpDetails? details,
    String? errorMessage,
  }) {
    return TopUpState(
      status: status ?? this.status,
      details: details ?? this.details,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, details, errorMessage];
}
