import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';

void showTransactionSuccessSheet(BuildContext context, {required String amount}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ResultSheet(
      isSuccess: true,
      title: 'Payout Successful!',
      message: 'A withdrawal of ₦$amount has been sent to your bank account. It should reflect within a few minutes.',
    ),
  );
}

void showTransactionFailureSheet(BuildContext context, {required String message}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ResultSheet(
      isSuccess: false,
      title: 'Transaction Failed',
      message: message,
    ),
  );
}

class _ResultSheet extends StatelessWidget {
  final bool isSuccess;
  final String title;
  final String message;

  const _ResultSheet({required this.isSuccess, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
      decoration: BoxDecoration(
        color: KorraColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: KorraColors.border, borderRadius: BorderRadius.circular(100))),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isSuccess ? KorraColors.brand : KorraColors.danger).withOpacity(0.1),
            ),
            child: Icon(
              isSuccess ? Iconsax.check : Iconsax.export_3,
              color: isSuccess ? KorraColors.brand : KorraColors.danger,
              size: 28.sp,
            ),
          ),
          SizedBox(height: 16.h),
          Text(title, style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 8.h),
          Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14.sp, color: KorraColors.textMuted, height: 1.5)),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: FilledButton(
              onPressed: () => Get.back(),
              style: FilledButton.styleFrom(
                backgroundColor: isSuccess ? KorraColors.brand : KorraColors.text,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              ),
              child: Text(isSuccess ? 'Done' : 'Try Again', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}