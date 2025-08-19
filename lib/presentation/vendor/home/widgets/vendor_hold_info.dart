import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class VendorHoldInfo extends StatelessWidget {
  final String holdText;     // e.g., '₦1,300,000'
  final String nextRelease;  // e.g., 'Aug 27'
  final VoidCallback onViewSchedule;

  const VendorHoldInfo({
    super.key,
    required this.holdText,
    required this.nextRelease,
    required this.onViewSchedule,
  });

  static const _brand = Color(0xFFA54600);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F3EF),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFEAE6E2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.r)),
              child: const Icon(Iconsax.lock_1, color: _brand, size: 18),
            ),
            SizedBox(width: 10.w),
            Expanded(child: Text(
              'Settlement hold • releases after 10 days',
              style: GoogleFonts.inter(fontSize: 13.5.sp, fontWeight: FontWeight.w700),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
            InkWell(
              borderRadius: BorderRadius.circular(10.r),
              onTap: onViewSchedule,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                child: Text('View schedule',
                  style: GoogleFonts.inter(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: _brand)),
              ),
            ),
          ]),
          SizedBox(height: 6.h),
          Text(
            '$holdText on hold • Next release $nextRelease',
            style: GoogleFonts.inter(fontSize: 12.5.sp, color: const Color(0xFF5E5E5E)),
          ),
        ]),
      ),
    );
  }
}
