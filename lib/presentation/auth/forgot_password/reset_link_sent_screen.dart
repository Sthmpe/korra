import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:korra/presentation/auth/role_login/role_login_screen.dart';

import '../../../config/constants/sizes.dart';

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
            const Icon(Iconsax.message_favorite, size: 88),
            SizedBox(height: 24.h),
            Text(
              'Check your email',
              style: GoogleFonts.inter(
                fontSize: 32.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'We sent a password reset link to ${_mask(email)}.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 60.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {}, // later: open mail app
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
                  ),
                ),
                child: Text(
                  'Open mail app',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'Use a different email',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Get.offAll(() => RoleLoginScreen()),
              child: Text(
                'Back to sign in',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
