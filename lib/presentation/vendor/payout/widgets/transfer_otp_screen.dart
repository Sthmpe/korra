import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:korra/config/constants/colors.dart';

class OtpVerificationScreen extends StatefulWidget {
  final void Function(String otp) onCompleted;
  final VoidCallback onResend;

  const OtpVerificationScreen({
    super.key,
    required this.onCompleted,
    required this.onResend,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  Timer? _timer;
  int _remainingSeconds = 600; // 10 minutes = 600 seconds

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    if (mounted) {
      setState(() => _remainingSeconds--);
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _remainingSeconds = 600;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  void _onOtpChanged(int index, String value) {
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    } else if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6) {
      widget.onCompleted(otp);
    }
  }

  String _formatTime(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40.h),
              Text(
                "Enter OTP",
                style: GoogleFonts.inter(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w600,
                  color: KorraColors.brand,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "We sent a 6-digit code to your registered email.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 32.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0.w),
                    child: SizedBox(
                      width: 45.w,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: GoogleFonts.inter(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: KorraColors.brand, // burnt orange
                        ),
                        maxLength: 1,
                        decoration: InputDecoration(
                          counterText: "",
                          contentPadding: EdgeInsets.zero,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: KorraColors.brand,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor:
                              Colors.white, // ✅ make sure digits are visible
                        ),
                        onChanged: (value) => _onOtpChanged(index, value),
                        onSubmitted: (_) {
                          if (index < 5) _focusNodes[index + 1].requestFocus();
                        },
                        onEditingComplete: () {
                          if (index == 5) {
                            final otp = _controllers.map((c) => c.text).join();
                            if (otp.length == 6) widget.onCompleted(otp);
                          }
                        },
                        onTap: () {
                          _controllers[index].selection =
                              TextSelection.fromPosition(
                                TextPosition(
                                  offset: _controllers[index].text.length,
                                ),
                              );
                        },
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 32.h),
              if (_remainingSeconds > 0)
                Text(
                  "Resend available in ${_formatTime(_remainingSeconds)}",
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: Colors.grey[700],
                  ),
                )
              else
                TextButton(
                  onPressed: () {
                    if (_remainingSeconds == 0) {
                      widget.onResend();
                      _startTimer();
                    }
                  },
                  child: Text(
                    "Resend OTP",
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: KorraColors.brand,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
