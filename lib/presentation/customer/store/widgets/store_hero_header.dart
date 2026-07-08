// lib/presentation/customer/store/widgets/store_hero_header.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';

/// Premium gradient hero for the Stores tab: brand banner with soft
/// decorative circles and a floating white search bar overlapping its edge.
class StoreHeroHeader extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  const StoreHeroHeader({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Brand gradient banner with decorative bubbles
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 52.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [KorraColors.brand, Color(0xFFE05600)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Faded storefront icons — intentional brand watermark
              Positioned(
                right: -10.w,
                top: -14.h,
                child: Transform.rotate(
                  angle: -0.18,
                  child: Icon(
                    Iconsax.shop,
                    size: 96.sp,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Positioned(
                right: 92.w,
                bottom: -22.h,
                child: Transform.rotate(
                  angle: 0.14,
                  child: Icon(
                    Iconsax.bag_2,
                    size: 52.sp,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Stores",
                    style: GoogleFonts.inter(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "Discover and browse your favorite merchants",
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Floating search bar overlapping the banner edge
        Positioned(
          left: 16.w,
          right: 16.w,
          bottom: -26.h,
          child: Container(
            height: 52.h,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Iconsax.search_normal, size: 19.sp, color: KorraColors.brand),
                SizedBox(width: 10.w),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: "Search store name or store code...",
                      hintStyle: GoogleFonts.inter(fontSize: 13.5.sp, color: KorraColors.textHint),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: GoogleFonts.inter(fontSize: 14.sp, color: KorraColors.textDark),
                  ),
                ),
                if (searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: onClearSearch,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2F4F7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, size: 14.sp, color: KorraColors.textMuted),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}