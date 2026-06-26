import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/constants/buttons.dart';
import '../../../config/constants/icons.dart';
import '../../../config/constants/sizes.dart';
import '../../../config/theme/gaps.dart';
import '../../../config/routes/app_routes.dart';

class ResetLinkSentScreen extends StatelessWidget {
  const ResetLinkSentScreen({super.key, required this.email});
  final String email;

  String _mask(String e) {
    final p = e.split('@');
    if (p.length != 2) return e;
    final n = p[0];
    final masked = n.length <= 5 ? '*' * n.length : '${n.substring(0, 3)}***${n[n.length - 1]}';
    return '$masked@${p[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: KorraSizes.gutter.w),
        child: Column(
          children: [
            SizedBox(height: 80.h),
            Icon(KorraIcons.messageFavorite, size: 88),
            Gaps.h24,
            Text(
              'Check your email',
              style: GoogleFonts.inter(
                fontSize: KorraSizes.font5xl.sp,
                fontWeight: KorraSizes.weightBold,
              ),
            ),
            Gaps.h20,
            Text(
              'We sent a password reset link to ${_mask(email)}.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: KorraSizes.fontXl.sp,
                fontWeight: KorraSizes.weightMedium,
              ),
            ),
            SizedBox(height: 60.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: KorraSizes.s14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
                  ),
                ),
                child: Text(
                  'Open mail app',
                  style: GoogleFonts.inter(
                    fontSize: KorraSizes.fontLg.sp,
                    fontWeight: KorraSizes.weightBold,
                  ),
                ),
              ),
            ),
            Gaps.h20,
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'Use a different email',
                style: GoogleFonts.inter(
                  fontSize: KorraSizes.fontLg.sp,
                  fontWeight: KorraSizes.weightBold,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Get.offAllNamed(Routes.roleLoginScreen),
              child: Text(
                'Back to sign in',
                style: GoogleFonts.inter(
                  fontSize: KorraSizes.fontLg.sp,
                  fontWeight: KorraSizes.weightBold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
