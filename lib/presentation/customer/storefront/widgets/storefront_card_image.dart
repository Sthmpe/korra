// lib/presentation/customer/storefront/widgets/storefront_card_image.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/campaign_tags.dart';
import '../../../../config/constants/colors.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/vendor/campaign_model.dart';
import '../../store/widgets/deal_countdown_badge.dart';
import 'storefront_lazy_image.dart';

/// Image frame for [StorefrontProductCard]: crossfading gallery image,
/// bottom scrim, model/campaign badges, sold-out veil and dot indicators.
class StorefrontCardImage extends StatelessWidget {
  final Product product;
  final int imageIndex;
  final bool soldOut;

  /// The store's running/upcoming timed campaign for this product, if any —
  /// shows the same live countdown badge used on the Hot Deals cards.
  final Campaign? deal;

  /// When true the image fills whatever space the parent gives it (used when
  /// the card lives in a FIXED-height strip and the image sits in an
  /// Expanded). When false (masonry default) the image drives its own height
  /// via a dynamic AspectRatio.
  final bool expand;

  const StorefrontCardImage({
    super.key,
    required this.product,
    required this.imageIndex,
    required this.soldOut,
    this.deal,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final images = product.images;

    final frame = Container(
      color: const Color(0xFFF4F5F7),
      width: double.infinity,
      height: expand ? double.infinity : null,
      child: images.isNotEmpty
          ? AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: StorefrontLazyImage(
                key: ValueKey(images[imageIndex % images.length]),
                url: images[imageIndex % images.length],
              ),
            )
          : Center(child: Icon(Iconsax.image, size: 28.sp, color: Colors.grey)),
    );

    return Stack(
      children: [
        if (expand)
          frame
        else
          AspectRatio(
            // Dynamic aspect ratio keeps the Pinterest staggered masonry feel
            aspectRatio: (product.id.hashCode % 2 == 0) ? 0.82 : 1.12,
            child: frame,
          ),

        // Soft bottom gradient scrim for depth (premium editorial look)
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.65, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.12),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Sold-out veil across the whole image
        if (soldOut)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.55),
              alignment: Alignment.center,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: KorraColors.textDark.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "SOLD OUT",
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

        // Model Tag (STRICT / DIRECT / OUTRIGHT)
        Positioned(
          top: 8.h,
          left: 8.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.5.h),
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
              product.allowReservation ? product.modelType.name.toUpperCase() : "OUTRIGHT",
              style: GoogleFonts.inter(
                fontSize: 8.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // Campaign tag overlay on top right — flash-like tags (Flash Deal,
        // Hot Deal, Limited Stock) get a solid urgent chip with a bolt icon.
        if (product.activeCampaignTag != null && product.activeCampaignTag!.isNotEmpty)
          Positioned(
            top: 8.h,
            right: 8.w,
            child: Builder(builder: (context) {
              final tag = product.activeCampaignTag!;
              final isFlash = KorraCampaignTags.isFlashDeal(tag);
              final accent = KorraCampaignTags.colorFor(tag);
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.5.h),
                decoration: BoxDecoration(
                  color: isFlash ? accent : const Color(0xFFFFF4ED),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFlash) ...[
                      Icon(Icons.bolt_rounded, size: 9.sp, color: Colors.white),
                      SizedBox(width: 2.w),
                    ],
                    Text(
                      tag.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w800,
                        color: isFlash ? Colors.white : const Color(0xFFA54600),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

        // Live countdown for a merchant-timed deal on this product
        if (deal != null && deal!.hasTimer)
          Positioned(
            bottom: 8.h,
            left: 8.w,
            child: DealCountdownBadge(campaign: deal!),
          ),

        // Gallery dot indicators (only when more than one image)
        if (images.length > 1)
          Positioned(
            bottom: 8.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length > 6 ? 6 : images.length, (i) {
                final active = i == (imageIndex % images.length);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                  width: active ? 14.w : 5.w,
                  height: 5.w,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}