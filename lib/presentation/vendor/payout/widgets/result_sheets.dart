import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lottie/lottie.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/vendor/payout/payout_bloc.dart';
import 'pin_input_sheet.dart';

/// Shows the elegant failure bottom sheet, adapted from your proven design.
void showPayoutFailureSheet(BuildContext context, {required String title, required String message}) {
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
      child: _KorraFailureSheet(title: title, message: message),
    ),
  );
}

class _KorraFailureSheet extends StatelessWidget {
  final String title;
  final String message;
  const _KorraFailureSheet({required this.title, required this.message});

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

          // --- Warning Icon ---
          Icon(Iconsax.warning_2, size: 36.sp, color: KorraColors.danger),
          SizedBox(height: 16.h),

          // --- Title ---
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700),
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
              // Cancel
              Expanded(
                child: SizedBox(
                  height: 52.h,
                  child: OutlinedButton(
                    onPressed: () {
                      Get.back();
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
              SizedBox(width: 12.w),

              // Try Again
              Expanded(
                child: SizedBox(
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      showPinInputSheet(context); // Reopen the PIN input sheet
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      backgroundColor: KorraColors.brand,
                    ),
                    child: Text(
                      'Try Again',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // --- Forgot PIN link ---
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



/// A full-screen widget to celebrate a successful transaction.
class TransactionSuccessScreen extends StatelessWidget {
  final String amount;
  const TransactionSuccessScreen({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    // This assumes you have a success image in your assets folder.
    // Replace 'assets/images/success_illustration.png' with your actual path.
    final successImage = Lottie.asset('assets/animations/payment_sucess.json', height: 200.h);

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
                style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w800, color: KorraColors.textMuted, height: 1.6),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () { /* TODO: Implement View Details navigation */ },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: KorraColors.border),
                  minimumSize: Size.fromHeight(52.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                ),
                child: Text('View Details', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: KorraColors.text)),
              ),
              SizedBox(height: 12.h),
              FilledButton(
                // Closes 2 routes: this screen and the underlying PayoutScreen.
                onPressed: () => Get.close(2), 
                style: FilledButton.styleFrom(
                  backgroundColor: KorraColors.brand,
                  minimumSize: Size.fromHeight(52.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                ),
                child: Text('Done', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }
}
