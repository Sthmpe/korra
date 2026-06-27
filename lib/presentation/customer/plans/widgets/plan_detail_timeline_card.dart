import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../data/models/customer/plans.dart';

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
    Color iconColor = const Color(0xFF1570EF);
    IconData icon = Iconsax.calendar_1;

    if (plan.isOverdue) {
      title = "Action Required";
      subtitle = "Plan closing in ${daysLeft.abs() + 3} days.";
      isCritical = true;
    } else if (isExtension) {
      title = "Extension Active";
      subtitle = "Timeline extended to ${DateFormat('MMM d').format(deadline)}";
      bg = const Color(0xFFECFDF5);
      iconColor = const Color(0xFF039855);
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
}
