// lib/presentation/customer/storefront/widgets/storefront_cart_balances.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants/colors.dart';

/// Balance strip for the cart sheet: shows the customer's store balance at
/// this merchant and their Korra wallet balance side by side, plus an
/// "insufficient funds" banner when both together can't cover the total.
///
/// Store balance is ALWAYS consumed first — the customer doesn't choose.
class StorefrontCartBalancesCard extends StatelessWidget {
  final double storeBalance;
  final double walletBalance;
  final double shortfall; // > 0 means insufficient

  const StorefrontCartBalancesCard({
    super.key,
    required this.storeBalance,
    required this.walletBalance,
    required this.shortfall,
  });

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
    final insufficient = shortfall > 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _balanceTile(
                icon: Iconsax.shop,
                label: "Store Balance",
                value: money.format(storeBalance),
                hint: storeBalance <= 0 ? "None at this store yet" : "Used first, automatically",
                accent: storeBalance > 0 ? KorraColors.settleGreen : KorraColors.textMuted,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _balanceTile(
                icon: Iconsax.wallet_3,
                label: "Wallet Balance",
                value: money.format(walletBalance),
                hint: "Covers the rest",
                accent: KorraColors.brand,
              ),
            ),
          ],
        ),
        if (insufficient) ...[
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3F2),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFFECDCA)),
            ),
            child: Row(
              children: [
                Icon(Iconsax.warning_2, size: 16.sp, color: const Color(0xFFB42318)),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    "Insufficient funds. You need ${money.format(shortfall)} more to complete this purchase.",
                    style: GoogleFonts.inter(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFB42318),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _balanceTile({
    required IconData icon,
    required String label,
    required String value,
    required String hint,
    required Color accent,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFF2F4F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13.sp, color: accent),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w600,
                    color: KorraColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: KorraColors.textDark,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 9.5.sp,
              fontWeight: FontWeight.w500,
              color: KorraColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}