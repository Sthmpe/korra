import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';

import '../../../../config/constants/colors.dart';
import '../../shared/widgets/korra_header.dart'; // Adjust path to your colors

class LegalPdfScreen extends StatelessWidget {
  final String title;
  final String pdfUrl;

  const LegalPdfScreen({
    Key? key,
    required this.title,
    required this.pdfUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: KorraHeader(title: title, showLeadingIcon: true,),
      // The Cached PDF Viewer handles everything: downloading, loading state, and error state.
      body: const PDF(
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: false,
        pageFling: true,
      ).cachedFromUrl(
        pdfUrl,
        placeholder: (progress) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 30.h,
                width: 30.h,
                child: const CircularProgressIndicator(
                  color: KorraColors.brand,
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "Loading Document... ${progress.toInt()}%",
                style: GoogleFonts.inter(
                  color: const Color(0xFF667085),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        errorWidget: (error) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.document_filter, color: Colors.red.shade300, size: 48.sp),
              SizedBox(height: 16.h),
              Text(
                "Failed to load document.\nPlease check your connection.",
                style: GoogleFonts.inter(
                  color: const Color(0xFF344054),
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}