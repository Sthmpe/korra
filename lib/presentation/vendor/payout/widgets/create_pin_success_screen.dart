// create_pin_success_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../logic/bloc/vendor/payout/payout_bloc.dart';
import '../../../../logic/bloc/vendor/payout/payout_event.dart';

class CreatePinSuccessScreen extends StatelessWidget {
  const CreatePinSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Lottie or icon
              Icon(Icons.check_circle, color: Colors.green, size: 100.sp),

              SizedBox(height: 24.h),

              Text(
                "PIN Created Successfully!",
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 12.h),

              Text(
                "You can now securely complete your transactions.",
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 40.h),

              ElevatedButton(
                onPressed: () {
                  context.read<PayoutBloc>().add(ResetPayoutFlow());
                  Navigator.of(context).pop(); // Or navigate to dashboard
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA54600), // brand color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 14.h),
                ),
                child: Text(
                  "Continue",
                  style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
