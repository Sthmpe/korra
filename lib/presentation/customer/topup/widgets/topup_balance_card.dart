import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/utils/currency_formatters.dart';
import '../../../../logic/bloc/customer/topup/top_up_state.dart';

class TopupBalanceCard extends StatelessWidget {
  final TopUpState state;
  const TopupBalanceCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: KorraColors.brand.withOpacity(0.055),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: KorraColors.brand.withOpacity(0.1), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // == BALANCE SECTION ==
          Text(
            'Available balance',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: KorraColors.brand.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '₦${formatToCurrency(state.details.availableBalance)}',
            style: GoogleFonts.inter(
              fontSize: 32.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B1B1B),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}