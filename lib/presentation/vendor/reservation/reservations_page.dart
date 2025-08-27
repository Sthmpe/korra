// ...imports unchanged...

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/models/vendor/vendor_reservation.dart';
import '../../../data/repository/vendors/vendor_reservations_repository.dart';
import '../../../logic/bloc/vendor/reservation/vendor_reservations_bloc.dart';
import '../../../logic/bloc/vendor/reservation/vendor_reservations_event.dart';
import '../../../logic/bloc/vendor/reservation/vendor_reservations_state.dart';
import '../../shared/widgets/korra_header.dart';
import 'widgets/reservation_list.dart';
import 'widgets/reservation_search_bar.dart';
import 'widgets/reservation_status_tabs.dart';

class VendorReservationsPage extends StatelessWidget {
  const VendorReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VendorReservationsBloc(
        DemoVendorReservationsRepository(),
        repo: DemoVendorReservationsRepository(),
        initial: ReservationStatus.ongoing,
      )..add(const VResStarted(ReservationStatus.ongoing)),
      child: BlocBuilder<VendorReservationsBloc, VendorReservationsState>(
        builder: (context, s) {
          final bloc = context.read<VendorReservationsBloc>();
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: const KorraHeader(title: 'Reservations'),
            body: RefreshIndicator(
              onRefresh: () async => bloc.add(const VResRefresh()),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Search bar (keep)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 6.h),
                      child: ReservationSearchBar(
                        initial: s.query,
                        onChanged: (q) => bloc.add(VResSearchChanged(q)),
                        onClear: () => bloc.add(const VResSearchChanged('')),
                      ),
                    ),
                  ),
                  // Tabs (now with explicit counts)
                  SliverToBoxAdapter(
                    child: ReservationStatusTabs(
                      current: s.filter,
                      newCount: s.countNew,
                      ongoingCount: s.countOngoing,
                      completedCount: s.countCompleted,
                      cancelledCount: s.countCancelled,
                      onChanged: (st) => bloc.add(VResChangeFilter(st)),
                    ),
                  ),
                  // List
                  ReservationList(
                    loading: s.loading,
                    items: s.visible,
                    filter: s.filter,
                    onOpen: (id) => bloc.add(VResOpen(id)),
                    onArrangeDelivery: (id) => bloc.add(VResArrangeDelivery(id)),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 18.h)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
