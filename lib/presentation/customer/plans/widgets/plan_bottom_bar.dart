import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../config/constants/colors.dart';
import '../../../../../logic/bloc/customer/plans/create_plan_state.dart';

class PlanBottomBar extends StatelessWidget {
  final CreatePlanStatus status;
  final bool isSlotsFull;
  final bool isInsufficient;
  final bool isFullPayment;
  final double walletAmount;
  final double storeCreditUsed;
  final double userEnteredDownPayment;
  final double processingFee;
  final double minDown;
  final String? cadenceType;
  final bool agreedToTerms;
  final NumberFormat currencyFormat;
  final VoidCallback onPayPressed;
  final VoidCallback onJumpToPlan;
  final VoidCallback onFundWallet;

  const PlanBottomBar({
    super.key,
    required this.status,
    required this.isSlotsFull,
    required this.isInsufficient,
    required this.isFullPayment,
    required this.walletAmount,
    required this.storeCreditUsed,
    required this.userEnteredDownPayment,
    required this.processingFee,
    required this.minDown,
    required this.cadenceType,
    required this.agreedToTerms,
    required this.currencyFormat,
    required this.onPayPressed,
    required this.onJumpToPlan,
    required this.onFundWallet,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAmountValid = (userEnteredDownPayment + processingFee) >= (minDown + processingFee);
    final bool isSchedulePicked = isFullPayment || cadenceType != null;
    final bool isFormComplete = isAmountValid && isSchedulePicked;

    final bool canProceed = !isSlotsFull && isFormComplete && agreedToTerms;

    String btnText = "Pay & Start Plan";
    if (storeCreditUsed > 0 && walletAmount == 0) {
      btnText = "Pay with Store Credit";
    } else if (storeCreditUsed > 0) {
      btnText = "Pay Balance (${currencyFormat.format(walletAmount)})";
    }

    Color btnColor = KorraColors.brand;
    VoidCallback? customAction;

    if (isSlotsFull) {
      btnText = "View Active Plans";
      btnColor = Colors.orange.shade800;
      customAction = onJumpToPlan;
    } else if (isInsufficient) {
      btnText = "Fund Wallet & Start";
      btnColor = Colors.black;
      customAction = onFundWallet;
    } else if (isFullPayment && walletAmount > 0) {
      btnText = "Pay Full Amount";
    }

    final VoidCallback? onPressed =
        (status == CreatePlanStatus.creating ||
            (!canProceed && !isInsufficient && !isSlotsFull))
        ? null
        : () {
            if (customAction != null) {
              customAction();
            } else {
              onPayPressed();
            }
          };

    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 32.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54.h,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: btnColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          onPressed: onPressed,
          child: status == CreatePlanStatus.creating
              ? SizedBox(
                  height: 24.h,
                  width: 24.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  btnText,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
