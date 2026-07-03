// lib/presentation/customer/storefront/widgets/storefront_product_details_sheet.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants/colors.dart';
import '../../../../data/models/product_model.dart';

class StorefrontProductDetailsSheet extends StatefulWidget {
  final Product product;
  final DocumentSnapshot? rawDoc;
  final ScrollController scrollController;
  final Function(Product, int) onAddToCart;
  final Function(DocumentSnapshot?) onPayInstallments;

  const StorefrontProductDetailsSheet({
    super.key,
    required this.product,
    this.rawDoc,
    required this.scrollController,
    required this.onAddToCart,
    required this.onPayInstallments,
  });

  @override
  State<StorefrontProductDetailsSheet> createState() => _StorefrontProductDetailsSheetState();
}

class _StorefrontProductDetailsSheetState extends State<StorefrontProductDetailsSheet> {
  int _selectedQuantity = 1;
  int _carouselIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Swipable Image Carousel
          Container(
            height: 240.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: KorraColors.borderLight),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: widget.product.images.isEmpty
                  ? Icon(Iconsax.image, size: 40.sp, color: Colors.grey)
                  : Stack(
                      children: [
                        PageView.builder(
                          itemCount: widget.product.images.length,
                          onPageChanged: (index) {
                            setState(() {
                              _carouselIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              widget.product.images[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(Iconsax.image, size: 40.sp, color: Colors.grey),
                            );
                          },
                        ),
                        if (widget.product.images.length > 1)
                          Positioned(
                            bottom: 12.h,
                            right: 12.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                "${_carouselIndex + 1} / ${widget.product.images.length}",
                                style: GoogleFonts.inter(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          SizedBox(height: 16.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.product.name,
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: KorraColors.textDark,
                  ),
                ),
              ),
              if (widget.product.discountedPrice != null && widget.product.discountedPrice! > 0) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text(
                          currencyFormat.format(widget.product.discountedPrice),
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFA54600),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFECDCA),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            "-${((widget.product.price - widget.product.discountedPrice!) / widget.product.price * 100).round()}%",
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFB42318),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      currencyFormat.format(widget.product.price),
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade400,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                )
              ] else ...[
                Text(
                  currencyFormat.format(widget.product.price),
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFA54600),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8.h),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4ED),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              widget.product.category.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFA54600),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: widget.product.allowReservation ? const Color(0xFFECFDF3) : const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  widget.product.allowReservation ? Iconsax.shield_tick : Iconsax.info_circle,
                  color: widget.product.allowReservation ? KorraColors.settleGreen : Colors.grey.shade600,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    widget.product.allowReservation
                        ? "Installment Plan Available (Reserve this item now)"
                        : "Outright Purchase Only (Installment plans disabled for this item)",
                    style: GoogleFonts.inter(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: widget.product.allowReservation ? const Color(0xFF027A48) : Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          Text(
            "Description",
            style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w800, color: KorraColors.textDark),
          ),
          SizedBox(height: 6.h),
          Text(
            widget.product.description.isNotEmpty ? widget.product.description : "No description provided for this item.",
            style: GoogleFonts.inter(fontSize: 13.sp, color: KorraColors.textBody, height: 1.4),
          ),
          SizedBox(height: 24.h),

          Row(
            children: [
              Icon(Iconsax.box, size: 16.sp, color: KorraColors.textHint),
              SizedBox(width: 6.w),
              Text(
                widget.product.availableStock > 0 ? "${widget.product.availableStock} items in stock" : "Out of stock",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: widget.product.availableStock > 0 ? KorraColors.textMuted : Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // Quantity Selector Row
          if (widget.product.availableStock > 0) ...[
            Row(
              children: [
                Text(
                  "Select Quantity",
                  style: GoogleFonts.inter(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: KorraColors.textDark,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    if (_selectedQuantity > 1) {
                      setState(() {
                        _selectedQuantity--;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(5.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(color: const Color(0xFFEAECF0)),
                    ),
                    child: Icon(Icons.remove, size: 16.sp, color: Colors.grey.shade700),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    _selectedQuantity.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: KorraColors.textDark,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_selectedQuantity < widget.product.availableStock) {
                      setState(() {
                        _selectedQuantity++;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(5.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(color: const Color(0xFFEAECF0)),
                    ),
                    child: Icon(Icons.add, size: 16.sp, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),
          ],

          // Bottom actions: Add to Cart & Pay Installments
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48.h,
                  child: OutlinedButton(
                    onPressed: widget.product.availableStock > 0
                        ? () => widget.onAddToCart(widget.product, _selectedQuantity)
                        : null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFA54600)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      "Add to Cart",
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFA54600),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.product.allowReservation) ...[
                SizedBox(width: 12.w),
                Expanded(
                  child: SizedBox(
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: widget.product.availableStock > 0
                          ? () => widget.onPayInstallments(widget.rawDoc)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA54600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      child: Text(
                        "Pay Installments",
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
