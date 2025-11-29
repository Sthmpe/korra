import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:korra/data/repository/customer/plans_repository.dart';
import '../../../../data/repository/customer/customer_repository.dart';


enum PlansTab { active, pending, completed, overdue, canceled }
enum SortBy { nextDue, amount, progress }

// --- EVENTS ---
abstract class PlanActionEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class PayInstallmentRequested extends PlanActionEvent {
  final String planId;
  final String uid;
  final double amount;
  PayInstallmentRequested(this.planId, this.uid, this.amount);
}

class CancelPlanRequested extends PlanActionEvent {
  final String planId;
  final String uid;
  final String reason;
  CancelPlanRequested(this.planId, this.uid, this.reason);
}

// --- STATE ---
enum PlanActionStatus { initial, loading, success, error }

class PlanActionState extends Equatable {
  final PlanActionStatus status;
  final String? message; // Success or Error message

  const PlanActionState({this.status = PlanActionStatus.initial, this.message});

  @override
  List<Object?> get props => [status, message];
}

// --- BLOC ---
class PlanActionBloc extends Bloc<PlanActionEvent, PlanActionState> {
  final CustomerRepository repo;

  PlanActionBloc({required this.repo}) : super(const PlanActionState()) {
    
    // Handle Payment
    on<PayInstallmentRequested>((event, emit) async {
      emit(const PlanActionState(status: PlanActionStatus.loading));
      try {
        await repo.payInstallment(
          planId: event.planId,
          customerUid: event.uid,
          amount: event.amount
        );
        emit(const PlanActionState(status: PlanActionStatus.success, message: "Payment Successful"));
      } catch (e) {
        emit(PlanActionState(status: PlanActionStatus.error, message: e.toString()));
      }
    });

    // Handle Cancellation
    on<CancelPlanRequested>((event, emit) async {
      emit(const PlanActionState(status: PlanActionStatus.loading));
      try {
        await repo.cancelPlan(
          planId: event.planId,
          customerUid: event.uid,
          reason: event.reason
        );
        emit(const PlanActionState(status: PlanActionStatus.success, message: "Plan Cancelled. Refund processing."));
      } catch (e) {
        emit(PlanActionState(status: PlanActionStatus.error, message: e.toString()));
      }
    });
  }
}