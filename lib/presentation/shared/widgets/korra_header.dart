import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../config/constants/colors.dart'; // Ensure KorraColors is imported

class KorraHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onHistory;
  final VoidCallback? onMenu;
  final VoidCallback? onSupport;
  final VoidCallback? onBackpressed;
  final bool showHistoryDot;
  final bool showLeadingIcon;
  final List<Widget>? trailingActions;

  const KorraHeader({
    super.key,
    required this.title,
    this.onHistory,
    this.onMenu,
    this.onSupport,
    this.onBackpressed,
    this.showHistoryDot = false,
    this.showLeadingIcon = false,
    this.trailingActions,
  });

  @override
  Size get preferredSize => Size.fromHeight(60.h); // Slightly taller for modern feel

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Dark icons on white status bar
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Container(
        color: Colors.white, // Solid background
        padding: EdgeInsets.symmetric(horizontal: 20.w), // More breathing room
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 60.h,
          alignment: Alignment.center,
          child: Row(
            children: [
              // --- LEADING (Back or Brand) ---
              if (showLeadingIcon)
                _BackButton(onPressed: onBackpressed)
              else
                _BrandLogo(),

              SizedBox(width: 12.w),

              // --- TITLE ---
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 20.sp, // Larger, bolder title
                    fontWeight: FontWeight.w700,
                    color: KorraColors.black,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // --- ACTIONS ---
              Row(
                children: trailingActions ??
                    [
                      if (onHistory != null)
                        _HeaderActionBtn(
                          icon: Iconsax.clock, 
                          onTap: onHistory,
                        ),
                      if (onMenu != null)
                        _HeaderActionBtn(
                          icon: Icons.more_vert_rounded,
                          onTap: onMenu,
                        ),
                      if (onSupport != null) ...[
                        SizedBox(width: 4.w), // Tiny gap between icons
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

// -----------------------------------------------------------------------------
// SUB-COMPONENTS
// -----------------------------------------------------------------------------

class _BackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _BackButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed ?? () => Get.back(),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 40.w,
        height: 40.w,
        alignment: Alignment.centerLeft, // Align icon left to remove visual padding
        child: Icon(
          Iconsax.arrow_left,
          size: 24.sp,
          color: KorraColors.black,
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
        borderRadius: BorderRadius.circular(10.r), // Soft square
        boxShadow: [
          BoxShadow(
            color: KorraColors.brand.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        MdiIcons.crown,
        size: 20.sp,
        color: Colors.white,
      ),
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
          icon: Icon(
            icon, 
            size: 24.sp, 
            color: const Color(0xFF111111), // Almost black
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
                color: const Color(0xFFFF3B30), // iOS Red
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5), // White ring
              ),
            ),
          ),
      ],
    );
  }
}