import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductRestrictionBanner extends StatelessWidget {
  final String status;
  final String title;

  const ProductRestrictionBanner({
    super.key,
    required this.status,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (status == 'restricted' || status == 'suspended' || status == 'banned') {
      return Container(
        margin: EdgeInsets.only(bottom: 20.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3F2), // Soft error background
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lock_outline,
              color: const Color(0xFFD92D20),
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB42318),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
