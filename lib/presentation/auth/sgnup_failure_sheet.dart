import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../config/constants/buttons.dart';
import '../../config/constants/colors.dart';
import '../../config/constants/sizes.dart';

/// Failure bottom sheet shown during signup flows.
class SignupFailureSheet extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? retryCallback;

  const SignupFailureSheet({
    super.key,
    required this.title,
    required this.message,
    this.retryCallback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: KorraColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(KorraSizes.sheetRadius.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Handle bar ---
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: KorraColors.border,
              borderRadius: BorderRadius.circular(KorraSizes.xs.r),
            ),
          ),
          SizedBox(height: 24.h),

          // --- Warning Icon ---
          Icon(Iconsax.warning_2, size: KorraSizes.font6xl.sp, color: KorraColors.danger),
          SizedBox(height: 16.h),

          // --- Title ---
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: KorraSizes.fontXl.sp,
              fontWeight: KorraSizes.weightBold,
            ),
          ),
          SizedBox(height: 8.h),

          // --- Message ---
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: KorraSizes.fontMd.sp,
              color: KorraColors.textMuted,
              height: KorraSizes.lineHeightNormal,
            ),
          ),
          SizedBox(height: 24.h),

          // --- Try Again & Cancel Row ---
          Row(
            children: [
              // Cancel
              Expanded(
                child: SizedBox(
                  height: KorraButtons.heightSm.h,
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: KorraButtons.outlinedBorderStyle(radius: KorraButtons.radiusSm),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: KorraSizes.fontLg.sp,
                        fontWeight: KorraSizes.weightSemiBold,
                        color: KorraColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // Try Again
              Expanded(
                child: SizedBox(
                  height: KorraButtons.heightSm.h,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      retryCallback?.call();
                    },
                    style: KorraButtons.primaryStyle(radius: KorraButtons.radiusSm),
                    child: Text(
                      'Try Again',
                      style: GoogleFonts.inter(
                        fontSize: KorraSizes.fontLg.sp,
                        fontWeight: KorraSizes.weightBold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
