import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:korra/config/utils/text_util.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/constants/sizes.dart';
import '../../../../config/validators/validators.dart';
import '../../../../logic/bloc/auth/signup_customer/signup_customer_bloc.dart';
import '../../legal/legal_sheet.dart';

class StepReview extends StatelessWidget {
  final GlobalKey<FormState> formKey; // not used, but kept for uniformity
  const StepReview({super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SignupCustomerBloc>().state;

    String _fullName() {
      final fn = s.firstName.titleCase;
      final ln = s.lastName.titleCase;
      final on = s.otherName.trim().isEmpty ? '' : ' ${s.otherName.titleCase}';
      return '$fn $ln$on';
    }

    Widget row(String k, String v) => Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          SizedBox(width: 120.w, child: Text(k, style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.black54))),
          Expanded(child: Text(v, style: GoogleFonts.inter(fontSize: 13.5.sp, fontWeight: FontWeight.w600))),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KorraSizes.cardRadius.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: EdgeInsets.all(16.r),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Review & consent', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700)),
            SizedBox(height: 12.h),
        
            row('Name', _fullName()),
            row('Phone', s.phone),
            row('Email', s.email),
            row('DOB', s.dob == null ? '-' : KorraValidators.formatDate(s.dob!)),
            row('Gender', s.gender.name),
            SizedBox(height: 10.h),
        
            RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 12.5.sp,
                  color: Colors.black87,
                  height: 1.38,
                ),
                children: [
                  const TextSpan(
                    text: 'By creating an account, you agree to Korra’s ',
                  ),
                  TextSpan(
                    text: 'Terms',
                    style: TextStyle(
                      color: KorraColors.brand,
                      fontWeight: FontWeight.w700,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => showKorraTermsSheet(context),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: KorraColors.brand,
                      fontWeight: FontWeight.w700,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => showKorraPrivacySheet(context),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
