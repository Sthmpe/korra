// lib/presentation/vendor/reservation/widgets/outright_order_list.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/vendor/outright_order.dart';
import '../../../../logic/bloc/vendor/outright_order/outright_orders_bloc.dart';
import '../../../../logic/bloc/vendor/outright_order/outright_orders_event.dart';
import '../../../shared/widgets/date_group_label.dart';
import 'outright_order_grid_tile.dart';
import 'outright_order_tile.dart';

class OutrightOrderList extends StatelessWidget {
  final bool loading;
  final List<OutrightOrder> items;
  final Function(String) onOpen;
  final bool grid;

  /// False when this sliver is one segment of a split list (e.g. the paid
  /// segment above the Awaiting Payment section) so an empty segment renders
  /// nothing instead of the full-screen empty state.
  final bool showEmpty;

  const OutrightOrderList({
    super.key,
    required this.loading,
    required this.items,
    required this.onOpen,
    this.grid = false,
    this.showEmpty = true,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isEmpty && !showEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    if (items.isEmpty) {
      return SliverFillRemaining(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48.sp, color: Colors.grey.shade300),
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
            mainAxisExtent: 218.h,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = items[index];
              final bloc = context.read<OutrightOrdersBloc>();
              final isSelected = bloc.state.selectedIds.contains(item.id);
              final isSelectionMode = bloc.state.selectedIds.isNotEmpty;
              final canSelect =
                  (item.isPending || item.isReadyToDeliver) && !item.isAwaitingPayment;

              return OutrightOrderGridTile(
                order: item,
                isSelected: isSelected,
                isSelectionMode: isSelectionMode,
                onTap: () {
                  if (isSelectionMode && canSelect) {
                    bloc.add(OutrightToggleSelection(item.id));
                    return;
                  }
                  if (!isSelectionMode) onOpen(item.id);
                },
                onLongPress: canSelect
                    ? () => bloc.add(OutrightToggleSelection(item.id))
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
          final bloc = context.read<OutrightOrdersBloc>();
          final isSelected = bloc.state.selectedIds.contains(item.id);
          final isSelectionMode = bloc.state.selectedIds.isNotEmpty;

          // Only New (pending) and Ready-to-Deliver orders can be bulk-delivered.
          // Delivered/cancelled orders are never selectable.
          final canSelect = item.isPending || item.isReadyToDeliver;

          // Date buckets (list view only — the 2-col grid stays unbroken):
          // Today / Yesterday / Last Week / Last Month / month names.
          final groupLabel = recencyGroupLabel(item.createdAt);
          final showHeader = index == 0 ||
              recencyGroupLabel(items[index - 1].createdAt) != groupLabel;

          final tile = OutrightOrderTile(
            order: item,
            isSelected: isSelected,
            isSelectionMode: isSelectionMode,
            onTap: () {
              if (isSelectionMode && canSelect) {
                bloc.add(OutrightToggleSelection(item.id));
                return;
              }
              // In selection mode, tapping an ineligible order does nothing;
              // otherwise open its details.
              if (!isSelectionMode) onOpen(item.id);
            },
            // Long-press starts selection only on eligible orders.
            onLongPress: canSelect
                ? () => bloc.add(OutrightToggleSelection(item.id))
                : null,
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
