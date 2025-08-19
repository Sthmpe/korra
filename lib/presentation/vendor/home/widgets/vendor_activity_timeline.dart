import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/vendor_activity.dart';

part 'vendor_activity_tile_pro.dart';

class VendorActivityTimeline extends StatelessWidget {
  final List<VendorActivity> items;

  // optional callbacks
  final void Function(VendorActivity)? onOpenReservation;
  final void Function(VendorActivity)? onAdjustStock;
  final void Function(VendorActivity)? onViewPlan;

  const VendorActivityTimeline({
    super.key,
    required this.items,
    this.onOpenReservation,
    this.onAdjustStock,
    this.onViewPlan,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFEAE6E2)),
          ),
          child: Text('No recent activity.',
            style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF5E5E5E))),
        ),
      );
    }

    return Column(
      children: List.generate(items.length, (i) {
        final a = items[i];
        return _VendorActivityTilePro(
          item: a,
          isFirst: i == 0,
          isLast: i == items.length - 1,
          onOpenReservation: onOpenReservation,
          onAdjustStock: onAdjustStock,
          onViewPlan: onViewPlan,
        );
      }),
    );
  }
}
