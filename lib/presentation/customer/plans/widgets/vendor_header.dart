import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class VendorHeader extends StatelessWidget {
  final String? storeName;
  final String? logoUrl; // Optional: If you add real logos later
  final bool showVerified;

  const VendorHeader({
    super.key,
    this.storeName,
    this.logoUrl,
    this.showVerified = true,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Safe Name Logic
    final String name = (storeName == null || storeName!.trim().isEmpty) 
        ? "Store" 
        : storeName!;

    // 2. Safe Initial Logic
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    return Row(
      children: [
        // Logo Circle
        Container(
          height: 40.h,
          width: 40.w,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
            // If you have a logoUrl, use DecorationImage here
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 16.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        
        // Name Column
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF101828), // Dark Text
                  ),
                ),
                if (showVerified) ...[
                  SizedBox(width: 4.w),
                  Icon(Icons.verified, size: 14.sp, color: Colors.blue),
                ]
              ],
            ),
            Text(
              "Verified Merchant", // Placeholder subtitle
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}