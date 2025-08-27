import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/vendor/vendor_reservation.dart';
import 'reservation_tile.dart';

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
          child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
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
          padding: EdgeInsets.all(16.r),
          child: Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFEAE6E2)),
            ),
            child: Text(emptyText,
              style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF5E5E5E))),
          ),
        ),
      );
    }

    return SliverList.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: 16.h), // extra gap between cards
      itemBuilder: (_, i) {
        final r = items[i];
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: ReservationTile(
            data: r,
            onTap: () => onOpen(r.id),                   // ← FIX: pass onTap
            onArrangeDelivery: () => onArrangeDelivery(r.id),
          ),
        );
      },
    );
  }
}
