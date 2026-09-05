import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/models/vendor/reservation.dart';
import '../../../../logic/bloc/vendor/reservation/reservations_bloc.dart';
import '../../../../logic/bloc/vendor/reservation/reservations_event.dart';
import '../../../shared/widgets/date_group_label.dart';
import 'reservation_grid_tile.dart';
import 'reservation_tile.dart'; // Import the new Tile

class ReservationList extends StatelessWidget {
  final bool loading;
  final List<Reservation> items;
  final ReservationStatus filter;
  final Function(String) onOpen;
  final Function(String) onArrangeDelivery;
  final bool grid;

  const ReservationList({
    super.key,
    required this.loading,
    required this.items,
    required this.filter,
    required this.onOpen,
    required this.onArrangeDelivery,
    this.grid = false,
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
              "No orders found",
              style: GoogleFonts.inter(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    if (grid) {
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            mainAxisExtent: 244.h,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = items[index];
              final bloc = context.read<ReservationsBloc>();
              final isSelected = bloc.state.selectedIds.contains(item.id);
              final isSelectionMode = bloc.state.selectedIds.isNotEmpty;
              final isReadyTab = filter == ReservationStatus.readyForPickup;

              return ReservationGridTile(
                reservation: item,
                isSelected: isSelected,
                isSelectionMode: isSelectionMode,
                onTap: () {
                  if (isSelectionMode) {
                    bloc.add(ResToggleSelection(item.id));
                  } else {
                    onOpen(item.id);
                  }
                },
                onLongPress: isReadyTab
                    ? () => bloc.add(ResToggleSelection(item.id))
                    : null,
              );
            },
            childCount: items.length,
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
          final bloc = context.read<ReservationsBloc>();
          final isSelected = bloc.state.selectedIds.contains(item.id);
          final isSelectionMode = bloc.state.selectedIds.isNotEmpty;

          final isReadyTab = filter == ReservationStatus.readyForPickup;

          // Date buckets (list view only — the 2-col grid stays unbroken):
          // Today / Yesterday / Last Week / Last Month / month names.
          final groupLabel = recencyGroupLabel(item.createdAt);
          final showHeader = index == 0 ||
              recencyGroupLabel(items[index - 1].createdAt) != groupLabel;

          final tile = ReservationTile(
            reservation: item,
            isSelected: isSelected,
            isSelectionMode: isSelectionMode,
            onTap: () {
              if (isSelectionMode) {
                bloc.add(ResToggleSelection(item.id));
              } else {
                onOpen(item.id);
              }
            },
            onLongPress: isReadyTab ? () {
              bloc.add(ResToggleSelection(item.id));
            } : null,
          );

          if (!showHeader) return tile;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DateGroupHeader(
                label: groupLabel,
                padding: EdgeInsets.fromLTRB(16.w, index == 0 ? 2.h : 8.h, 16.w, 10.h),
              ),
              tile,
            ],
          );
        },
        childCount: items.length,
      ),
    );
  }
}