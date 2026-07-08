import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../config/constants/colors.dart';
import '../../../../data/models/customer/plans.dart';

/// Timeline status: days remaining, extension active or action required.
/// Soft tinted card with a white icon bubble — no border lines.
class PlanDetailTimelineCard extends StatelessWidget {
  final Plan plan;

  const PlanDetailTimelineCard({
    super.key,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime deadline = plan.effectiveDeadline;
    final int daysLeft = deadline.difference(DateTime.now()).inDays;
    final bool isExtension = plan.isExtensionActive;

    bool isCritical = daysLeft <= 3;

    String title = "$daysLeft Days Remaining";
    String subtitle = "Timeline ends on ${DateFormat('MMM d').format(deadline)}";
    Color bg = const Color(0xFFF0F9FF);
    Color accent = const Color(0xFF1570EF);
    IconData icon = Iconsax.calendar_1;

    if (plan.isOverdue) {
      title = "Action Required";
      subtitle = "Plan closing in ${daysLeft.abs() + 3} days.";
      isCritical = true;
    } else if (isExtension) {
      title = "Extension Active";
      subtitle = "Timeline extended to ${DateFormat('MMM d').format(deadline)}";
      bg = const Color(0xFFECFDF5);
      accent = const Color(0xFF039855);
      icon = Iconsax.tick_circle;
      isCritical = false;
    }

    if (isCritical) {
      bg = const Color(0xFFFEF2F2);
      accent = const Color(0xFFD92D20);
      icon = Iconsax.warning_2;
    }

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20.sp, color: accent),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5.sp,
                    color: accent,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: KorraColors.textBody,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
