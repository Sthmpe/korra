import 'package:firebase_analytics/firebase_analytics.dart';
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

        int duration = 14;
        int notice = 3; 
        int extension = 0;
        bool allowExtension = false;
        final price = event.productPrice;

        // Check if Merchant provided custom settings
        if (event.merchantDurationDays != null && event.merchantDurationDays! > 0) {
            duration = event.merchantDurationDays!;
            allowExtension = event.allowExtension ?? false;
            extension = event.extensionDays ?? 0;
            notice = event.noticeDays ?? 3;
        } else {
            // --- GRANULAR TIER LOGIC (FALLBACK) ---
            if (price <= 50000) {
              duration = 14; notice = 3; extension = 0; allowExtension = false;
            } else if (price <= 200000) {
                duration = 21; notice = 3; extension = 5; allowExtension = true;
            } else if (price <= 500000) {
                duration = 30; notice = 3; extension = 7; allowExtension = true;
            } else if (price <= 750000) {
                duration = 60; notice = 3; extension = 7; allowExtension = true;
            } else {
                duration = 90; notice = 3; extension = 7; allowExtension = true;
            }
        }

        await FirebaseAnalytics.instance.logEvent(
          name: 'plan_preview_loaded',
          parameters: {
            'product_id': event.productId,
            'product_price': event.productPrice,
            'min_downpayment': (result['minDownPayment'] as num).toDouble(),
            'has_active_plans': hasPlans ? 1 : 0,
          },
        );

        emit(
          state.copyWith(
            status: CreatePlanStatus.previewLoaded,
            
            riskEngineUpfront: (result['minDownPayment'] as num).toDouble(),
            secureToken: result['secureToken'] as String?, 
            
            loanAmount: (price - (result['minDownPayment'] as num)).toDouble(),
            dpPercentage: ((result['minDownPayment'] as num) / price) * 100,

            // ✅ Write the final calculated days to the state
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

        await FirebaseAnalytics.instance.logEvent(
          name: 'plan_created',
          parameters: {
            'product_id': event.planModel.productId,
            'value': event.planModel.totalAmount,      // product price
            'vendor_id': event.planModel.vendorId,
            'downpayment': event.downPayment,          // upfront amount paid
            'loan_amount': state.loanAmount,
            'duration_days': state.baseDurationDays,
          },
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

        await FirebaseAnalytics.instance.logEvent(
          name: 'plan_creation_failed',
          parameters: {
            'error_message': userMessage,
          },
        );

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