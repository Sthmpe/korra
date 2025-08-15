import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class PlanCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String vendor;
  final int progressPercent;
  final String nextDue;
  final double aspectRatio;
  final VoidCallback onPay;
  final VoidCallback onDetails;

  const PlanCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.vendor,
    required this.progressPercent,
    required this.nextDue,
    required this.aspectRatio,
    required this.onPay,
    required this.onDetails,
  });

  static const _brand = Color(0xFFA54600);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEAE6E2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: AspectRatio(
              aspectRatio: aspectRatio, // width / height
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEAE6E2)),
              ),
            ),
          ),
          Positioned(
            left: 8.w,
            top: 8.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.94),
                borderRadius: BorderRadius.circular(999.r),
                border: Border.all(color: const Color(0xFFEAE6E2)),
              ),
              child: Row(children: [
                const Icon(Icons.verified_outlined, size: 14, color: _brand),
                SizedBox(width: 4.w),
                Text(vendor, style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
          Positioned(
            right: 8.w,
            bottom: 8.h,
            child: SizedBox(
              height: 48.h, width: 48.h,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: progressPercent / 100,
                  strokeWidth: 4.w,
                  color: _brand,
                  backgroundColor: const Color(0xFFEDE8E4),
                ),
                Text('$progressPercent%', style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ]),
        SizedBox(height: 10.h),
        Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w800)),
        SizedBox(height: 8.h),
        Row(children: [
          Icon(Icons.calendar_today_outlined, size: 16.sp, color: const Color(0xFF5E5E5E)),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(nextDue, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF5E5E5E))),
          ),
          SizedBox(width: 8.w),
          SizedBox(
            height: 40.h,
            child: FilledButton(
              onPressed: onPay,
              style: FilledButton.styleFrom(
                backgroundColor: _brand,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              ),
              child: Text('Pay', style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ]),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onDetails,
            child: Text('Details',
                style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, color: const Color(0xFFA54600))),
          ),
        ),
      ]),
    );
  }
}
