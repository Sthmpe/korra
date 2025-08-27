// lib/presentation/customer/home/widgets/activity_timeline.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../data/models/customer/activity_item.dart';

part 'activity_tile_pro.dart';

class ActivityTimeline extends StatelessWidget {
  final List<ActivityItem> items;

  // optional callbacks
  final void Function(ActivityItem)? onPayNow;
  final void Function(ActivityItem)? onViewPlan;
  final void Function(ActivityItem)? onViewReceipt;
  final void Function(ActivityItem)? onReviewLink;
  final void Function(ActivityItem)? onEnableAutopay;

  const ActivityTimeline({
    super.key,
    required this.items,
    this.onPayNow,
    this.onViewPlan,
    this.onViewReceipt,
    this.onReviewLink,
    this.onEnableAutopay,
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
          child: Text(
            'No recent activity.',
            style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF5E5E5E)),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(items.length, (i) {
        final a = items[i];
        return _ActivityTilePro(
          item: a,
          isFirst: i == 0,
          isLast: i == items.length - 1,
          onPayNow: onPayNow,
          onViewPlan: onViewPlan,
          onViewReceipt: onViewReceipt,
          onReviewLink: onReviewLink,
          onEnableAutopay: onEnableAutopay,
        );
      }),
    );
  }
}
