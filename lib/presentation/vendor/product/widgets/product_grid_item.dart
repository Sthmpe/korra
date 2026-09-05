import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/vendor/product/vendor_products_state.dart';

/// Compact 2-column grid card for the merchant catalog: image with the status
/// pill overlaid (status is the one thing a merchant must never lose sight
/// of), name, price and a stock line. Tap opens product details where share,
/// edit and delete live; long-press still enters selection mode.
class ProductGridItem extends StatelessWidget {
  final ProductItem product;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ProductGridItem({
    super.key,
    required this.product,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final soldOut = product.stock <= 0;
    final lowStock = !soldOut && product.stock < 5;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? KorraColors.brand : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- IMAGE + STATUS PILL (+ selection check) ---
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl.first,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey.shade100,
                            child: Icon(Iconsax.image,
                                size: 22.sp, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: Icon(Iconsax.image,
                              size: 22.sp, color: Colors.grey),
                        ),
                  Positioned(
                    left: 8.w,
                    top: 8.h,
                    child: _StatusPill(status: product.status),
                  ),
                  if (isSelectionMode)
                    Positioned(
                      right: 8.w,
                      top: 8.h,
                      child: Container(
                        padding: EdgeInsets.all(2.r),
                        decoration: BoxDecoration(
                          color: isSelected ? KorraColors.brand : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? KorraColors.brand
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Icon(
                          Icons.check,
                          size: 14.sp,
                          color: isSelected ? Colors.white : Colors.transparent,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // --- CONTENT ---
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1B1B),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    product.priceText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: KorraColors.brand,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    soldOut ? 'Out of stock' : '${product.stock} in stock',
                    style: GoogleFonts.inter(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                      color: soldOut
                          ? const Color(0xFFB42318)
                          : lowStock
                              ? const Color(0xFFB54708)
                              : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ProductStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color bg;
    final Color fg;

    switch (status) {
      case ProductStatus.approved:
        text = 'APPROVED';
        bg = const Color(0xFFECFDF3);
        fg = const Color(0xFF027A48);
        break;
      case ProductStatus.pending:
        text = 'PENDING';
        bg = const Color(0xFFFFFAEB);
        fg = const Color(0xFFB54708);
        break;
      case ProductStatus.rejected:
        text = 'REJECTED';
        bg = const Color(0xFFFEF3F2);
        fg = const Color(0xFFB42318);
        break;
      case ProductStatus.outOfStock:
        text = 'NO STOCK';
        bg = const Color(0xFFF2F4F7);
        fg = const Color(0xFF475467);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.95),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 8.5.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: fg,
        ),
      ),
    );
  }
}
