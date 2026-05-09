import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:korra/config/utils/text_util.dart';

import '../../../../../config/constants/colors.dart';
import '../../../../../config/constants/icons.dart';
import '../../../../../config/constants/paddings.dart';
import '../../../../../config/constants/sizes.dart';
import '../../../../../config/theme/gaps.dart';
import '../../../../../logic/bloc/auth/signup_customer/signup_customer_bloc.dart';
import '../../legal/legal_sheet.dart';

class StepReview extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  const StepReview({super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SignupCustomerBloc>().state;

    String fullName() {
      final fn = s.firstName.titleCase;
      final ln = s.lastName.titleCase;
      final on = s.otherName.trim().isEmpty ? '' : ' ${s.otherName.titleCase}';
      return '$fn $ln$on';
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: KorraPaddings.pageH,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Consent',
            style: GoogleFonts.inter(
              fontSize: KorraSizes.font2xlPlus.sp,
              fontWeight: KorraSizes.weightExtraBold,
              color: KorraColors.nearBlack,
              letterSpacing: KorraSizes.trackingSnug,
            ),
          ),
          Gaps.h8,
          Text(
            'Please double check your details before creating your account.',
            style: GoogleFonts.inter(
              fontSize: KorraSizes.fontMd.sp,
              color: KorraColors.labelGrey,
              height: KorraSizes.lineHeightMd,
            ),
          ),
          Gaps.h32,

          // --- SUMMARY CARD ---
          Container(
            padding: KorraPaddings.all20,
            decoration: BoxDecoration(
              color: KorraColors.white,
              borderRadius: BorderRadius.circular(KorraSizes.cardRadius.r),
              border: Border.all(color: KorraColors.inputBorderInactive.withOpacity(0.35)),
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
                  label: 'Full Name',
                  value: fullName(),
                  icon: KorraIcons.account,
                ),
                Divider(height: 24, color: KorraColors.dividerSubtle),
                _ReviewRow(
                  label: 'Email Address',
                  value: s.email,
                  icon: KorraIcons.email,
                ),
                Divider(height: 24, color: KorraColors.dividerSubtle),
                _ReviewRow(
                  label: 'Phone Number',
                  value: s.phone,
                  icon: KorraIcons.phone,
                ),
              ],
            ),
          ),

          Gaps.h32,

          // --- LEGAL FOOTER ---
          Container(
            padding: KorraPaddings.all16,
            decoration: BoxDecoration(
              color: KorraColors.surface,
              borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
              border: Border.all(color: const Color(0xFFF3F4F6).withOpacity(0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: KorraSizes.s2.h),
                  child: Icon(
                    KorraIcons.shieldCheck,
                    size: KorraSizes.fontXl.sp,
                    color: KorraColors.brand,
                  ),
                ),
                Gaps.w12,
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: KorraSizes.fontSmPlus.sp,
                        color: KorraColors.textBodyCool,
                        height: KorraSizes.lineHeightNormal,
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

          Gaps.h40,
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
          padding: KorraPaddings.all8,
          decoration: BoxDecoration(
            color: KorraColors.inputBgInactive,
            borderRadius: BorderRadius.circular(KorraSizes.sm.r),
          ),
          child: Icon(icon, size: KorraSizes.fontLg.sp, color: KorraColors.labelGrey),
        ),
        Gaps.w12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: KorraSizes.fontSm.sp,
                  fontWeight: KorraSizes.weightMedium,
                  color: KorraColors.textSecondary,
                ),
              ),
              Gaps.h2,
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: KorraSizes.fontMdHalf.sp,
                  fontWeight: KorraSizes.weightSemiBold,
                  color: KorraColors.iosBlack,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
