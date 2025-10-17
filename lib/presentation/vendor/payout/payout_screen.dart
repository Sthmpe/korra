// lib/presentation/vendor/payout/payout_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/constants/colors.dart';
import '../../../logic/bloc/vendor/payout/payout_bloc.dart';
import '../../../logic/bloc/vendor/payout/payout_event.dart';
import '../../../logic/bloc/vendor/payout/payout_state.dart';
import '../../../config/utils/currency_formatters.dart';
import '../../shared/widgets/korra_header.dart';
import 'widgets/create_pin_input_sheet.dart';
import 'widgets/create_pin_success_screen.dart';
import 'widgets/payout_balance_card.dart';
import 'widgets/payout_method_card.dart';
import 'widgets/pin_input_sheet.dart';
import 'widgets/result_sheets.dart';
import 'widgets/success_snackbar.dart';
import 'widgets/transaction_status_overlay.dart';
import 'widgets/transfer_otp_screen.dart';

class PayoutScreen extends StatelessWidget {

  const PayoutScreen({
    super.key,
  });

  void closeAllOverlays() {
    while (Get.isOverlaysOpen) {
      Get.back();
    }
  }

  void _handleCreatePinFlow(BuildContext context, PayoutState state) {
  if (state.createPinStep == CreatePinStep.success) {
    closeAllOverlays();
    Get.to(() => BlocProvider.value(
          value: context.read<PayoutBloc>(),
          child: const CreatePinSuccessScreen(),
        ));
  } else if (state.createPinStep == CreatePinStep.error) {
    closeAllOverlays();
    showPayoutFailureSheet(
      context,
      title: 'PIN Setup Failed',
      message: state.createPinError ?? 'Could not create your PIN. Please try again.',
      retryCallback: () => showCreatePinSheet(context),
    );
  }
}

void _handlePayoutFlow(BuildContext context, PayoutState state) {
  switch (state.payoutFlowStatus) {
    case PayoutFlowStatus.requiresPin:
      closeAllOverlays();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showPinInputSheet(context);
      });
      break;
    case PayoutFlowStatus.createPin:
      closeAllOverlays();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showCreatePinSheet(context);
      });
      break;
    case PayoutFlowStatus.requiresOTP:
      closeAllOverlays();
      Get.to(() => OtpVerificationScreen(
            onCompleted: (otp) => context.read<PayoutBloc>().add(OtpSubmitted(otp)),
            onResend: () {
              context.read<PayoutBloc>().add(OtpResendRequested());
              showSuccessSnackbar("A new OTP has been sent to your email.");
            },
          ));
      break;
    case PayoutFlowStatus.sending:
      closeAllOverlays();
      Get.dialog(
        BlocProvider.value(
          value: context.read<PayoutBloc>(),
          child: const TransactionStatusOverlay(),
        ),
        barrierDismissible: false,
      );
      break;
    case PayoutFlowStatus.success:
      closeAllOverlays();
      Get.to(() => BlocProvider.value(
            value: context.read<PayoutBloc>(),
            child: TransactionSuccessScreen(amount: state.amountToWithdraw),
          ));
      break;
    case PayoutFlowStatus.failure:
      closeAllOverlays();
      showPayoutFailureSheet(
        context,
        title: state.errorTitle ?? 'Transaction Failed',
        message: state.errorMessage ?? 'An unknown error occurred.',
        retryCallback: () => showPinInputSheet(context),
      );
      break;
    default:
      break;
  }
}


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: BlocListener<PayoutBloc, PayoutState>(
        listener: (context, state) {
          _handleCreatePinFlow(context, state);
          _handlePayoutFlow(context, state);
        },
        child: Scaffold(
          backgroundColor: KorraColors.bg,
          appBar: KorraHeader(
            title: 'Manage Payout',
            trailingActions: const [],
            showLeadingIcon: true,
            onBackpressed: () {
              Get.back();
            },
          ),
          body: BlocBuilder<PayoutBloc, PayoutState>(
            builder: (context, state) {
              if (state.status == PayoutStatus.loading ||
                  state.status == PayoutStatus.initial) {
                return const Center(
                  child: CircularProgressIndicator(color: KorraColors.brand),
                );
              }
      
              if (state.status == PayoutStatus.failure) {
                return Center(
                  child: Text(state.errorMessage ?? 'An error occurred.'),
                );
              }
              return ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 12.h,
                ),
                children: [
                  PayoutBalanceCard(state: state),
                  SizedBox(height: 24.h),
                  PayoutMethodCard(state: state),
                  SizedBox(height: 24.h),
                  _buildAmountInput(context, state),
                  SizedBox(height: 32.h),
                  SizedBox(
                    height: 52.h,
                    child: FilledButton(
                      onPressed: state.amountToWithdraw.isNotEmpty
                          ? () {
                              FocusScope.of(context).unfocus();
                              context.read<PayoutBloc>().add(
                                WithdrawTapped(),
                              );
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: KorraColors.brand,
                        disabledBackgroundColor: KorraColors.brand
                            .withOpacity(0.4),
                        disabledForegroundColor: Colors.white.withOpacity(
                          0.7,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        'Withdraw Funds',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput(BuildContext context, PayoutState state) {
    return TextField(
      onChanged: (value) =>
          context.read<PayoutBloc>().add(AmountChanged(value)),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        CurrencyInputFormatter(),
      ],
      style: GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: KorraColors.text,
      ),
      decoration: InputDecoration(
        labelText: 'Amount to Withdraw',
        labelStyle: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: KorraColors.textMuted,
        ),
        prefixText: '₦ ',
        prefixStyle: GoogleFonts.inter(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: KorraColors.text,
        ),
        filled: true,
        fillColor: KorraColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: KorraColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: KorraColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: KorraColors.brand, width: 1.5),
        ),
        helperText: state.amountToWithdraw.isEmpty
            ? 'Enter the amount you want to transfer.'
            : (state.amountError != null ? state.amountError : null),
        helperStyle: GoogleFonts.inter(
          fontSize: 12.sp,
          color: state.amountToWithdraw.isEmpty
              ? KorraColors.textMuted
              : Colors.redAccent,
        ),
      ),
    );
  }
}