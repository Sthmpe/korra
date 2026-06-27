import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../config/constants/colors.dart';

class PlanLimitContainer extends StatelessWidget {
  final int activePlans;
  final int maxSlots;
  final bool isSlotsFull;

  const PlanLimitContainer({
    super.key,
    required this.activePlans,
    required this.maxSlots,
    required this.isSlotsFull,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSlotsFull ? Colors.orange : Colors.green;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: isSlotsFull ? Colors.orange.shade50 : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSlotsFull
                    ? Colors.orange.shade100
                    : Colors.grey.shade200,
              ),
            ),
            child: Icon(
              Iconsax.box,
              size: 16.sp,
              color: isSlotsFull ? Colors.orange : KorraColors.text,
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Active Slot Limit",
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                isSlotsFull
                    ? "Limit Reached ($activePlans/$maxSlots)"
                    : "$activePlans of $maxSlots Slots Used",
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: isSlotsFull
                      ? Colors.orange.shade800
                      : KorraColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            isSlotsFull ? Icons.info_outline_rounded : Icons.check_circle,
            color: color,
            size: 20.sp,
          ),
        ],
      ),
    );
  }
}
