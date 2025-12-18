import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart'; // Ensure GetX is imported for dialogs

import '../../../data/models/vendor/vendor_reservation.dart';
import '../../../data/repository/vendors/vendor_reservations_repository.dart';
import '../../../logic/bloc/vendor/reservation/vendor_reservations_bloc.dart';
import '../../../logic/bloc/vendor/reservation/vendor_reservations_event.dart';
import '../../../logic/bloc/vendor/reservation/vendor_reservations_state.dart';
import '../../shared/widgets/korra_header.dart';
import 'widgets/reservation_list.dart';
import 'widgets/reservation_search_bar.dart';
import 'widgets/reservation_status_tabs.dart';
import 'widgets/vendor_reservation_detail_sheet.dart';

class VendorReservationsPage extends StatelessWidget {
  final String vendorId; // ✅ Added required ID
  final ReservationStatus initialFilter;

  const VendorReservationsPage({
    super.key,
    required this.vendorId, // ✅ Required
    this.initialFilter = ReservationStatus.ongoing,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VendorReservationsBloc(
        repo: VendorReservationsRepository(vendorId: vendorId),
        initial: initialFilter,
      )..add(VResStarted(initialFilter)),
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
                  // Search bar
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
                  // Tabs
                  SliverToBoxAdapter(
                    child: ReservationStatusTabs(
                      current: s.filter,
                      // ✅ format counts correctly
                      newCount: _formatCount(s.countNew),
                      ongoingCount: _formatCount(s.countOngoing),
                      completedCount: _formatCount(s.countCompleted),
                      cancelledCount: _formatCount(s.countCancelled),
                      onChanged: (st) => bloc.add(VResChangeFilter(st)),
                    ),
                  ),
                  // List
                  ReservationList(
                    loading: s.loading,
                    items: s.visible,
                    filter: s.filter,
                    onOpen: (id) {
                       final item = s.visible.firstWhere((e) => e.id == id);
    
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true, // Allows sheet to be tall
                        backgroundColor: Colors.transparent,
                        builder: (_) => SizedBox(
                          height: 600.h, // Fixed height or flexible
                          child: VendorReservationDetailSheet(data: item),
                        ),
                      );
                    },
                    onArrangeDelivery: (id) {
                       // ✅ Just show a prompt, no complex logic
                       Get.defaultDialog(
                         title: "Arranging Delivery",
                         middleText: "Please contact the customer to arrange delivery.",
                         textConfirm: "Okay",
                         confirmTextColor: Colors.white,
                         onConfirm: () => Get.back(),
                       );
                    },
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

  String _formatCount(int count) => count > 99 ? '99+' : count.toString();
}