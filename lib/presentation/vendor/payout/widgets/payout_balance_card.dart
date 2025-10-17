// lib/presentation/vendor/payout/widgets/payout_balance_card.dart

import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants/colors.dart';
import '../../../../data/models/vendor/payout/payout_history.dart';
import '../../../../logic/bloc/vendor/payout/payout_state.dart';
import '../../../../config/utils/currency_formatters.dart';

class PayoutBalanceCard extends StatelessWidget {
  final PayoutState state;
  const PayoutBalanceCard({super.key, required this.state});

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
            'Withdrawable balance',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: KorraColors.brand.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '₦${formatToCurrency(state.payoutDetails.withdrawableBalance)}',
            style: GoogleFonts.inter(
              fontSize: 32.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B1B1B),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          // SizedBox(height: 20.h),
          
          // == DIVIDER ==
          // A subtle divider creates a clear, intentional separation.
          // Divider(color: KorraColors.brand.withOpacity(0.1), height: 1.h),
          // SizedBox(height: 12.h),

          // // == HISTORY SECTION ==
          // Text(
          //   'Recent Payouts',
          //   style: GoogleFonts.inter(
          //     fontSize: 14.sp,
          //     fontWeight: FontWeight.w700,
          //     color: KorraColors.text,
          //   ),
          // ),

          // SizedBox(height: 16.h),

          // // Conditional history display
          // state.history.isEmpty
          //     ? _buildEmptyHistoryState()
          //     : _buildHistoryList(state.history),
        ],
      ),
    );
  }

  // A meticulously designed empty state.
  Widget _buildEmptyHistoryState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Iconsax.receipt_search, color: KorraColors.textMuted.withOpacity(0.5), size: 28.sp),
          SizedBox(height: 12.h),
          Text(
            'No recent payouts',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: KorraColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
  
  // The list of history items.
  Widget _buildHistoryList(List<PayoutHistory> history) {
    return Column(
      children: history.map((item) => _buildHistoryTile(item)).toList(),
    );
  }

  // A single, beautifully styled history entry.
  Widget _buildHistoryTile(PayoutHistory item) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Text(
            DateFormat('MMM dd').format(item.createdAt), // e.g., "Sep 05"
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: KorraColors.textMuted,
            ),
          ),
          const Spacer(),
          Text(
            '₦${formatToCurrency(item.amount)}',
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: KorraColors.text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: (item.status == 'completed' ? KorraColors.success : Colors.orange).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              item.status.capitalizeFirst!,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: item.status == 'completed' ? KorraColors.success : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}