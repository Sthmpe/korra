// lib/presentation/vendor/reservation/widgets/reservations_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../data/models/vendor/reservation.dart';
import '../../../../logic/bloc/vendor/reservation/reservations_bloc.dart';
import '../../../../logic/bloc/vendor/reservation/reservations_event.dart';
import '../../../../logic/bloc/vendor/reservation/reservations_state.dart';
import 'reservation_list.dart';
import 'reservation_status_tabs.dart';
import 'vendor_reservation_detail_sheet.dart';

class ReservationsPanel extends StatelessWidget {
  /// View mode owned by the Orders page (its header hosts the toggle).
  final bool grid;

  const ReservationsPanel({super.key, this.grid = false});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ReservationsBloc>();

    return BlocBuilder<ReservationsBloc, ReservationsState>(
      buildWhen: (previous, current) {
        if (previous.loading != current.loading) return true;
        if (previous.filter != current.filter) return true;
        if (previous.query != current.query) return true;
        if (previous.countNew != current.countNew) return true;
        if (previous.countOngoing != current.countOngoing) return true;
        if (previous.countReady != current.countReady) return true;
        if (previous.countCompleted != current.countCompleted) return true;
        if (previous.countCancelled != current.countCancelled) return true;
        // Selection changes must re-render the tiles (green fill + check circle).
        if (!identical(previous.selectedIds, current.selectedIds)) return true;
        if (previous.visible.length != current.visible.length) return true;
        for (int i = 0; i < previous.visible.length; i++) {
          if (previous.visible[i] != current.visible[i]) return true;
        }
        return false;
      },
      builder: (context, state) {
        final query = state.query.toLowerCase();
        final displayList = state.query.isEmpty
            ? state.visible
            : state.visible.where((r) {
                return r.customerName.toLowerCase().contains(query) ||
                       r.productTitle.toLowerCase().contains(query) ||
                       r.productCode.toLowerCase().contains(query) ||
                       r.id.toLowerCase().contains(query);
              }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            bloc.add(const ResRefresh());
            try {
              await bloc.stream
                  .firstWhere((s) => !s.loading)
                  .timeout(const Duration(seconds: 10));
            } catch (_) {}
          },
          color: const Color(0xFFA54600),
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                bloc.add(const ResLoadMore());
              }
              return false;
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                // Spacer above tabs
                SliverToBoxAdapter(child: SizedBox(height: 12.h)),

                // 2. Status Filter Tabs
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: ReservationStatusTabs(
                      current: state.filter,
                      newCount: _formatCount(state.countNew),
                      ongoingCount: _formatCount(state.countOngoing),
                      readyCount: _formatCount(state.countReady),
                      completedCount: _formatCount(state.countCompleted),
                      cancelledCount: _formatCount(state.countCancelled),
                      onChanged: (st) => bloc.add(ResChangeFilter(st)),
                    ),
                  ),
                ),

                // 3. List
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  sliver: ReservationList(
                    loading: state.loading,
                    items: displayList,
                    grid: grid,
                    filter: state.filter,
                    onOpen: (id) {
                      final item = state.visible.firstWhere((e) => e.id == id);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => BlocProvider.value(
                          value: bloc,
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.85,
                            child: VendorReservationDetailSheet(data: item),
                          ),
                        ),
                      );
                    },
                    onArrangeDelivery: (id) {},
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 100.h)),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatCount(int count) => count > 99 ? '99+' : count.toString();
}
