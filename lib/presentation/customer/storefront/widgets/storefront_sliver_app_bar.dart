// lib/presentation/customer/storefront/widgets/storefront_sliver_app_bar.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import 'storefront_lazy_image.dart';

/// Collapsing storefront app bar: parallax cover photo that shrinks into a
/// pinned white toolbar, with a glassmorphic logo card floating over the cover.
class StorefrontSliverAppBar extends StatelessWidget {
  final String storeName;
  final String logoUrl;
  final String coverUrl;
  final List<Widget> actions;

  const StorefrontSliverAppBar({
    super.key,
    required this.storeName,
    required this.logoUrl,
    required this.coverUrl,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 220.h,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: Center(
        child: GlassIconButton(
          icon: Iconsax.arrow_left,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [...actions, SizedBox(width: 8.w)],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // Collapse progress: 1.0 fully collapsed → 0.0 fully expanded.
          final minH = kToolbarHeight + topPadding;
          final range = (220.h + topPadding) - minH;
          final t = range <= 0
              ? 1.0
              : (1 - ((constraints.maxHeight - minH) / range)).clamp(0.0, 1.0);
          // Title fades in only during the last stretch of the collapse
          final titleOpacity = ((t - 0.75) / 0.25).clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                stretchModes: const [StretchMode.zoomBackground],
                background: _buildBackground(),
              ),

              // Collapsed toolbar title, aligned exactly next to the back
              // button inside the toolbar band (not FlexibleSpaceBar's
              // scaling title, which sat off-position).
              Positioned(
                top: topPadding,
                left: 56.w,
                right: 104.w,
                height: kToolbarHeight,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: titleOpacity,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: KorraColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
              fit: StackFit.expand,
              children: [
                // Parallax cover photo (brand gradient fallback)
                if (coverUrl.isNotEmpty)
                  StorefrontLazyImage(url: coverUrl, memCacheWidth: 1080)
                else
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [KorraColors.brand, Color(0xFFE05600)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),

                // Scrims: keep status bar icons and the glass card readable
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.35, 0.7, 1.0],
                      colors: [
                        Color(0x66000000),
                        Color(0x00000000),
                        Color(0x00000000),
                        Color(0x59000000),
                      ],
                    ),
                  ),
                ),

                // Glassmorphic logo card
                Positioned(
                  left: 16.w,
                  right: 16.w,
                  bottom: 16.h,
                  child: _GlassLogoCard(storeName: storeName, logoUrl: logoUrl),
                ),
              ],
            );
  }
}

/// Frosted glass card holding the store logo and name over the cover photo.
class _GlassLogoCard extends StatelessWidget {
  final String storeName;
  final String logoUrl;

  const _GlassLogoCard({required this.storeName, required this.logoUrl});

  @override
  Widget build(BuildContext context) {
    final initial = storeName.isNotEmpty ? storeName[0].toUpperCase() : 'S';

    return Align(
      alignment: Alignment.centerLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              // Dark brand-tinted glass so the white store name always pops
              color: KorraColors.brandDark.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(16.r),
              // Border kept for edge definition but nearly invisible
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 46.w,
                  width: 46.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: logoUrl.isNotEmpty
                        ? StorefrontLazyImage(url: logoUrl, memCacheWidth: 200)
                        : Container(
                            color: KorraColors.brandLight,
                            alignment: Alignment.center,
                            child: Text(
                              initial,
                              style: GoogleFonts.inter(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                                color: KorraColors.brand,
                              ),
                            ),
                          ),
                  ),
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              size: 12.sp, color: Colors.white.withValues(alpha: 0.9)),
                          SizedBox(width: 4.w),
                          Text(
                            "Korra Storefront",
                            style: GoogleFonts.inter(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
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
      ),
    );
  }
}

/// White circular icon button that stays readable over the cover photo and on
/// the collapsed white toolbar (Airbnb-style).
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 36.w,
          width: 36.w,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 18.sp, color: KorraColors.textDark),
        ),
      ),
    );
  }
}