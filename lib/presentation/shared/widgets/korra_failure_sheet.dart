import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/constants/colors.dart';

void showKorraFailureSheet(
  BuildContext context, {
  required String title,
  required String message,
  VoidCallback? onRetry,
  VoidCallback? onCancel,
}) {
  HapticFeedback.lightImpact(); // le haptic on error
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(height: 32.h),

            // --- ICON WITH SOFT BACKGROUND ---
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2), // Soft Red Background
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Iconsax.warning_2,
                size: 32.sp,
                color: const Color(0xFFDC2626), // Deep Red
              ),
            ),
            SizedBox(height: 24.h),

            // --- TITLE ---
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111111), // Almost Black
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 12.h),

            // --- MESSAGE ---
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                height: 1.5,
                color: const Color(0xFF666666), // Modern Grey
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
                      height: 56.h,
                      child: TextButton(
                        onPressed: () {
                          Get.back();
                          onCancel?.call();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF2F2F7), // iOS Secondary Fill
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
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
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          onRetry?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KorraColors.brand,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
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
              // Dismiss Only (Full Width)
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    onCancel?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2F2F7), // Soft Grey
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text(
                    "Dismiss",
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
            
            SizedBox(height: 12.h), // Bottom padding
          ],
        ),
      ),
    );
  }
}