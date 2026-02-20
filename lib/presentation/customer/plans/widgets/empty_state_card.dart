import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptyStateCard extends StatelessWidget {
  final String text;
  final IconData? icon; // Added optional icon for better UX

  const EmptyStateCard({
    super.key, 
    required this.text,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 24.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA), // Very subtle grey background
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFF0F0F0).withOpacity(0.35)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Visual Anchor (The Icon)
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Icon(
                icon ?? Icons.assignment_outlined, // Default icon
                size: 32.sp,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: 16.h),
            
            // 2. The Text
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14.sp, 
                color: const Color(0xFF5E5E5E),
                height: 1.5, // Better readability
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}