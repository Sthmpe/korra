import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class VendorKpiBlock extends StatelessWidget {
  final String newCount, ongoingCount, completedCount, cancelledCount;
  final VoidCallback onTapNew, onTapOngoing, onTapCompleted, onTapCancelled;

  const VendorKpiBlock({
    super.key,
    required this.newCount,
    required this.ongoingCount,
    required this.completedCount,
    required this.cancelledCount,
    required this.onTapNew,
    required this.onTapOngoing,
    required this.onTapCompleted,
    required this.onTapCancelled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _tile(label: 'New', value: newCount, c: const Color(0xFFA54600), bg: const Color(0xFFF7F3EF), onTap: onTapNew),
          SizedBox(width: 8.w),
          _tile(label: 'Ongoing', value: ongoingCount, c: const Color(0xFF1A73E8), bg: const Color(0xFFE9F1FE), onTap: onTapOngoing),
          SizedBox(width: 8.w),
          _tile(label: 'Completed', value: completedCount, c: const Color(0xFF1DB954), bg: const Color(0xFFEAF6EE), onTap: onTapCompleted),
          SizedBox(width: 8.w),
          _tile(label: 'Cancelled', value: cancelledCount, c: const Color(0xFFE53935), bg: const Color(0xFFFFF0EF), onTap: onTapCancelled),
        ]),
      ]),
    );
  }

  Widget _tile({
    required String label,
    required String value,
    required Color c,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: () { HapticFeedback.selectionClick(); onTap(); },
          child: Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: c, width: 1.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(value, style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w800)),
                SizedBox(height: 2.h),
                Text(label, style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF5E5E5E))),
              ])),
            ]),
          ),
        ),
      ),
    );
  }
}
