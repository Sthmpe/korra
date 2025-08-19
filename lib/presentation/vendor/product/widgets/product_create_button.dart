import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductCreateButton extends StatelessWidget {
  final VoidCallback onTap;
  const ProductCreateButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: SizedBox(
        height: 48.h,
        width: double.infinity,
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFA54600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            elevation: 0,
          ),
          child: Text('Create product',
            style: GoogleFonts.inter(fontSize: 14.5.sp, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }
}
