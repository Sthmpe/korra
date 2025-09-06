// lib/presentation/vendor/payout/payout_screen.dart


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/constants/colors.dart';
import '../../../data/repository/vendors/vendor_repository.dart';
import '../../../logic/bloc/vendor/home/vendor_home_bloc.dart';
import '../../../logic/bloc/vendor/home/vendor_home_event.dart';
import '../../../logic/bloc/vendor/payout/payout_bloc.dart';
import '../../../logic/bloc/vendor/payout/payout_event.dart';
import '../../../logic/bloc/vendor/payout/payout_state.dart';
import '../../shared/widgets/korra_header.dart';
import 'widgets/payout_balance_card.dart';
import 'widgets/payout_method_card.dart';
import 'widgets/pin_input_sheet.dart';
import 'widgets/transaction_status_overlay.dart';

class PayoutScreen extends StatelessWidget {
  final String vendorUid;
  final VendorRepository vendors;

  const PayoutScreen({
    super.key,
    required this.vendorUid,
    required this.vendors,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PayoutBloc(vendorUid: vendorUid, vendors: vendors)
            ..add(PayoutStarted()),
      child: BlocListener<PayoutBloc, PayoutState>(
        listenWhen: (p, c) => p.payoutFlowStatus != c.payoutFlowStatus,
        listener:(context, state) {
          if (state.status == PayoutStatus.loaded) {
            context.read<VendorHomeBloc>().add(const VendorHomeRefresh());
          }
           // Listen for the signal to create a PIN
          if (state.navigateTo == PayoutNavigation.toCreatePin) {
            // TODO: Navigate to your CreatePinScreen
            // Get.to(() => const CreatePinScreen());
          }

           // A switch statement provides a clean, declarative way to handle each state.
          switch (state.payoutFlowStatus) {
            case PayoutFlowStatus.requiresPin:
              showPinInputSheet(context);
              break;
            case PayoutFlowStatus.pinInvalid:
              Get.snackbar('Error', 'Incorrect PIN. Please try again.', colorText: Colors.white, backgroundColor: KorraColors.danger);
              break;
            case PayoutFlowStatus.sending:
              Get.dialog(
                TransactionStatusOverlay(state: state),
                barrierDismissible: false,
              );
              break;
            case PayoutFlowStatus.success:
              if (Get.isDialogOpen ?? false) Get.back(); // Dismiss the sending dialog
              // TODO: Show the final success bottom sheet
              Get.snackbar('Success', 'Your withdrawal has been processed.', colorText: Colors.white, backgroundColor: KorraColors.success);
              break;
            case PayoutFlowStatus.failure:
              if (Get.isDialogOpen ?? false) Get.back();
              Get.snackbar('Error', state.errorMessage ?? 'Transaction Failed', colorText: Colors.white, backgroundColor: KorraColors.danger);
              break;
            default:
              break;
          }
        },
        child: Scaffold(
          backgroundColor: KorraColors.bg,
          appBar: const KorraHeader(
            title: 'Manage Payout',
            trailingActions: [],
            showLeadingIcon: true,
          ),
          body: BlocBuilder<PayoutBloc, PayoutState>(
            builder: (context, state) {
              debugPrint('PayoutState: $state');
              debugPrint('vendorUid: $vendorUid');
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
              debugPrint('Payout Details: ${state.payoutDetails.toMap()}');
              return ListView(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
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
                      onPressed: () =>
                          context.read<PayoutBloc>().add(WithdrawTapped()),
                      style: FilledButton.styleFrom(
                        backgroundColor: KorraColors.brand,
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
    return TextFormField(
      onChanged: (value) =>
          context.read<PayoutBloc>().add(AmountChanged(value)),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          borderSide: BorderSide(color: KorraColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: KorraColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: KorraColors.brand, width: 2.0),
        ),
        helperText: 'Enter the amount you wish to transfer.',
        helperStyle: GoogleFonts.inter(
          fontSize: 12.sp,
          color: KorraColors.textMuted,
        ),
      ),
    );
  }
}
