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

class PlanDetailInfoGrid extends StatelessWidget {
  final Plan plan;

  const PlanDetailInfoGrid({
    super.key,
    required this.plan,
  });

  static const _stroke = Color(0xFFF2F4F7);
  static const _brand = KorraColors.brand;

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = plan.status == 'completed';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _stroke.withOpacity(0.5)),
      ),
      child: Column(
        children: [
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
}
