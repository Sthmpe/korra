import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Ensure you have intl or use custom formatter
// Update these imports to match your project structure
import '../../../../data/models/customer/activity_item.dart';

part 'activity_tile_pro.dart';

class ActivityTimeline extends StatelessWidget {
  final List<ActivityItem> items;

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
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Text(
          'No recent activity.',
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _ActivityTilePro(
          item: items[index],
          isFirst: index == 0,
          isLast: index == items.length - 1,
          onPayNow: onPayNow,
          onViewPlan: onViewPlan,
          onViewReceipt: onViewReceipt,
        );
      },
    );
  }
}