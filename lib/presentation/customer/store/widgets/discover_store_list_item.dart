import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../shared/widgets/signal_badge_dot.dart';
import '../../storefront/widgets/storefront_lazy_image.dart';

/// Premium merchant card for the Stores tab: gradient-ringed logo,
/// borderless floating surface, lazy product preview strip and a
/// "Visit Store" call-to-action.
class DiscoverStoreListItem extends StatelessWidget {
  final String vendorId;
  final String name;
  final String description;
  final String logoUrl;
  final String slug;

  /// True when the customer left items in this store's cart, shows the
  /// broadcasting red dot and an "In your cart" pill.
  final bool hasPendingCart;

  /// True when this store has a live campaign running right now, shows the
  /// same broadcasting dot (cart takes the pill text priority if both apply)
  /// and a "Live deal" pill.
  final bool hasActiveCampaign;

  const DiscoverStoreListItem({
    super.key,
    required this.vendorId,
    required this.name,
    required this.description,
    required this.logoUrl,
    required this.slug,
    this.hasPendingCart = false,
    this.hasActiveCampaign = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Get.toNamed('/store/$slug'),
              child: Padding(
                padding: EdgeInsets.all(14.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _GradientRingAvatar(name: name, logoUrl: logoUrl),
                            if (hasPendingCart || hasActiveCampaign)
                              Positioned(
                                top: -6.h,
                                right: -6.w,
                                child: SignalBadgeDot(size: 8.w),
                              ),
                          ],
                        ),
                        SizedBox(width: 12.w),

                        // Store Copy details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 14.5.sp,
                                        fontWeight: FontWeight.w800,
                                        color: KorraColors.textDark,
                                      ),
                                    ),
                                  ),
                                  if (hasPendingCart) ...[
                                    SizedBox(width: 6.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.5.h),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3F2),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        "In your cart",
                                        style: GoogleFonts.inter(
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFB42318),
                                        ),
                                      ),
                                    ),
                                  ] else if (hasActiveCampaign) ...[
                                    SizedBox(width: 6.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.5.h),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF4ED),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        "Live deal",
                                        style: GoogleFonts.inter(
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFA54600),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w400,
                                  color: KorraColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10.w),

                        // Chevron in a soft brand-tinted circle
                        Container(
                          height: 30.w,
                          width: 30.w,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF4ED),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Iconsax.arrow_right_3,
                            size: 14.sp,
                            color: KorraColors.brand,
                          ),
                        ),
                      ],
                    ),

                    // Product preview strip (lazy blurred thumbnails)
                    _ProductPreviewStrip(vendorId: vendorId),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular store logo wrapped in a brand gradient ring.
class _GradientRingAvatar extends StatelessWidget {
  final String name;
  final String logoUrl;

  const _GradientRingAvatar({required this.name, required this.logoUrl});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    return Container(
      height: 54.w,
      width: 54.w,
      padding: EdgeInsets.all(2.5.w),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [KorraColors.brand, Color(0xFFE05600)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: ClipOval(
          child: logoUrl.isNotEmpty
              ? StorefrontLazyImage(url: logoUrl, memCacheWidth: 150)
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
    );
  }
}

/// Up to three square product thumbnails plus a "Visit Store" footer.
class _ProductPreviewStrip extends StatelessWidget {
  final String vendorId;

  const _ProductPreviewStrip({required this.vendorId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('vendorId', isEqualTo: vendorId)
          .where('status', isEqualTo: 'approved')
          .limit(3)
          .snapshots(),
      builder: (context, prodSnapshot) {
        if (!prodSnapshot.hasData || prodSnapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final urls = prodSnapshot.data!.docs.map((doc) {
          final prodData = doc.data() as Map<String, dynamic>;
          final images = List<String>.from(prodData['images'] ?? []);
          return images.isNotEmpty ? images.first : '';
        }).toList();

        return _buildStrip(urls);
      },
    );
  }

  Widget _buildStrip(List<String> urls) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: Divider(height: 1.h, color: const Color(0xFFF2F4F7)),
            ),
            Row(
              children: List.generate(3, (i) {
                if (i >= urls.length) {
                  // Keep all three slots equal width even with fewer products
                  return const Expanded(child: SizedBox.shrink());
                }
                final String imgUrl = urls[i];

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 8.w : 0),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: imgUrl.isNotEmpty
                            ? StorefrontLazyImage(url: imgUrl, memCacheWidth: 300)
                            : Container(
                                color: const Color(0xFFF4F5F7),
                                child: Icon(Iconsax.image, size: 16.sp, color: Colors.grey),
                              ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Visit Store",
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: KorraColors.brand,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(Iconsax.arrow_right_3, size: 12.sp, color: KorraColors.brand),
              ],
            ),
          ],
        );
  }
}