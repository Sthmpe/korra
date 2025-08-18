import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../logic/bloc/customer_shell/plans/plans_event.dart';

class PlansTabBar extends StatelessWidget {
  final PlansTab currentTab;
  final ValueChanged<PlansTab> onChanged;

  const PlansTabBar({
    super.key,
    required this.currentTab,
    required this.onChanged,
  });

  static const _brand = Color(0xFFA54600);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildTab("Active", PlansTab.active),
        _buildTab("Completed", PlansTab.completed),
        _buildTab("Overdue", PlansTab.overdue),
      ],
    );
  }

  Widget _buildTab(String text, PlansTab tab) {
    final selected = currentTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(tab),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: selected ? _brand : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFEAE6E2)),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF101828),
            ),
          ),
        ),
      ),
    );
  }
}
