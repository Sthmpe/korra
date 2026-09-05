// lib/presentation/customer/storefront/widgets/storefront_details_carousel.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../data/models/product_model.dart';
import 'storefront_lazy_image.dart';

/// Premium swipable image carousel for the product details sheet:
/// lazy blurred images, stretching dot indicators, photo counter pill,
/// model/campaign badges and a sold-out veil — matching the grid cards.
class StorefrontDetailsCarousel extends StatefulWidget {
  final Product product;

  const StorefrontDetailsCarousel({super.key, required this.product});

  @override
  State<StorefrontDetailsCarousel> createState() => _StorefrontDetailsCarouselState();
}

class _StorefrontDetailsCarouselState extends State<StorefrontDetailsCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = product.images;
    final soldOut = product.availableStock <= 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: SizedBox(
        height: 300.h,
        width: double.infinity,
        child: images.isEmpty
            ? Container(
                color: const Color(0xFFF4F5F7),
                alignment: Alignment.center,
                child: Icon(Iconsax.image, size: 40.sp, color: Colors.grey),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) =>
                        StorefrontLazyImage(url: images[i], memCacheWidth: 900),
                  ),

                  // Soft bottom scrim so dots stay readable
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.75, 1.0],
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.18),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Sold-out veil
                  if (soldOut)
                    IgnorePointer(
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.55),
                        alignment: Alignment.center,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                          decoration: BoxDecoration(
                            color: KorraColors.textDark.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            "SOLD OUT",
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Model tag (STRICT / DIRECT / OUTRIGHT)
                  Positioned(
                    top: 12.h,
                    left: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: (!product.allowReservation
                                ? Colors.grey.shade800
                                : (product.modelType.name == 'strict'
                                    ? KorraColors.brandDark
                                    : KorraColors.settleGreen))
                            .withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        product.allowReservation
                            ? product.modelType.name.toUpperCase()
                            : "OUTRIGHT",
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Campaign tag
                  if (product.activeCampaignTag != null && product.activeCampaignTag!.isNotEmpty)
                    Positioned(
                      top: 12.h,
                      right: 12.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4ED),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          product.activeCampaignTag!.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFA54600),
                          ),
                        ),
                      ),
                    ),

                  // Photo counter pill
                  if (images.length > 1)
                    Positioned(
                      bottom: 12.h,
                      right: 12.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          "${_index + 1} / ${images.length}",
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  // Stretching dot indicators
                  if (images.length > 1)
                    Positioned(
                      bottom: 12.h,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length > 8 ? 8 : images.length, (i) {
                          final active = i == _index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: EdgeInsets.symmetric(horizontal: 2.5.w),
                            width: active ? 16.w : 6.w,
                            height: 6.w,
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}