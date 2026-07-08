import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

/// Full-screen lock shown over a suspended/restricted storefront.
/// The store behind it stays visible (first screen only) but frozen —
/// this overlay absorbs every touch except its own "Go back" button.
class StorefrontSuspendedOverlay extends StatelessWidget {
  final String storeName;

  /// Admin-facing public message from vendor_compliance; falls back to a
  /// generic explanation when the doc has none.
  final String? message;

  const StorefrontSuspendedOverlay({
    super.key,
    required this.storeName,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final reason = (message == null || message!.trim().isEmpty)
        ? "This store has been suspended or restricted due to a policy or compliance issue on Korra."
        : message!.trim();

    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          color: Colors.black.withValues(alpha: 0.45),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Container(
            padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 24.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64.w,
                  height: 64.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3F2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Iconsax.shield_cross,
                      size: 30.sp, color: const Color(0xFFD92D20)),
                ),
                SizedBox(height: 18.h),
                Text(
                  "Store temporarily unavailable",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    height: 1.5,
                    color: const Color(0xFF475467),
                  ),
                ),
                SizedBox(height: 14.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Text(
                    "Browsing, reservations and payments to $storeName are paused. If you think this is an error, please contact the merchant directly.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11.5.sp,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF667085),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF101828),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      "Go back",
                      style: GoogleFonts.inter(
                        fontSize: 13.5.sp,
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
      ),
    );
  }
}
