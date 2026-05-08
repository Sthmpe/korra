import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/constants/buttons.dart';
import '../../../config/constants/colors.dart';
import '../../../config/constants/sizes.dart';

void showKorraFailureSheet(
  BuildContext context, {
  required String title,
  required String message,
  VoidCallback? onRetry,
  VoidCallback? onCancel,
}) {
  HapticFeedback.lightImpact();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _KorraFailureSheet(
      title: title,
      message: message,
      onRetry: onRetry,
      onCancel: onCancel,
    ),
  );
}

class _KorraFailureSheet extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const _KorraFailureSheet({
    required this.title,
    required this.message,
    this.onRetry,
    this.onCancel,
  });

  bool get hasRetry => onRetry != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(KorraSizes.sheetRadius.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- HANDLE BAR ---
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: KorraColors.border,
                  borderRadius: BorderRadius.circular(KorraSizes.xs.r),
                ),
              ),
            ),
            SizedBox(height: 32.h),

            // --- ICON WITH SOFT BACKGROUND ---
            Container(
              width: 64.w,
              height: 64.w,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Iconsax.warning_2,
                size: KorraSizes.iconXl.sp,
                color: KorraColors.debtRed,
              ),
            ),
            SizedBox(height: 24.h),

            // --- TITLE ---
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: KorraSizes.font2xl.sp,
                fontWeight: KorraSizes.weightBold,
                color: KorraColors.nearBlack,
                letterSpacing: KorraSizes.trackingSnug,
              ),
            ),
            SizedBox(height: 12.h),

            // --- MESSAGE ---
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: KorraSizes.fontMdPlus.sp,
                height: KorraSizes.lineHeightNormal,
                color: const Color(0xFF666666),
              ),
            ),
            SizedBox(height: 32.h),

            // --- BUTTONS ---
            if (hasRetry) ...[
              Row(
                children: [
                  // Cancel (Soft Grey Button - iOS Style)
                  Expanded(
                    child: SizedBox(
                      height: KorraButtons.heightLg.h,
                      child: TextButton(
                        onPressed: () {
                          Get.back();
                          onCancel?.call();
                        },
                        style: KorraButtons.cancelStyle(),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: KorraSizes.fontLg.sp,
                            fontWeight: KorraSizes.weightSemiBold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  // Retry (Brand Primary)
                  Expanded(
                    child: SizedBox(
                      height: KorraButtons.heightLg.h,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          onRetry?.call();
                        },
                        style: KorraButtons.primaryStyle(),
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
              )
            ] else ...[
              // Dismiss Only (Full Width)
              SizedBox(
                width: double.infinity,
                height: KorraButtons.heightLg.h,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    onCancel?.call();
                  },
                  style: KorraButtons.softGreyStyle(),
                  child: Text(
                    'Dismiss',
                    style: GoogleFonts.inter(
                      fontSize: KorraSizes.fontLg.sp,
                      fontWeight: KorraSizes.weightBold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }
}
