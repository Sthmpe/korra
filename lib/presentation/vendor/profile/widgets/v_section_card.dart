import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class VSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const VSectionCard({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEAE6E2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 8.h),
          child: Text(title, style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w900)),
        ),
        ...children,
      ]),
    );
  }
}
