import 'package:equatable/equatable.dart';

enum FPStatus { idle, editing, submitting, sent, error }

class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    required this.email,
    required this.isValid,
    required this.status,
    this.error,
  });

  factory ForgotPasswordState.initial() =>
      const ForgotPasswordState(email: '', isValid: false, status: FPStatus.idle);

  final String email;
  final bool isValid;
  final FPStatus status;
  final String? error;

  ForgotPasswordState copyWith({
    String? email,
    bool? isValid,
    FPStatus? status,
    String? error,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      isValid: isValid ?? this.isValid,
      status: status ?? this.status,
      error: error,
    );
  }

  @override
  List<Object?> get props => [email, isValid, status, error];
}
