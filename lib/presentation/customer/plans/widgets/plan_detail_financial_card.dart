import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../config/constants/colors.dart';
import '../../../../data/models/customer/plans.dart';

/// Paid / Remaining amounts with the ownership progress bar. Floating white
/// card — soft shadow, no border lines.
class PlanDetailFinancialCard extends StatelessWidget {
  final Plan plan;

  const PlanDetailFinancialCard({
    super.key,
    required this.plan,
  });

  static const _brand = KorraColors.brand;

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
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Ownership Progress",
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: KorraColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: (isUnlocked ? const Color(0xFF039855) : _brand)
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "${(percent * 100).toInt()}%",
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: isUnlocked ? const Color(0xFF039855) : _brand,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _amountCol(currencyFormat, "Paid", plan.amountPaid, _brand,
                  CrossAxisAlignment.start),
              _amountCol(currencyFormat, "Remaining",
                  plan.outstandingLoanAmount, KorraColors.textDark,
                  CrossAxisAlignment.end),
            ],
          ),
          SizedBox(height: 16.h),
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
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
          if (showExtensionLogic) ...[
            SizedBox(height: 10.h),
            Text(
              isUnlocked
                  ? "Time Extension Available"
                  : "Reach 80% to unlock time",
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: isUnlocked
                    ? const Color(0xFF039855)
                    : const Color(0xFFB42318),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _amountCol(NumberFormat formatter, String label, double amt,
      Color color, CrossAxisAlignment align) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w600,
            color: KorraColors.textMuted,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          formatter.format(amt),
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
