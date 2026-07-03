// lib/presentation/customer/storefront/widgets/storefront_product_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants/colors.dart';
import '../../../../data/models/product_model.dart';

class StorefrontProductCard extends StatelessWidget {
  final Product product;
  final DocumentSnapshot? rawDoc;
  final Function(Product, DocumentSnapshot?) onTap;

  const StorefrontProductCard({
    super.key,
    required this.product,
    this.rawDoc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
    final hasDiscount = product.discountedPrice != null && product.discountedPrice! > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: KorraColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.02 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(product, rawDoc),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Essential for Masonry unequal sizing
              children: [
                // Image Frame (Dynamic aspect ratio for Pinterest staggered masonry grid)
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: (product.id.hashCode % 2 == 0) ? 0.82 : 1.12,
                      child: Container(
                        color: Colors.grey.shade50,
                        width: double.infinity,
                        child: product.images.isNotEmpty
                            ? Image.network(
                                product.images.first,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(Iconsax.image, size: 28.sp, color: Colors.grey),
                              )
                            : Icon(Iconsax.image, size: 28.sp, color: Colors.grey),
                      ),
                    ),

                    // Model Tag (STRICT / DIRECT / OUTRIGHT)
                    Positioned(
                      top: 8.h,
                      left: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: !product.allowReservation
                              ? Colors.grey.shade700
                              : (product.modelType.name == 'strict'
                                  ? KorraColors.brandDark
                                  : KorraColors.settleGreen),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          product.allowReservation
                              ? product.modelType.name.toUpperCase()
                              : "OUTRIGHT",
                          style: GoogleFonts.inter(
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Campaign tag overlay on top right
                    if (product.campaignTag != null && product.campaignTag!.isNotEmpty)
                      Positioned(
                        top: 8.h,
                        right: 8.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4ED),
                            borderRadius: BorderRadius.circular(4.r),
                            border: Border.all(color: const Color(0xFFFFD6B2)),
                          ),
                          child: Text(
                            product.campaignTag!.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFA54600),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Details Text
                Padding(
                  padding: EdgeInsets.all(10.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Product Name
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: KorraColors.textDark,
                        ),
                      ),
                      SizedBox(height: 3.h),

                      // Description
                      Text(
                        product.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10.5.sp,
                          color: KorraColors.textMuted,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 8.h),

                      // Price Row (Handles Discount vs Regular Pricing)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: hasDiscount
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            currencyFormat.format(product.discountedPrice),
                                            style: GoogleFonts.inter(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFFA54600),
                                            ),
                                          ),
                                          SizedBox(width: 4.w),
                                          // Discount percentage bubble badge
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFECDCA),
                                              borderRadius: BorderRadius.circular(3.r),
                                            ),
                                            child: Text(
                                              "-${((product.price - product.discountedPrice!) / product.price * 100).round()}%",
                                              style: GoogleFonts.inter(
                                                fontSize: 7.sp,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFFB42318),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 1.h),
                                      Text(
                                        currencyFormat.format(product.price),
                                        style: GoogleFonts.inter(
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade400,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    currencyFormat.format(product.price),
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFA54600),
                                    ),
                                  ),
                          ),
                          
                          // Stock Indicator
                          if (product.availableStock <= 0)
                            Text(
                              "SOLD OUT",
                              style: GoogleFonts.inter(
                                fontSize: 8.5.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.red,
                              ),
                            )
                          else if (product.availableStock < 5)
                            Text(
                              "${product.availableStock} Left",
                              style: GoogleFonts.inter(
                                fontSize: 8.5.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.amber.shade800,
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
