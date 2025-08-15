import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class KorraHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onHistory;
  final VoidCallback? onSupport;
  final bool showHistoryDot;

  const KorraHeader({
    super.key,
    required this.title,
    this.onHistory,
    this.onSupport,
    this.showHistoryDot = false,
  });

  static const _brand = Color(0xFFA54600);

  @override
  Size get preferredSize => Size.fromHeight(56.h);

  @override
  Widget build(BuildContext context) {
    // light surface like your login, no heavy shadow
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 56.h,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border(
                    bottom: BorderSide(color: const Color(0xFFEAE6E2), width: 1.w),
                  ),
                ),
                child: Row(
                  children: [
                    // brand tile with crown placeholder (swap with your asset if you have one)
                    Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(
                        color: _brand,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        MdiIcons.crown, // crown placeholder
                        size: 16.sp,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(width: 8.w),

                    // centered title
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1B1B1B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // actions
                    Row(
                      children: [
                        // history with optional unread dot
                        _IconBtn(
                          icon: MdiIcons.history,
                          onTap: onHistory,
                          dot: showHistoryDot,
                        ),
                        SizedBox(width: 8.w),
                        _IconBtn(
                          icon: Iconsax.notification,
                          onTap: onSupport,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool dot;

  const _IconBtn({required this.icon, this.onTap, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: 45.w,
          height: 45.w,
          child: IconButton(
            onPressed: onTap,
            icon: Icon(icon, size: 22.sp, color: const Color(0xFF1B1B1B))
          ),
        ),
        if (dot)
          Positioned(
            right: 6.w,
            top: 6.h,
            child: Container(
              width: 8.w,
              height: 8.w,
              decoration: const BoxDecoration(
                color: Color(0xFFA54600),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
