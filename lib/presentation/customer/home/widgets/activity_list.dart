// lib/presentation/customer/home/widgets/activity_list.dart
import 'package:flutter/widgets.dart';

import '../../../../data/models/customer/activity_item.dart';
import 'activity_tile.dart';

class ActivityList extends StatelessWidget {
  final List<ActivityItem> items;

  // optional callbacks by type
  final void Function(ActivityItem)? onPayNow;
  final void Function(ActivityItem)? onViewPlan;
  final void Function(ActivityItem)? onViewReceipt;
  final void Function(ActivityItem)? onReviewLink;
  final void Function(ActivityItem)? onEnableAutopay;

  const ActivityList({
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
    return Column(
      children: items.map((a) {
        return ActivityTile(
          item: a,
          onPayNow: onPayNow,
          onViewPlan: onViewPlan,
          onViewReceipt: onViewReceipt,
          onReviewLink: onReviewLink,
          onEnableAutopay: onEnableAutopay,
        );
      }).toList(),
    );
  }
}
