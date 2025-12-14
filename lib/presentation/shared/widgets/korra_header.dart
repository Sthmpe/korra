import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../config/constants/colors.dart';

class KorraHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackpressed;
  final bool showLeadingIcon; // For "Back" button
  final bool showLogo;        // ✅ NEW: Only for Home Page
  final List<Widget>? trailingActions;
  
  // Shortcuts for standard actions
  final VoidCallback? onHistory;
  final VoidCallback? onSupport;
  final bool showHistoryDot;

  const KorraHeader({
    super.key,
    required this.title,
    this.onBackpressed,
    this.showLeadingIcon = false,
    this.showLogo = false, // Default to FALSE. Cleaner.
    this.trailingActions,
    this.onHistory,
    this.onSupport,
    this.showHistoryDot = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(56.h); // Standard iOS/Android height

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: 56.h,
          child: Row(
            children: [
              // --- 1. LEADING AREA (Mutual Exclusive) ---
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
                  // If Logo is present, Title usually isn't needed or is secondary
                  ? const SizedBox.shrink() 
                  : Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 20.sp, 
                        fontWeight: FontWeight.w700, 
                        color: const Color(0xFF101828), // Deep Black
                        letterSpacing: -0.5,
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

// -----------------------------------------------------------------------------
// SUB-COMPONENTS
// -----------------------------------------------------------------------------

class _BackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _BackButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact(); // Tactile feel
        if (onPressed != null) {
          onPressed!();
        } else {
          Get.back();
        }
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 40.w,
        height: 40.w,
        alignment: Alignment.centerLeft, // Left align to reduce visual gap
        child: Icon(
          Iconsax.arrow_left,
          size: 24.sp,
          color: const Color(0xFF101828),
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
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: KorraColors.brand.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(MdiIcons.crown, size: 20.sp, color: Colors.white),
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
            size: 24.sp, 
            color: const Color(0xFF101828),
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
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}