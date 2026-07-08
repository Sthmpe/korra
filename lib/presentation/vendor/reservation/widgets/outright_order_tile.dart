// lib/presentation/vendor/reservation/widgets/outright_order_tile.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../config/constants/colors.dart';
import '../../../../data/models/vendor/outright_order.dart';

class OutrightOrderTile extends StatelessWidget {
  final OutrightOrder order;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isSelectionMode;

  const OutrightOrderTile({
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
    final extraItemsCount = order.items.length - 1;
    final displayTitle = firstItem != null
        ? (extraItemsCount > 0
            ? "${firstItem.title} +$extraItemsCount more"
            : firstItem.title)
        : 'Outright Order';

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h, left: 16.w, right: 16.w),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF1DB954) : const Color(0xFFF2F4F7),
            width: isSelected ? 0.001 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF101828).withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Image Container (with potential count overlay)
                _buildImage(firstItem, extraItemsCount),
                SizedBox(width: 12.w),

                // 2. Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order.id.substring(0, 8).toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: KorraColors.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (isSelectionMode)
                            Container(
                              margin: EdgeInsets.only(right: 4.w),
                              width: 22.w,
                              height: 22.w,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF1DB954) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF1DB954) : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                              child: isSelected
                                  ? Icon(Icons.check, size: 16.sp, color: Colors.white)
                                  : null,
                            )
                          else
                            _buildStatusBadge(),
                        ],
                      ),
                      SizedBox(height: 4.h),

                      // Order Title
                      Text(
                        displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: KorraColors.text,
                        ),
                      ),
                      SizedBox(height: 2.h),

                      // Customer Name
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 12.sp, color: Colors.grey),
                          SizedBox(width: 4.w),
                          Text(
                            order.customerName,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: const Color(0xFF475467),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12.h),
            const Divider(height: 1, color: Color(0xFFF2F4F7)),
            SizedBox(height: 12.h),

            // 3. Progress / Status & Price Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: const Color(0xFF027A48), size: 14.sp),
                    SizedBox(width: 4.w),
                    Text(
                      "Paid Outright",
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF027A48),
                      ),
                    ),
                  ],
                ),
                Text(
                  order.totalText,
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: KorraColors.text,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(OutrightOrderItem? item, int extraCount) {
    final hasImage = item != null && item.imageUrl.isNotEmpty;
    return Stack(
      children: [
        Container(
          width: 64.w,
          height: 64.w,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFF2F4F7)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11.r),
            child: hasImage
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(Icons.image_outlined, color: Colors.grey),
                  )
                : const Icon(Icons.inventory_2_outlined, color: Colors.grey),
          ),
        ),
        if (extraCount > 0)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6.r),
                  bottomRight: Radius.circular(11.r),
                ),
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
      ],
    );
  }

  Widget _buildStatusBadge() {
    String text;
    Color bg;
    Color fg;

    switch (order.status) {
      case OutrightOrderStatus.pending:
        text = "New";
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        break;
      case OutrightOrderStatus.readyToDeliver:
        text = "Ready to Deliver";
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFB95000);
        break;
      case OutrightOrderStatus.delivered:
        text = "Delivered";
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        break;
      case OutrightOrderStatus.cancelled:
        text = "Cancelled";
        bg = const Color(0xFFFEF3F2);
        fg = const Color(0xFFB42318);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: bg.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
