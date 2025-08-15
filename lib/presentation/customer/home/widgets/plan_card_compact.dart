// lib/presentation/customer/home/widgets/plan_card_compact.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class PlanCardCompact extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String vendor;

  // summary
  final int progressPercent;
  final String amountPaidText;     // “₦75,500”
  final String amountRemainText;   // “₦224,500”
  final String cadenceText;        // “Daily plan / Weekly plan / Monthly plan”
  final String nextDueText;        // “Due Fri”
  final String nextAmountText;     // “₦12,500”

  final double aspectRatio;        // 4/3
  final VoidCallback onPay;
  final VoidCallback onDetails;

  const PlanCardCompact({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.vendor,
    required this.progressPercent,
    required this.amountPaidText,
    required this.amountRemainText,
    required this.cadenceText,
    required this.nextDueText,
    required this.nextAmountText,
    required this.aspectRatio,
    required this.onPay,
    required this.onDetails,
  });

  static const _brand = Color(0xFFA54600);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEAE6E2)),
      ),
      clipBehavior: Clip.antiAlias, // to make image truly edge-to-edge
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE — edge-to-edge (no inner padding)
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: aspectRatio,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFFEAE6E2)),
                  ),
                ),
                // vendor chip
                Positioned(
                  left: 10.w,
                  top: 10.h,
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
                      Text(vendor,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1B1B1B),
                          )),
                    ]),
                  ),
                ),
                // progress ring
                Positioned(
                  right: 10.w,
                  bottom: 10.h,
                  child: SizedBox(
                    height: 48.h, width: 48.h,
                    child: Stack(alignment: Alignment.center, children: [
                      CircularProgressIndicator(
                        value: progressPercent / 100,
                        strokeWidth: 4.w,
                        color: _brand,
                        backgroundColor: const Color(0xFFEDE8E4),
                      ),
                      Text('$progressPercent%',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          )),
                    ]),
                  ),
                ),
              ],
            ),
        
            // CONTENT
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // title
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B1B1B),
                    ),
                  ),
                  SizedBox(height: 8.h),
        
                  // row 1: Paid • Remaining
                  Row(
                    children: [
                      Text('Paid ',
                          style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF5E5E5E))),
                      Text(amountPaidText,
                          style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700)),
                      Text('  •  Remaining ',
                          style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF5E5E5E))),
                      Expanded(
                        child: Text(
                          amountRemainText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
        
                  // row 2: cadence chip + next due
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F1ED),
                          borderRadius: BorderRadius.circular(999.r),
                          border: Border.all(color: const Color(0xFFEAE6E2)),
                        ),
                        child: Text(
                          cadenceText,
                          style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: _brand),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          '$nextDueText • $nextAmountText',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF5E5E5E), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
        
                  SizedBox(height: 10.h),
        
                  // CTA row
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 40.h,
                      child: FilledButton(
                        onPressed: onPay,
                        style: FilledButton.styleFrom(
                          backgroundColor: _brand,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                          padding: EdgeInsets.symmetric(horizontal: 18.w),
                        ),
                        child: Text(
                          'Pay',
                          style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
