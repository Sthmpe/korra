import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
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
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: KorraColors.brand,
                borderRadius: BorderRadius.circular(20.r), // Softer, modern radius
                boxShadow: [
                  BoxShadow(
                    color: KorraColors.brand.withOpacity(0.3), // The "Glow"
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Icon(
                MdiIcons.crown,
                color: Colors.white,
                size: 36.sp,
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
                'Reserve now — pay in parts, own with ease.',
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