import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:korra/config/constants/colors.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../logic/bloc/vendor/payout/payout_bloc.dart';
import '../../../../logic/bloc/vendor/payout/payout_event.dart';

class PaymentReceiptScreen extends StatelessWidget {
  final String ref;
  final String amount;
  final String transactionTime;
  final String? transactionFee;
  final String recipientAccount;
  final String recipientBank;

  const PaymentReceiptScreen({
    super.key,
    required this.ref,
    required this.amount,
    required this.transactionTime,
    this.transactionFee,
    required this.recipientAccount,
    required this.recipientBank,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate transaction fee (1.5% capped at 2000)    
    final parsedAmount = double.tryParse(amount.replaceAll(",", "")) ?? 0;
    final fee =
        transactionFee ??
        (parsedAmount * 0.015).clamp(0, 2000).toStringAsFixed(2);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- Logo ---
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: KorraColors.brand,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(MdiIcons.crown, size: 28.sp, color: Colors.white),
            ),
            SizedBox(height: 16.h),

            Text(
              "Payment Successful",
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 32.h),

            // --- Receipt Details ---
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  _buildDetailRow("Amount", "₦$amount"),
                  _divider(),
                  _buildDetailRow("Transaction Fee", "₦$fee"),
                  _divider(),
                  _buildDetailRow("Recipient Account", recipientAccount),
                  _divider(),
                  _buildDetailRow("Recipient Bank", recipientBank),
                  _divider(),
                  _buildDetailRow("Reference", ref!),
                  _divider(),
                  _buildDetailRow("Method", 'Bank Transfer'),
                  _divider(),
                  _buildDetailRow("Date", transactionTime.toString()),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // --- Monnify Note ---
            Text(
              "All transactions are securely processed by our partnered payment provider, Monnify.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
            ),

            const Spacer(),

            // --- Close Button ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KorraColors.brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 14.h),
              ),
              onPressed: () {
                context.read<PayoutBloc>().add(ResetPayoutFlow());
                Get.close(3);
              },
              child: Text(
                "Close",
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, thickness: 0.5, color: Colors.grey[300]);
  }
}
