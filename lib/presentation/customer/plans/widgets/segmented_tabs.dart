// lib/presentation/customer/plans/widgets/segmented_tabs.dart (or wherever PlansTabsSliver is)

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// Ensure this matches your Enum definition location
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
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
               _chip('Active', PlansTab.active),
              _chip('Ready for Pickup', PlansTab.readyForPickup, isHighPriority: true),
              _chip('Completed', PlansTab.completed),
              _chip('Overdue', PlansTab.overdue),
              _chip('Pending', PlansTab.pending),
              _chip('Cancelled', PlansTab.cancelled),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, PlansTab value, {bool isHighPriority = false}) {
    final selected = current == value;
    
    // Special styling for "Ready" tab to make it pop
    final Color activeColor = isHighPriority ? const Color(0xFF027A48) : _brand; // Green for pickup, Brand for others
    final Color activeText = Colors.white;
    final Color inactiveText = isHighPriority ? const Color(0xFF027A48) : const Color(0xFF667085);
    final Color inactiveBg = isHighPriority ? const Color(0xFFECFDF5) : Colors.transparent;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 5),
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
        margin: EdgeInsets.only(right: 4.w),
        decoration: BoxDecoration(
          color: selected ? activeColor : inactiveBg,
          borderRadius: BorderRadius.circular(10.r),
        ),
        alignment: Alignment.center,
        child: Row(
          children: [
            if (isHighPriority) ...[
               Icon(Icons.inventory_2_outlined, size: 14.sp, color: selected ? activeText : inactiveText),
               SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? activeText : inactiveText,
              ),
            ),
          ],
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