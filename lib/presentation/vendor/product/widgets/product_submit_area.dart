import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/constants/colors.dart';

class ProductSubmitArea extends StatelessWidget {
  final String status;
  final bool isLoading;
  final String buttonText;
  final VoidCallback onSubmit;
  final VoidCallback onResolveSupport;
  final String pausedTitle;
  final String pausedMessage;

  const ProductSubmitArea({
    super.key,
    required this.status,
    required this.isLoading,
    required this.buttonText,
    required this.onSubmit,
    required this.onResolveSupport,
    required this.pausedTitle,
    required this.pausedMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (status == 'restricted' || status == 'suspended' || status == 'banned') {
      return Padding(
        padding: EdgeInsets.only(top: 24.h),
        child: _buildStatusCard(
          context,
          title: pausedTitle,
          message: pausedMessage,
          icon: Icons.lock_outline,
          accentColor: const Color(0xFFD92D20),
          buttonText: "Resolve Issue",
          onPressed: onResolveSupport,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: KorraColors.brand,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onSubmit,
        child: isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                buttonText,
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color accentColor,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 24.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF101828),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: const Color(0xFF667085),
              height: 1.4,
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 40.h,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: accentColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100.r),
                ),
              ),
              onPressed: onPressed,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(Icons.arrow_forward_rounded, size: 16.sp, color: accentColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
