import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../../config/constants/colors.dart';
import '../../../../data/models/vendor/reservation.dart';

class ReservationTile extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onTap;

  const ReservationTile({
    super.key,
    required this.reservation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h, left: 16.w, right: 16.w),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF101828).withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFF2F4F7)),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Premium Image Container
                _buildImage(),
                SizedBox(width: 12.w),

                // 2. Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: ID and Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              reservation.id.substring(0, 8),
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: KorraColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          _buildStatusBadge(),
                        ],
                      ),
                      SizedBox(height: 4.h),

                      // Product Title
                      Text(
                        reservation.productTitle,
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
                          Icon(Iconsax.user, size: 12.sp, color: Colors.grey),
                          SizedBox(width: 4.w),
                          Text(
                            reservation.customerName,
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

            // 3. Progress & Money Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Progress Bar
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${reservation.progress}% Paid",
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: reservation.progress01,
                          minHeight: 6.h,
                          backgroundColor: const Color(0xFFF2F4F7),
                          valueColor: AlwaysStoppedAnimation(_getStatusColor()),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),

                // Money Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      reservation.paidText,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: KorraColors.text,
                      ),
                    ),
                    Text(
                      "of ${reservation.totalText}",
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: KorraColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: 64.w,
      height: 64.w,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFF2F4F7)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11.r),
        child: reservation.imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: reservation.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(Iconsax.image, color: Colors.grey),
              )
            : const Icon(Iconsax.box, color: Colors.grey),
      ),
    );
  }

  Widget _buildStatusBadge() {
    String text;
    Color bg;
    Color fg;

    switch (reservation.status) {
      case ReservationStatus.newRes:
        text = "New";
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        break;
      case ReservationStatus.ongoing:
        text = "Active";
        bg = const Color(0xFFECFDF3); // Success-50
        fg = const Color(0xFF027A48); // Success-700
        break;
      case ReservationStatus.readyForPickup:
        text = "Ready";
        bg = const Color(0xFFFFF7ED); // Orange/Cream
        fg = const Color(0xFFB95000);
        break;
      case ReservationStatus.completed:
        text = "Completed";
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        break;
      case ReservationStatus.cancelled:
        text = "Closed";
        bg = const Color(0xFFFEF3F2); // Error-50
        fg = const Color(0xFFB42318); // Error-700
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: bg.withOpacity(0.5)), // Subtle border
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

  Color _getStatusColor() {
    if (reservation.status == ReservationStatus.cancelled) return Colors.red;
    if (reservation.status == ReservationStatus.completed) return Colors.grey;
    return KorraColors.brand;
  }
}