import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../config/utils/korra_exception.dart';

// 1. Define the function signature
typedef ChangePasswordCallback = Future<void> Function({
  required String currentPassword,
  required String newPassword,
});

// EVENTS
abstract class ChangePasswordEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChangePasswordSubmitted extends ChangePasswordEvent {
  final String currentPass;
  final String newPass;

  ChangePasswordSubmitted(this.currentPass, this.newPass);
}

// STATE
enum ChangePassStatus { initial, loading, success, failure }

class ChangePasswordState extends Equatable {
  final ChangePassStatus status;
  final String? error;

  const ChangePasswordState({this.status = ChangePassStatus.initial, this.error});

  @override
  List<Object?> get props => [status, error];
}

// BLOC
class ChangePasswordBloc extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  // 2. Accept the function instead of a specific Repository class
  final ChangePasswordCallback changePassword;

  ChangePasswordBloc({required this.changePassword}) : super(const ChangePasswordState()) {
    on<ChangePasswordSubmitted>((event, emit) async {
      emit(const ChangePasswordState(status: ChangePassStatus.loading));
      try {
        // 3. Call the injected function
        await changePassword(
          currentPassword: event.currentPass,
          newPassword: event.newPass,
        );
        emit(const ChangePasswordState(status: ChangePassStatus.success));
      } catch (e) {
        final msg = e is KorraException ? e.message : "Failed to update password";
        emit(ChangePasswordState(status: ChangePassStatus.failure, error: msg));
      }
    });
  }
}