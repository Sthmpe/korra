import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:korra/config/constants/colors.dart';

enum SnackbarType { success, warning, error }

void showAppSnackbar(String message, SnackbarType type) {
  IconData icon;
  Color color;

  switch (type) {
    case SnackbarType.success:
      icon = Icons.check_circle;
      color = KorraColors.brand; // burnt orange
      break;
    case SnackbarType.warning:
      icon = Icons.info; // circle i
      color = Colors.amber.shade700;
      break;
    case SnackbarType.error:
      icon = Icons.error;
      color = Colors.redAccent;
      break;
  }

  Get.snackbar(
    '',
    '',
    snackPosition: SnackPosition.TOP,
    duration: const Duration(seconds: 12),
    overlayBlur: 0,
    barBlur: 0,
    backgroundColor: Colors.transparent,
    padding: EdgeInsets.zero,
    margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
    borderRadius: 12,
    maxWidth: 340,
    titleText: Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border(
          left: BorderSide(
            color: color,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12.r,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: KorraColors.text,
                height: 1.3,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Get.closeAllSnackbars(),
            child: Icon(
              Icons.close,
              color: KorraColors.textMuted,
              size: 20.sp,
            ),
          ),
        ],
      ),
    ),
  );
}
