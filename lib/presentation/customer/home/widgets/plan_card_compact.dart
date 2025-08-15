// lib/presentation/customer/home/widgets/plan_card_compact.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class PlanCardCompact extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String vendor;

  final int progressPercent; // 0..100
  final String amountPaidText; // e.g. "₦75,500"
  final String amountRemainText; // e.g. "₦224,500"
  final String cadenceText; // e.g. "Weekly plan"
  final String nextDueText; // e.g. "Due Tue"
  final String nextAmountText; // e.g. "₦12,500"

  final double aspectRatio; // 4/3
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEAE6E2).withOpacity(0.3)),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE — edge to edge + vendor chip + thin progress bar
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
                Positioned(
                  left: 10.w,
                  top: 10.h,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.94),
                      borderRadius: BorderRadius.circular(999.r),
                      border: Border.all(color: const Color(0xFFEAE6E2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          size: 14,
                          color: _brand,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          vendor,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1B1B1B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Thin progress bar on the image
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 6.h,
                    color: const Color(0xFFEDE8E4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: (progressPercent.clamp(0, 100)) / 100.0,
                        child: Container(color: _brand),
                      ),
                    ),
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
                  // Title
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

                  // Cadence chip + next due / amount
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F1ED),
                              borderRadius: BorderRadius.circular(999.r),
                              border: Border.all(
                                color: const Color(0xFFEAE6E2),
                              ),
                            ),
                            child: Text(
                              cadenceText,
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: _brand,
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '$nextDueText • $nextAmountText',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF5E5E5E),
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      SizedBox(
                        height: 40.h,
                        child: FilledButton(
                          onPressed: onPay,
                          style: FilledButton.styleFrom(
                            backgroundColor: _brand,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 18.w),
                          ),
                          child: Text(
                            'Pay',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),

                  // Stats strip: Paid | Remaining (compact “receipt” look)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF7F4),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFEAE6E2)),
                    ),
                    child: Row(
                      children: [
                        _Stat(label: 'Paid', value: amountPaidText),
                        _DividerDot(),
                        _Stat(label: 'Remaining', value: amountRemainText),
                      ],
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

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7A7A7A),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B1B1B),
            ),
          ),
        ],
      ),
    );
  }
}

class _DividerDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Container(
        width: 4.w,
        height: 4.w,
        decoration: const BoxDecoration(
          color: Color(0xFFD4CBC5),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
