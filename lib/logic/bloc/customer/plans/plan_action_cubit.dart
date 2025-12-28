import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:korra/data/repository/customer/plans_repository.dart';
import '../../../../data/repository/customer/customer_repository.dart';

// --- States ---
abstract class PlanActionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PlanActionInitial extends PlanActionState {}
class PlanActionLoading extends PlanActionState {}
class PlanActionSuccess extends PlanActionState {
  final String message;
  PlanActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}
class PlanActionError extends PlanActionState {
  final String error;
  PlanActionError(this.error);
  @override
  List<Object?> get props => [error];
}

// --- Cubit ---
class PlanActionCubit extends Cubit<PlanActionState> {
  final CustomerRepository repo;

  PlanActionCubit(this.repo) : super(PlanActionInitial());

  // --- 1. Conversion Logic ---
  Future<void> convertToStoreCredit({
    required String planId,
    required String customerUid,
  }) async {
    emit(PlanActionLoading());
    try {
      await repo.cancelPlan(
        planId: planId,
        customerUid: customerUid,
        reason: "User converted to Store Credit",
      );
      emit(PlanActionSuccess("Your balance has been moved to Store Credit."));
    } catch (e, stackTrace) {
      _handleError("conversion", e, stackTrace);
    }
  }

  // --- 2. Extension Logic ---
  Future<void> extendPlan(String planId) async {
    emit(PlanActionLoading());
    try {
      await repo.extendPlan(planId);
      emit(PlanActionSuccess("Success! New deadline set. 🗓️"));
    } catch (e, stackTrace) {
      _handleError("extension", e, stackTrace);
    }
  }

  // --- Private Error Mapper ---
  void _handleError(String action, Object e, StackTrace stack) {
    // 1. Log the technical details for the developer
    debugPrint("❌ ERROR during $action: $e");
    debugPrint("Stacktrace: $stack");

    // 2. Map to a User-Friendly message
    String userMessage = "Something went wrong. Please try again later.";

    final errorString = e.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connectivity')) {
      userMessage = "No internet connection. Please check your signal and try again.";
    } else if (errorString.contains('permission-denied')) {
      userMessage = "You don't have permission to modify this plan.";
    } else if (errorString.contains('not-found')) {
      userMessage = "We couldn't find this plan. It might have already been updated.";
    } else if (errorString.contains('insufficient-funds')) {
      userMessage = "You haven't reached the 80% requirement to extend this plan.";
    } else if (errorString.contains('already-extended')) {
      userMessage = "This plan has already been extended and cannot be extended again.";
    }

    emit(PlanActionError(userMessage));
  }
}