import 'package:equatable/equatable.dart';

abstract class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();
  @override
  List<Object?> get props => [];
}

class FPEmailChanged extends ForgotPasswordEvent {
  const FPEmailChanged(this.email);
  final String email;
  @override
  List<Object?> get props => [email];
}

class FPSubmit extends ForgotPasswordEvent {
  const FPSubmit();
}
