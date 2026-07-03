// lib/presentation/vendor/reservation/widgets/outright_orders_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../config/constants/colors.dart';
import '../../../../data/models/vendor/outright_order.dart';
import '../../../../logic/bloc/vendor/outright_order/outright_orders_bloc.dart';
import '../../../../logic/bloc/vendor/outright_order/outright_orders_event.dart';
import '../../../../logic/bloc/vendor/outright_order/outright_orders_state.dart';
import 'outright_order_detail_sheet.dart';
import 'outright_order_list.dart';

class OutrightOrdersPanel extends StatelessWidget {
  const OutrightOrdersPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OutrightOrdersBloc>();

    return BlocBuilder<OutrightOrdersBloc, OutrightOrdersState>(
      buildWhen: (previous, current) {
        if (previous.loading != current.loading) return true;
        if (previous.filter != current.filter) return true;
        if (previous.query != current.query) return true;
        if (previous.countPending != current.countPending) return true;
        if (previous.countReadyToDeliver != current.countReadyToDeliver) return true;
        if (previous.countDelivered != current.countDelivered) return true;
        if (previous.countCancelled != current.countCancelled) return true;
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
            : state.visible.where((o) {
                // Search by customer name, order ID, or product titles
                final matchesCustomer = o.customerName.toLowerCase().contains(query);
                final matchesId = o.id.toLowerCase().contains(query);
                final matchesProducts = o.items.any((item) => item.title.toLowerCase().contains(query));
                return matchesCustomer || matchesId || matchesProducts;
              }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            bloc.add(const OutrightOrdersRefresh());
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
                bloc.add(const OutrightOrdersLoadMore());
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
                    child: _OutrightStatusTabs(
                      current: state.filter,
                      pendingCount: _formatCount(state.countPending),
                      readyCount: _formatCount(state.countReadyToDeliver),
                      deliveredCount: _formatCount(state.countDelivered),
                      cancelledCount: _formatCount(state.countCancelled),
                      onChanged: (st) => bloc.add(OutrightOrdersChangeFilter(st)),
                    ),
                  ),
                ),

                // 3. List
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  sliver: OutrightOrderList(
                    loading: state.loading,
                    items: displayList,
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
                            child: OutrightOrderDetailSheet(order: item),
                          ),
                        ),
                      );
                    },
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

class _OutrightStatusTabs extends StatelessWidget {
  final OutrightOrderStatus current;
  final String pendingCount;
  final String readyCount;
  final String deliveredCount;
  final String cancelledCount;
  final Function(OutrightOrderStatus) onChanged;

  const _OutrightStatusTabs({
    required this.current,
    required this.pendingCount,
    required this.readyCount,
    required this.deliveredCount,
    required this.cancelledCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // 1. Ready to Deliver (High Priority - Green/Orange)
          _Tab(
            label: "Ready to Deliver",
            count: readyCount,
            isActive: current == OutrightOrderStatus.readyToDeliver,
            onTap: () => onChanged(OutrightOrderStatus.readyToDeliver),
            activeColor: const Color(0xFF027A48),
          ),
          
          // 2. New (Pending)
          _Tab(
            label: "New",
            count: pendingCount,
            isActive: current == OutrightOrderStatus.pending,
            onTap: () => onChanged(OutrightOrderStatus.pending),
          ),

          // 3. Delivered
          _Tab(
            label: "Delivered",
            count: deliveredCount,
            isActive: current == OutrightOrderStatus.delivered,
            onTap: () => onChanged(OutrightOrderStatus.delivered),
          ),

          // 4. Cancelled
          _Tab(
            label: "Cancelled",
            count: cancelledCount,
            isActive: current == OutrightOrderStatus.cancelled,
            onTap: () => onChanged(OutrightOrderStatus.cancelled),
          ),
          
          SizedBox(width: 16.w),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final String count;
  final bool isActive;
  final VoidCallback onTap;
  final Color? activeColor;
  final Color? activeBg;

  const _Tab({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
    this.activeColor,
    this.activeBg,
  });

  @override
  Widget build(BuildContext context) {
    final mainColor = activeColor ?? KorraColors.brand;
    final bg = isActive ? (activeBg ?? mainColor) : Colors.transparent;
    final textCol = isActive ? (activeBg != null ? mainColor : Colors.white) : Colors.grey.shade600;
    final borderCol = isActive ? mainColor : Colors.grey.shade300;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: borderCol),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: textCol,
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
              ),
            ),
            if (count != '0') ...[
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isActive
                      ? (activeBg != null ? mainColor.withValues(alpha: 0.1) : Colors.white.withOpacity(0.2))
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  count,
                  style: GoogleFonts.inter(
                    color: isActive ? mainColor : Colors.grey.shade700,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
