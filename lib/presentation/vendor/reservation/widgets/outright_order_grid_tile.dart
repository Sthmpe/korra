import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/constants/colors.dart';
import '../../../../data/models/vendor/outright_order.dart';

/// Compact 2-column grid version of an outright order: first item's image
/// (with a +N badge for multi-item orders) and the status pill, title,
/// customer and the total paid. Tap opens the detail sheet; long-press keeps
/// the same selection eligibility as the list tile.
class OutrightOrderGridTile extends StatelessWidget {
  final OutrightOrder order;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isSelectionMode;

  const OutrightOrderGridTile({
    super.key,
    required this.order,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final extraCount = order.items.length - 1;
    final displayTitle = firstItem != null
        ? (extraCount > 0 ? "${firstItem.title} +$extraCount more" : firstItem.title)
        : 'Outright Order';
    final hasImage = firstItem != null && firstItem.imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF1DB954) : const Color(0xFFF2F4F7),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF101828).withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- IMAGE + STATUS PILL (+ item count / selection check) ---
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  hasImage
                      ? CachedNetworkImage(
                          imageUrl: firstItem.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFFF9FAFB),
                            child: const Icon(Icons.image_outlined,
                                color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF9FAFB),
                          child: const Icon(Icons.inventory_2_outlined,
                              color: Colors.grey),
                        ),
                  Positioned(
                    left: 8.w,
                    top: 8.h,
                    child: Row(
                      children: [
                        _statusBadge(),
                        if (order.webPurchase) ...[
                          SizedBox(width: 4.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF8FF).withOpacity(0.95),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              "WEB",
                              style: GoogleFonts.inter(
                                fontSize: 8.5.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: const Color(0xFF175CD3),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (extraCount > 0)
                    Positioned(
                      right: 8.w,
                      bottom: 8.h,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          "+$extraCount",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  if (isSelectionMode)
                    Positioned(
                      right: 8.w,
                      top: 8.h,
                      child: Container(
                        width: 22.w,
                        height: 22.w,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1DB954) : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1DB954)
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? Icon(Icons.check, size: 14.sp, color: Colors.white)
                            : null,
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
                    displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: KorraColors.text,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    order.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475467),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(
                          order.isAwaitingPayment
                              ? Icons.hourglass_top_rounded
                              : Icons.check_circle_rounded,
                          color: order.isAwaitingPayment
                              ? const Color(0xFFB95000)
                              : const Color(0xFF027A48),
                          size: 12.sp),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          order.totalText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w800,
                            color: KorraColors.text,
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

  Widget _statusBadge() {
    final String text;
    final Color bg;
    final Color fg;

    switch (order.status) {
      case OutrightOrderStatus.awaitingPayment:
        text = 'UNPAID';
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFB95000);
        break;
      case OutrightOrderStatus.pending:
        text = 'NEW';
        bg = const Color(0xFFEFF8FF);
        fg = const Color(0xFF175CD3);
        break;
      case OutrightOrderStatus.readyToDeliver:
        text = 'READY';
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFB95000);
        break;
      case OutrightOrderStatus.delivered:
        text = 'DELIVERED';
        bg = const Color(0xFFF2F4F7);
        fg = const Color(0xFF475467);
        break;
      case OutrightOrderStatus.cancelled:
        text = 'CANCELLED';
        bg = const Color(0xFFFEF3F2);
        fg = const Color(0xFFB42318);
        break;
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
