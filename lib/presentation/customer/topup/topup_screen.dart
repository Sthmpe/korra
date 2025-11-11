import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../../../config/constants/colors.dart';
import '../../../logic/bloc/customer/topup/top_up_bloc.dart';
import '../../../logic/bloc/customer/topup/top_up_event.dart';
import '../../../logic/bloc/customer/topup/top_up_state.dart';
import '../../shared/widgets/korra_header.dart';
import 'widgets/topup_balance_card.dart';
import 'widgets/topup_wallet_details_card.dart';

class TopUpScreen extends StatelessWidget {
  const TopUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KorraColors.bg,
      appBar: KorraHeader(
        title: 'Top-Up Wallet',
        showLeadingIcon: true,
        onBackpressed: () => Get.back(),
      ),
      body: BlocBuilder<TopUpBloc, TopUpState>(
        builder: (context, state) {
          if (state.status == TopUpStatus.loading ||
              state.status == TopUpStatus.initial) {
            return const Center(
              child: CircularProgressIndicator(color: KorraColors.brand),
            );
          }

          if (state.status == TopUpStatus.failure) {
            return Center(
              child: Text(state.errorMessage ?? 'An error occurred.'),
            );
              }
          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            children: [
              TopupBalanceCard(state: state),
              SizedBox(height: 24.h),
              WalletDetailsCard(state: state),
              SizedBox(height: 40.h),
              _buildPaymentButton(context),
            ],
          );
        }
      ),
    );
  }

  

  // === BUTTON ===
  Widget _buildPaymentButton(BuildContext context) {
    return BlocBuilder<TopUpBloc, TopUpState>(
      builder: (context, state) {
        final isVerifying = state.status == TopUpStatus.verifying;

        return SizedBox(
          height: 52.h,
          child: FilledButton(
            onPressed: isVerifying
                ? null
                : () {
                    context.read<TopUpBloc>().add(VerifyPaymentPressed());
                    Get.close(1);
                  },
            style: FilledButton.styleFrom(
              backgroundColor: KorraColors.brand,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: isVerifying
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Verifying payment...',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'I have made payment',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
