import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import 'kyc_premium_input.dart';

class KycNinField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isVerificationInProgress;
  final bool isVerified;
  final String? verificationError;
  final VoidCallback onVerifyPressed;

  const KycNinField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isVerificationInProgress,
    required this.isVerified,
    required this.verificationError,
    required this.onVerifyPressed,
  });

  @override
  Widget build(BuildContext context) {
    Widget? suffix;
    bool isValidLength = controller.text.trim().length == 11;

    if (isVerificationInProgress) {
      suffix = Padding(
        padding: EdgeInsets.all(12.r),
        child: const SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: KorraColors.brand,
          ),
        ),
      );
    } else if (isVerified) {
      suffix = Icon(Iconsax.tick_circle, color: Colors.green, size: 20.sp);
    } else if (isValidLength) {
      suffix = Padding(
        padding: EdgeInsets.only(right: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                onVerifyPressed();
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 8.h,
                ),
                decoration: BoxDecoration(
                  color: KorraColors.brand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  "Verify",
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: KorraColors.brand,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KycPremiumInput(
          controller: controller,
          focusNode: focusNode,
          label: 'National Identity Number (NIN)',
          hint: '11-digit NIN',
          inputType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          readOnly: isVerified || isVerificationInProgress,
          suffixIcon: suffix,
        ),
        Padding(
          padding: EdgeInsets.only(left: 4.w, top: 6.h),
          child: Text(
            isVerificationInProgress
                ? 'Verifying NIN...'
                : isVerified
                ? 'NIN successfully verified'
                : verificationError != null
                ? verificationError!
                : 'Dial *346# to check your NIN',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: isVerificationInProgress
                  ? KorraColors.brand
                  : isVerified
                  ? Colors.green
                  : verificationError != null
                  ? Colors.red
                  : const Color(0xFF667085),
            ),
          ),
        ),
      ],
    );
  }
}
