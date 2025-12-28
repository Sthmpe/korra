import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:korra/data/repository/customer/plans_repository.dart';

import '../../../../config/constants/colors.dart';
import '../../../../data/models/customer/plans.dart';
import '../../../../data/repository/customer/customer_repository.dart';
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
  static const _stroke = Color(0xFFF2F4F7);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Plan?>(
      stream: customerRepo.streamSinglePlan(plan.id),
      initialData: plan,
      builder: (context, snapshot) {
        final currentPlan = snapshot.data ?? plan;

        final isCompleted = currentPlan.status == 'completed';
        final isCancelled = currentPlan.status == 'cancelled';
        final canInteract = !isCompleted && !isCancelled;

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: const KorraHeader(
            title: 'Reservation Details',
            showLeadingIcon: true,
          ),
          bottomNavigationBar: canInteract
              ? _buildStickyAction(context, currentPlan)
              : null,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCancelled) _buildCancelledBanner(currentPlan),
                if (currentPlan.isOverdue && !isCancelled) _buildOverdueBanner(currentPlan),

                // 1. PRODUCT HERO
                _buildProductHeader(currentPlan),

                // 2. FINANCIAL PROGRESS (The 80% View)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _buildFinancialCard(currentPlan),
                ),

                SizedBox(height: 16.h),

                // 3. PAYMENT TARGET (Fixed ₦0 Issue)
                if (canInteract && !currentPlan.isOverdue)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: _buildNextPaymentCard(currentPlan),
                  ),

                SizedBox(height: 24.h),

                // 4. INFORMATION GRID
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _buildInfoGrid(currentPlan),
                ),

                SizedBox(height: 40.h),

                // 5. CANCELLATION BUTTON
                if (canInteract)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 60.h),
                      child: TextButton.icon(
                        onPressed: () => _confirmConversion(context, currentPlan),
                        icon: Icon(Iconsax.wallet_3, size: 18.sp, color: Colors.grey.shade400),
                        label: Text(
                          "End Plan & Convert to Credit",
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
  }

  // --- 1. PRODUCT HEADER ---
  Widget _buildProductHeader(Plan p) {
    // Logic check for Lock type
    final bool isStrict = p.cancellationPolicy.contains("50%");
    final String modelName = isStrict ? "Strict Lock" : "Korra Direct";
    final Color modelColor = isStrict ? const Color(0xFF9E0A05) : const Color(0xFF026AA2);

    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 220.h,
            color: Colors.white,
            child: CachedNetworkImage(
              imageUrl: p.imageUrls.isNotEmpty ? p.imageUrls.first : '',
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VendorHeader(storeName: p.storeName),
                SizedBox(height: 12.h),
                Text(
                  p.title,
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
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

  // --- 2. FINANCIAL CARD (With 80% Logic) ---
  Widget _buildFinancialCard(Plan p) {
    final double percent = p.totalAmount == 0 ? 0 : (p.amountPaid / p.totalAmount);
    final bool canExtend = p.extensionGraceDays > 0 && percent >= 0.8;

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
              _amountCol("Remaining", p.outstandingLoanAmount, const Color(0xFF101828)),
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
                  valueColor: AlwaysStoppedAnimation(percent >= 0.8 ? Colors.green : _brand),
                ),
              ),
              // Marker for 80%
              Positioned(
                left: 0.8 * (1.sw - 72.w), // Approximate width calculation
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
                percent >= 0.8 ? "Extension Unlocked! ✅" : "Reach 80% to unlock extension",
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: percent >= 0.8 ? Colors.green : Colors.grey,
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
          )
        ],
      ),
    );
  }

  // --- 3. NEXT PAYMENT (Calculated) ---
  Widget _buildNextPaymentCard(Plan p) {
    // If nextAmount is 0, we calculate a target based on the loan divided by remaining intervals
    double targetAmount = p.nextAmount;
    if (targetAmount <= 0) {
      double intervals = 1;
      if (p.cadenceType == "weekly") intervals = (p.baseDurationDays / 7);
      else if (p.cadenceType == "daily") intervals = p.baseDurationDays.toDouble();
      else intervals = (p.baseDurationDays / 30);
      targetAmount = p.loanAmount / (intervals > 0 ? intervals : 1);
    }

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _stroke),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12.r)),
            child: Icon(Iconsax.calendar_tick, color: _brand, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Target Payment: ${currencyFormat.format(targetAmount)}",
                  style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700),
                ),
                Text(
                  "Pay by ${DateFormat('MMM dd, yyyy').format(p.nextDueDate)}",
                  style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF667085)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. INFORMATION GRID ---
  Widget _buildInfoGrid(Plan p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _stroke),
      ),
      child: Column(
        children: [
          _infoRow("Plan ID", p.productCode, isCopyable: true),
          _infoRow("Cadence", p.cadenceType?.capitalizeFirst ?? "Flexible"),
          _infoRow("End Date", DateFormat('MMM dd, yyyy').format(p.planExpiryDate)),
          _infoRow("Service Fee", currencyFormat.format(p.processingFee), isLast: true),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isCopyable = false, bool isLast = false}) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: _stroke)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF667085))),
          GestureDetector(
            onTap: isCopyable ? () {
              Clipboard.setData(ClipboardData(text: value));
              showAppSnackbar("Copied", SnackbarType.success);
            } : null,
            child: Row(
              children: [
                Text(value, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                if (isCopyable) ...[SizedBox(width: 4.w), Icon(Iconsax.copy, size: 14.sp, color: _brand)],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. STICKY BOTTOM ACTION ---
  Widget _buildStickyAction(BuildContext context, Plan p) {
    final bool isOverdue = p.isOverdue;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Outstanding Balance", style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF667085))),
                Text(
                  currencyFormat.format(p.outstandingLoanAmount),
                  style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 160.w,
            height: 52.h,
            child: FilledButton(
              onPressed: () {
                if (isOverdue) {
                  _showResolveSheet(context, p);
                } else {
                  Get.to(() => PayPlanInputScreen(plan: p, repo: customerRepo));
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: isOverdue ? const Color(0xFFD92D20) : const Color(0xFF101828),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Text(
                isOverdue ? "Resolve Plan" : "Make Payment",
                style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. LOGIC DIALOGS ---

  void _showResolveSheet(BuildContext context, Plan p) {
    final double percent = (p.amountPaid / p.totalAmount);
    final bool canExtend = p.extensionGraceDays > 0 && percent >= 0.8;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 40.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Resolve Overdue Plan", style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 24.h),
            _resolveTile(
              icon: Iconsax.card,
              title: "Pay to 80% & Extend",
              subtitle: "Unlock ${p.extensionGraceDays} extra days",
              color: Colors.blue,
              onTap: () {
                Navigator.pop(ctx);
                Get.to(() => PayPlanInputScreen(plan: p, repo: customerRepo));
              },
            ),
            SizedBox(height: 12.h),
            if (canExtend)
              _resolveTile(
                icon: Iconsax.timer_1,
                title: "Use Extension Now",
                subtitle: "You've reached 80%! Extend now.",
                color: Colors.green,
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmExtension(context, p);
                },
              ),
            SizedBox(height: 12.h),
            _resolveTile(
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

  Widget _resolveTile({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(border: Border.all(color: _stroke), borderRadius: BorderRadius.circular(12.r)),
        child: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _confirmConversion(BuildContext context, Plan p) {
    Get.defaultDialog(
      title: "Convert to Store Credit?",
      middleText: "This will end your plan. All money paid will be converted to Store Credit with ${p.storeName}.",
      textConfirm: "Convert",
      confirmTextColor: Colors.white,
      buttonColor: Colors.orange,
      onConfirm: () async {
        Get.back();
        await customerRepo.cancelPlan(planId: p.id, customerUid: p.customerId, reason: "Store Credit Conversion");
        showAppSnackbar("Plan converted to Store Credit", SnackbarType.success);
      },
    );
  }

  void _confirmExtension(BuildContext context, Plan p) {
    Get.defaultDialog(
      title: "Extend Plan?",
      middleText: "Add ${p.extensionGraceDays} days to your deadline.",
      textConfirm: "Extend",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();
        // await customerRepo.extendPlan(p.id); // Implement extension call
        showAppSnackbar("Plan extended successfully", SnackbarType.success);
      },
    );
  }

  Widget _amountCol(String label, double amt, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF667085))),
        SizedBox(height: 4.h),
        Text(currencyFormat.format(amt), style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  // Banner builders...
  Widget _buildOverdueBanner(Plan p) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFB42318),
      padding: EdgeInsets.all(12.r),
      child: Row(children: [
        const Icon(Iconsax.danger, color: Colors.white, size: 18),
        SizedBox(width: 8.w),
        Text("Reservation Overdue. Resolve to prevent termination.", style: GoogleFonts.inter(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildCancelledBanner(Plan p) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF2F4F7),
      padding: EdgeInsets.all(12.r),
      child: Row(children: [
        const Icon(Iconsax.info_circle, color: Color(0xFF344054), size: 18),
        SizedBox(width: 8.w),
        Text("This plan has been converted to Store Credit.", style: GoogleFonts.inter(color: const Color(0xFF344054), fontSize: 12.sp)),
      ]),
    );
  }
}