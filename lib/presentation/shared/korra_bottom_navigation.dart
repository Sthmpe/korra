import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/constants/buttons.dart';
import '../../../config/constants/colors.dart';
import '../../../config/constants/sizes.dart';

class BottomNav<B extends StateStreamable<S>, S> extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool isLast;
  final bool loading;
  final int Function(S state)? pageIndexSelector;
  final VoidCallback? openKycSheet;
  final VoidCallback? onComplete;
  final VoidCallback? onNextPressed;
  final VoidCallback? onBackPressed;

  const BottomNav({
    super.key,
    required this.formKey,
    required this.isLast,
    required this.loading,
    this.pageIndexSelector,
    this.openKycSheet,
    this.onComplete,
    this.onNextPressed,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    Future<void> handleNext() async {
      FocusScope.of(context).unfocus();

      final ok = formKey.currentState?.validate() ?? true;
      if (!ok) return;

      if (isLast) {
        // handle submit & completion
        onComplete?.call();
        return;
      }

      // Optional KYC flow logic (if provided)
      if (pageIndexSelector != null) {
        final s = context.read<B>().state;
        final index = pageIndexSelector!(s);
        if (index == 4 && openKycSheet != null) {
          openKycSheet!();
        }
      }

      // proceed next
      onNextPressed?.call();
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: Size.fromHeight(48.h),
              side: BorderSide(color: KorraColors.greyShade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
              ),
            ),
            onPressed: onBackPressed,
            child: Text(
              'Back',
              style: GoogleFonts.inter(
                fontSize: KorraSizes.fontMd.sp,
                fontWeight: KorraSizes.weightSemiBold,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(48.h),
                  backgroundColor: KorraColors.brand,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
                  ),
                ),
                onPressed: loading ? null : handleNext,
                child: Text(
                  isLast ? 'Create account' : 'Next',
                  style: GoogleFonts.inter(
                    fontSize: KorraSizes.fontMdHalf.sp,
                    fontWeight: KorraSizes.weightBold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (loading)
                Padding(
                  padding: EdgeInsets.only(right: 14.w),
                  child: SizedBox(
                    height: 16.r,
                    width: 16.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
