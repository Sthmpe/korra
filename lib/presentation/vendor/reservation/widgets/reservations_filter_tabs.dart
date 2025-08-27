import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../logic/bloc/vendor/shared/resv_filter.dart';

const _brand = Color(0xFFA54600);

class ReservationsFilterTabs extends StatelessWidget {
  final ResvFilter selected;
  final String newCount, ongoingCount, completedCount, cancelledCount;
  final ValueChanged<ResvFilter> onChanged;

  const ReservationsFilterTabs({
    super.key,
    required this.selected,
    required this.newCount,
    required this.ongoingCount,
    required this.completedCount,
    required this.cancelledCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w, runSpacing: 8.h,
      children: [
        _chip('New', newCount, ResvFilter.newRes, selected),
        _chip('Ongoing', ongoingCount, ResvFilter.ongoing, selected, c: const Color(0xFF1A73E8)),
        _chip('Completed', completedCount, ResvFilter.completed, selected, c: const Color(0xFF1DB954)),
        _chip('Cancelled', cancelledCount, ResvFilter.cancelled, selected, c: const Color(0xFFE53935)),
      ],
    );
  }

  Widget _chip(String label, String value, ResvFilter me, ResvFilter sel, {Color c = _brand}) {
    final active = sel == me;
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: () => onChanged(me),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: c, width: active ? 1.6 : 1.2),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(value,
            style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w800)),
          SizedBox(width: 8.w),
          Text(label,
            style: GoogleFonts.inter(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: const Color(0xFF5E5E5E))),
        ]),
      ),
    );
  }
}
