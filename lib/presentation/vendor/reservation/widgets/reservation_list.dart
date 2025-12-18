import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/vendor/vendor_reservation.dart';
import 'reservation_tile.dart'; // Ensure you have this tile widget

class ReservationList extends StatelessWidget {
  final bool loading;
  final List<VendorReservation> items;
  final ReservationStatus filter;
  final void Function(String id) onOpen;
  final void Function(String id) onArrangeDelivery;

  const ReservationList({
    super.key,
    required this.loading,
    required this.items,
    required this.filter,
    required this.onOpen,
    required this.onArrangeDelivery,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(22),
          child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFA54600)))),
        ),
      );
    }

    if (items.isEmpty) {
      final emptyText = switch (filter) {
        ReservationStatus.newRes      => 'No new reservations yet.',
        ReservationStatus.ongoing     => 'No ongoing reservations.',
        ReservationStatus.completed   => 'No completed reservations.',
        ReservationStatus.cancelled   => 'No cancelled reservations.',
      };
      
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.inbox_rounded, size: 40.sp, color: Colors.grey.shade300),
                SizedBox(height: 8.h),
                Text(emptyText, style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF5E5E5E))),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (_, i) {
        final r = items[i];
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: ReservationTile(
            data: r,
            onTap: () => onOpen(r.id),
            onArrangeDelivery: () => onArrangeDelivery(r.id),
          ),
        );
      },
    );
  }
}