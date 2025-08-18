import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../logic/bloc/customer_shell/plans/plans_event.dart';

class PlansTabsSliver extends SliverPersistentHeaderDelegate {
  final PlansTab current;
  final ValueChanged<PlansTab> onChanged;

  PlansTabsSliver({required this.current, required this.onChanged});

  static const _brand = Color(0xFFA54600);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    Widget chip(String label, PlansTab value) {
      final selected = current == value;
      return Expanded(
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            decoration: BoxDecoration(
              color: selected ? _brand : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFEAE6E2)),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF1B1B1B),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.white,
      child: Container(
        height: 58.h,
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEAE6E2), width: 1)),
        ),
        child: Row(
          children: [
            chip('Active', PlansTab.active), SizedBox(width: 8.w),
            chip('Completed', PlansTab.completed), SizedBox(width: 8.w),
            chip('Overdue', PlansTab.overdue),
          ],
        ),
      ),
    );
  }

  @override double get minExtent => 58.h;
  @override double get maxExtent => 58.h;

  // CRITICAL: rebuild when tab changes
  @override
  bool shouldRebuild(covariant PlansTabsSliver old) => old.current != current;
}
