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
    
    // =========================================================================
    // 1. LOAD PREVIEW (Get Min DP & Secure Token)
    // =========================================================================
    on<LoadPlanPreview>((event, emit) async {
      emit(state.copyWith(status: CreatePlanStatus.loadingPreview));
      
      // We check active plans locally just for UI state (button color etc), 
      // but the real enforcement happens on the server.
      final hasPlans = await repo.hasActivePlans(event.customerUid);

      try {
        // 1. Fetch Financials from Server (Risk Engine)
        // This returns { minDownPayment, secureToken }
        final result = await repo.fetchPlanPreview(
          customerUid: event.customerUid,
          productPrice: event.productPrice,
          productId: event.productId,
        );

        // 2. Calculate Tier Logic Locally (Based on Price Table)
        int duration = 14;
        int notice = 3; 
        int extension = 0;
        bool allowExtension = false;
        final price = event.productPrice;

        // --- GRANULAR TIER LOGIC ---
        if (price <= 7000) {
          duration = 14; notice = 3; extension = 0; allowExtension = false;
        } else if (price <= 15000) {
          duration = 21; notice = 3; extension = 0; allowExtension = false;
        } else if (price <= 20000) {
          duration = 21; notice = 3; extension = 7; allowExtension = true;
        } else if (price <= 25000) {
          duration = 25; notice = 3; extension = 7; allowExtension = true;
        } else if (price <= 35000) {
          duration = 30; notice = 3; extension = 7; allowExtension = true;
        } else if (price <= 50000) {
          duration = 35; notice = 3; extension = 14; allowExtension = true;
        } else if (price <= 75000) {
          duration = 45; notice = 3; extension = 14; allowExtension = true;
        } else {
          // 75k - 100k+
          duration = 56; notice = 3; extension = 14; allowExtension = true;
        }

        emit(
          state.copyWith(
            status: CreatePlanStatus.previewLoaded,
            
            // Financials from Server
            riskEngineUpfront: (result['minDownPayment'] as num).toDouble(),
            secureToken: result['secureToken'] as String?, // ✅ Store the key!
            
            // Computed Display Values
            loanAmount: (price - (result['minDownPayment'] as num)).toDouble(),
            dpPercentage: ((result['minDownPayment'] as num) / price) * 100,

            // Local Tiers
            baseDurationDays: duration,
            noticeDays: notice,
            extensionDays: extension,
            canExtend: allowExtension,
            
            hasActivePlans: hasPlans,
          ),
        );
      } catch (e) {
        // If error is "Slot Limit", we flag it so UI shows "View Plans" button
        final isSlotError = e.toString().contains("Slot Limit");
        
        emit(
          state.copyWith(
            status: CreatePlanStatus.error,
            hasActivePlans: isSlotError || hasPlans, 
            errorMessage: e.toString().replaceAll("Exception: ", ""),
          ),
        );
      }
    });

    // =========================================================================
    // 2. CONFIRM CREATION (Send Token + Money)
    // =========================================================================
    on<ConfirmPlanCreation>((event, emit) async {
      // Safety Check
      if (state.secureToken == null) {
         emit(state.copyWith(status: CreatePlanStatus.error, errorMessage: "Session expired. Please refresh."));
         return;
      }

      emit(state.copyWith(status: CreatePlanStatus.creating));
      
      try {
        await repo.createPlanSecurely(
          plan: event.planModel, 
          totalDebitAmount: event.downPayment, // (Principal + Fee)
          secureToken: state.secureToken!      // ✅ Handshake
        );
        
        emit(state.copyWith(status: CreatePlanStatus.success));
      } catch (e) {
        String userMessage = "An unexpected error occurred.";
        
        if (e is KorraException) {
          userMessage = e.message;
        } else if (e is FunctionException) {
          // Extract Supabase error message safely
          final details = e.details;
          if (details is Map) {
             userMessage = details['error'] ?? details['message'] ?? e.reasonPhrase ?? "Server Error";
          } else if (details is String) {
             userMessage = details;
          }
        } else {
          userMessage = e.toString().replaceAll("Exception: ", "");
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