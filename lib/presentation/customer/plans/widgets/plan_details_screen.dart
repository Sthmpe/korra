import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../../data/models/customer/plans.dart';
import '../../../../data/repository/customer/customer_repository.dart';
import '../../../../data/repository/customer/plans_repository.dart';
import '../../../../logic/bloc/customer/plans/plan_action_cubit.dart';
import '../../../shared/widgets/korra_header.dart';
import '../../../shared/widgets/show_app_snackbar.dart';
import 'vendor_header.dart';

import 'plan_detail_status_banner.dart';
import 'plan_detail_pickup_section.dart';
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
  final currencyFormat = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 2,
  );

  int _currentImageIndex = 0;

  static const _stroke = Color(0xFFF2F4F7);

  late Stream<Plan?> _singlePlanStream;

  @override
  void initState() {
    super.initState();
    customerRepo = context.read<CustomerRepository>();
    _singlePlanStream = customerRepo.streamSinglePlan(widget.plan.id);
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
            showAppSnackbar(state.message, SnackbarType.success);
            Navigator.pop(context);
          }
          if (state is PlanActionError) {
            showAppSnackbar(state.error, SnackbarType.error);
            Navigator.pop(context);
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
                  backgroundColor: const Color(0xFFF9FAFB),
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

                        _buildProductHeader(currentPlan),

                        if (isCompleted)
                          PlanDetailPickupSection(plan: currentPlan),

                        if (!isCompleted)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: PlanDetailFinancialCard(plan: currentPlan),
                          ),

                        SizedBox(height: 16.h),

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
                          SizedBox(height: 24.h),
                        ],

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: PlanDetailInfoGrid(plan: currentPlan),
                        ),

                        SizedBox(height: 40.h),

                        if (canInteract)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 60.h),
                              child: TextButton.icon(
                                onPressed: () =>
                                    _showConversionSheet(context, currentPlan),
                                icon: Icon(
                                  Iconsax.wallet_3,
                                  size: 18.sp,
                                  color: Colors.grey.shade400,
                                ),
                                label: Text(
                                  "Close Plan & Secure Funds",
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            ),
                          ),
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

  Widget _buildImageCarousel(List<dynamic> images) {
    if (images.isEmpty) return SizedBox(height: 200.h);
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 280.h,
          width: double.infinity,
          child: PageView.builder(
            onPageChanged: (index) =>
                setState(() => _currentImageIndex = index),
            itemCount: images.length,
            itemBuilder: (context, index) => CachedNetworkImage(
              imageUrl: images[index],
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[100],
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 16.h,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: images
                  .asMap()
                  .entries
                  .map(
                    (entry) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentImageIndex == entry.key ? 16.0.w : 6.0.w,
                      height: 4.0.h,
                      margin: const EdgeInsets.symmetric(horizontal: 3.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: _currentImageIndex == entry.key
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductHeader(Plan p) {
    final bool isStrict = p.cancellationPolicy.contains("Store");
    final String modelName = isStrict ? "Strict Lock" : "Korra Direct";
    final Color modelColor = isStrict
        ? const Color(0xFF9E0A05)
        : const Color(0xFF026AA2);

    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageCarousel(p.imageUrls),
          Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VendorHeader(storeName: p.storeName),
                SizedBox(height: 12.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        p.title,
                        style: GoogleFonts.inter(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF101828),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      currencyFormat.format(p.totalAmount),
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF101828),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: modelColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    modelName,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: modelColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _stroke),
        ],
      ),
    );
  }
}
