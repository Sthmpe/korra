import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/constants/colors.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- LOGO WITH GLOW ---
            Container(
              height: 100.h,
              width: 100.h,
              padding: EdgeInsets.all(2.r), // Optional padding
              decoration: BoxDecoration(
                color: KorraColors.brand,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: KorraColors.brand.withOpacity(0.3),
                    blurRadius: 4.r,
                    offset: const Offset(0, 5),
                    spreadRadius: -4,
                  ),
                ],
              ),
              // 👇 WRAP IMAGE IN ClipRRect
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.r), // Slightly less than container (20 - padding)
                child: Image.asset(
                  'assets/images/korra_logo_icon.webp',
                  fit: BoxFit.cover, // Ensures it fills the clipped area without distortion
                ),
              ),
            ),
            
            SizedBox(height: 20.h),
            
            // --- BRAND NAME ---
            Text(
              'Korra',
              style: GoogleFonts.inter(
                fontSize: 30.sp,
                fontWeight: FontWeight.w800, // Extra Bold for impact
                color: const Color(0xFF111111), // Almost black
                letterSpacing: -1.0, // Tight tracking looks more professional
              ),
            ),
            
            SizedBox(height: 8.h),
            
            // --- SUBTITLE ---
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 35.w), // Prevent edge touching on small screens
              child: Text(
                'Smart People Own Things Differently.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.5.sp,
                  color: const Color(0xFF666666), // Premium Grey
                  height: 1.4, // Relaxed line height
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}