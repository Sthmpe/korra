import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/constants/colors.dart';

void showSuccessSheet(BuildContext context,
    {required String amount, required String bank}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: KorraColors.brand,
            ),
            child: Icon(Icons.check, size: 40.sp, color: Colors.white),
          ),
          SizedBox(height: 16.h),
          Text("Withdrawal Successful",
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: KorraColors.text,
              )),
          SizedBox(height: 8.h),
          Text("₦ $amount sent to $bank",
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: KorraColors.textMuted,
              )),
          SizedBox(height: 24.h),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: KorraColors.brand,
              minimumSize: Size(double.infinity, 48.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text("Done",
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                )),
          )
        ],
      ),
    ),
  );
}
