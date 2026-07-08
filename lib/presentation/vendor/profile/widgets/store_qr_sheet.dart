// lib/presentation/vendor/profile/widgets/store_qr_sheet.dart
//
// Bottom sheet showing the merchant's store QR. Encodes the storefront link
// (built from the store slug) — customers who scan it land on the storefront.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _brand = Color(0xFFA54600);

class StoreQrSheet extends StatelessWidget {
  final String storeName;
  final String storeLink;

  const StoreQrSheet({super.key, required this.storeName, required this.storeLink});

  static Future<void> show(BuildContext context,
      {required String storeName, required String storeLink}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => StoreQrSheet(storeName: storeName, storeLink: storeLink),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 28.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFEAECF0),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              "My Store QR",
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF101828),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              "Customers scan this to open your storefront.",
              style: GoogleFonts.inter(fontSize: 12.5.sp, color: const Color(0xFF667085)),
            ),
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: QrImageView(
                data: storeLink,
                version: QrVersions.auto,
                size: 200.w,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: _brand),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: Color(0xFF344054),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              storeName,
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF101828),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              storeLink,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11.5.sp, color: const Color(0xFF667085)),
            ),
          ],
        ),
      ),
    );
  }
}
