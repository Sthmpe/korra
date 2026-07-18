import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/utils/currency_formatters.dart';
import '../../../../data/models/customer/plans.dart';

/// Compact 2-column grid version of a plan card: image with a status pill,
/// title, store, slim progress bar and the amount left. Tap anywhere opens
/// plan details (where the full breakdown and actions live); active plans
/// keep a small Pay chip.
class PlanCardGrid extends StatelessWidget {
  final Plan plan;
  final VoidCallback onPayNow;
  final VoidCallback onView;

  const PlanCardGrid({
    super.key,
    required this.plan,
    required this.onPayNow,
    required this.onView,
  });

  static const _brand = Color(0xFFA54600);

  // Remaining balance always rounds UP so the customer never underpays by
  // a kobo (same rule as the list card).
  double get _remaining {
    final amount = plan.amountRemaining;
    if (amount == 0) return 0;
    return (amount * 100).ceil() / 100;
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = plan.status == 'completed';
    final bool isCancelled = plan.status == 'cancelled';
    final bool isPending =
        plan.status == 'pending' || plan.status == 'pending_approval';
    final bool isOverdue = plan.isOverdue && !isCompleted && !isCancelled;
    final bool payable = !isCompleted && !isCancelled && !isPending;

    return GestureDetector(
      onTap: onView,
      behavior: HitTestBehavior.opaque,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- IMAGE + STATUS PILL ---
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: plan.imageUrls.isNotEmpty ? plan.imageUrls.first : '',
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade100,
                      child: Icon(Iconsax.image, size: 22.sp, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    left: 8.w,
                    top: 8.h,
                    child: _StatusPill(
                      isOverdue: isOverdue,
                      isPending: isPending,
                      isCompleted: isCompleted,
                      isCancelled: isCancelled,
                    ),
                  ),
                ],
              ),
            ),

            // --- CONTENT ---
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1B1B),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    plan.storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Slim progress bar + %
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: (plan.progressPercent.clamp(0, 100)) / 100.0,
                            minHeight: 5.h,
                            backgroundColor: const Color(0xFFF0F0F0),
                            valueColor: AlwaysStoppedAnimation(
                              isOverdue ? const Color(0xFFD92D20) : _brand,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '${plan.progressPercent.toInt()}%',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  // Amount left + Pay chip
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isCompleted || isCancelled
                              ? formatToCurrency(plan.totalAmount)
                              : '${formatToCurrency(_remaining)} left',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1B1B1B),
                          ),
                        ),
                      ),
                      if (payable)
                        GestureDetector(
                          onTap: onPayNow,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 5.h),
                            decoration: BoxDecoration(
                              color: _brand,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              'Pay',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
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
}

class _StatusPill extends StatelessWidget {
  final bool isOverdue;
  final bool isPending;
  final bool isCompleted;
  final bool isCancelled;

  const _StatusPill({
    required this.isOverdue,
    required this.isPending,
    required this.isCompleted,
    required this.isCancelled,
  });

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color bg;
    final Color fg;

    if (isOverdue) {
      text = 'OVERDUE';
      bg = const Color(0xFFFEF3F2);
      fg = const Color(0xFFB42318);
    } else if (isPending) {
      text = 'PENDING';
      bg = const Color(0xFFFFFAEB);
      fg = const Color(0xFFB54708);
    } else if (isCompleted) {
      text = 'COMPLETED';
      bg = const Color(0xFFECFDF3);
      fg = const Color(0xFF027A48);
    } else if (isCancelled) {
      text = 'CLOSED';
      bg = const Color(0xFFF2F4F7);
      fg = const Color(0xFF475467);
    } else {
      text = 'ACTIVE';
      bg = const Color(0xFFECFDF3);
      fg = const Color(0xFF027A48);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.95),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 8.5.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: fg,
        ),
      ),
    );
  }
}
