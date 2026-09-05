import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import '../../../../config/constants/colors.dart';
import '../../../../data/models/customer/plans.dart';
import '../../../shared/widgets/show_app_snackbar.dart';

/// Plan facts (ID, cadence, dates) as a floating white card — rows separated
/// by spacing only, no divider or border lines.
class PlanDetailInfoGrid extends StatelessWidget {
  final Plan plan;

  const PlanDetailInfoGrid({
    super.key,
    required this.plan,
  });

  static const _brand = KorraColors.brand;

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = plan.status == 'completed';

    return Container(
      padding: EdgeInsets.fromLTRB(18.r, 16.r, 18.r, 6.r),
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
          Text(
            "Plan Information",
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: KorraColors.textDark,
            ),
          ),
          SizedBox(height: 6.h),
          _infoRow("Plan ID", plan.id.substring(0, 8), isCopyable: true),
          _infoRow("Cadence", plan.cadenceType?.capitalizeFirst ?? "Flexible"),
          _infoRow(
            "Created On",
            DateFormat('MMM dd, yyyy').format(plan.createdAt),
          ),
          if (isCompleted)
            _infoRow(
              "Completed On",
              DateFormat('MMM dd, yyyy').format(plan.completedAt ?? plan.updatedAt),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isCopyable = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w500,
              color: KorraColors.textMuted,
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
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: KorraColors.textDark,
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
}
