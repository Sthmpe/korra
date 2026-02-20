import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../../../../config/constants/colors.dart'; // Adjust path
import '../../../../config/routes/app_routes.dart';
import '../../../../config/utils/currency_formatters.dart';
import '../../../../data/models/customer/plans.dart';
import '../../../../data/repository/customer/customer_repository.dart'; // For wallet stream
import '../../../../logic/bloc/customer/plans/pay_plan_bloc.dart';
import '../../../shared/widgets/show_app_snackbar.dart';

void showPaySheet(BuildContext context, Plan p, CustomerRepository customerRepo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        // Pass the Bloc from the Page to the Sheet
        return PayConfirmationSheet(
          plan: p, 
          customerUid: p.customerId,
          customerRepo: customerRepo,
        );
      },
    );
}

class PayConfirmationSheet extends StatelessWidget {
  final Plan plan;
  final String customerUid;
  final CustomerRepository customerRepo;

  const PayConfirmationSheet({
    super.key,
    required this.plan,
    required this.customerUid,
    required this.customerRepo,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PayPlanBloc(repo: customerRepo),
      child: StreamBuilder(
        stream: customerRepo.streamCustomer(customerUid), // Listen to Wallet Balance
        builder: (context, snapshot) {
          final walletBalance = snapshot.data?.availableBalance ?? 0.0;
          final amountToPay = plan.nextAmount; 
          final bool canPay = walletBalance >= amountToPay;
      
          return Container(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                ),
                SizedBox(height: 24.h),
                
                Text("Confirm Payment", style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800, color: KorraColors.text)),
                SizedBox(height: 24.h),
      
                // Summary Card
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFEAECF0)),
                  ),
                  child: Column(
                    children: [
                      _row("Paying for", plan.title, isBold: true),
                      SizedBox(height: 12.h),
                      Divider(height: 1, color: Colors.grey.shade300),
                      SizedBox(height: 12.h),
                      _row("Amount Paid", formatToCurrency(amountToPay)),
                      SizedBox(height: 8.h),
                      _row("Wallet Balance", formatToCurrency(walletBalance), color: canPay ? Colors.green : Colors.red),
                    ],
                  ),
                ),
      
                SizedBox(height: 32.h),
      
                // Action Button
                BlocConsumer<PayPlanBloc, PayPlanState>(
                  listener: (context, state) {
                    if (state.status == PayPlanStatus.success) {
                      Navigator.pop(context); // Close sheet
                      // Show Success Snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Payment Successful!", style: GoogleFonts.inter(color: Colors.white)),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        )
                      );
                    }
                    if (state.status == PayPlanStatus.failure) {
                      Navigator.pop(context); // Close sheet to show error
                      // Show Error Sheet/Snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.errorMessage ?? "Error", style: GoogleFonts.inter(color: Colors.white)),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        )
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state.status == PayPlanStatus.loading) {
                      return const Center(child: CircularProgressIndicator(color: KorraColors.brand));
                    }
      
                    if (!canPay) {
                      return SizedBox(
                        width: double.infinity,
                        height: 52.h,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            final customerData = snapshot.data;
  
                            if (customerData != null) {
                              Get.toNamed(
                                Routes.customerBankDetails, 
                                arguments: customerData 
                              );
                            } else {
                              // Optional: Show a message if data isn't ready
                              showAppSnackbar("Please wait, data is loading...", SnackbarType.info);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black, // Dark for "Action needed"
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                          ),
                          child: Text("Fund Wallet", style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      );
                    }
      
                    return SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: FilledButton(
                        onPressed: () {
                          context.read<PayPlanBloc>().add(PayInstallmentConfirmed(
                            planId: plan.id,
                            customerUid: customerUid,
                            amount: amountToPay,
                          ));
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: KorraColors.brand,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        ),
                        child: Text("Confirm Payment", style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey.shade600))),
        Text(value, style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: isBold ? FontWeight.w700 : FontWeight.w600, color: color ?? Colors.black)),
      ],
    );
  }
}