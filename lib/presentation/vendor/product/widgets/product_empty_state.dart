import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class ProductEmptyState extends StatelessWidget {
  const ProductEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFEAE6E2)),
        ),
        child: Row(children: [
          Container(
            width: 44.w, height: 44.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F2F1), borderRadius: BorderRadius.circular(12.r)),
            child: const Icon(Iconsax.box, color: Color(0xFFA54600)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text('You haven’t added any products yet.',
              style: GoogleFonts.inter(fontSize: 13.5.sp, color: const Color(0xFF5E5E5E))),
          ),
        ]),
      ),
    );
  }
}
