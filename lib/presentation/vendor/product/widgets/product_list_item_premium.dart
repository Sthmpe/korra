import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final initial = product.name.isNotEmpty ? product.name[0].toUpperCase() : 'P';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isSelected ? KorraColors.brand : KorraColors.borderCool.withOpacity(0.35),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Image Thumbnail (No border, rounded corner)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          width: 72.w,
                          height: 72.w,
                          color: const Color(0xFFF9FAFB),
                          child: product.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: product.imageUrl.first,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Icon(MdiIcons.imageOutline, color: Colors.grey.shade400, size: 24.sp),
                                )
                              : Center(
                                  child: Text(
                                    initial,
                                    style: GoogleFonts.inter(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFA54600),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(width: 14.w),

                      // 2. Info Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 14.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF101828),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                _StatusBadge(status: product.status),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                                  product.category,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF667085),
                                  ),
                                ),
                            // Row(
                            //   children: [
                                
                            //     SizedBox(width: 6.w),
                            //     Text(
                            //       "•",
                            //       style: TextStyle(color: Colors.grey.shade400, fontSize: 10.sp),
                            //     ),
                            //     SizedBox(width: 6.w),
                            //     Text(
                            //       product.code,
                            //       style: GoogleFonts.spaceMono(
                            //         fontSize: 10.5.sp,
                            //         fontWeight: FontWeight.w600,
                            //         color: const Color(0xFF475467),
                            //       ),
                            //     ),
                            //   ],
                            // ),
                            SizedBox(height: 8.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  product.priceText,
                                  style: GoogleFonts.inter(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFA54600),
                                  ),
                                ),
                                
                                // Installments status badge
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                                  decoration: BoxDecoration(
                                    color: product.allowReservation 
                                        ? const Color(0xFFECFDF3) 
                                        : const Color(0xFFF2F4F7),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        product.allowReservation ? MdiIcons.shieldCheck : Icons.shopping_bag_outlined,
                                        size: 11.sp,
                                        color: product.allowReservation ? const Color(0xFF027A48) : const Color(0xFF667085),
                                      ),
                                      SizedBox(width: 3.w),
                                      Text(
                                        product.allowReservation ? "INSTALLMENTS" : "OUTRIGHT ONLY",
                                        style: GoogleFonts.inter(
                                          fontSize: 8.sp,
                                          fontWeight: FontWeight.w800,
                                          color: product.allowReservation ? const Color(0xFF027A48) : const Color(0xFF344054),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  const Divider(color: Color(0xFFF2F4F7), height: 0.5, thickness: 0.5),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Stock indicator
                      Row(
                        children: [
                          Container(
                            width: 6.w,
                            height: 6.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: product.stock > 0 
                                  ? const Color(0xFF12B76A) // Green
                                  : const Color(0xFFF04438), // Red
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            product.stock > 0 
                                ? "${product.stock} items left" 
                                : "Out of stock",
                            style: GoogleFonts.inter(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w600,
                              color: product.stock > 0 
                                  ? const Color(0xFF344054) 
                                  : const Color(0xFFF04438),
                            ),
                          ),
                        ],
                      ),

                      // Actions
                      Row(
                        children: [
                          if (onShare != null && product.status == ProductStatus.approved)
                            GestureDetector(
                              onTap: onShare,
                              child: Container(
                                padding: EdgeInsets.all(6.r),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFF4ED),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.share,
                                  size: 16.sp,
                                  color: const Color(0xFFA54600),
                                ),
                              ),
                            ),
                          if (onShare != null && product.status == ProductStatus.approved)
                            SizedBox(width: 8.w),
                          GestureDetector(
                            onTap: onEdit,
                            child: Container(
                              padding: EdgeInsets.all(6.r),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF2F4F7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit,
                                size: 16.sp,
                                color: const Color(0xFF344054),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          GestureDetector(
                            onTap: onDelete,
                            child: Container(
                              padding: EdgeInsets.all(6.r),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEF3F2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.delete,
                                size: 16.sp,
                                color: const Color(0xFFD92D20),
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
          ),
        ),
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
        bg = const Color(0xFFECFDF3);
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