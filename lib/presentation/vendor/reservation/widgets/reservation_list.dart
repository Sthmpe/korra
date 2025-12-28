import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/models/vendor/reservation.dart';
import 'reservation_tile.dart'; // Import the new Tile

class ReservationList extends StatelessWidget {
  final bool loading;
  final List<Reservation> items;
  final ReservationStatus filter;
  final Function(String) onOpen;
  final Function(String) onArrangeDelivery;

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
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isEmpty) {
      return SliverFillRemaining(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.box_remove, size: 48.sp, color: Colors.grey.shade300),
            SizedBox(height: 16.h),
            Text(
              "No reservations found",
              style: GoogleFonts.inter(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
          // ✅ FIX: Pass the 'reservation' argument here
          return ReservationTile(
            reservation: item, 
            onTap: () => onOpen(item.id),
          );
        },
        childCount: items.length,
      ),
    );
  }
}