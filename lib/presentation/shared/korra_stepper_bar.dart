import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/constants/colors.dart';
import '../../../config/constants/sizes.dart';

class KorraStepperBar extends StatelessWidget {
  final int pageIndex;
  final int totalPages;

  const KorraStepperBar({
    super.key,
    required this.pageIndex,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 4.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7), // Light grey track
            borderRadius: BorderRadius.circular(2.r),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Prevent division by zero just in case
              final safeTotalPages = totalPages > 0 ? totalPages : 1; 
              
              final stepWidth = constraints.maxWidth / safeTotalPages;
              final currentWidth = stepWidth * (pageIndex + 1);
              
              return Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    width: currentWidth,
                    decoration: BoxDecoration(
                      color: KorraColors.brand,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Step ${pageIndex + 1} of $totalPages',
          style: GoogleFonts.inter(
            fontSize: KorraSizes.fontSm.sp,
            fontWeight: KorraSizes.weightSemiBold,
            color: const Color(0xFF666666),
          ),
        ),
      ],
    );
  }
}