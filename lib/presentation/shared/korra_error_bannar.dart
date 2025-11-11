import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    // This banner is designed to be a subtle, floating 'chip' that
    // informs without disrupting the overall premium feel of the UI.
    return Container(
      margin: EdgeInsets.only(top: 12.h, left: 60.w, right: 60.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        // Using a dark, semi-transparent color for a sophisticated, modern feel.
        color: const Color(0xFF262626).withOpacity(0.9),
        borderRadius: BorderRadius.circular(
          100,
        ), // A pill shape is modern and clean.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // The icon is subtle and uses a less alarming color.
          Icon(
            Icons.cloud_off_outlined,
            color: const Color(0xFFAAAAAA),
            size: 16.sp,
          ),
          SizedBox(width: 4.w),
          // Typography is key: clean font, readable size, and soft color.
          SizedBox(
            width: 245.w,
            child: Center(
              child: Text(
                message,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFFE0E0E0),
                  fontWeight: FontWeight.w500,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
