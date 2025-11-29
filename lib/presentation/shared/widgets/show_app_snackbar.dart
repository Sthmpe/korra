import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

enum SnackbarType { success, warning, error }

void showAppSnackbar(String message, SnackbarType type) {
  // 1. Haptic Feedback (Immediate physical response)
  if (type == SnackbarType.error) {
    HapticFeedback.mediumImpact();
  } else {
    HapticFeedback.lightImpact();
  }

  IconData icon;
  Color primaryColor;
  Color backgroundColor;

  // 2. Define "Soft" Palette
  switch (type) {
    case SnackbarType.success:
      icon = Iconsax.tick_circle;
      primaryColor = const Color(0xFF10B981); // Emerald Green
      backgroundColor = const Color(0xFFECFDF5); // Soft Green Bg
      break;
    case SnackbarType.warning:
      icon = Iconsax.info_circle;
      primaryColor = const Color(0xFFF59E0B); // Amber
      backgroundColor = const Color(0xFFFFFBEB); // Soft Amber Bg
      break;
    case SnackbarType.error:
      icon = Iconsax.warning_2;
      primaryColor = const Color(0xFFEF4444); // Red
      backgroundColor = const Color(0xFFFEF2F2); // Soft Red Bg
      break;
  }

  Get.snackbar(
    '', // Title hidden
    '', // Message hidden (we use custom titleText)
    snackPosition: SnackPosition.TOP,
    duration: const Duration(seconds: 4), // 4s is standard. 12s is too long.
    animationDuration: const Duration(milliseconds: 400),
    
    // Remove default GetX styling
    backgroundColor: Colors.transparent,
    barBlur: 0,
    overlayBlur: 0,
    snackStyle: SnackStyle.FLOATING,
    
    // Position & Margin
    margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 0), // Top padding handled by GetX usually
    padding: EdgeInsets.zero,
    
    // --- THE CUSTOM CARD ---
    titleText: Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r), // iOS-style pill
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // Very diffuse shadow
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Align top for long text
        children: [
          // 1. Status Icon Pill
          Container(
            height: 36.w,
            width: 36.w,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: primaryColor, size: 20.sp),
          ),
          
          SizedBox(width: 12.w),

          // 2. Message Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2.h), // Center visually with icon
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600, // Semi-bold for readability
                  color: const Color(0xFF1F2937), // Grey-900 (Softer than black)
                  height: 1.4, // Breathable line height
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          SizedBox(width: 8.w),

          // 3. Close Action
          GestureDetector(
            onTap: () => Get.closeCurrentSnackbar(),
            child: Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Icon(
                Iconsax.close_circle,
                color: Colors.grey.shade400,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}