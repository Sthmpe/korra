import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

/// A single-row informative strip. Use when you want minimal footprint.
class VendorHoldStrip extends StatelessWidget {
  final String holdText;     // '₦1,300,000'
  final String nextRelease;  // 'Aug 27'
  final VoidCallback onTap;  // open schedule/details

  const VendorHoldStrip({
    super.key,
    required this.holdText,
    required this.nextRelease,
    required this.onTap,
  });

  static const _brand = Color(0xFFA54600);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F3EF),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFEAE6E2)),
        ),
        child: Row(children: [
          Container(
            width: 34.w, height: 34.w,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.r)),
            child: const Icon(Iconsax.lock_1, color: _brand, size: 18),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              '$holdText on hold • Next $nextRelease',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 13.5.sp, fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(width: 8.w),
          Text('Schedule',
            style: GoogleFonts.inter(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: _brand)),
        ]),
      ),
    );
  }
}
