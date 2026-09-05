import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../data/models/product_model.dart';
import '../../../../data/models/customer/customer_model.dart';
import '../../../../data/models/customer/plans.dart';
import '../../../../data/repository/customer/customer_repository.dart';
import '../../../../config/constants/colors.dart';
import '../../../../config/constants/sizes.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../shared/widgets/outright_only_sheet.dart';

class ClipboardScannerHelper {
  static final RegExp _productRegex = RegExp(r'^K-[A-Z0-9]{4}-[A-Z0-9]{7}$', caseSensitive: false);

  static Future<void> checkClipboardAndPrompt(
    BuildContext context, 
    CustomerRepository repo, 
    String customerUid,
  ) async {
    // 1. Skip on Web to avoid browser permission dialog spam
    if (kIsWeb) return;

    // 🚀 DELAY SAFEGUARD: Let the app layout settle and gain focus before accessing clipboard
    await Future.delayed(const Duration(seconds: 2));

    try {
      // 2. Read clipboard text with a strict 2s timeout to prevent platform hangs
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain).timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TimeoutException("Clipboard read timed out"),
      );
      final String? rawText = clipboardData?.text;
      if (rawText == null || rawText.trim().isEmpty) return;

      final String cleanText = rawText.trim();

      // 3. Match regex pattern
      if (!_productRegex.hasMatch(cleanText)) return;

      final String upperCode = cleanText.toUpperCase();

      // 4. Check if already scanned to prevent double prompts
      final prefs = await SharedPreferences.getInstance();
      final String? lastScanned = prefs.getString('last_scanned_product_code');
      if (lastScanned == upperCode) return;

      // 5. Save the code immediately so we don't repeat the prompt on subsequent app resumes
      await prefs.setString('last_scanned_product_code', upperCode);

      // 6. Fetch the product details to confirm it exists and show rich info
      final productResult = await repo.getProduct(upperCode);
      if (productResult == null) return;

      // Outright-only products can't start a plan — hand off to the
      // merchant's storefront instead of the plan-creation prompt.
      if (OutrightOnlySheet.isOutrightOnly(productResult.data)) {
        if (!context.mounted) return;
        OutrightOnlySheet.show(context,
            productId: productResult.id, data: productResult.data);
        return;
      }

      final product = Product.fromMap(productResult.data, productResult.id);

      // 7. Fetch the customer details to populate creation route arguments
      final customerSnap = await repo.firestore.collection("customers").doc(customerUid).get();
      if (!customerSnap.exists) return;
      final customer = Customer.fromMap(customerSnap.data()!);
      final double walletBalance = customer.availableBalance;

      // 8. Show the custom bottom sheet
      if (!context.mounted) return;
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => ClipboardPromptSheet(
          product: product,
          productResult: productResult,
          customer: customer,
          customerUid: customerUid,
          walletBalance: walletBalance,
        ),
      );
    } catch (e) {
      debugPrint("⚠️ Clipboard scanning failed: $e");
    }
  }
}

class ClipboardPromptSheet extends StatelessWidget {
  final Product product;
  final ProductFetchResult productResult;
  final Customer customer;
  final String customerUid;
  final double walletBalance;

  const ClipboardPromptSheet({
    required this.product,
    required this.productResult,
    required this.customer,
    required this.customerUid,
    required this.walletBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(KorraSizes.sheetRadius.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 2,
          )
        ],
      ),
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
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

            // Header Row (Clipboard Icon + Title)
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: KorraColors.brandLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.document_copy,
                    size: 20.sp,
                    color: KorraColors.brand,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    "Product Code Detected",
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: KorraColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Product Preview Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: KorraColors.surface,
                borderRadius: BorderRadius.circular(KorraSizes.cardRadius.r),
                border: Border.all(
                  width: 0.5.w,
                  color: KorraColors.borderLight
                ),
              ),
              child: Row(
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(KorraSizes.logoRadius.r),
                    child: Container(
                      width: 60.w,
                      height: 60.w,
                      color: Colors.grey.shade100,
                      child: product.images.isNotEmpty
                          ? Image.network(
                              product.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Iconsax.image,
                                size: 24.sp,
                                color: Colors.grey,
                              ),
                            )
                          : Icon(
                              Iconsax.image,
                              size: 24.sp,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                  SizedBox(width: 16.w),

                  // Product Text Details
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
                            fontWeight: FontWeight.w700,
                            color: KorraColors.textDark,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "${product.storeName}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: KorraColors.textMid,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          "₦${product.price.toStringAsFixed(2)}",
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: KorraColors.brand,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 28.h),

            // Action Buttons
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close sheet
                // Route to plan creation screen
                Get.toNamed(
                  Routes.customerCreatePlan,
                  arguments: {
                    'product': productResult,
                    'customer': customer,
                    'customerUid': customerUid,
                    'walletBalance': walletBalance,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: KorraColors.brand,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: Size(double.infinity, KorraSizes.buttonHeight.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KorraSizes.pillRadius.r),
                ),
              ),
              child: Text(
                "View Product",
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                minimumSize: Size(double.infinity, KorraSizes.buttonHeightSm.h),
              ),
              child: Text(
                "Dismiss",
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
