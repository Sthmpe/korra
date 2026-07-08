import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../../data/models/customer/plans.dart';
import '../../../../data/repository/customer/customer_repository.dart';
import '../../../../logic/bloc/customer/plans/plan_action_cubit.dart';
import '../../../shared/widgets/korra_header.dart';
import '../../../shared/widgets/show_app_snackbar.dart';

import 'plan_detail_status_banner.dart';
import 'plan_detail_pickup_section.dart';
import 'plan_detail_product_header.dart';
import 'plan_detail_financial_card.dart';
import 'plan_detail_timeline_card.dart';
import 'plan_detail_next_payment_card.dart';
import 'plan_detail_info_grid.dart';
import 'plan_detail_sticky_action.dart';
import 'plan_detail_resolve_sheet.dart';
import 'plan_detail_conversion_sheet.dart';

class PlanDetailsScreen extends StatefulWidget {
  final Plan plan;

  const PlanDetailsScreen({
    super.key,
    required this.plan,
  });

  @override
  State<PlanDetailsScreen> createState() => _PlanDetailsScreenState();
}

class _PlanDetailsScreenState extends State<PlanDetailsScreen> {
  late final CustomerRepository customerRepo;

  late Stream<Plan?> _singlePlanStream;

  @override
  void initState() {
    super.initState();
    customerRepo = context.read<CustomerRepository>();
    _singlePlanStream = customerRepo.streamSinglePlan(widget.plan.id);
  }

  /// Pops ONLY a sheet/dialog sitting above this screen — never the screen
  /// itself. Popping blindly here used to double-pop (the sheets can also
  /// close themselves), which wedged the navigator/overlay and froze input.
  void _dismissTopSheetIfAny(BuildContext context) {
    final route = ModalRoute.of(context);
    final navigator = Navigator.of(context);
    if (route != null && !route.isCurrent && navigator.canPop()) {
      navigator.pop();
    }
  }

  /// Get.snackbar during a route transition can leave a dead overlay that
  /// swallows all taps. Defer it to the next frame so the pop settles first.
  void _showSnackbarSafely(String message, SnackbarType type) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showAppSnackbar(message, type);
    });
  }

  void _showResolveSheet(BuildContext context, Plan p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: context.read<PlanActionCubit>(),
        child: PlanDetailResolveSheet(plan: p),
      ),
    );
  }

  void _showConversionSheet(BuildContext context, Plan p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BlocProvider.value(
        value: context.read<PlanActionCubit>(),
        child: PlanDetailConversionSheet(plan: p),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlanActionCubit(customerRepo),
      child: BlocListener<PlanActionCubit, PlanActionState>(
        listener: (context, state) {
          if (state is PlanActionSuccess) {
            _dismissTopSheetIfAny(context);
            _showSnackbarSafely(state.message, SnackbarType.success);
          }
          if (state is PlanActionError) {
            _dismissTopSheetIfAny(context);
            _showSnackbarSafely(state.error, SnackbarType.error);
          }
        },
        child: StreamBuilder<Plan?>(
          stream: _singlePlanStream,
          initialData: widget.plan,
          builder: (context, snapshot) {
            final currentPlan = snapshot.data ?? widget.plan;

            final bool isCompleted = currentPlan.status == 'completed';
            final bool isCancelled = currentPlan.status == 'cancelled';
            final bool isTerminated = currentPlan.isEffectivelyTerminated;
            final bool canInteract =
                !isCompleted && !isCancelled && !isTerminated;

            return BlocBuilder<PlanActionCubit, PlanActionState>(
              builder: (context, actionState) {
                final bool isLoading = actionState is PlanActionLoading;

                return Scaffold(
                  backgroundColor: KorraColors.surface,
                  appBar: const KorraHeader(
                    title: 'Plan Details',
                    showLeadingIcon: true,
                  ),
                  bottomNavigationBar: canInteract
                      ? IgnorePointer(
                          ignoring: isLoading,
                          child: Opacity(
                            opacity: isLoading ? 0.6 : 1.0,
                            child: PlanDetailStickyAction(
                              plan: currentPlan,
                              isLoading: isLoading,
                              onResolve: () => _showResolveSheet(context, currentPlan),
                              onPay: () => Get.toNamed(
                                Routes.customerPayPlan,
                                arguments: {'plan': currentPlan},
                              ),
                            ),
                          ),
                        )
                      : null,
                  body: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isCancelled)
                          const PlanDetailStatusBanner(
                            icon: Iconsax.info_circle,
                            title: "Plan Closed",
                            subtitle: "Funds are secured in your Store Balance.",
                            color: Color(0xFF344054),
                            bg: Color(0xFFF2F4F7),
                          ),

                        if (isTerminated && !isCancelled && !isCompleted)
                          const PlanDetailStatusBanner(
                            icon: Iconsax.timer_1,
                            title: "Timeline Ended",
                            subtitle: "Plan incomplete. Funds moved to Store Balance.",
                            color: Color(0xFFB54708),
                            bg: Color(0xFFFFFAEB),
                          ),

                        if (currentPlan.isOverdue &&
                            !isTerminated &&
                            !isCancelled)
                          const PlanDetailOverdueBanner(),

                        PlanDetailProductHeader(plan: currentPlan),

                        SizedBox(height: 16.h),

                        if (isCompleted)
                          PlanDetailPickupSection(plan: currentPlan),

                        if (!isCompleted) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: PlanDetailFinancialCard(plan: currentPlan),
                          ),
                          SizedBox(height: 16.h),
                        ],

                        if (!isCompleted && !isCancelled) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: PlanDetailTimelineCard(plan: currentPlan),
                          ),
                          SizedBox(height: 16.h),
                        ],

                        if (canInteract && !currentPlan.isOverdue) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: PlanDetailNextPaymentCard(plan: currentPlan),
                          ),
                          SizedBox(height: 16.h),
                        ],

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: PlanDetailInfoGrid(plan: currentPlan),
                        ),

                        SizedBox(height: 32.h),

                        if (canInteract)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 48.h),
                              child: TextButton.icon(
                                onPressed: () =>
                                    _showConversionSheet(context, currentPlan),
                                icon: Icon(
                                  Iconsax.wallet_3,
                                  size: 18.sp,
                                  color: KorraColors.textHint,
                                ),
                                label: Text(
                                  "Close Plan & Secure Funds",
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: KorraColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        if (!canInteract) SizedBox(height: 48.h),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
