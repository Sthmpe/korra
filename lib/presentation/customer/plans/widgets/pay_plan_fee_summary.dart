import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants/colors.dart';

class PayPlanFeeSummary extends StatelessWidget {
  final double storePortion;
  final double storeFeeAmt;
  final double cashPortion;
  final double cashFeeAmt;
  final double applied;
  final double walletDeducted;

  const PayPlanFeeSummary({
    super.key,
    required this.storePortion,
    required this.storeFeeAmt,
    required this.cashPortion,
    required this.cashFeeAmt,
    required this.applied,
    required this.walletDeducted,
  });

  static final _moneyFormat = NumberFormat('#,##0.00');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFEAECF0), width: 0.5.w),
      ),
      child: Column(
        children: [
          // Store balance row
          if (storePortion > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Store balance used",
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  "₦${_moneyFormat.format(storePortion)}",
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF027A48),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Store balance fee (0.35%)",
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.grey.shade400,
                  ),
                ),
                Text(
                  "₦${_moneyFormat.format(storeFeeAmt)} from wallet",
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
          ],
          // Cash fee row
          if (cashPortion > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Processing fee (3.5%)",
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  "- ₦${_moneyFormat.format(cashFeeAmt)}",
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
          ],
          Divider(height: 1, color: Colors.grey.shade200),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Applied to your plan",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF101828),
                ),
              ),
              Text(
                "₦${_moneyFormat.format(applied)}",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: KorraColors.brand,
                ),
              ),
            ],
          ),
          if (storePortion > 0) ...[
            SizedBox(height: 4.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Wallet deducted",
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.grey.shade400,
                  ),
                ),
                Text(
                  "₦${_moneyFormat.format(walletDeducted)}",
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.grey.shade500,
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
