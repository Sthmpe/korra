import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/constants/sizes.dart';

class KorraHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackpressed;
  final bool showLeadingIcon;
  final bool showLogo;
  final List<Widget>? trailingActions;

  final VoidCallback? onHistory;
  final VoidCallback? onSupport;
  final bool showHistoryDot;

  const KorraHeader({
    super.key,
    required this.title,
    this.onBackpressed,
    this.showLeadingIcon = false,
    this.showLogo = false,
    this.trailingActions,
    this.onHistory,
    this.onSupport,
    this.showHistoryDot = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(56.h);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: KorraSizes.gutter.w),
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: 56.h,
          child: Row(
            children: [
              // --- 1. LEADING AREA ---
              if (showLeadingIcon) ...[
                _BackButton(onPressed: onBackpressed),
                SizedBox(width: 12.w),
              ] else if (showLogo) ...[
                _BrandLogo(),
                SizedBox(width: 12.w),
              ],

              // --- 2. TITLE AREA ---
              Expanded(
                child: showLogo
                    ? const SizedBox.shrink()
                    : Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: KorraSizes.font2xl.sp,
                          fontWeight: KorraSizes.weightBold,
                          color: KorraColors.textDark,
                          letterSpacing: KorraSizes.trackingSnug,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),

              // --- 3. ACTIONS AREA ---
              Row(
                mainAxisSize: MainAxisSize.min,
                children: trailingActions ?? [
                  if (onHistory != null)
                    _HeaderActionBtn(icon: Iconsax.clock, onTap: onHistory),
                  if (onSupport != null) ...[
                    SizedBox(width: 4.w),
                    _HeaderActionBtn(
                      icon: Iconsax.notification,
                      onTap: onSupport,
                      showDot: showHistoryDot,
                    ),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _BackButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        if (onPressed != null) {
          onPressed!();
        } else {
          Get.back();
        }
      },
      borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
      child: Container(
        width: 40.w,
        height: 40.w,
        alignment: Alignment.centerLeft,
        child: Icon(
          Iconsax.arrow_left,
          size: KorraSizes.iconLg.sp,
          color: KorraColors.textDark,
        ),
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36.w,
      height: 36.w,
      decoration: BoxDecoration(
        color: KorraColors.brand,
        borderRadius: BorderRadius.circular(KorraSizes.chipRadius.r),
        boxShadow: [
          BoxShadow(
            color: KorraColors.brand.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(MdiIcons.crown, size: KorraSizes.iconMd.sp, color: Colors.white),
    );
  }
}

class _HeaderActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool showDot;

  const _HeaderActionBtn({
    required this.icon,
    this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          splashRadius: 24.r,
          constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.w),
          icon: Icon(
            icon,
            size: KorraSizes.iconLg.sp,
            color: KorraColors.textDark,
          ),
        ),
        if (showDot)
          Positioned(
            right: 10.w,
            top: 10.h,
            child: Container(
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
