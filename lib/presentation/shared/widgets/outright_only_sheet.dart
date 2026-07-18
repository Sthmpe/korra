import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/constants/colors.dart';
import '../../../config/constants/sizes.dart';

/// Shown when a shared product code resolves to an outright-only product
/// (allowReservation == false). Those can't start a plan, so instead of a
/// dead end we hand the customer to the merchant's storefront with the
/// product's detail sheet auto-opened. Covers old shared links and products
/// whose merchant disabled reservation after sharing.
class OutrightOnlySheet extends StatelessWidget {
  final String productId;
  final String productName;
  final String storeName;
  final String vendorId;
  final String? imageUrl;

  const OutrightOnlySheet({
    super.key,
    required this.productId,
    required this.productName,
    required this.storeName,
    required this.vendorId,
    this.imageUrl,
  });

  /// True when a fetched product doc can't start a reservation plan.
  static bool isOutrightOnly(Map<String, dynamic> data) =>
      (data['allowReservation'] ?? true) == false;

  /// Builds the sheet straight from a product doc's raw map.
  static Future<void> show(
    BuildContext context, {
    required String productId,
    required Map<String, dynamic> data,
  }) {
    final images = (data['images'] as List?)?.cast<String>() ?? const [];
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OutrightOnlySheet(
        productId: productId,
        productName: (data['name'] ?? 'This product').toString(),
        storeName: (data['storeName'] ?? 'the store').toString(),
        vendorId: (data['vendorId'] ?? '').toString(),
        imageUrl: images.isNotEmpty ? images.first : null,
      ),
    );
  }

  Future<void> _openInStore(BuildContext context) async {
    Navigator.pop(context);
    // Prefer the store's slug; the storefront route also accepts the raw
    // vendor uid, so a missing slug still lands in the right store.
    var slug = vendorId;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .get();
      final storeMap = doc.data()?['store'] as Map<String, dynamic>? ?? {};
      final s = (storeMap['slug'] ?? '').toString().trim();
      if (s.isNotEmpty) slug = s;
    } catch (_) {}
    Get.toNamed('/store/$slug', parameters: {'product': productId});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(KorraSizes.sheetRadius.r)),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF7ED),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Iconsax.shop, size: 20.sp, color: KorraColors.brand),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    "Sold outright only",
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: KorraColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(KorraSizes.logoRadius.r),
                  child: Container(
                    width: 52.w,
                    height: 52.w,
                    color: Colors.grey.shade100,
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Icon(Iconsax.image, size: 22.sp, color: Colors.grey),
                          )
                        : Icon(Iconsax.image, size: 22.sp, color: Colors.grey),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: KorraColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              "This product doesn't support reserve plans, so it can't be added with a code. You can buy it directly in $storeName's store.",
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: KorraColors.textMid,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () => _openInStore(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: KorraColors.brand,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: Size(double.infinity, KorraSizes.buttonHeight.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KorraSizes.pillRadius.r),
                ),
              ),
              icon: const Icon(Iconsax.shop, size: 18),
              label: Text(
                "Buy it in $storeName's store",
                style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Not now",
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: KorraColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
