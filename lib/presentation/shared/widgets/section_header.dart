// lib/presentation/customer/home/widgets/section_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart'; // Ensure this is imported

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final double topPadding;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
    this.topPadding = 24, // Increased default for better visual separation
  });

  @override
  Widget build(BuildContext context) {
    // Check if we have a valid action to show
    final hasAction = actionText != null && actionText!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, topPadding.h, 20.w, 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Section Title
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18.sp, // Slightly bigger for hierarchy
              fontWeight: FontWeight.w700, // Bold
              color: KorraColors.black,
              letterSpacing: -0.5, // Modern tight tracking
            ),
          ),

          // Action Button (View All >)
          if (hasAction)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque, // Ensures easy tapping
              child: Row(
                children: [
                  Text(
                    actionText!,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: KorraColors.brand,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Iconsax.arrow_right_3, // Clean chevron style
                    size: 16.sp,
                    color: KorraColors.brand,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}