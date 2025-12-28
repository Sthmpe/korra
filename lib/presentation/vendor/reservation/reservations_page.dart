import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/models/vendor/reservation.dart';
import '../../../data/repository/vendors/vendor_repository.dart';
import '../../../logic/bloc/vendor/reservation/reservations_bloc.dart';
import '../../../logic/bloc/vendor/reservation/reservations_event.dart';
import '../../../logic/bloc/vendor/reservation/reservations_state.dart';
import '../../shared/widgets/korra_header.dart';
import 'widgets/reservation_list.dart';
import 'widgets/reservation_search_bar.dart';
import 'widgets/reservation_status_tabs.dart';
import 'widgets/vendor_reservation_detail_sheet.dart';

class ReservationsPage extends StatelessWidget {
  final String vendorId;
  final ReservationStatus initialFilter;
  final VendorRepository vendors;
  final bool showLeadingIcon;

  const ReservationsPage({
    super.key,
    required this.vendorId,
    this.initialFilter = ReservationStatus.ongoing,
    required this.vendors,
    this.showLeadingIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReservationsBloc(
        repo: vendors,
        vendorId: vendorId,
        initial: initialFilter,
      )..add(ResStarted(initialFilter)),
      child: BlocBuilder<ReservationsBloc, ReservationsState>(
        builder: (context, state) {
          final bloc = context.read<ReservationsBloc>(); // 1. Capture the Bloc here

          final query = state.query.toLowerCase();
          final displayList = state.query.isEmpty
              ? state.visible
              : state.visible.where((r) {
                  return r.customerName.toLowerCase().contains(query) ||
                         r.productTitle.toLowerCase().contains(query) ||
                         r.productCode.toLowerCase().contains(query) ||
                         r.id.toLowerCase().contains(query);
                }).toList();

          return Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
            appBar: KorraHeader(title: 'Reservations', showLeadingIcon: showLeadingIcon),
            body: RefreshIndicator(
              onRefresh: () async => bloc.add(const ResRefresh()),
              color: const Color(0xFFA54600), // KorraColors.brand
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  // --- 1. SEARCH ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 12.h),
                      child: ReservationSearchBar(
                        initial: state.query,
                        onChanged: (q) => bloc.add(ResSearchChanged(q)),
                        onClear: () => bloc.add(const ResSearchChanged('')),
                      ),
                    ),
                  ),

                  // --- 2. TABS ---
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

                  // --- 3. LIST ---
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    sliver: ReservationList(
                      loading: state.loading,
                      items: displayList,
                      filter: state.filter,
                      onOpen: (id) {
                        final item = state.visible.firstWhere((e) => e.id == id);
                        
                        // 2. Pass the Bloc to the Sheet using BlocProvider.value
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => BlocProvider.value(
                            value: bloc, // ✅ CRITICAL FIX
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
      ),
    );
  }

  String _formatCount(int count) => count > 99 ? '99+' : count.toString();
}