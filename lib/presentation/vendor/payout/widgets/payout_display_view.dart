import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/vendor/payout/payout_bloc.dart';
import '../../../../logic/bloc/vendor/payout/payout_event.dart';
import '../../../../logic/bloc/vendor/payout/payout_state.dart';

class PayoutDisplayView extends StatelessWidget {
  final PayoutState state;
  const PayoutDisplayView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final details = state.payoutDetails;
    final accNum = details.bankAccountNumber;
    final maskedAcc = accNum.length > 4 ? accNum.substring(accNum.length - 4) : accNum;

    return Row(
      children: [
        Icon(Iconsax.bank, color: KorraColors.textMuted, size: 24.sp),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text( 
                details.bankName.isNotEmpty ? details.bankName : 'No Bank Details Added',
                style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: KorraColors.text),
              ),
              if (details.bankName.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text( 
                  '${details.bankAccountName} ••$maskedAcc',
                  style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w500, color: KorraColors.textMuted),
                ),
              ],
            ],
          ),
        ),
        SizedBox(width: 12.w),
        TextButton(
          onPressed: () => context.read<PayoutBloc>().add(EditMethodToggled()), 
          child: Text( 
            details.bankName.isNotEmpty ? 'Update' : 'Add',
            style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: KorraColors.brand),
          ),
        ),
      ],
    );
  }
}