import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class PlanLiabilityDisclaimer extends StatelessWidget {
  const PlanLiabilityDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 24.h, bottom: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(
              Iconsax.info_circle,
              size: 16.sp,
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(
                    text:
                        "Disclaimer: Korra facilitates and tracks payments, and monitors merchant compliance, but is ",
                  ),
                  TextSpan(
                    text: "not liable ",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const TextSpan(
                    text:
                        "for product quality, authenticity, or delivery. All fulfillment issues are the responsibility of the merchant.",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
