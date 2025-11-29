import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../config/utils/korra_exception.dart';
import '../../../../data/repository/customer/customer_repository.dart';

// EVENTS
abstract class ChangePasswordEvent extends Equatable {
  @override List<Object?> get props => [];
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

  @override List<Object?> get props => [status, error];
}

// BLOC
class ChangePasswordBloc extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  final CustomerRepository repo;

  ChangePasswordBloc({required this.repo}) : super(const ChangePasswordState()) {
    on<ChangePasswordSubmitted>((event, emit) async {
      emit(const ChangePasswordState(status: ChangePassStatus.loading));
      try {
        await repo.changePassword(
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