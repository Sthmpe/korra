import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../config/constants/colors.dart'; // Adjust path
import 'transaction_receipt_screen.dart';

class PaymentResultScreen extends StatefulWidget {
  final bool isSuccess;
  final bool isPlanCompleted;
  final double amount;
  final String planName;
  final String? errorMessage;

  const PaymentResultScreen({
    super.key,
    required this.isSuccess,
    this.isPlanCompleted = false,
    required this.amount,
    required this.planName,
    this.errorMessage,
  });

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  @override
  Widget build(BuildContext context) {
    // Logic setup remains same, styling updated
    // Logic setup
    String lottieUrl;
    String title;
    String subtitle;
    Color btnColor;

    if (!widget.isSuccess) {
      // ❌ FAILURE
      lottieUrl = 'https://assets9.lottiefiles.com/packages/lf20_tl52xzvn.json'; 
      title = "Payment Failed";
      subtitle = widget.errorMessage ?? "We couldn't process your payment at this time.";
      btnColor = Colors.red;
      
    } else if (widget.isPlanCompleted) {
      // ✅ PLAN COMPLETED (The New Logic)
      lottieUrl = 'https://assets10.lottiefiles.com/packages/lf20_u4yrau.json'; 
      
      title = "Payment Completed"; // Formal title
      
      // The specific instruction:
      subtitle = "Your plan has been fully paid. Contact the vendor directly to arrange collection.";
      
      btnColor = const Color(0xFF027A48); // Deep Green (Official/Legal)
      
    } else {
      // ✅ NORMAL INSTALLMENT
      lottieUrl = 'https://assets7.lottiefiles.com/packages/lf20_jbrw3hcz.json'; 
      title = "Payment Successful";
      subtitle = "We've received ₦${NumberFormat("#,##0").format(widget.amount)} towards ${widget.planName}.";
      btnColor = KorraColors.brand;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            children: [
              const Spacer(),
              
              // ANIMATION
              SizedBox(
                height: 180.h,
                width: 180.w,
                child: Lottie.network(lottieUrl, repeat: widget.isPlanCompleted),
              ),
              SizedBox(height: 32.h),

              // TEXT
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 22.sp, fontWeight: FontWeight.w800, color: const Color(0xFF101828)),
              ),
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 15.sp, color: const Color(0xFF667085), height: 1.5),
                ),
              ),

              const Spacer(),

              // BUTTONS
              if (widget.isSuccess) ...[
                SizedBox(
                  width: double.infinity,
                  height: 54.h,
                  child: OutlinedButton(
                    onPressed: () {
                      Get.to(() => TransactionReceiptScreen(
                        amount: widget.amount, 
                        planName: widget.planName,
                        date: DateTime.now(),
                      ));
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    ),
                    child: Text("View Receipt", style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w600, color: const Color(0xFF344054))),
                  ),
                ),
                SizedBox(height: 12.h),
              ],

              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: FilledButton(
                  onPressed: () => Get.back(),
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
      ),
    );
  }
}