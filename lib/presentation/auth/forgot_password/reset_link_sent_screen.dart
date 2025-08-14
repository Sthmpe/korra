import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/constants/sizes.dart';

class ResetLinkSentScreen extends StatelessWidget {
  const ResetLinkSentScreen({super.key, required this.email});
  final String email;

  String _mask(String e) {
    final p = e.split('@');
    if (p.length != 2) return e;
    final n = p[0];
    final masked = n.length <= 5 ? '*' * n.length : '${n[0]}***${n[n.length - 1]}';
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
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 28.h),
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
                child: const Text('Open mail app'),
              ),
            ),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Use a different email'),
            ),
            TextButton(
              onPressed: () => Get.offAllNamed('/login'),
              child: const Text('Back to sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
