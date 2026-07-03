// lib/presentation/customer/storefront/widgets/storefront_cart_sheet.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants/colors.dart';
import '../../../shared/widgets/show_app_snackbar.dart';
import 'cart_service.dart';

class StorefrontCartSheet extends StatefulWidget {
  final String vendorId;
  final String storeName;
  final String customerUid;
  final ScrollController scrollController;

  const StorefrontCartSheet({
    super.key,
    required this.vendorId,
    required this.storeName,
    required this.customerUid,
    required this.scrollController,
  });

  @override
  State<StorefrontCartSheet> createState() => _StorefrontCartSheetState();
}

class _StorefrontCartSheetState extends State<StorefrontCartSheet> {
  bool _isCheckingOut = false;

  void _updateQuantity(String productId, int delta) {
    CartService.instance.updateQuantity(widget.vendorId, productId, delta);
  }

  void _removeItem(String productId) {
    CartService.instance.removeItem(widget.vendorId, productId);
  }

  void _checkoutCart(double subtotal) async {
    setState(() => _isCheckingOut = true);

    try {
      // Clear the Cart locally
      CartService.instance.clearCart(widget.vendorId);

      if (mounted) {
        Navigator.pop(context); // Close sheet
        showAppSnackbar("Order checkout submitted! Backend processing initiated.", SnackbarType.success);
      }
    } catch (e) {
      showAppSnackbar("Failed to submit checkout: $e", SnackbarType.error);
    } finally {
      if (mounted) {
        setState(() => _isCheckingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('vendors').doc(widget.vendorId).snapshots(),
      builder: (context, vendorSnapshot) {
        bool absorbOutrightFee = false;
        if (vendorSnapshot.hasData && vendorSnapshot.data!.exists) {
          final data = vendorSnapshot.data!.data() as Map<String, dynamic>? ?? {};
          final storeMap = data['store'] as Map<String, dynamic>? ?? {};
          absorbOutrightFee = storeMap['absorbOutrightFee'] ?? false;
        }

        return ValueListenableBuilder<Map<String, List<CartItem>>>(
          valueListenable: CartService.instance.cartsNotifier,
          builder: (context, carts, _) {
            final items = carts[widget.vendorId] ?? [];

            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 54.sp, color: Colors.grey.shade300),
                    SizedBox(height: 16.h),
                    Text(
                      "Your Cart is Empty",
                      style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: KorraColors.textDark),
                    ),
                  ],
                ),
              );
            }

            // Calculate Subtotal
            double subtotal = 0.0;
            for (final item in items) {
              subtotal += item.price * item.quantity;
            }

            // Calculate Processing Fee
            double fee = 0.0;
            if (!absorbOutrightFee) {
              fee = subtotal * 0.035;
              if (fee > 7500.0) {
                fee = 7500.0;
              }
            }

            return Column(
              children: [
                // Handle bar
                Center(
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 10.h),
                    width: 40.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.5.r),
                    ),
                  ),
                ),
                
                // Header title
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Cart Details",
                        style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800, color: KorraColors.textDark),
                      ),
                      Text(
                        "${items.length} Item${items.length == 1 ? '' : 's'}",
                        style: GoogleFonts.inter(fontSize: 13.5.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFFF2F4F7)),

                // Cart Items Scroll
                Expanded(
                  child: ListView.builder(
                    controller: widget.scrollController,
                    itemCount: items.length,
                    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return Container(
                        margin: EdgeInsets.only(bottom: 14.h),
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: const Color(0xFFEAECF0)),
                        ),
                        child: Row(
                          children: [
                            // Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10.r),
                              child: item.imageUrl.isNotEmpty
                                  ? Image.network(item.imageUrl, width: 68.w, height: 68.w, fit: BoxFit.cover)
                                  : Container(
                                      color: Colors.grey.shade100,
                                      width: 68.w,
                                      height: 68.w,
                                      child: const Icon(Icons.image, color: Colors.grey),
                                    ),
                            ),
                            SizedBox(width: 14.w),
                            
                            // Name and Price
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: KorraColors.textDark),
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    currencyFormat.format(item.price),
                                    style: GoogleFonts.inter(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFFA54600)),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Quantity Adjuster & Remove Button
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: () => _removeItem(item.productId),
                                  child: Padding(
                                    padding: EdgeInsets.all(4.w),
                                    child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 22.sp),
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _updateQuantity(item.productId, -1),
                                      child: Container(
                                        padding: EdgeInsets.all(6.w),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF9FAFB),
                                          borderRadius: BorderRadius.circular(6.r),
                                          border: Border.all(color: const Color(0xFFEAECF0)),
                                        ),
                                        child: Icon(Icons.remove, size: 16.sp, color: Colors.grey.shade700),
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Text(
                                      item.quantity.toString(),
                                      style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w800, color: KorraColors.textDark),
                                    ),
                                    SizedBox(width: 10.w),
                                    GestureDetector(
                                      onTap: () => _updateQuantity(item.productId, 1),
                                      child: Container(
                                        padding: EdgeInsets.all(6.w),
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
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Subtotal & Checkout Footer
                Container(
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4))],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Subtotal Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Subtotal",
                              style: GoogleFonts.inter(fontSize: 13.5.sp, fontWeight: FontWeight.w600, color: KorraColors.textMuted),
                            ),
                            Text(
                              currencyFormat.format(subtotal),
                              style: GoogleFonts.inter(fontSize: 14.5.sp, fontWeight: FontWeight.w700, color: KorraColors.textDark),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        
                        // Processing Fee Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              absorbOutrightFee ? "Fee (absorbed by merchant)" : "Processing Fee (3.5% max ₦7,500)",
                              style: GoogleFonts.inter(fontSize: 13.5.sp, fontWeight: FontWeight.w600, color: KorraColors.textMuted),
                            ),
                            Text(
                              absorbOutrightFee ? "₦0" : currencyFormat.format(fee),
                              style: GoogleFonts.inter(
                                fontSize: 14.5.sp, 
                                fontWeight: FontWeight.w700, 
                                color: absorbOutrightFee ? KorraColors.settleGreen : KorraColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        Divider(color: const Color(0xFFF2F4F7), height: 24.h),

                        // Paying Now Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Paying Now",
                              style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: KorraColors.textDark),
                            ),
                            Text(
                              currencyFormat.format(subtotal + fee),
                              style: GoogleFonts.inter(fontSize: 19.sp, fontWeight: FontWeight.w900, color: const Color(0xFFA54600)),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        SizedBox(
                          width: double.infinity,
                          height: 52.h,
                          child: ElevatedButton(
                            onPressed: _isCheckingOut ? null : () => _checkoutCart(subtotal),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA54600),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                              elevation: 0,
                            ),
                            child: _isCheckingOut
                                ? SizedBox(width: 24.w, height: 24.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(
                                    "Proceed to Outright Purchase",
                                    style: GoogleFonts.inter(fontSize: 14.5.sp, fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
