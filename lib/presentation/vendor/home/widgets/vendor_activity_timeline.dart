import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/vendor/vendor_activity_type.dart';

// Import the new model
// import 'path/to/vendor_activity_item.dart';

class VendorActivityTimeline extends StatelessWidget {
  final List<VendorActivityItem> items;
  
  // Callbacks for navigation logic
  final Function(VendorActivityItem)? onOpenReservation;
  final Function(VendorActivityItem)? onAdjustStock;
  final Function(VendorActivityItem)? onViewPlan;

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
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Center(
          child: Text("No recent activity", style: GoogleFonts.inter(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _VendorActivityTile(
          item: item,
          onTap: () => _handleNavigation(item),
        );
      },
    );
  }

  void _handleNavigation(VendorActivityItem item) {
    switch (item.type) {
      case VendorActivityType.newReservation:
      case VendorActivityType.cancelled:
        if (onOpenReservation != null) onOpenReservation!(item);
        break;
      case VendorActivityType.stockLow:
        if (onAdjustStock != null) onAdjustStock!(item);
        break;
      case VendorActivityType.planCompleted:
        if (onViewPlan != null) onViewPlan!(item);
        break;
      default:
        break; // Payouts usually don't need detailed nav here
    }
  }
}

class _VendorActivityTile extends StatelessWidget {
  final VendorActivityItem item;
  final VoidCallback onTap;

  const _VendorActivityTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = _getStyleForType(item.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Icon Container
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: style.bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(style.icon, size: 20.sp, color: style.iconColor),
            ),
            SizedBox(width: 14.w),

            // 2. Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF101828),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Time
                      Text(
                        _formatTime(item.date),
                        style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  
                  // Subtitle & Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.subtitle,
                          style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.amountDisplay != null) ...[
                        SizedBox(width: 8.w),
                        Text(
                          item.amountDisplay!,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: style.iconColor, // Match icon color for impact
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return DateFormat('MMM d').format(date);
  }

  _ActivityStyle _getStyleForType(VendorActivityType type) {
    switch (type) {
      case VendorActivityType.newReservation:
        return _ActivityStyle(Iconsax.receipt_item, const Color(0xFF16A34A), const Color(0xFFECFDF5)); // Green
      case VendorActivityType.payout:
        return _ActivityStyle(Iconsax.bank, const Color(0xFF175CD3), const Color(0xFFEFF6FF)); // Blue
      case VendorActivityType.stockLow:
        return _ActivityStyle(Iconsax.box, const Color(0xFFF79009), const Color(0xFFFFFAEB)); // Orange
      case VendorActivityType.planCompleted:
        return _ActivityStyle(Iconsax.tick_circle, const Color(0xFF7A5AF8), const Color(0xFFF9F5FF)); // Purple
      case VendorActivityType.cancelled:
        return _ActivityStyle(Iconsax.close_circle, const Color(0xFFB42318), const Color(0xFFFEF3F2)); // Red
      default:
        return _ActivityStyle(Iconsax.notification, Colors.grey.shade700, Colors.grey.shade100);
    }
  }
}

class _ActivityStyle {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  _ActivityStyle(this.icon, this.iconColor, this.bgColor);
}