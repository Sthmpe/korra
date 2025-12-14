import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class ProductSearchBar extends StatelessWidget {
  final String initialValue;
  final Function(String) onChanged;

  const ProductSearchBar({super.key, required this.initialValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: "Search products...",
        hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14.sp),
        filled: true,
        fillColor: const Color(0xFFF2F4F7), // Light Grey fill
        prefixIcon: const Icon(Iconsax.search_normal, size: 20, color: Colors.grey),
        contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none, // No border = Modern
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFA54600), width: 1), // subtle brand focus
        ),
      ),
    );
  }
}