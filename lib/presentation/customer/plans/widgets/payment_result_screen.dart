import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../config/constants/colors.dart';
import '../../../../data/models/customer/payment_receipt_data.dart';
import 'transaction_receipt_screen.dart';

class PaymentResultScreen extends StatefulWidget {
  final bool isSuccess;
  final bool isPlanCompleted;
  final double amount;
  final String planName;
  final String? errorMessage;

  // Optional: If we came from the Bloc with full data, pass it here
  final PaymentReceiptData fullReceiptData; 

  const PaymentResultScreen({
    super.key,
    required this.isSuccess,
    this.isPlanCompleted = false,
    required this.amount,
    required this.planName,
    this.errorMessage,
    required this.fullReceiptData,
  });

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  @override
  Widget build(BuildContext context) {
    String lottieUrl;
    String title;
    String subtitle;
    Color btnColor;
    Color bgPillColor;
    Color textPillColor;

    if (!widget.isSuccess) {
      // ❌ FAILURE
      lottieUrl = 'https://assets9.lottiefiles.com/packages/lf20_tl52xzvn.json';
      title = "Payment Failed";
      subtitle = widget.errorMessage ?? "We couldn't process your payment. Please try again.";
      btnColor = Colors.red;
      bgPillColor = Colors.red.shade50;
      textPillColor = Colors.red;
    } else if (widget.isPlanCompleted) {
      // ✅ PLAN COMPLETED
      lottieUrl = 'https://assets10.lottiefiles.com/packages/lf20_u4yrau.json';
      title = "Plan Completed!";
      subtitle = "You've fully paid for ${widget.planName}. Contact the vendor to arrange collection.";
      btnColor = const Color(0xFF027A48); // Success Green
      bgPillColor = const Color(0xFFECFDF3);
      textPillColor = const Color(0xFF027A48);
    } else {
      // ✅ INSTALLMENT SUCCESS
      lottieUrl = 'https://assets7.lottiefiles.com/packages/lf20_jbrw3hcz.json';
      title = "Payment Successful";
      subtitle = "We've received ₦${NumberFormat("#,##0").format(widget.amount)} towards your goal.";
      btnColor = KorraColors.brand;
      bgPillColor = const Color(0xFFFFF4ED); // Brand Orange Light
      textPillColor = KorraColors.brand;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // 1. ANIMATION
            SizedBox(
              height: 200.h,
              width: 200.w,
              child: Lottie.network(lottieUrl, repeat: widget.isPlanCompleted),
            ),
            SizedBox(height: 24.h),

            // 2. STATUS PILL
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: bgPillColor,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                widget.isSuccess ? (widget.isPlanCompleted ? "ALL DONE" : "CONFIRMED") : "FAILED",
                style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: textPillColor, letterSpacing: 1.0),
              ),
            ),
            SizedBox(height: 24.h),

            // 3. TITLE & AMOUNT
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 24.sp, fontWeight: FontWeight.w800, color: const Color(0xFF101828)),
            ),
            SizedBox(height: 8.h),
            if (widget.isSuccess)
              Text(
                "₦${NumberFormat("#,##0").format(widget.amount)}",
                style: GoogleFonts.plusJakartaSans(fontSize: 36.sp, fontWeight: FontWeight.w800, color: const Color(0xFF101828), letterSpacing: -1.0),
              ),

            SizedBox(height: 16.h),
            
            // 4. SUBTITLE
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 15.sp, color: const Color(0xFF667085), height: 1.5),
              ),
            ),

            const Spacer(flex: 3),

            // 5. BUTTONS
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              child: Column(
                children: [
                  if (widget.isSuccess) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: OutlinedButton(
                        onPressed: () {
                          // ✅ FIX: Construct Receipt Data Here
                          // If we have full data from Bloc, use it. If not, construct Partial.
                          final data = widget.fullReceiptData;

                          Get.to(() => TransactionReceiptScreen(data: data));
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        ),
                        child: Text("View Receipt", style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w600, color: const Color(0xFF344054))),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: FilledButton(
                      onPressed: () => Get.back(), // Or Navigate Home
                      style: FilledButton.styleFrom(
                        backgroundColor: btnColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        elevation: 0,
                      ),
                      child: Text("Done", style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}