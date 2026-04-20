import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/vendor/product/vendor_products_state.dart';

class ProductListItemPremium extends StatelessWidget {
  final ProductItem product;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onShare;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onLongPress;

  const ProductListItemPremium({
    super.key,
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onShare,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            foregroundDecoration: isSelected 
                    ? BoxDecoration(color: KorraColors.brand.withOpacity(0.05), borderRadius: BorderRadius.circular(16.r)) 
                    : null,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFEAECF0).withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Image Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    width: 80.w, 
                    height: 80.w,
                    color: const Color(0xFFF2F4F7),
                    child: product.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl.first,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(Iconsax.image, color: Colors.grey),
                          )
                        : Center(
                            child: Text(
                              product.name.substring(0, 1).toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 24.sp, 
                                fontWeight: FontWeight.w700, 
                                color: Colors.grey.shade400
                              ),
                            ),
                          ),
                  ),
                ),
                
                SizedBox(width: 16.w),
          
                // 2. Content Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Title & Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 15.sp, 
                                    fontWeight: FontWeight.w600, 
                                    color: const Color(0xFF101828)
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  product.category,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp, 
                                    color: const Color(0xFF667085), 
                                    fontWeight: FontWeight.w500
                                  ),
                                ),
                              ],
                            ),
                          ),
                          isSelectionMode ? SizedBox.shrink() : SizedBox(width: 8.w),
                          _StatusBadge(status: product.status),
                          isSelectionMode ? SizedBox(width: 28.w) : SizedBox.shrink(),
                        ],
                      ),
          
                      SizedBox(height: 12.h),
          
                      // Row 2: Price & Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Price
                          Text(
                            product.priceText,
                            style: GoogleFonts.inter(
                              fontSize: 15.sp, 
                              fontWeight: FontWeight.w700, 
                              color: const Color(0xFF101828)
                            ),
                          ),
                          
                          // Actions Area
                          Row(
                            children: [
                              // Stock Indicator
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F4F7),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  "${product.stock} left",
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp, 
                                    fontWeight: FontWeight.w600, 
                                    color: const Color(0xFF344054)
                                  ),
                                ),
                              ),
          
                              // Share Button (Only if active)
                              if (onShare != null) ...[
                                SizedBox(width: 8.w),
                                InkWell(
                                  onTap: onShare,
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Container(
                                    padding: EdgeInsets.all(4.r),
                                    margin: EdgeInsets.symmetric(horizontal: 2.w),
                                    decoration: BoxDecoration(
                                      //color: const Color(0xFFFFF4ED), // Light brand orange
                                      borderRadius: BorderRadius.circular(8.r),
                                      //border: Border.all(color: const Color(0xFFFFE0D0)),
                                    ),
                                    child: Icon(
                                      // ✅ UPDATED ICON: The standard "Share Node"
                                      Icons.share, 
                                      size: 18.sp,
                                      color: const Color(0xFFA54600),
                                    ),
                                  ),
                                ),
                              ],
          
                              InkWell(
                                onTap: onDelete,
                                borderRadius: BorderRadius.circular(8.r),
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                                  decoration: BoxDecoration(
                                      //color: Colors.red.shade50, // Light brand red
                                      borderRadius: BorderRadius.circular(8.r),
                                      //border: Border.all(color: const Color(0xFFFFE0D0)),
                                    ),
                                  child: Padding(
                                    padding: EdgeInsets.all(4.r),
                                    child: Icon(Icons.delete, size: 16.sp, color: Colors.black87),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 3. Selection Overlay
          if (isSelectionMode)
            Positioned(
              top: 12.h,
              right: 12.w,
              child: Container(
                width: 24.r, height: 24.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? KorraColors.brand : Colors.white,
                  border: Border.all(color: isSelected ? KorraColors.brand : Colors.grey.shade300, width: 2),
                ),
                child: isSelected 
                    ? Icon(Icons.check, size: 16.sp, color: Colors.white) 
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ProductStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case ProductStatus.approved:
        bg = const Color(0xFFECFDF5);
        text = const Color(0xFF027A48);
        label = "Active";
        break;
      case ProductStatus.pending:
        bg = const Color(0xFFFFFAEB);
        text = const Color(0xFFB54708);
        label = "Review";
        break;
      case ProductStatus.rejected:
        bg = const Color(0xFFFEF3F2);
        text = const Color(0xFFB42318);
        label = "Rejected";
        break;
      case ProductStatus.outOfStock:
        bg = const Color(0xFFF9FAFB);
        text = const Color(0xFF344054);
        label = "Empty";
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100.r),
        border: Border.all(color: bg == const Color(0xFFF9FAFB) ? const Color(0xFFEAECF0) : Colors.transparent),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 10.sp, fontWeight: FontWeight.w700, color: text),
      ),
    );
  }
}