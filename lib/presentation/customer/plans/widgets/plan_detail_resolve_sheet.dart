import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import '../../../../data/models/customer/plans.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../../logic/bloc/customer/plans/plan_action_cubit.dart';
import 'plan_detail_conversion_sheet.dart';

class PlanDetailResolveSheet extends StatelessWidget {
  final Plan plan;

  const PlanDetailResolveSheet({
    super.key,
    required this.plan,
  });

  static const _stroke = Color(0xFFF2F4F7);

  void _showConversionSheet(BuildContext context, Plan p, PlanActionCubit cubit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BlocProvider.value(
        value: cubit,
        child: PlanDetailConversionSheet(plan: p),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double percent = plan.totalAmount == 0
        ? 0
        : (plan.amountPaid / plan.totalAmount);
    final bool canExtend = plan.extensionGraceDays > 0 && percent >= 0.8;
    final cubit = context.read<PlanActionCubit>();

    return Padding(
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
              subtitle: "Fund plan to 80% to unlock +${plan.extensionGraceDays} days.",
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                Get.toNamed(
                  Routes.customerPayPlan,
                  arguments: {'plan': plan},
                );
              },
            ),

          // OPTION 2: Use Extension (If Unlocked)
          if (canExtend)
            _resolveTile(
              icon: Iconsax.timer_1,
              title: "Activate Time Extension",
              subtitle: "Extension Unlocked. Add +${plan.extensionGraceDays} days now.",
              color: const Color(0xFF039855),
              onTap: () {
                Navigator.pop(context);
                cubit.extendPlan(plan.id);
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
              Navigator.pop(context);
              _showConversionSheet(context, plan, cubit);
            },
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
