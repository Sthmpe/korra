import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korra/data/repository/customer/plans_repository.dart';
import '../../../../config/utils/korra_exception.dart';
import '../../../../data/repository/customer/customer_repository.dart';

// --- EVENTS ---
abstract class PayPlanEvent {}

class PayInstallmentConfirmed extends PayPlanEvent {
  final String planId;
  final String customerUid;
  final double amount;

  PayInstallmentConfirmed({
    required this.planId, 
    required this.customerUid, 
    required this.amount
  });
}

// --- STATE ---
enum PayPlanStatus { initial, loading, success, failure }

class PayPlanState {
  final PayPlanStatus status;
  final String? errorMessage;

  const PayPlanState({this.status = PayPlanStatus.initial, this.errorMessage});
}

// --- BLOC ---
class PayPlanBloc extends Bloc<PayPlanEvent, PayPlanState> {
  final CustomerRepository repo;

  PayPlanBloc({required this.repo}) : super(const PayPlanState()) {
    on<PayInstallmentConfirmed>(_onPayConfirmed);
  }

  Future<void> _onPayConfirmed(PayInstallmentConfirmed event, Emitter<PayPlanState> emit) async {
    emit(const PayPlanState(status: PayPlanStatus.loading));
    
    try {
      // Call the Repo (which calls the Edge Function)
      await repo.payInstallment(
        planId: event.planId,
        customerUid: event.customerUid,
        amount: event.amount,
      );
      
      emit(const PayPlanState(status: PayPlanStatus.success));
    } catch (e) {
      String msg = "Payment failed. Please try again.";
      if (e is KorraException) {
        msg = e.message; // Use the specific message from the Edge Function (e.g. "Insufficient Balance")
      }
      emit(PayPlanState(status: PayPlanStatus.failure, errorMessage: msg));
    }
  }
}