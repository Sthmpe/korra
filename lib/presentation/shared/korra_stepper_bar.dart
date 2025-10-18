import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/constants/colors.dart';

class StepperBar<B extends StateStreamable<S>, S> extends StatelessWidget {
  /// Function that extracts the current page index from the Bloc state
  final int Function(S state) pageIndexSelector;

  /// Function that extracts total pages from the Bloc state
  final int Function(S state) totalPagesSelector;

  /// Optional: icon to display on the right side
  final IconData? icon;

  /// Optional: override progress bar color
  final Color? progressColor;

  /// Optional: override background bar color
  final Color? backgroundColor;

  const StepperBar({
    super.key,
    required this.pageIndexSelector,
    required this.totalPagesSelector,
    this.icon,
    this.progressColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<B, S>(
      buildWhen: (p, c) =>
          pageIndexSelector(p) != pageIndexSelector(c),
      builder: (_, s) {
        final pageIndex = pageIndexSelector(s);
        final totalPages = totalPagesSelector(s);
        final progress = (pageIndex + 1) / totalPages;

        return Column(
          children: [
            // Progress bar
            Stack(
              children: [
                Container(
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: backgroundColor ?? Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 6.h,
                    decoration: BoxDecoration(
                      color: progressColor ?? KorraColors.brand,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),

            // Step info row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step ${pageIndex + 1} of $totalPages',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.black54,
                  ),
                ),
                if (icon != null)
                  Icon(
                    icon,
                    size: 20.sp,
                    color: progressColor ?? KorraColors.brand,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
