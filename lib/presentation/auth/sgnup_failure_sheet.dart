import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/constants/buttons.dart';
import '../../config/constants/colors.dart';
import '../../config/constants/icons.dart';
import '../../config/constants/paddings.dart';
import '../../config/constants/sizes.dart';
import '../../config/theme/gaps.dart';

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
      padding: KorraPaddings.sheetFailure,
      decoration: BoxDecoration(
        color: KorraColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(KorraSizes.sheetRadius.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Handle bar ---
          Container(
            width: KorraSizes.s40.w,
            height: KorraSizes.s4.h,
            decoration: BoxDecoration(
              color: KorraColors.border,
              borderRadius: BorderRadius.circular(KorraSizes.xs.r),
            ),
          ),
          Gaps.h24,

          // --- Warning Icon ---
          Icon(KorraIcons.warning, size: KorraSizes.font6xl.sp, color: KorraColors.danger),
          Gaps.h16,

          // --- Title ---
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: KorraSizes.fontXl.sp,
              fontWeight: KorraSizes.weightBold,
            ),
          ),
          Gaps.h8,

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
          Gaps.h24,

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
              Gaps.w12,

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
                        color: KorraColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Gaps.h16,
        ],
      ),
    );
  }
}
