import 'package:firebase_analytics/firebase_analytics.dart';
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
      await FirebaseAnalytics.instance.logEvent(
        name: 'plan_converted_to_store_credit',
        parameters: {'plan_id': planId},
      );
      emit(PlanActionSuccess("Your funds have been moved to Store Balance."));
    } catch (e, stackTrace) {
      _handleError("conversion", e, stackTrace);
    }
  }

  // --- 2. Extension Logic ---
  Future<void> extendPlan(String planId) async {
    emit(PlanActionLoading());
    try {
      await repo.extendPlan(planId);
      await FirebaseAnalytics.instance.logEvent(
        name: 'plan_extended',
        parameters: {'plan_id': planId},
      );
      emit(PlanActionSuccess("Plan extended. New deadline confirmed."));
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
    String userMessage = "We encountered an issue. Please try again.";

    final errorString = e.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connectivity')) {
      userMessage = "Connection lost. Please check your internet.";
    } else if (errorString.contains('permission-denied')) {
      userMessage = "You don't have permission to modify this plan.";
    } else if (errorString.contains('not-found')) {
      userMessage = "We couldn't find this plan. It might have already been updated.";
    } else if (errorString.contains('insufficient-funds')) {
      userMessage = "Eligibility requirement not met. 80% payment needed to extend.";
    } else if (errorString.contains('already-extended')) {
      userMessage = "Extension limit reached. This plan cannot be extended further.";
    }

    emit(PlanActionError(userMessage));
  }
}