import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';

class KycDobSelector extends StatelessWidget {
  final DateTime? dob;
  final bool isLocked;
  final ValueChanged<DateTime> onDobChanged;

  const KycDobSelector({
    super.key,
    required this.dob,
    required this.isLocked,
    required this.onDobChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasDob = dob != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Date of Birth",
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111111),
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: isLocked
              ? null
              : () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: dob ?? DateTime(2000),
                    firstDate: DateTime(1930),
                    lastDate: DateTime.now(),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: KorraColors.brand,
                          onPrimary: Colors.white,
                          onSurface: Colors.black,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (date != null) {
                    onDobChanged(date);
                  }
                },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: isLocked
                  ? const Color(0xFFF9FAFB)
                  : const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasDob
                        ? "${dob!.day}/${dob!.month}/${dob!.year}"
                        : "DD/MM/YYYY",
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: hasDob ? FontWeight.w600 : FontWeight.w400,
                      color: hasDob
                          ? const Color(0xFF1B1B1B)
                          : const Color(0xFFAAAAAA),
                    ),
                  ),
                ),
                Icon(
                  Iconsax.calendar_1,
                  size: 20.sp,
                  color: const Color(0xFF667085),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
