import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/constants/colors.dart';

class KycGenderSelector extends StatelessWidget {
  final String? gender;
  final bool isLocked;
  final ValueChanged<String> onGenderChanged;

  const KycGenderSelector({
    super.key,
    required this.gender,
    required this.isLocked,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Gender",
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111111),
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            _buildChip(context, "Male"),
            SizedBox(width: 8.w),
            _buildChip(context, "Female"),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(BuildContext context, String label) {
    final isSelected = label == gender;
    return Expanded(
      child: GestureDetector(
        onTap: isLocked ? null : () => onGenderChanged(label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            color: isSelected
                ? KorraColors.brand.withOpacity(0.1)
                : (isLocked
                      ? const Color(0xFFF9FAFB)
                      : const Color(0xFFF7F7F7)),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? KorraColors.brand : const Color(0xFFE5E5E5),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? KorraColors.brand : const Color(0xFF667085),
            ),
          ),
        ),
      ),
    );
  }
}
