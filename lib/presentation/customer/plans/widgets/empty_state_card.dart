import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptyStateCard extends StatelessWidget {
  final String text;
  const EmptyStateCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFEAE6E2)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF5E5E5E)),
        ),
      ),
    );
  }
}
