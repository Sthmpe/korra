import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../data/models/vendor/reservation.dart';

/// Compact 2-column grid version of a reservation: product image with the
/// status pill overlaid, title, customer, progress bar and paid-of-total.
/// Tap opens the detail sheet; long-press keeps the same selection behavior
/// as the list tile.
class ReservationGridTile extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isSelectionMode;

  const ReservationGridTile({
    super.key,
    required this.reservation,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
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
            // --- IMAGE + STATUS PILL (+ selection check) ---
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  reservation.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: reservation.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFFF9FAFB),
                            child: const Icon(Iconsax.image, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF9FAFB),
                          child: const Icon(Iconsax.box, color: Colors.grey),
                        ),
                  Positioned(left: 8.w, top: 8.h, child: _statusBadge()),
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
                    reservation.displayTitle,
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
                    reservation.customerName,
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
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: reservation.progress01,
                            minHeight: 5.h,
                            backgroundColor: const Color(0xFFF2F4F7),
                            valueColor: AlwaysStoppedAnimation(_statusColor()),
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '${reservation.progress}%',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          reservation.paidText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: KorraColors.text,
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'of ${reservation.totalText}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: KorraColors.textMuted,
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

    switch (reservation.status) {
      case ReservationStatus.newRes:
        text = 'NEW';
        bg = const Color(0xFFEFF8FF);
        fg = const Color(0xFF175CD3);
        break;
      case ReservationStatus.ongoing:
        text = 'ACTIVE';
        bg = const Color(0xFFECFDF3);
        fg = const Color(0xFF027A48);
        break;
      case ReservationStatus.readyForPickup:
        text = 'READY';
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFB95000);
        break;
      case ReservationStatus.completed:
        text = 'DELIVERED';
        bg = const Color(0xFFF2F4F7);
        fg = const Color(0xFF475467);
        break;
      case ReservationStatus.cancelled:
        text = 'CLOSED';
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

  Color _statusColor() {
    if (reservation.status == ReservationStatus.cancelled) return Colors.red;
    if (reservation.status == ReservationStatus.completed) return Colors.grey;
    return KorraColors.brand;
  }
}
