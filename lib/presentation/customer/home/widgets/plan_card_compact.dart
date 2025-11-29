import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:korra/config/utils/currency_formatters.dart';

class PlanCardCompact extends StatelessWidget {
  final List<String> imageUrls;
  final String title;
  final String storeName;

  final int progressPercent; 
  final double amountPaid; 
  final double amountRemain; 
  final String cadenceText; 
  final String nextDueText; 
  final double? nextAmount; 

  final double aspectRatio;
  final VoidCallback onPay;
  final VoidCallback onDetails;

  const PlanCardCompact({
    super.key,
    required this.imageUrls,
    required this.title,
    required this.storeName,
    required this.progressPercent,
    required this.amountPaid,
    required this.amountRemain,
    required this.cadenceText,
    required this.nextDueText,
    required this.nextAmount,
    required this.aspectRatio,
    required this.onPay,
    required this.onDetails,
  });

  static const _brand = Color(0xFFA54600);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDetails,
      behavior: HitTestBehavior.opaque,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFEAE6E2).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max, // Fill the available height
          children: [
            // 1. IMAGE SECTION: Changed to EXPANDED
            // This takes "all remaining space" so it never pushes content off screen
            Expanded(
              child: Stack(
                fit: StackFit.expand, // Ensures image fills the Expanded area
                children: [
                  Image.network(
                    imageUrls.isNotEmpty ? imageUrls.first : '',
                    fit: BoxFit.cover,
                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded) return child;
                      return AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        child: child,
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF5F5F5),
                      child: Center(
                        child: Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade400, size: 24.sp),
                      ),
                    ),
                  ),
                  
                  // Vendor Chip
                  Positioned(
                    left: 10.w,
                    top: 10.h,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: const Color(0xFFEAE6E2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded, size: 14, color: _brand),
                          SizedBox(width: 4.w),
                          Text(
                            storeName,
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1B1B1B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Progress Bar
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 4.h,
                      color: const Color(0xFFF0F0F0),
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
            ),

            // 2. CONTENT SECTION: Static Height (Priority)
            // This determines how much space is left for the image
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h), // Reduced top padding slightly
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Hug content
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1B1B),
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 8.h), // Reduced gap slightly

                  // Cadence + Pay Button
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDF8F6),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                cadenceText,
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: _brand,
                                ),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              nextDueText,
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
                      ),
                      
                      SizedBox(width: 8.w),
                      
                      GestureDetector(
                        onTap: onPay,
                        child: SizedBox(
                          height: 36.h,
                          child: FilledButton(
                            onPressed: onPay,
                            style: FilledButton.styleFrom(
                              backgroundColor: _brand,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              elevation: 0,
                            ),
                            child: Text(
                              'Pay',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 10.h), // Reduced gap slightly

                  // Stats Strip
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h), // Tighter padding
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        _Stat(label: 'Paid', value: formatToCurrency(amountPaid as num)),
                        _DividerDot(),
                        _Stat(label: 'Remaining', value: formatToCurrency(amountRemain as num)),
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

// Helpers remain unchanged
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
            style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B1B)),
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
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Container(width: 1.w, height: 24.h, color: Colors.grey.shade300),
    );
  }
}