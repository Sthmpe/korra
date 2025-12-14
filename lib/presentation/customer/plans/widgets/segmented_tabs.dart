import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../logic/bloc/customer/plans/plan_action_bloc.dart';

class PlansTabsSliver extends SliverPersistentHeaderDelegate {
  final PlansTab current;
  final ValueChanged<PlansTab> onChanged;

  PlansTabsSliver({required this.current, required this.onChanged});

  static const _brand = Color(0xFFA54600);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: Container(
        height: 58.h,
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFEAECF0)),
        ),
        padding: EdgeInsets.all(4.r),
        // ✅ CHANGED: Wrapped in ScrollView to handle 5 tabs safely
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _chip('Active', PlansTab.active),
              _chip('Pending', PlansTab.pending), // ✅ ADDED
              _chip('Completed', PlansTab.completed),
              _chip('Overdue', PlansTab.overdue),
              _chip('Cancelled', PlansTab.cancelled),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, PlansTab value) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w), // Fixed padding for scroll
        margin: EdgeInsets.only(right: 4.w),
        decoration: BoxDecoration(
          color: selected ? _brand : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF667085),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 74.h;
  @override
  double get minExtent => 74.h;
  @override
  bool shouldRebuild(covariant PlansTabsSliver old) => old.current != current;
}