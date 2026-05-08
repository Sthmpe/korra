import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/constants/sizes.dart';
import '../../../config/constants/snackbars.dart';

enum SnackbarType { success, warning, error, info }

void showAppSnackbar(String message, SnackbarType type, {VoidCallback? onTap}) {
  if (type == SnackbarType.error) {
    HapticFeedback.mediumImpact();
  } else {
    HapticFeedback.lightImpact();
  }

  IconData icon;
  Color primaryColor;
  Color backgroundColor;

  switch (type) {
    case SnackbarType.success:
      icon = Iconsax.tick_circle;
      primaryColor = KorraSnackbars.successPrimary;
      backgroundColor = KorraSnackbars.successBg;
      break;
    case SnackbarType.warning:
      icon = Iconsax.info_circle;
      primaryColor = KorraSnackbars.warningPrimary;
      backgroundColor = KorraSnackbars.warningBg;
      break;
    case SnackbarType.error:
      icon = Iconsax.warning_2;
      primaryColor = KorraSnackbars.errorPrimary;
      backgroundColor = KorraSnackbars.errorBg;
      break;
    case SnackbarType.info:
      icon = Iconsax.info_circle;
      primaryColor = KorraSnackbars.infoPrimary;
      backgroundColor = KorraSnackbars.infoBg;
      break;
  }

  Get.snackbar(
    '',
    '',
    onTap: onTap != null ? (_) => onTap() : null,
    snackPosition: SnackPosition.TOP,
    duration: KorraSnackbars.durationNormal,
    animationDuration: KorraSnackbars.animationDuration,
    backgroundColor: Colors.transparent,
    barBlur: 0,
    overlayBlur: 0,
    snackStyle: SnackStyle.FLOATING,
    margin: EdgeInsets.fromLTRB(KorraSnackbars.marginH.w, 0, KorraSnackbars.marginH.w, 0),
    padding: EdgeInsets.zero,
    titleText: Container(
      padding: EdgeInsets.symmetric(
        horizontal: KorraSnackbars.paddingH.w,
        vertical: KorraSnackbars.paddingVPill.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KorraSnackbars.radiusPill.r),
        boxShadow: [
          BoxShadow(
            color: KorraSnackbars.shadowColor,
            blurRadius: KorraSnackbars.shadowBlurPill,
            offset: KorraSnackbars.shadowOffsetPill,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: KorraSnackbars.iconContainerSize.w,
            width: KorraSnackbars.iconContainerSize.w,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: primaryColor, size: KorraSnackbars.iconSize.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: KorraSizes.fontSmPlusH.sp,
                  fontWeight: KorraSizes.weightSemiBold,
                  color: const Color(0xFF1F2937),
                  height: KorraSizes.lineHeightMd,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () => Get.closeCurrentSnackbar(),
            child: Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Icon(
                Iconsax.close_circle,
                color: Colors.grey.shade400,
                size: KorraSnackbars.closeSize.sp,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
