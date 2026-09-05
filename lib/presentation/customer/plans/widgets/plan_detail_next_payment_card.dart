import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../config/constants/colors.dart';
import '../../../../data/models/customer/plans.dart';

class PlanDetailNextPaymentCard extends StatelessWidget {
  final Plan plan;

  const PlanDetailNextPaymentCard({
    super.key,
    required this.plan,
  });

  static const _brand = KorraColors.brand;

  double get _smartTargetAmount {
    if (plan.nextAmount > 0) return plan.nextAmount;

    double total = plan.outstandingLoanAmount;
    if (total <= 0) return 0;

    int daysRemaining = plan.planExpiryDate.difference(DateTime.now()).inDays;
    if (daysRemaining <= 0) return total;

    int intervalDays = 30;
    if (plan.cadenceType == 'weekly') intervalDays = 7;
    if (plan.cadenceType == 'bi-weekly') intervalDays = 14;
    if (plan.cadenceType == 'daily') intervalDays = 1;

    double intervalsLeft = daysRemaining / intervalDays;
    if (intervalsLeft < 1) intervalsLeft = 1;

    double calculated = total / intervalsLeft;

    return (calculated / 100).ceil() * 100.0;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 2,
    );

    final now = DateTime.now();

    double targetAmount = plan.amountPerPeriod ?? 0;
    if (targetAmount <= 0) {
      targetAmount = _smartTargetAmount;
    }

    DateTime displayDate = plan.nextDueDate;

    int addDays = 30;
    if (plan.cadenceType == "weekly") addDays = 7;
    if (plan.cadenceType == "daily") addDays = 1;
    if (plan.cadenceType == "bi-weekly") addDays = 14;

    while (displayDate.isBefore(now) &&
        !DateUtils.isSameDay(displayDate, now)) {
      displayDate = displayDate.add(Duration(days: addDays));
    }

    final DateTime finalDeadline = plan.effectiveDeadline;
    final DateTime originalExpiry = plan.planExpiryDate;

    if (displayDate.isAfter(finalDeadline)) {
      displayDate = finalDeadline;
    }

    final bool isExtraTime = displayDate.isAfter(originalExpiry);

    Color bgColor = Colors.white;
    Color iconColor = _brand;
    Color iconBg = KorraColors.brandLight;
    String labelText = "Next Scheduled Payment";
    String subText = "Suggested Date ${DateFormat('MMM dd').format(displayDate)}";

    if (isExtraTime) {
      bgColor = const Color(0xFFFFF7ED);
      iconColor = const Color(0xFFC4320A);
      iconBg = const Color(0xFFFFE4E6);
      labelText = "Extra Time Active ⏳";
      subText = "Pay quickly! Ends ${DateFormat('MMM dd').format(displayDate)}";
    } else if (displayDate.isAtSameMomentAs(finalDeadline)) {
      labelText = "Final Payment Deadline";
      iconColor = Colors.red;
    }

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
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
}
