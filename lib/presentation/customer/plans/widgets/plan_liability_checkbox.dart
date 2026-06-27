import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../config/constants/colors.dart';
import 'penalty_explainer_sheet.dart';

class PlanLiabilityCheckbox extends StatelessWidget {
  final bool isChecked;
  final String policyString;
  final ValueChanged<bool?> onChanged;

  const PlanLiabilityCheckbox({
    super.key,
    required this.isChecked,
    required this.policyString,
    required this.onChanged,
  });

  void _showPenaltyExplainer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => PenaltyExplainerSheet(policyString: policyString),
    );
  }

  @override
  Widget build(BuildContext context) {
    const String highlightText = "Store Balance Terms";

    return Padding(
      padding: EdgeInsets.only(top: 24.h, bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24.w,
            height: 24.w,
            child: Checkbox(
              value: isChecked,
              onChanged: onChanged,
              activeColor: KorraColors.brand,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(
                    text:
                        "I acknowledge that incomplete plans are secured under the ",
                  ),
                  TextSpan(
                    text: highlightText,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: KorraColors.brand,
                      decoration: TextDecoration.underline,
                      decorationColor: KorraColors.brand.withOpacity(0.5),
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _showPenaltyExplainer(context),
                  ),
                  const TextSpan(text: "."),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
