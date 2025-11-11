// === WALLET DETAILS CARD ===
  import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:korra/logic/bloc/customer/topup/top_up_state.dart';

import '../../../../config/constants/colors.dart';
import 'copy_account_number_tile.dart';

class WalletDetailsCard extends StatelessWidget {
  final TopUpState state;
  const WalletDetailsCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFECECEC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _walletRow('Account Name', state.details.walletAccountName),
          SizedBox(height: 14.h),
          CopyAccountNumberTile(accountNumber: state.details.walletAccountNumber),
          SizedBox(height: 14.h),
          _walletRow('Bank Name', state.details.walletBankName, showImageLogo: true, imagePath: state.details.bankLogoImageString),
          SizedBox(height: 18.h),
          Divider(height: 1, color: KorraColors.border.withOpacity(0.4)),
          SizedBox(height: 14.h),
          Text(
            'Use the above account to transfer the amount you wish to top up. '
            'Your wallet will be credited automatically once payment is confirmed.',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: KorraColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

  Widget _walletRow(String label, String value, {bool showImageLogo = false, String? imagePath}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (showImageLogo)
          Image.asset(
            '$imagePath',
            width: 24.r,
            height: 24.r,
          ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: KorraColors.textMuted,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: KorraColors.text,
          ),
        ),
      ],
    );
  }