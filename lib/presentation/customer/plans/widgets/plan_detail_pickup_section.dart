import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../data/models/customer/plans.dart';

class PlanDetailPickupSection extends StatelessWidget {
  final Plan plan;

  const PlanDetailPickupSection({
    super.key,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF3), // Soft Success Green
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: const Color(0xFF027A48), size: 24.sp),
              SizedBox(width: 12.w),
              Text(
                "Payment Complete!",
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF027A48),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            "You have fully paid for this item. Please contact ${plan.storeName} directly to arrange for collection or delivery.",
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0xFF027A48).withOpacity(0.9),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
