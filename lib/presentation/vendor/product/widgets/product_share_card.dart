import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/vendor/product/vendor_products_state.dart';
import '../../../shared/widgets/show_app_snackbar.dart';

class ProductShareCard extends StatelessWidget {
  final ProductItem product;
  final GlobalKey repaintKey;

  const ProductShareCard({
    super.key,
    required this.product,
    required this.repaintKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: 340.w,
        height: 540.h, // Taller for that "Story" aspect ratio
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          // Premium Shadow
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA54600).withOpacity(0.2), // Orange shadow tint
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: Column(
            children: [
              // --- 1. BRAND HEADER ---
              Container(
                height: 60.h,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                color: KorraColors.brand,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "KORRA",
                      style: GoogleFonts.oswald(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30.r),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Text(
                        "OWN IT NOW",
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- 2. HERO IMAGE (Biggest Section) ---
              Expanded(
                flex: 6,
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF2F4F7),
                  child: product.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl.first,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: const Color(0xFFF2F4F7)),
                          errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                        )
                      : Center(
                          child: Icon(Icons.shopping_bag_outlined, size: 60.sp, color: Colors.grey.shade300),
                        ),
                ),
              ),

              // --- 3. DETAILS & CODE (The "Ticket" Look) ---
              Expanded(
                flex: 4,
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Detail Content
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name & Model
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF101828),
                                            height: 1.2,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          "Secured via Korra Lock",
                                          style: GoogleFonts.inter(
                                            fontSize: 11.sp,
                                            color: const Color(0xFF667085),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  // Price is the STAR
                                  Text(
                                    product.priceText,
                                    style: GoogleFonts.inter(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w800,
                                      color: KorraColors.brand,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // --- 4. TICKET CUTOUT SEPARATOR ---
                      SizedBox(
                        height: 20.h,
                        child: Row(
                          children: [
                            // Left Cutout
                            Container(
                              width: 10.w,
                              height: 20.h,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200, // Matches background of screen usually
                                borderRadius: BorderRadius.horizontal(right: Radius.circular(10.r)),
                              ),
                            ),
                            // Dashed Line
                            Expanded(
                              child: Flex(
                                direction: Axis.horizontal,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                mainAxisSize: MainAxisSize.max,
                                children: List.generate(12, (_) {
                                  return SizedBox(
                                    width: 5.w,
                                    height: 1,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(color: Colors.grey.shade300),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            // Right Cutout
                            Container(
                              width: 10.w,
                              height: 20.h,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.horizontal(left: Radius.circular(10.r)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // --- 5. THE CODE PILL (Apple Wallet Style) ---
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 20.h),
                        child: GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: product.code));
                            showAppSnackbar("Code '${product.code}' Copied to clipboard!", SnackbarType.success);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            decoration: BoxDecoration(
                              color: KorraColors.brand, // Dark Premium background
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "USE THIS CODE",
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white54,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                // 🛡️ FittedBox keeps it safe
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      children: [
                                        Text(
                                          product.code,
                                          style: GoogleFonts.spaceMono(
                                            fontSize: 20.sp,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white, // White text on Dark
                                            letterSpacing: 3.0,
                                          ),
                                        ),
                                        SizedBox(width: 8.w), // Space between Code and Icon
                                        Icon(
                                          Icons.copy, 
                                          color: Colors.white, 
                                          size: 18.sp
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}