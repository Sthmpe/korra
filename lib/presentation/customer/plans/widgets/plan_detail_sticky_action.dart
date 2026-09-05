import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../config/constants/colors.dart';
import '../../../../data/models/customer/plans.dart';

class PlanDetailStickyAction extends StatelessWidget {
  final Plan plan;
  final bool isLoading;
  final VoidCallback onResolve;
  final VoidCallback onPay;

  const PlanDetailStickyAction({
    super.key,
    required this.plan,
    required this.isLoading,
    required this.onResolve,
    required this.onPay,
  });

  static const _brand = KorraColors.brand;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 2,
    );

    final bool isOverdue = plan.isOverdue;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Outstanding Balance",
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: const Color(0xFF667085),
                  ),
                ),
                Text(
                  currencyFormat.format(plan.outstandingLoanAmount),
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 160.w,
            height: 52.h,
            child: FilledButton(
              onPressed: isLoading
                  ? null
                  : () {
                      if (isOverdue) {
                        onResolve();
                      } else {
                        onPay();
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: isOverdue ? const Color(0xFFB42318) : _brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      height: 20.h,
                      width: 20.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isOverdue ? "Resolve Plan" : "Make Payment",
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
