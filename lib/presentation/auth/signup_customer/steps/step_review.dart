import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:korra/config/utils/text_util.dart'; // Ensure string extension exists

import '../../../../../config/constants/colors.dart';
import '../../../../../config/validators/validators.dart';
import '../../../../../logic/bloc/auth/signup_customer/signup_customer_bloc.dart';
import '../../legal/legal_sheet.dart';

class StepReview extends StatelessWidget {
  final GlobalKey<FormState> formKey;
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Consent',
            style: GoogleFonts.inter(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111111),
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Please double check your details before creating your account.',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0xFF666666),
              height: 1.4,
            ),
          ),
          SizedBox(height: 32.h),

          // --- SUMMARY CARD ---
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFE5E5E5).withOpacity(0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _ReviewRow(
                  label: "Full Name",
                  value: _fullName(),
                  icon: Iconsax.user,
                ),
                const Divider(height: 24, color: Color(0xFFF0F0F0)),
                _ReviewRow(
                  label: "Email Address",
                  value: s.email,
                  icon: Iconsax.sms,
                ),
                const Divider(height: 24, color: Color(0xFFF0F0F0)),
                _ReviewRow(
                  label: "Phone Number",
                  value: s.phone,
                  icon: Iconsax.call,
                ),
              ],
            ),
          ),

          SizedBox(height: 32.h),

          // --- LEGAL FOOTER ---
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB), // Very subtle grey
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFF3F4F6).withOpacity(0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Icon(
                    Iconsax.shield_tick,
                    size: 18.sp,
                    color: KorraColors.brand,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: const Color(0xFF4B5563), // Grey-600
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(
                          text:
                              'By creating an account, you confirm that you have read and agree to Korra’s ',
                        ),
                        TextSpan(
                          text: 'Terms of Service',
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
                ),
              ],
            ),
          ),

          SizedBox(height: 40.h),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// REUSABLE ROW COMPONENT
// -----------------------------------------------------------------------------
class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReviewRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 16.sp, color: const Color(0xFF666666)),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8E8E93), // Label grey
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C1C1E), // Value black
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
