import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../config/constants/colors.dart';

/// Shows the elegant failure bottom sheet, adapted from your proven design.

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 24.h),

          // --- Warning Icon ---
          Icon(Iconsax.warning_2, size: 36.sp, color: KorraColors.danger),
          SizedBox(height: 16.h),

          // --- Title ---
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),

          // --- Message ---
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: KorraColors.textMuted,
              height: 1.5,
            ),
          ),
          SizedBox(height: 24.h),

          // --- Try Again & Cancel Row ---
          Row(
            children: [
              // Cancel
              Expanded(
                child: SizedBox(
                  height: 52.h,
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
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
                      retryCallback?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      backgroundColor: KorraColors.brand,
                    ),
                    child: Text(
                      'Try Again',
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
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
