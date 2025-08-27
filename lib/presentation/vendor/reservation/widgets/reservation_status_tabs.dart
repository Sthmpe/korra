import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../data/models/vendor/vendor_reservation.dart';

class ReservationStatusTabs extends StatelessWidget {
  final ReservationStatus current;
  final String newCount;
  final String ongoingCount;
  final String completedCount;
  final String cancelledCount;
  final ValueChanged<ReservationStatus> onChanged;

  const ReservationStatusTabs({
    super.key,
    required this.current,
    required this.newCount,
    required this.ongoingCount,
    required this.completedCount,
    required this.cancelledCount,
    required this.onChanged,
  });

  static const _brand = Color(0xFFA54600);

  @override
  Widget build(BuildContext context) {
    final items = [
      _TabSpec('New',        ReservationStatus.newRes,     newCount),
      _TabSpec('Ongoing',    ReservationStatus.ongoing,    ongoingCount),
      _TabSpec('Completed',  ReservationStatus.completed,  completedCount),
      _TabSpec('Cancelled',  ReservationStatus.cancelled,  cancelledCount),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 10.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: items.map((t) {
            final selected = current == t.status;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(t.status);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
                    decoration: BoxDecoration(
                      color: selected ? _brand.withOpacity(.08) : Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: selected ? _brand : const Color(0xFFEAE6E2),
                        width: selected ? 1.4 : 1,
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        t.label,
                        style: GoogleFonts.inter(
                          fontSize: 13.5.sp,
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                          color: selected ? _brand : const Color(0xFF4D4D4D),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _CountDot(text: t.count, selected: selected),
                    ]),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CountDot extends StatelessWidget {
  final String text;
  final bool selected;
  const _CountDot({required this.text, required this.selected});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFA54600) : const Color(0xFFF0ECE8),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
          color: selected ? Colors.white : const Color(0xFF4D4D4D),
        ),
      ),
    );
  }
}

class _TabSpec {
  final String label; final ReservationStatus status; final String count;
  _TabSpec(this.label, this.status, this.count);
}
