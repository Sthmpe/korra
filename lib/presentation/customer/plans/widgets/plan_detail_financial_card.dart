import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../config/constants/colors.dart';
import '../../../../data/models/customer/plans.dart';

class PlanDetailFinancialCard extends StatelessWidget {
  final Plan plan;

  const PlanDetailFinancialCard({
    super.key,
    required this.plan,
  });

  static const _brand = KorraColors.brand;
  static const _stroke = Color(0xFFF2F4F7);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 2,
    );

    final double percent = plan.totalAmount == 0
        ? 0
        : (plan.amountPaid / plan.totalAmount);

    final bool showExtensionLogic = plan.isOverdue && plan.extensionGraceDays > 0;
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
              _amountCol(currencyFormat, "Paid", plan.amountPaid, _brand),
              _amountCol(
                currencyFormat,
                "Remaining",
                plan.outstandingLoanAmount,
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
                        ? "Time Extension Available"
                        : "Reach 80% to unlock time")
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

  Widget _amountCol(NumberFormat formatter, String label, double amt, Color color) {
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
          formatter.format(amt),
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
