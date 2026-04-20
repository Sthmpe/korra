import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_bloc.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_event.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_state.dart';

import '../../../shared/widgets/show_app_snackbar.dart';

class EmailOtpBottomSheet extends StatefulWidget {
  const EmailOtpBottomSheet({super.key});

  @override
  State<EmailOtpBottomSheet> createState() => _EmailOtpBottomSheetState();
}

class _EmailOtpBottomSheetState extends State<EmailOtpBottomSheet> {
  final TextEditingController _otpController = TextEditingController();
  Timer? _timer;
  int _secondsRemaining = 180; // 3 minutes = 180 seconds

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() => _secondsRemaining = 180);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 UPGRADED to BlocConsumer to handle both UI changes (builder) and Actions (listener)
    return BlocConsumer<SignupVendorBloc, SignupVendorState>(
      listenWhen: (p, c) => 
          p.emailOtpVerified != c.emailOtpVerified || 
          p.emailError != c.emailError, 
      listener: (context, state) {
        // 1. ON SUCCESS: Close the sheet
        if (state.emailOtpVerified) {
          Navigator.pop(context); 
        }
        
        // 2. ON ERROR: Clear input and show error message
        if (state.emailError != null && state.emailError != '' && !state.emailOtpVerified) {
          _otpController.clear(); // 🚀 Clears the input so they can try again
          showAppSnackbar(state.emailError!, SnackbarType.error); // 🚀 Show error message
        }
      },
      builder: (context, state) {
        // 🚀 Detect if we are currently verifying. 
        // (Adjust this boolean check depending on what loading flag you use in your state, e.g., state.loading or state.emailChecking)
        final isVerifying = state.emailChecking || state.loading; 

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 32.h),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40.w, height: 4.h,
                    decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(4.r)),
                  ),
                  SizedBox(height: 24.h),

                  // Icon & Title
                  Icon(Iconsax.sms_tracking, size: 48.sp, color: KorraColors.brand),
                  SizedBox(height: 16.h),
                  Text(
                    "Verify your Email",
                    style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.w800, color: const Color(0xFF111111)),
                  ),
                  SizedBox(height: 8.h),
                  
                  // Subtitle with user email
                  Text(
                    "We sent a 6-digit code to\n${state.email}",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF666666), height: 1.4),
                  ),
                  SizedBox(height: 24.h),

                  // 🚀 6-Digit Code Input OR Loading Spinner
                  SizedBox(
                    width: double.infinity,
                    height: 56.h, // Fixed height prevents UI jump when switching to spinner
                    child: isVerifying 
                      ? Center(
                          child: SizedBox(
                            width: 24.w, height: 24.w,
                            child: const CircularProgressIndicator(color: KorraColors.brand, strokeWidth: 3),
                          ),
                        )
                      : TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          style: GoogleFonts.inter(fontSize: 24.sp, fontWeight: FontWeight.w700, letterSpacing: 8),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            counterText: "", 
                            hintText: "000000",
                            hintStyle: GoogleFonts.inter(color: Colors.grey.shade300, letterSpacing: 8),
                            filled: true,
                            fillColor: const Color(0xFFF7F7F7),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                          ),
                          onChanged: (val) {
                            if (val.length == 6) {
                              HapticFeedback.mediumImpact();
                              FocusScope.of(context).unfocus(); // 🚀 Drops keyboard instantly so user sees the spinner
                              context.read<SignupVendorBloc>().add(SignupVendorVerifyEmailOtpPressed(val));
                            }
                          },
                        ),
                  ),
                  SizedBox(height: 16.h),

                  // Warning Note
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8.r)),
                    child: Row(
                      children: [
                        Icon(Iconsax.warning_2, size: 16.sp, color: Colors.orange.shade800),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            "Can't find it? Check your spam or junk folder.",
                            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.orange.shade900, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Resend Timer & Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      ),
                      TextButton(
                        onPressed: _secondsRemaining == 0 
                            ? () {
                                context.read<SignupVendorBloc>().add(SignupVendorSendEmailOtpPressed());
                                _startTimer(); // Restart the 3 minutes
                              }
                            : null,
                        child: Text(
                          _secondsRemaining == 0 ? "Resend Code" : "Resend in $_formattedTime",
                          style: GoogleFonts.inter(
                            color: _secondsRemaining == 0 ? KorraColors.brand : Colors.grey.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}