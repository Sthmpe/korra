import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class LivenessBlockerSheet extends StatelessWidget {
  const LivenessBlockerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 34.h),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- HANDLE BAR ---
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
            SizedBox(height: 32.h),

            // --- ICON WITH SOFT BACKGROUND ---
            Container(
              width: 64.w,
              height: 64.w,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2), // Soft Red Background
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Iconsax.user_search, // Liveness/Identity Icon
                size: 32.sp,
                color: const Color(0xFFDC2626), // Deep Red
              ),
            ),
            SizedBox(height: 24.h),

            // --- TITLE ---
            Text(
              "Liveness Check Required",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111111), // Almost Black
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 12.h),

            // --- MESSAGE ---
            Text(
              "We need to verify your identity before you can withdraw funds. This is a security measure to protect your account.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                height: 1.5,
                color: const Color(0xFF666666), // Modern Grey
              ),
            ),
            SizedBox(height: 24.h),

            // --- CONTACT SUPPORT BOX ---
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB), // Very light grey
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFEAECF0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // Hug content
                children: [
                  Icon(Iconsax.sms, size: 18.sp, color: Colors.grey.shade600),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      "Contact support@korra.com.ng to continue",
                      style: GoogleFonts.inter(
                        fontSize: 13.sp, 
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 32.h),

            // --- CLOSE BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111111), // Black brand
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  "Close",
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
