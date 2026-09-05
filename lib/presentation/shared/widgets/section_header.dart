// lib/presentation/customer/home/widgets/section_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/constants/colors.dart';
import '../../../config/constants/sizes.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final double topPadding;

  /// Optional dressing: a leading icon in a soft tinted circle and a light
  /// one-line subtitle under the title. Sections without them render exactly
  /// as before.
  final IconData? icon;
  final Color iconColor;
  final String? subtitle;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
    this.topPadding = 24, // Increased default for better visual separation
    this.icon,
    this.iconColor = KorraColors.brand,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    // Check if we have a valid action to show
    final hasAction = actionText != null && actionText!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, topPadding.h, 20.w, 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.09),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16.sp, color: iconColor),
            ),
            SizedBox(width: 10.w),
          ],

          // Section Title (+ optional subtitle)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: KorraSizes.fontXl.sp,
                    fontWeight: KorraSizes.weightBold,
                    color: KorraColors.black,
                    letterSpacing: KorraSizes.trackingSnug,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
              ],
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
                      fontSize: KorraSizes.fontSmPlus.sp,
                      fontWeight: KorraSizes.weightSemiBold,
                      color: KorraColors.brand,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Iconsax.arrow_right_3, // Clean chevron style
                    size: KorraSizes.iconSm.sp,
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
