// lib/presentation/vendor/product/widgets/campaigns/campaign_reach_cards.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../config/constants/colors.dart';
import '../../../../../config/constants/sizes.dart';
import '../../../../../data/models/vendor/vendor_visibility.dart';

class CampaignReachCards extends StatelessWidget {
  final VendorVisibility visibility;

  const CampaignReachCards({
    super.key,
    required this.visibility,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Top Seller Reach
        Expanded(
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(KorraSizes.cardRadius.r),
              border: Border.all(color: const Color(0xFFF2F4F7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events_outlined, color: const Color(0xFFFFB000), size: 18.sp),
                    SizedBox(width: 6.w),
                    Text(
                      "Top Seller Reach",
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  "${visibility.topSellerCircles} circles",
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: KorraColors.textDark,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "Ranked per customer circle based on order volume.",
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12.w),
        // Most Visited Reach
        Expanded(
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(KorraSizes.cardRadius.r),
              border: Border.all(color: const Color(0xFFF2F4F7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.remove_red_eye_outlined, color: Colors.blue.shade600, size: 18.sp),
                    SizedBox(width: 6.w),
                    Text(
                      "Most Visited Reach",
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  "${visibility.mostVisitedCircles} circles",
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: KorraColors.textDark,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "Ranked per customer circle based on store opens.",
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
