import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants/colors.dart';

class ProductLimitHeader extends StatelessWidget {
  final double availableLimit;
  final double price;
  final int stock;

  const ProductLimitHeader({
    super.key,
    required this.availableLimit,
    required this.price,
    required this.stock,
  });

  @override
  Widget build(BuildContext context) {
    final totalValue = price * (stock > 0 ? stock : 1); // Estimate value
    final isExceeded = totalValue > availableLimit;
    final progress = (availableLimit > 0)
        ? (totalValue / availableLimit).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isExceeded
            ? const Color(0xFFFEF3F2)
            : KorraColors.brandLight, // Red or Blue bg
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Reservation Limit",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isExceeded
                      ? const Color(0xFFB42318)
                      : KorraColors.brandDark,
                ),
              ),
              Text(
                "₦${NumberFormat('#,##0').format(availableLimit)} Available",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: isExceeded
                      ? const Color(0xFFB42318)
                      : KorraColors.brandDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation(
                isExceeded ? const Color(0xFFD92D20) : KorraColors.brandDark,
              ),
              minHeight: 6.h,
            ),
          ),

          if (isExceeded) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Iconsax.warning_2,
                  size: 14.sp,
                  color: const Color(0xFFB42318),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    "Product value (₦${NumberFormat.compact().format(totalValue)}) exceeds your limit.",
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: const Color(0xFFB42318),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
