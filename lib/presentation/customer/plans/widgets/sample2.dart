import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:korra/data/repository/customer/plans_repository.dart';

import '../../../../config/constants/colors.dart';
import '../../../../data/models/customer/plans.dart';
import '../../../../data/repository/customer/customer_repository.dart';
import '../../../../logic/bloc/customer/plans/plan_action_cubit.dart';
import '../../../shared/widgets/korra_header.dart';
import '../../../shared/widgets/show_app_snackbar.dart';
import 'pay_plan_input_screen.dart';
import 'vendor_header.dart';

class PlanDetailsScreen extends StatelessWidget {
  final Plan plan;
  final CustomerRepository customerRepo;

  PlanDetailsScreen({
    super.key,
    required this.plan,
    required this.customerRepo,
  });

  final currencyFormat = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 0,
  );

  static const _brand = KorraColors.brand;
  static const _stroke = Color(0xFFEAE6E2);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlanActionCubit(customerRepo),
      child: StreamBuilder<Plan?>(
        stream: customerRepo.streamSinglePlan(plan.id),
        initialData: plan,
        builder: (context, snapshot) {
          final currentPlan = snapshot.data ?? plan;

          final isCompleted = currentPlan.status == 'completed';
          final isCancelled = currentPlan.status == 'cancelled';
          final canInteract = !isCompleted && !isCancelled;

          return BlocListener<PlanActionCubit, PlanActionState>(
            listener: (context, state) {
              if (state is PlanActionSuccess) {
                showAppSnackbar(state.message, SnackbarType.success);
              }
              if (state is PlanActionError) {
                showAppSnackbar(state.error, SnackbarType.error);
              }
            },
            child: BlocBuilder<PlanActionCubit, PlanActionState>(
              builder: (context, actionState) {
                final isLoading = actionState is PlanActionLoading;
                return Stack(
                  children: [
                    Scaffold(
                      backgroundColor: Colors.white,
                      appBar: KorraHeader(
                        title: 'Plan Details',
                        showLeadingIcon: true,
                      ),

                      // Sticky Bottom Bar: Shows "Pay Now" or "Resolve Overdue"
                      bottomNavigationBar: canInteract
                        ? IgnorePointer(
                            ignoring: isLoading, // 🛡️ Prevent double-taps while loading
                            child: Opacity(
                              opacity: isLoading ? 0.6 : 1.0,
                              child: _buildStickyAction(context, currentPlan),
                            ),
                          )
                        : null,
                      body: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🛑 1. STATUS BANNERS
                            if (isCancelled) _buildCancelledBanner(currentPlan),
                            if (currentPlan.isOverdue && !isCancelled)
                              _buildOverdueBanner(currentPlan),

                            // --- A. PRODUCT HERO ---
                            _buildProductHeader(currentPlan),

                            // --- B. FINANCIAL PROGRESS ---
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: _buildFinancialCard(currentPlan),
                            ),

                            SizedBox(height: 16.h),

                            // --- C. TIMELINE & DEADLINE ---
                            if (canInteract) ...[
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.w),
                                child: _buildTimelineCard(currentPlan),
                              ),
                              SizedBox(height: 24.h),
                            ],

                            // --- D. PAYMENT INFO ---
                            // Only show "Next Payment" if active AND NOT Overdue (Overdue has its own banner)
                            if (canInteract && !currentPlan.isOverdue) ...[
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.w),
                                child: Text(
                                  "Next Payment",
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.w),
                                child: _buildNextPaymentCard(currentPlan),
                              ),
                              SizedBox(height: 32.h),
                            ],

                            // --- E. PLAN METADATA ---
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              child: Text(
                                "Plan Information",
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              child: _buildInfoGrid(currentPlan),
                            ),

                            SizedBox(height: 40.h),

                            // --- F. CANCEL BUTTON ---
                            // Only show generic cancel if NOT Overdue (Overdue uses specific Resolve flow)
                            if (canInteract)
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 60.h),
                                  child: TextButton.icon(
                                    onPressed: () {
                                      _confirmExtension(context, currentPlan);
                                    },
                                    icon: Icon(
                                      Iconsax.info_circle,
                                      size: 18.sp,
                                      color: Colors.grey.shade400,
                                    ),
                                    label: Text(
                                      "End Plan & Convert",
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
                    ),

                    if (isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.2),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(_brand),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 🛑 STATUS BANNERS
  // ===========================================================================

  Widget _buildOverdueBanner(Plan p) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFEF2F2), // Light Red
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Icon(Iconsax.warning_2, color: Colors.red, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Action Required: Overdue",
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade900,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  "Resolve now to avoid automatic conversion to Store Credit.",
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.red.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledBanner(Plan p) {
    // Determine context based on Policy used
    // Since Plan model doesn't have 'cancellationReason', we infer from Policy
    final bool isStrict = p.cancellationPolicy.contains("50%");

    String title = "Plan Cancelled";
    String body = "This plan has been terminated.";
    Color bgColor = Colors.grey.shade100;
    Color iconColor = Colors.grey;
    IconData icon = Iconsax.close_circle;

    if (isStrict) {
      // Likely Refund or Default
      title = "Plan Terminated";
      body = "Funds have been processed according to the 50% Refund Policy.";
      bgColor = const Color(0xFFFEF2F2);
      iconColor = Colors.red;
    } else {
      // Direct -> Likely Store Credit
      title = "Converted to Store Credit";
      body = "Your equity has been moved to your Store Credit balance.";
      bgColor = const Color(0xFFFFF7ED);
      iconColor = Colors.orange;
      icon = Iconsax.wallet_check;
    }

    return Container(
      width: double.infinity,
      color: bgColor,
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 🕹️ ACTION & LOGIC
  // ===========================================================================

  Widget _buildStickyAction(BuildContext context, Plan p) {
    final bool isOverdue = p.isOverdue;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20.w,
        18.h,
        20.w,
        24.h + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        //border: Border(top: BorderSide(color: _stroke)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Outstanding Balance",
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: const Color(0xFF667085),
                  ),
                ),
                Text(
                  currencyFormat.format(p.outstandingLoanAmount),
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            width: 160.w, // Wider for "Resolve Overdue"
            height: 52.h,
            child: FilledButton(
              onPressed: () {
                if (isOverdue) {
                  _showResolveOverdueSheet(context, p);
                } else {
                  Get.to(() => PayPlanInputScreen(plan: p, repo: customerRepo));
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: isOverdue ? Colors.red.shade600 : _brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                isOverdue ? "Resolve Plan" : "Pay Now",
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 THE NEW RESOLVE LOGIC SHEET
  void _showResolveOverdueSheet(BuildContext context, Plan p) {
    // 2. Check Extension Eligibility (80% Rule)
    final double percentPaid = p.totalAmount == 0
        ? 0
        : (p.amountPaid / p.totalAmount);
    final bool hasExtensionEnabled = p.extensionGraceDays > 0;

    // Can extend IF enabled AND paid >= 80%
    final bool canExtend = hasExtensionEnabled && percentPaid >= 0.80;

    // Show locked option IF enabled but < 80%
    final bool showLockedExtension = hasExtensionEnabled && percentPaid < 0.80;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 40.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.warning_2,
                    color: Colors.red,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  "Resolve Plan",
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              "Select an option to resolve this plan before it is automatically converted to store credit.",
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 24.h),

            // === OPTION A: EXTEND (Strict Only) ===
            if (showLockedExtension)
              _buildResolveOption(
                icon: Icons.lock_outline,
                title: "Pay to 80% & Extend",
                subtitle:
                    "Unlock ${p.extensionGraceDays} extra days by paying 80% of total.",
                color: Colors.grey,
                isLocked: true,
                onTap: () {
                  Navigator.pop(ctx);
                  Get.to(() => PayPlanInputScreen(plan: p, repo: customerRepo));
                },
              ),
            SizedBox(height: 12.h),
            if (canExtend)
              _buildResolveOption(
                icon: Iconsax.timer_1,
                title: "Use Extension Now",
                subtitle:
                    "You've reached 80%! Extend to ${p.extensionGraceDays} extra days now.",
                color: Colors.green,
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmExtension(context, p);
                },
              ),
            SizedBox(height: 12.h),
            _buildResolveOption(
              icon: Iconsax.wallet_3,
              title: "Convert to Store Credit",
              subtitle: "End plan and save your money as credit",
              color: Colors.orange,
              onTap: () {
                Navigator.pop(ctx);
                _confirmConversion(context, p);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResolveOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    bool isLocked = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: isLocked ? Colors.grey.shade50 : Colors.white,
          border: Border.all(
            color: isLocked ? Colors.grey.shade200 : const Color(0xFFEAECF0),
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: isLocked ? Colors.grey.shade200 : color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isLocked ? Colors.grey : color,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: isLocked ? Colors.grey : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: isLocked ? Colors.grey : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  void _confirmExtension(BuildContext context, Plan p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align Left = Modern/Premium
          children: [
            // 1. Minimal Header with Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.history_toggle_off_rounded,
                    size: 24.sp,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: Icon(
                    Icons.close,
                    size: 20.sp,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // 2. Tight Typography (The Premium Look)
            Text(
              "Extend date",
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: -0.5, // Tight tracking
              ),
            ),
            SizedBox(height: 8.h),
            RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: "We can add "),
                  TextSpan(
                    text: "${p.extensionGraceDays} extra days",
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(
                    text:
                        " to your timeline. This helps you keep your plan active.",
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),

            // 3. Action Button (Full Width, Low Profile)
            SizedBox(
              width: double.infinity,
              height: 54.h, // Specific premium height
              child: ElevatedButton(
                onPressed: () async {
                  Get.back(); // Close dialog
                  context.read<PlanActionCubit>().extendPlan(p.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  "Confirm Extension",
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h), // Safety bottom padding
          ],
        ),
      ),
    );
  }

  // 💳 CONVERSION: High Value, Financial Feel
  void _confirmConversion(BuildContext context, Plan p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Centered Layout for Major Actions
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5), // Soft Orange Tint
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 26.sp,
                color: const Color(0xFFA54600),
              ),
            ),
            SizedBox(height: 20.h),

            Text(
              "Convert to Store Credit",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 10.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                "This ends your plan. Your current equity will be instantly moved to your wallet for this vendor.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: Colors.grey.shade500,
                  height: 1.5, // Readable height
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // 2. Info Card (Subtle Border)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.transparent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_rounded,
                    size: 18.sp,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    "No fees applied to conversion",
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),

            // 3. Stacked Actions
            SizedBox(
              width: double.infinity,
              height: 54.h,
              child: ElevatedButton(
                onPressed: () async {
                  Get.back(); // Close dialog
                  context.read<PlanActionCubit>().convertToStoreCredit(
                    planId: p.id,
                    customerUid: p.customerId,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA54600), // Korra Orange
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  "Convert Now",
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Text Button with proper sizing
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 🧩 STANDARD WIDGETS (Header, Financials, etc.)
  // ===========================================================================

  Widget _buildProductHeader(Plan p) {
    final bool isStrict = p.modelType.contains("strict");
    final String modelName = isStrict ? "Strict Lock" : "Korra Direct";
    final Color modelColor = isStrict
        ? const Color(0xFF9A3412)
        : const Color(0xFF075985);
    final Color modelBg = isStrict
        ? const Color(0xFFFFF7ED)
        : const Color(0xFFF0F9FF);

    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 220.h,
            color: Colors.grey.shade50,
            child: CachedNetworkImage(
              imageUrl: p.imageUrls.isNotEmpty ? p.imageUrls.first : '',
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[100],
                child: const Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    VendorHeader(storeName: p.storeName),
                    _buildStatusChip(p),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  p.title,
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 8.h),

                Row(
                  children: [
                    Text(
                      currencyFormat.format(p.totalAmount),
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: modelBg,
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(color: modelColor.withOpacity(0.2)),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(Plan p) {
    final double percent = p.totalAmount == 0
        ? 0
        : (p.amountPaid / p.totalAmount);

    // ✅ LOGIC: Only check for extension eligibility IF the user is actually Overdue
    final bool isOverdue = p.isOverdue;
    final bool supportsExtension = p.extensionGraceDays > 0;

    // We only show the "Unlock" logic if they are Overdue AND the plan allows it
    final bool showExtensionLogic = isOverdue && supportsExtension;
    final bool isUnlocked = showExtensionLogic && percent >= 0.8;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _stroke),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _amountCol("Paid Equity", p.amountPaid, _brand),
              _amountCol(
                "Remaining",
                p.outstandingLoanAmount,
                const Color(0xFF101828),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percent.clamp(0.0, 1.0),
                  minHeight: 12.h,
                  backgroundColor: const Color(0xFFF2F4F7),
                  // Only turn green if they are Overdue AND have unlocked the fix
                  valueColor: AlwaysStoppedAnimation(
                    isUnlocked ? Colors.green : _brand,
                  ),
                ),
              ),

              // Only show the 80% marker line if they are currently fighting for an extension
              if (showExtensionLogic)
                Positioned(
                  left: 0.8 * (1.sw - 72.w),
                  child: Container(
                    width: 2.w,
                    height: 12.h,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ✅ DYNAMIC TEXT
              Text(
                showExtensionLogic
                    ? (isUnlocked
                          ? "Extension Unlocked! ✅"
                          : "Pay to 80% to extend")
                    : "Payment Progress", // Default text for normal users
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  // Red text if they need to pay more to unlock, Green if unlocked, Grey if normal
                  color: showExtensionLogic
                      ? (isUnlocked ? Colors.green : Colors.red)
                      : Colors.grey,
                ),
              ),

              Text(
                "${(percent * 100).toInt()}%",
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF101828),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountCol(String label, double amount, Color color) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            currencyFormat.format(amount),
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      );
    }

  Widget _buildTimelineCard(Plan p) {
  final now = DateTime.now();
  final expiry = p.planExpiryDate; // This is the official due date
  
  // LOGIC: The "Hard Stop" is 3 days after the official expiry
  // (Or use p.noticePeriodDays if that's where you store the '3')
  final int gracePeriodDays = 3; 
  final terminationDate = expiry.add(Duration(days: gracePeriodDays));

  final daysToExpiry = expiry.difference(now).inDays;
  final daysToTermination = terminationDate.difference(now).inDays;

  // 1. IS OVERDUE? (Past Expiry, but inside the 3-day window)
  bool isOverdueGrace = daysToExpiry < 0 && daysToTermination >= 0;

  // 2. IS CRITICAL? (Less than 5 days to Expiry OR currently in Grace)
  bool isCritical = daysToExpiry <= 5; 

  // --- UI CONFIGURATION ---
  String title;
  String subtitle;
  Color bg;
  Color border;
  Color iconColor;
  IconData icon;

  if (isOverdueGrace) {
    // 🚨 STAGE 3: OVERDUE GRACE (The "3 Days" logic)
    // We show exactly how many hours/days left before auto-conversion
    title = "Final Notice: $daysToTermination Days Left";
    subtitle = "Plan terminates on ${DateFormat('MMM d').format(terminationDate)}. Resolve now!";
    bg = const Color(0xFFFEF2F2); // Red-50
    border = const Color(0xFFFECACA); // Red-200
    iconColor = const Color(0xFFDC2626); // Red-600
    icon = Iconsax.warning_2; // Alert icon
  } else if (daysToExpiry < 0) {
     // 💀 STAGE 4: TERMINATED (Cron job hasn't run yet, but time is up)
     title = "Processing Termination...";
     subtitle = "This plan is being converted to Store Credit.";
     bg = Colors.grey.shade100;
     border = Colors.grey.shade300;
     iconColor = Colors.grey;
     icon = Iconsax.close_circle;
  } else if (isCritical) {
    // ⚠️ STAGE 2: WARNING (Approaching Deadline)
    title = "$daysToExpiry Days Remaining";
    subtitle = "Expires on ${DateFormat('MMM d').format(expiry)}";
    bg = const Color(0xFFFFFAEB); // Amber-50
    border = const Color(0xFFFEF0C7); // Amber-200
    iconColor = const Color(0xFFD97706); // Amber-600
    icon = Iconsax.timer_1;
  } else {
    // 🔵 STAGE 1: NORMAL
    title = "$daysToExpiry Days Remaining";
    subtitle = "Expires on ${DateFormat('MMM d, yyyy').format(expiry)}";
    bg = const Color(0xFFF0F9FF); // Blue-50
    border = const Color(0xFFE0F2FE); // Blue-200
    iconColor = const Color(0xFF0284C7); // Blue-600
    icon = Iconsax.calendar_1;
  }

  return Container(
    padding: EdgeInsets.all(16.r),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(16.r),
      border: Border.all(color: border),
    ),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24.sp, color: iconColor),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700, // Bold for urgency
                  color: isOverdueGrace ? const Color(0xFF991B1B) : const Color(0xFF101828),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: isOverdueGrace ? const Color(0xFFB91C1C) : Colors.grey.shade600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildNextPaymentCard(Plan p) {
    double targetAmount = 0;
    if (p.cadenceType == 'weekly') {
      targetAmount = p.totalAmount / (p.baseDurationDays / 7);
    } else if (p.cadenceType == 'monthly') {
      targetAmount = p.totalAmount / (p.baseDurationDays / 30);
    } else {
      targetAmount = p.outstandingLoanAmount * 0.2; // Default 20%
    }

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F5),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _brand.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _brand.withOpacity(0.1)),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              size: 20.sp,
              color: _brand,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Target ${p.cadenceType!.capitalizeFirst}: ${currencyFormat.format(targetAmount)}",
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  "Due on ${DateFormat('MMM dd').format(p.nextDueDate)}",
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: const Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- PREMIUM INFO GRID ---
  Widget _buildInfoGrid(Plan p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _stroke),
      ),
      child: Column(
        children: [
          _infoRow("Reservation ID", p.id, isCopyable: true),
          _infoRow(
            "Created On",
            DateFormat('MMM dd, yyyy').format(p.createdAt),
          ),
          _infoRow("Target Goal", p.cadenceType!.capitalizeFirst!),
          _infoRow("Original Price", currencyFormat.format(p.totalAmount)),
          _infoRow(
            "Platform Fee",
            currencyFormat.format(p.processingFee),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool isCopyable = false,
    bool isLast = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: _stroke)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: const Color(0xFF667085),
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: isCopyable
                ? () {
                    Clipboard.setData(ClipboardData(text: value));
                    showAppSnackbar("ID Copied", SnackbarType.success);
                  }
                : null,
            child: Row(
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: const Color(0xFF101828),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isCopyable) ...[
                  SizedBox(width: 6.w),
                  Icon(Iconsax.copy, size: 14.sp, color: _brand),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(Plan p) {
    Color bg = Colors.grey.shade100;
    Color text = Colors.grey.shade700;
    String label = "Active";

    if (p.status == 'completed') {
      bg = const Color(0xFFECFDF5);
      text = const Color(0xFF059669);
      label = "Completed";
    } else if (p.status == 'cancelled') {
      bg = Colors.grey.shade200;
      text = Colors.grey.shade600;
      label = "Cancelled";
    } else if (p.isOverdue) {
      bg = const Color(0xFFFEF2F2);
      text = const Color(0xFFDC2626);
      label = "Overdue";
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }

  // ===========================================================================
  // 🛑 CANCELLATION LOGIC (UPDATED WITH 20K LIMIT)
  // ===========================================================================

  void _showCancelDialog(BuildContext context, Plan p) {
    final double totalPaid = p.amountPaid;

    // 🚨 1. HIGH VALUE CHECK (> 20k)
    // If they paid more than 20k, we force them to contact support.
    if (totalPaid > 20000) {
      _showHighValueCancelSheet(context, p);
      return;
    }

    // 🟢 2. LOW VALUE (Automated)
    // Proceed with standard automated refund dialog
    final TextEditingController reasonCtrl = TextEditingController();
    final bool isStrict50 = p.cancellationPolicy.contains("50%");
    final double penalty = isStrict50 ? (totalPaid * 0.50) : 0.0;
    final double refund = totalPaid - penalty;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Iconsax.warning_2, color: Colors.red, size: 24.sp),
            SizedBox(width: 8.w),
            Text(
              "Cancel Plan?",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 18.sp,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "This action cannot be undone. Funds will be returned to your wallet immediately.",
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.r),
              color: const Color(0xFFF9FAFB),
              child: Column(
                children: [
                  _buildMathRow("Total Paid", totalPaid, isBold: true),
                  _buildMathRow("Less Penalty", -penalty, color: Colors.red),
                  const Divider(),
                  _buildMathRow(
                    "Refund Amount",
                    refund,
                    color: Colors.green,
                    isBold: true,
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(hintText: "Reason (Optional)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Keep Plan"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await customerRepo.cancelPlan(
                planId: p.id,
                customerUid: p.customerId,
                reason: reasonCtrl.text,
              );
              showAppSnackbar(
                "Plan cancelled successfully",
                SnackbarType.success,
              );
            },
            child: const Text(
              "Confirm",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // 🛡️ HIGH VALUE SHEET (Manual Process)
  void _showHighValueCancelSheet(BuildContext context, Plan p) {
    final bool isStrict = p.cancellationPolicy.contains("50%");

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 40.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.shield_tick, color: Colors.red, size: 24.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              "Manual Refund Required",
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Because you have paid over ₦20,000, this refund must be processed manually by our support team for security reasons.",
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),

            SizedBox(height: 16.h),

            // Warning Box
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                border: Border.all(color: const Color(0xFFFFEDD5)),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18.sp,
                    color: Colors.orange.shade800,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      isStrict
                          ? "Note: This process does NOT guarantee a full refund. The 50% penalty policy still applies to all cancellations."
                          : "Note: Refunds for this plan type are typically processed as Store Credit.",
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.orange.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Copy Plan ID to clipboard for convenience
                  Clipboard.setData(
                    ClipboardData(text: "Cancel Plan ID: ${p.id}"),
                  );
                  showAppSnackbar(
                    "Plan ID copied! Please paste it in your email.",
                    SnackbarType.info,
                  );

                  // Launch Email or Support
                  // Use 'url_launcher' in real app, here we simulate or show info
                  // launchUrl(Uri.parse("mailto:support@korra.com.ng?subject=Refund Request ${p.id}"));
                },
                icon: const Icon(Icons.email_outlined),
                label: const Text("Contact support@korra.com.ng"),
                style: FilledButton.styleFrom(backgroundColor: Colors.black),
              ),
            ),

            SizedBox(height: 12.h),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  "Close",
                  style: GoogleFonts.inter(color: Colors.grey.shade600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMathRow(
    String label,
    double amount, {
    Color? color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          currencyFormat.format(amount),
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: color,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
