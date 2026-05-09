import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/constants/sizes.dart';
import '../../../../config/theme/gaps.dart';

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
              padding: EdgeInsets.all(KorraSizes.s2.r),
              decoration: BoxDecoration(
                color: KorraColors.brand,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: KorraColors.brand.withValues(alpha: 0.3),
                    blurRadius: 4.r,
                    offset: const Offset(0, 5),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.r),
                child: Image.asset(
                  'assets/images/korra_logo_icon.webp',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            Gaps.h20,

            // --- BRAND NAME ---
            Text(
              'Korra',
              style: GoogleFonts.inter(
                fontSize: KorraSizes.font4xlPlus.sp,
                fontWeight: KorraSizes.weightExtraBold,
                color: KorraColors.nearBlack,
                letterSpacing: KorraSizes.trackingTighter,
              ),
            ),

            Gaps.h8,

            // --- SUBTITLE ---
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 35.w),
              child: Text(
                'Smart People Own Things Differently.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: KorraSizes.fontMdHalf.sp,
                  color: KorraColors.labelGrey,
                  height: KorraSizes.lineHeightMd,
                  fontWeight: KorraSizes.weightMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
