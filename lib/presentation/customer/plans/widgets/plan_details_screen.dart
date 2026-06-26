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
import '../../../../config/routes/app_routes.dart';
import '../../../../data/models/customer/plans.dart';
import '../../../../data/repository/customer/customer_repository.dart';
import '../../../../logic/bloc/customer/plans/plan_action_cubit.dart';
import '../../../shared/widgets/korra_header.dart';
import '../../../shared/widgets/show_app_snackbar.dart';
import 'vendor_header.dart';

class PlanDetailsScreen extends StatefulWidget {
  final Plan plan;
  final CustomerRepository customerRepo;

  const PlanDetailsScreen({
    super.key,
    required this.plan,
    required this.customerRepo,
  });
   @override
  State<PlanDetailsScreen> createState() => _PlanDetailsScreenState();
}

class _PlanDetailsScreenState extends State<PlanDetailsScreen> {
  final currencyFormat = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 2,
  );

  int _currentImageIndex = 0;

  static const _brand = KorraColors.brand;
  static const _stroke = Color(0xFFF2F4F7);

  late Stream<Plan?> _singlePlanStream;

  @override
  void initState() {
    super.initState();
    _singlePlanStream = widget.customerRepo.streamSinglePlan(widget.plan.id);
  }

  double get _smartTargetAmount {
    // 1. If backend has a valid specific target, use it.
    if (widget.plan.nextAmount > 0) return widget.plan.nextAmount;

    // 2. Otherwise, calculate based on cadence (Weekly/Monthly)
    double total = widget.plan.outstandingLoanAmount;
    if (total <= 0) return 0;

    int daysRemaining = widget.plan.planExpiryDate.difference(DateTime.now()).inDays;
    if (daysRemaining <= 0) return total; // Overdue? Pay all.

    // Determine interval (e.g., 30 days for monthly, 7 for weekly)
    int intervalDays = 30;
    if (widget.plan.cadenceType == 'weekly') intervalDays = 7;
    if (widget.plan.cadenceType == 'bi-weekly') intervalDays = 14;
    if (widget.plan.cadenceType == 'daily') intervalDays = 1;

    // How many payments are left?
    double intervalsLeft = daysRemaining / intervalDays;
    if (intervalsLeft < 1) intervalsLeft = 1;

    // Amount per interval
    double calculated = total / intervalsLeft;

    // Round to nearest 100 for a cleaner number (e.g., 4322 -> 4400)
    return (calculated / 100).ceil() * 100.0;
  }

  @override
  Widget build(BuildContext context) {
    // 1. WRAP WITH CUBIT PROVIDER
    return BlocProvider(
      create: (context) => PlanActionCubit(widget.customerRepo),
      child: BlocListener<PlanActionCubit, PlanActionState>(
        listener: (context, state) {
          if (state is PlanActionSuccess) {
            showAppSnackbar(state.message, SnackbarType.success);
            Get.back();
          }
          if (state is PlanActionError) {
            showAppSnackbar(state.error, SnackbarType.error);
            Get.back();
          }
        },
        child: StreamBuilder<Plan?>(
          stream: _singlePlanStream,
          initialData: widget.plan,
          builder: (context, snapshot) {
            final currentPlan = snapshot.data ?? widget.plan;

            // 2. DETERMINE STATE
            final bool isCompleted = currentPlan.status == 'completed';
            final bool isCancelled = currentPlan.status == 'cancelled';

            // 🛡️ UI PROTECTION: If deadline passed, treat as terminated immediately
            final bool isTerminated = currentPlan.isEffectivelyTerminated;

            // Block interaction if any "End State" is reached
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

                  // Sticky Bottom Bar (Hidden if terminated/completed)
                  bottomNavigationBar: canInteract
                      ? IgnorePointer(
                          ignoring: isLoading,
                          child: Opacity(
                            opacity: isLoading ? 0.6 : 1.0,
                            child: _buildStickyAction(context, currentPlan, isLoading: isLoading),
                          ),
                        )
                      : null,

                  body: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- A. WARNING BANNERS ---
                        if (isCancelled)
                          _buildStatusBanner(
                            icon: Iconsax.info_circle,
                            title: "Plan Closed",
                            // ✅ "Secured in" sounds like a vault. "Transferred to" is also fine.
                            subtitle: "Funds are secured in your Store Balance.", 
                            color: const Color(0xFF344054),
                            bg: const Color(0xFFF2F4F7),
                          ),

                        if (isTerminated && !isCancelled && !isCompleted)
                          _buildStatusBanner(
                            icon: Iconsax.timer_1,
                            title: "Timeline Ended",
                            // ✅ "Moved to" is active and clear.
                            subtitle: "Plan incomplete. Funds moved to Store Balance.",
                            color: const Color(0xFFB54708),
                            bg: const Color(0xFFFFFAEB),
                          ),

                        // Show "Overdue" banner only if active & late
                        if (currentPlan.isOverdue &&
                            !isTerminated &&
                            !isCancelled)
                          _buildOverdueBanner(),

                        // --- B. HERO SECTION ---
                        _buildProductHeader(currentPlan),

                        // Only show if Completed
                        if (isCompleted)
                          _buildPickupSection(context, currentPlan),

                        // --- D. FINANCIALS ---
                        if (!isCompleted)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: _buildFinancialCard(currentPlan),
                          ),

                        SizedBox(height: 16.h),

                        // --- D. TIMELINE CARD ---
                        if (!isCompleted && !isCancelled) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: _buildTimelineCard(currentPlan),
                          ),
                          SizedBox(height: 16.h),
                        ],

                        // --- E. NEXT PAYMENT TARGET ---
                        if (canInteract && !currentPlan.isOverdue) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: _buildNextPaymentCard(currentPlan),
                          ),
                          SizedBox(height: 24.h),
                        ],

                        // --- F. INFO GRID ---
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: _buildInfoGrid(currentPlan),
                        ),

                        SizedBox(height: 40.h),

                        // --- G. CONVERT BUTTON ---
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

  // =========================================================
  // ✅ PAYMENT COMPLETED SECTION (Clean & Simple)
  // =========================================================
  Widget _buildPickupSection(BuildContext context, Plan p) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF3), // Soft Success Green
        borderRadius: BorderRadius.circular(16.r),
        //border: Border.all(color: const Color(0xFFD1FADF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: const Color(0xFF027A48), size: 24.sp),
              SizedBox(width: 12.w),
              Text(
                "Payment Complete!",
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF027A48),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            "You have fully paid for this item. Please contact ${p.storeName} directly to arrange for collection or delivery.",
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0xFF027A48).withOpacity(0.9),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

                    SizedBox(width: 16.w), // Space between title and price

                    Text(
                      // Make sure to replace 'totalAmount' with your actual price field
                      currencyFormat.format(p.totalAmount), 
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF101828), // Matches title color, or change to KorraColors.brand
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

  // =========================================================
  // 2. FINANCIAL CARD (Smart Logic)
  // =========================================================
  Widget _buildFinancialCard(Plan p) {
    final double percent = p.totalAmount == 0
        ? 0
        : (p.amountPaid / p.totalAmount);

    // Only show extension hint if Overdue AND Extension is possible
    final bool showExtensionLogic = p.isOverdue && p.extensionGraceDays > 0;
    final bool isUnlocked = showExtensionLogic && percent >= 0.8;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _stroke.withOpacity(0.8)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _amountCol("Paid", p.amountPaid, _brand),
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
                  minHeight: 10.h,
                  backgroundColor: const Color(0xFFF2F4F7),
                  // Green if unlocked, otherwise Brand color
                  valueColor: AlwaysStoppedAnimation(
                    isUnlocked ? const Color(0xFF039855) : _brand,
                  ),
                ),
              ),
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
              Text(
                showExtensionLogic
                  ? (isUnlocked
                      ? "Time Extension Available" // ✅ Celebration of status
                      : "Reach 80% to unlock time")  // ✅ "Reach" implies a goal, not a bill
                  : "Ownership Progress",
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: showExtensionLogic
                      ? (isUnlocked ? const Color(0xFF039855) : Colors.red)
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

  // =========================================================
  // 3. TIMELINE CARD (Grace Period Logic)
  // =========================================================
  Widget _buildTimelineCard(Plan p) {
    // Logic handles normal expiry + extension logic if active
    final DateTime deadline = p.effectiveDeadline;
    final int daysLeft = deadline.difference(DateTime.now()).inDays;
    final bool isExtension = p.isExtensionActive;

    // Critical if overdue or very close
    bool isCritical = daysLeft <= 3;

    // 3 Days Grace logic for display
    String title = "$daysLeft Days Remaining";
    String subtitle = "Timeline ends on ${DateFormat('MMM d').format(deadline)}";
    Color bg = const Color(0xFFF0F9FF);
    Color iconColor = const Color(0xFF1570EF);
    IconData icon = Iconsax.calendar_1;

    if (p.isOverdue) {
      title = "Action Required";
      subtitle =
          "Plan closing in ${daysLeft.abs() + 3} days."; // Assuming 3 days hard termination
      isCritical = true;
    } else if (isExtension) {
      title = "Extension Active";
      subtitle = "Timeline extended to ${DateFormat('MMM d').format(deadline)}";
      bg = const Color(0xFFECFDF5);
      iconColor = const Color(0xFF039855); // Premium Success Green
      icon = Iconsax.tick_circle;
      isCritical = false;
    }

    if (isCritical) {
      bg = const Color(0xFFFEF2F2);
      iconColor = Colors.red;
      icon = Iconsax.warning_2;
    }

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          width: 0.0,
          color: bg == const Color(0xFFFEF2F2).withOpacity(0.8)
              ? Colors.red.shade100.withOpacity(0.05)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24.sp, color: iconColor),
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
                    color: iconColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // 4. ACTION BAR & LOGIC
  // =========================================================
  Widget _buildStickyAction(BuildContext context, Plan p, {bool isLoading = false}) {
    final bool isOverdue = p.isOverdue;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
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
            width: 160.w,
            height: 52.h,
            child: FilledButton(
              onPressed: isLoading 
                  ? null 
                  : () {
                      if (isOverdue) {
                        _showResolveSheet(context, p);
                      } else {
                        Get.toNamed(
                          Routes.customerPayPlan,
                          arguments: {'plan': p, 'repo': widget.customerRepo},
                        );
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: isOverdue ? const Color(0xFFB42318): _brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: isLoading
                ? SizedBox(
                    height: 20.h,
                    width: 20.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isOverdue ? "Resolve Plan" : "Make Payment",
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

  void _showResolveSheet(BuildContext context, Plan p) {
    final double percent = p.totalAmount == 0
        ? 0
        : (p.amountPaid / p.totalAmount);
    // Can extend IF grace days available AND paid >= 80%
    final bool canExtend = p.extensionGraceDays > 0 && percent >= 0.8;

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
          children: [
            Text(
              "Resolve Past Due",
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Choose an action to secure your product.",
              style: GoogleFonts.inter(
                fontSize: 13.5.sp,
                color: const Color(0xFF667085),
              ),
            ),
            SizedBox(height: 24.h),

            // OPTION 1: Pay to 80% (If not yet there)
            if (!canExtend)
              _resolveTile(
                icon: Iconsax.card,
                title: "Reach 80% to Extend",
                subtitle: "Fund plan to 80% to unlock +${p.extensionGraceDays} days.",
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(ctx);
                  Get.toNamed(
                    Routes.customerPayPlan,
                    arguments: {'plan': p, 'repo': widget.customerRepo},
                  );
                },
              ),

            // OPTION 2: Use Extension (If Unlocked)
            if (canExtend)
              _resolveTile(
                icon: Iconsax.timer_1,
                title: "Activate Time Extension",
                subtitle: "Extension Unlocked. Add +${p.extensionGraceDays} days now.",
                color: const Color(0xFF039855),
                onTap: () {
                  Navigator.pop(ctx);
                  // Call Cubit to extend
                  context.read<PlanActionCubit>().extendPlan(p.id);
                },
              ),

            SizedBox(height: 12.h),

            // OPTION 3: Convert
            _resolveTile(
              icon: Iconsax.wallet_3,
              title: "Close & Secure Funds",
              subtitle: "Move payments to Store Balance instantly.",
              color: const Color(0xFF344054),
              onTap: () {
                Navigator.pop(ctx);
                _showConversionSheet(context, p);
              },
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // 5. HELPER WIDGETS
  // =========================================================
  void _showConversionSheet(BuildContext context, Plan p) {
    final cubit = context.read<PlanActionCubit>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BlocProvider.value(
        value: cubit,
        child: BlocBuilder<PlanActionCubit, PlanActionState>(
          builder: (context, state) {
            final bool isLoading = state is PlanActionLoading;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 40.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Drag Handle
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      margin: EdgeInsets.only(bottom: 24.h),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),

                  // 2. Icon Hero (Shield/Safe vibe)
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7), // Neutral Grey bg
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.wallet_check, // ✅ "Wallet Check" implies verification/safety
                      color: const Color(0xFF344054),
                      size: 32.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // 3. Headline (Strategic Exit)
                  Text(
                    "Close Plan & Secure Funds", // ✅ "Secure" is the keyword
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF101828),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "End this plan and move your funds to your Store Balance.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: const Color(0xFF667085),
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // 4. The "Receipt" Box
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFEAECF0).withOpacity(0.01), width: 0.0),
                    ),
                    child: Column(
                      children: [
                        _receiptRow(
                          "Total Funds Paid", // ✅ "Equity" sounds like an asset
                          currencyFormat.format(p.amountPaid),
                          isBold: true,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          child: const Divider(height: 0.1, thickness: 0.1),
                        ),
                        _receiptRow(
                          "Closing Fee", // ✅ Neutral term
                          "₦0.00",
                          color: Colors.green, // Reinforce the "Free" benefit
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          child: const Divider(height: 0.1, thickness: 0.1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Funds to Secure", // ✅ "Secure" again
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: const Color(0xFF667085),
                              ),
                            ),
                            Text(
                              currencyFormat.format(p.amountPaid),
                              style: GoogleFonts.inter(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF101828), // Dark High Status
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // 5. Value Proposition Note
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Iconsax.info_circle,
                        size: 18.sp,
                        color: const Color(0xFF344054), // Neutral
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          "Your funds never expire. Use them to start a new plan anytime.",
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: const Color(0xFF475467),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 32.h),

                  // 6. Action Buttons
                  Row(
                    children: [
                      // "Go Back" Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading ? null : () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            side: BorderSide(color: Color(0xFFD0D5DD).withOpacity(0.5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            "Keep Plan", // ✅ Positive reinforcement to stay
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF344054),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      
                      // "Secure Funds" Button
                      Expanded(
                        child: FilledButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  Navigator.pop(ctx);
                                  context
                                      .read<PlanActionCubit>()
                                      .convertToStoreCredit(
                                        planId: p.id,
                                        customerUid: p.customerId,
                                      );
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF101828), // Dark/Professional
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? SizedBox(
                                  height: 20.h,
                                  width: 20.h,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  "Secure Funds", // ✅ Action oriented
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper for the receipt rows
  Widget _receiptRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
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
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: color ?? const Color(0xFF101828),
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNextPaymentCard(Plan p) {
    final now = DateTime.now();

    // 1. CALCULATE TARGET AMOUNT (Your existing logic)
    double targetAmount = p.amountPerPeriod ?? 0;

    if (targetAmount <= 0) {
      targetAmount = _smartTargetAmount;
    }

    // 2. CALCULATE DYNAMIC DUE DATE
    DateTime displayDate = p.nextDueDate;

    // Determine days to add (Cadence)
    int addDays = 30; // Default monthly
    if (p.cadenceType == "weekly") addDays = 7;
    if (p.cadenceType == "daily") addDays = 1;
    if (p.cadenceType == "bi-weekly") addDays = 14;

    // Logic: Keep adding 'addDays' until the date is in the future
    // This fixes the "Past Date" issue
    while (displayDate.isBefore(now) &&
        !DateUtils.isSameDay(displayDate, now)) {
      displayDate = displayDate.add(Duration(days: addDays));
    }

    // 3. DEADLINE CHECK & "EXTRA TIME" LOGIC
    final DateTime finalDeadline = p.effectiveDeadline;
    final DateTime originalExpiry = p.planExpiryDate;

    // If calculation pushes past the hard deadline, cap it at the deadline
    if (displayDate.isAfter(finalDeadline)) {
      displayDate = finalDeadline;
    }

    // Check if we are in "Extra Time" (Extension Period)
    // Meaning: We are past the original expiry, but using grace days
    final bool isExtraTime = displayDate.isAfter(originalExpiry);

    // --- UI STYLING ---
    Color bgColor = Colors.white;
    Color iconColor = _brand;
    Color iconBg = const Color(0xFFF9FAFB);
    String labelText = "Next Scheduled Payment";
    String subText =
        "Suggested Date ${DateFormat('MMM dd').format(displayDate)}";

    if (isExtraTime) {
      // 🚨 EXTRA TIME UI
      bgColor = const Color(0xFFFFF7ED); // Orange tint
      iconColor = const Color(0xFFC4320A); // Deep Orange
      iconBg = const Color(0xFFFFE4E6);
      labelText = "Extra Time Active ⏳";
      subText = "Pay quickly! Ends ${DateFormat('MMM dd').format(displayDate)}";
    } else if (displayDate.isAtSameMomentAs(finalDeadline)) {
      // ⚠️ FINAL DEADLINE UI
      labelText = "Final Payment Deadline";
      iconColor = Colors.red;
    }

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.r),
        // border: Border.all(
        //   color: isExtraTime ? const Color(0xFFFEDF89) : _stroke,
        // ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              isExtraTime ? Iconsax.timer_start : Iconsax.calendar_tick,
              color: iconColor,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Target: ${currencyFormat.format(targetAmount)}",
                  style: GoogleFonts.inter(
                    // Premium Numbers
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF101828),
                  ),
                ),
                SizedBox(height: 4.h),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labelText,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: isExtraTime
                            ? const Color(0xFF9A3412)
                            : const Color(0xFF344054),
                      ),
                    ),
                    Text(
                      subText,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: isExtraTime
                            ? const Color(0xFFC4320A)
                            : const Color(0xFF667085),
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

  Widget _buildInfoGrid(Plan p) {
    final bool isCompleted = p.status == 'completed';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _stroke.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          _infoRow("Plan ID", p.id.substring(0, 8), isCopyable: true),
          _infoRow("Cadence", p.cadenceType?.capitalizeFirst ?? "Flexible"),
          _infoRow(
            "Created On",
            DateFormat('MMM dd, yyyy').format(p.createdAt),
          ),
          if (isCompleted)
            _infoRow(
              "Completed On",
              DateFormat('MMM dd, yyyy').format(p.completedAt ?? p.updatedAt),
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
            : Border(bottom: BorderSide(color: _stroke.withOpacity(0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: const Color(0xFF667085),
            ),
          ),
          GestureDetector(
            onTap: isCopyable
                ? () {
                    Clipboard.setData(ClipboardData(text: value));
                    showAppSnackbar("Copied", SnackbarType.success);
                  }
                : null,
            child: Row(
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isCopyable) ...[
                  SizedBox(width: 4.w),
                  Icon(Iconsax.copy, size: 14.sp, color: _brand),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountCol(String label, double amt, Color color) {
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
          currencyFormat.format(amt),
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildOverdueBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFB42318),
      padding: EdgeInsets.all(12.r),
      child: Row(
        children: [
          const Icon(Iconsax.danger, color: Colors.white, size: 18),
          SizedBox(width: 8.w),
          Text(
            "Reservation Past Due. Resolve to secure item.",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bg,
  }) {
    return Container(
      width: double.infinity,
      color: bg,
      padding: EdgeInsets.all(16.r),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
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
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resolveTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          border: Border.all(color: _stroke.withOpacity(0.0)),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
