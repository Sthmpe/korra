import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../config/constants/colors.dart';

void showKorraFailureSheetCustomer(
  BuildContext context, {
  required String title,
  required String message,
  VoidCallback? onRetry,
  VoidCallback? onCancel,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) => _KorraFailureSheetCustomer(
      title: title,
      message: message,
      onRetry: onRetry,
      onCancel: onCancel,
    ),
  );
}


class _KorraFailureSheetCustomer extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const _KorraFailureSheetCustomer({
    required this.title,
    required this.message,
    this.onRetry,
    this.onCancel,
  });

  bool get hasRetry => onRetry != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFFEAE6E2),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 24.h),

          // Icon
          Icon(
            Iconsax.warning_2,
            size: 36.sp,
            color: KorraColors.danger,
          ),
          SizedBox(height: 16.h),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: KorraColors.text,
            ),
          ),
          SizedBox(height: 8.h),

          // Message
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              height: 1.5,
              color: KorraColors.textMuted,
            ),
          ),
          SizedBox(height: 24.h),

          // Buttons
          if (hasRetry) ...[
            Row(
              children: [
                // Cancel
                Expanded(
                  child: SizedBox(
                    height: 52.h,
                    child: OutlinedButton(
                      onPressed: () {
                        onCancel?.call();
                        Get.back();
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        side: BorderSide(color: KorraColors.border),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
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
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        onRetry?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KorraColors.brand,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        "Try Again",
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ] else ...[
            // Only Dismiss Button
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: () {
                  onCancel?.call();
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: KorraColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  "Dismiss",
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: KorraColors.textMuted,
                  ),
                ),
              ),
            )
          ],

          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
