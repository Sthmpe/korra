import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/vendor/payout/payout_bloc.dart';
import '../../../../logic/bloc/vendor/payout/payout_event.dart';
import 'payout_recipt_screen.dart';

/// Shows the elegant failure bottom sheet, adapted from your proven design.
void showPayoutFailureSheet(
  BuildContext context, {
  required String title,
  required String message,
  bool showForgetButton = false,
  VoidCallback? retryCallback,
}) {
  final bloc = context.read<PayoutBloc>();
  if (Get.isOverlaysOpen) {
    // safe close of existing overlays (dialog/sheet)
    Get.until((route) => !Get.isOverlaysOpen);
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) => BlocProvider.value(
      value: bloc,
      child: _KorraFailureSheet(
        title: title,
        message: message,
        retryCallback: retryCallback,
        showForgetButton: showForgetButton,
      ),
    ),
  );
}

void showPayoutPendingSheet(
  BuildContext context, {
  required String title,
  required String message,
}) {
  final bloc = context.read<PayoutBloc>();
  if (Get.isOverlaysOpen) {
    // safe close of existing overlays (dialog/sheet)
    Get.until((route) => !Get.isOverlaysOpen);
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) => BlocProvider.value(
      value: bloc,
      child: _KorraPendingSheet(
        title: title,
        message: message
      ),
    ),
  );
}

class _KorraFailureSheet extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? retryCallback;
  final bool showForgetButton;

  const _KorraFailureSheet({
    required this.title,
    required this.message,
    this.retryCallback,
    required this.showForgetButton,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PayoutBloc>();
    final state = bloc.state.otpHasError;
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: KorraColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Handle bar ---
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: KorraColors.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 24.h),

          // --- Warning Icon ---
          Row(
            mainAxisAlignment: showForgetButton ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
            children: [
              if (showForgetButton) 40.h.horizontalSpace,
              Icon(Iconsax.warning_2, size: 36.sp, color: KorraColors.danger),
              if (showForgetButton)
                SizedBox(
                  width: 40.w,
                  height: 40.h,
                  child: IconButton(
                    onPressed: () {
                      bloc.add(ResetPayoutFlow());
                      Get.back();
                    },
                    icon: Icon(
                      Icons.close,
                      size: 24.sp,
                      color: KorraColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),

          // --- Title ---
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),

          // --- Message ---
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: KorraColors.textMuted,
              height: 1.5,
            ),
          ),
          SizedBox(height: 24.h),

          // --- Try Again & Cancel Row ---
          Row(
            children: [
              if (!showForgetButton)
                // Cancel
                Expanded(
                  child: SizedBox(
                    height: 52.h,
                    child: OutlinedButton(
                      onPressed: () {
                        bloc.add(ResetPayoutFlow());
                        state! ? Get.close(2) : Get.back();
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        side: BorderSide(color: KorraColors.border),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: KorraColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              if (!showForgetButton)
                SizedBox(width: 12.w),
              if (!state!)
              // Try Again
              Expanded(
                child: SizedBox(
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: () {
                      bloc.add(ResetPayoutFlow());
                      Get.back();
                      retryCallback?.call(); // Reopen the PIN input sheet
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      side: BorderSide(color: showForgetButton ? KorraColors.border : Colors.transparent),
                      backgroundColor: showForgetButton ? Colors.white : KorraColors.brand,
                    ),
                    child: Text(
                      'Try Again',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: showForgetButton ? KorraColors.textMuted : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // --- Forgot PIN link ---
          if (showForgetButton)
            TextButton(
              onPressed: () {
                // TODO: Navigate to Forgot PIN flow
              },
              child: Text(
                'Forgot PIN?',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: KorraColors.brand,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pending status sheet
class _KorraPendingSheet extends StatefulWidget {
  final String title;
  final String message;

  const _KorraPendingSheet({
    required this.title,
    required this.message,
  });

  @override
  State<_KorraPendingSheet> createState() => _KorraPendingSheetState();
}

class _KorraPendingSheetState extends State<_KorraPendingSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: KorraColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Handle bar ---
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: KorraColors.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 24.h),

          // --- Rotating Loader Icon ---
          RotationTransition(
            turns: _controller,
            child: Icon(
              Icons.autorenew_rounded,
              size: 36.sp,
              color: KorraColors.brand, // burnt orange
            ),
          ),
          SizedBox(height: 16.h),

          // --- Title ---
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),

          // --- Message ---
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: KorraColors.textMuted,
              height: 1.5,
            ),
          ),
          SizedBox(height: 24.h),

          // --- Dismiss Button ---
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed: () { 
                context.read<PayoutBloc>().add(ResetPayoutFlow());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: KorraColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(
                "Dismiss",
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: KorraColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A full-screen widget to celebrate a successful transaction.
class TransactionSuccessScreen extends StatelessWidget {
  final String amount;
  const TransactionSuccessScreen({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    // This assumes you have a success image in your assets folder.
    // Replace 'assets/images/success_illustration.png' with your actual path.
    final successImage = Lottie.asset(
      'assets/animations/payment_sucess.json',
      height: 200.h,
    );

    final bloc = context.read<PayoutBloc>();
    final amount = bloc.state.amountToWithdraw;
    final ref = bloc.state.transactionRef;
    final recipientAccount = bloc.state.payoutDetails.bankAccountNumber;
    final recipientBank = bloc.state.payoutDetails.bankName;
    final transactionTime = bloc.state.transactionTime;
    final transactionFee = bloc.state.transactionFee;

    return Scaffold(
      backgroundColor: KorraColors.bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              successImage,
              SizedBox(height: 12.h),
              Text(
                'You have successfully withdrawn ₦$amount to your registered bank account.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: KorraColors.textMuted,
                  height: 1.6,
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {
                  debugPrint('view details pressed'); //474523
                  debugPrint("ref: $ref");
                  debugPrint("amount: $amount");
                  debugPrint("recipientAccount: $recipientAccount");
                  debugPrint("recipientBank: $recipientBank");
                  debugPrint("transactionTime: $transactionTime");
                  debugPrint("transactionFee: $transactionFee");
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: bloc,
                        child: PaymentReceiptScreen(
                          amount: amount,
                          ref: ref!,
                          recipientAccount: recipientAccount,
                          recipientBank: recipientBank,
                          transactionTime: DateFormat("yyyy-MM-dd HH:mm:ss").format(transactionTime!),
                          transactionFee: transactionFee!.toString(),
                        ),
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: KorraColors.border),
                  minimumSize: Size.fromHeight(52.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  'View Details',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: KorraColors.text,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              FilledButton(
                // Closes 2 routes: this screen and the underlying PayoutScreen.
                onPressed: () {
                  context.read<PayoutBloc>().add(ResetPayoutFlow());
                  Get.close(2);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: KorraColors.brand,
                  minimumSize: Size.fromHeight(52.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }
}
