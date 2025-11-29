import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korra/data/repository/customer/plans_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/utils/korra_exception.dart';
import '../../../../data/repository/customer/customer_repository.dart';
import 'create_plan_event.dart';
import 'create_plan_state.dart';

class CreatePlanBloc extends Bloc<CreatePlanEvent, CreatePlanState> {
  final CustomerRepository repo;

  CreatePlanBloc({required this.repo}) : super(const CreatePlanState()) {
    // 1. LOAD PREVIEW (Calls Supabase)
    on<LoadPlanPreview>((event, emit) async {
      emit(state.copyWith(status: CreatePlanStatus.loadingPreview));
      try {
        // Fetch dynamic math from server
        final result = await repo.fetchPlanPreview(
          customerUid: event.customerUid,
          productPrice: event.productPrice,
        );

        emit(
          state.copyWith(
            status: CreatePlanStatus.previewLoaded,
            riskEngineUpfront: (result['totalUpfront'] as num).toDouble(),
            loanAmount: (result['loanAmount'] as num).toDouble(),
            gap: (result['gap'] as num).toDouble(),
            dpPercentage: (result['dpPercentage'] as num).toDouble(),
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            status: CreatePlanStatus.error,
            errorMessage: e.toString(),
          ),
        );
      }
    });

    // 2. CONFIRM CREATION
    on<ConfirmPlanCreation>((event, emit) async {
      emit(state.copyWith(status: CreatePlanStatus.creating));
      try {
        await repo.createPlanSecurely(plan: event.planModel);
        emit(state.copyWith(status: CreatePlanStatus.success));
      } catch (e) {
        // Default message
        String userMessage = "An unexpected error occurred.";

        // Use the friendly message if available
        if (e is KorraException) {
          userMessage = e.message;
        } else if (e is FunctionException) {
          // Supabase specific errors often have a 'details' map
          userMessage = e.details?['error'] ?? e.reasonPhrase ?? "Server error";
        }

        emit(
          state.copyWith(
            status: CreatePlanStatus.error,
            errorMessage: userMessage, // Show this to the user
          ),
        );
      }
    });
  }
}
