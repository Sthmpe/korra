import 'package:flutter/foundation.dart';
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
    on<LoadPlanPreview>((event, emit) async {
      emit(state.copyWith(status: CreatePlanStatus.loadingPreview));
      final hasPlans = await repo.hasActivePlans(event.customerUid);

      try {
        debugPrint('has plan: $hasPlans');
        
        // 1. Fetch Financials from Server
        final result = await repo.fetchPlanPreview(
          customerUid: event.customerUid,
          productPrice: event.productPrice,
        );

        // 2. Calculate Tier Logic Locally (Based on Price)
        // This matches the table you gave me.
        int duration = 90;
        int notice = 10;
        int extension = 30;
        bool allowExtension = true;
        final price = event.productPrice;

        // 2. THE GRANULAR TIER LOGIC (Your Table)
        if (price <= 7000) {
          duration = 15;
          notice = 1;
          extension = 0;
          allowExtension = false;
        } else if (price <= 15000) {
          duration = 25;
          notice = 2;
          extension = 0;
          allowExtension = false;
        } else if (price <= 20000) {
          duration = 30;
          notice = 3;
          extension = 7;
          allowExtension = true;
        } else if (price <= 25000) {
          duration = 30;
          notice = 3;
          extension = 15;
          allowExtension = true;
        } else if (price <= 35000) {
          duration = 45;
          notice = 5;
          extension = 15;
          allowExtension = true;
        } else if (price <= 50000) {
          duration = 45;
          notice = 10;
          extension = 21;
          allowExtension = true;
        } else if (price <= 75000) {
          duration = 90;
          notice = 10;
          extension = 21;
          allowExtension = true;
        } else {
          // 75k - 100k (and above)
          duration = 90;
          notice = 10;
          extension = 30;
          allowExtension = true;
        }

        emit(
          state.copyWith(
            status: CreatePlanStatus.previewLoaded,
            riskEngineUpfront: (result['totalUpfront'] as num).toDouble(),
            loanAmount: (result['loanAmount'] as num).toDouble(),
            gap: (result['gap'] as num).toDouble(),
            dpPercentage: (result['dpPercentage'] as num).toDouble(),

            // ✅ Save calculated tiers
            baseDurationDays: duration,
            noticeDays: notice,
            extensionDays: extension,
            canExtend: allowExtension,
            hasActivePlans: hasPlans,
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            status: CreatePlanStatus.error,
            hasActivePlans: hasPlans,
            errorMessage: e.toString(),
          ),
        );
      }
    });

    on<ConfirmPlanCreation>((event, emit) async {
      emit(state.copyWith(status: CreatePlanStatus.creating));
      try {
        await repo.createPlanSecurely(plan: event.planModel);
        emit(state.copyWith(status: CreatePlanStatus.success));
      } catch (e) {
        String userMessage = "An unexpected error occurred.";
        if (e is KorraException) {
          userMessage = e.message;
        } else if (e is FunctionException) {
          userMessage = e.details?['error'] ?? e.reasonPhrase ?? "Server error";
        }
        emit(
          state.copyWith(
            status: CreatePlanStatus.error,
            errorMessage: userMessage,
          ),
        );
      }
    });
  }
}
