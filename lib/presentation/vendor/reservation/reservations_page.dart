import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final bool showLeadingIcon;

  const ReservationsPage({
    super.key,
    required this.vendorId,
    this.initialFilter = ReservationStatus.ongoing,
    this.showLeadingIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final vendors = context.read<VendorRepository>();
    return BlocProvider(
      create: (_) => ReservationsBloc(
        repo: vendors,
        vendorId: vendorId,
        initial: initialFilter,
      )..add(ResStarted(initialFilter)),
      child: BlocBuilder<ReservationsBloc, ReservationsState>(
        buildWhen: (previous, current) {
          if (previous.loading != current.loading) return true;
          if (previous.filter != current.filter) return true;
          if (previous.query != current.query) return true;
          if (previous.errorMessage != current.errorMessage) return true;
          if (previous.countNew != current.countNew) return true;
          if (previous.countOngoing != current.countOngoing) return true;
          if (previous.countReady != current.countReady) return true;
          if (previous.countCompleted != current.countCompleted) return true;
          if (previous.countCancelled != current.countCancelled) return true;
          if (previous.verificationStatus != current.verificationStatus) return true;
          
          if (previous.visible.length != current.visible.length) return true;
          for (int i = 0; i < previous.visible.length; i++) {
            if (previous.visible[i] != current.visible[i]) return true;
          }

          if (previous.selectedIds.length != current.selectedIds.length) return true;
          if (!previous.selectedIds.containsAll(current.selectedIds)) return true;

          return false;
        },
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
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: state.selectedIds.isNotEmpty
                ? _buildPremiumBulkMenu(context, bloc, state, displayList)
                : null,
            body: RefreshIndicator(
              onRefresh: () async {
                // 1. Trigger the refresh event
                bloc.add(const ResRefresh());
                
                // 2. Tell the spinner to keep spinning until the bloc says loading is false
                try {
                  await bloc.stream
                      .firstWhere((s) => !s.loading)
                      .timeout(const Duration(seconds: 10)); // Safety catch so it never spins forever
                } catch (_) {}
              },
              color: const Color(0xFFA54600), // KorraColors.brand
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  // If we scroll within 200 pixels of the bottom, fire the Load More event!
                  if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                    bloc.add(const ResLoadMore()); // 🚀 Triggers your pagination!
                  }
                  return false; // Return false so the scroll acts normally
                },
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
            ),
          );
        },
      ),
    );
  }

  String _formatCount(int count) => count > 99 ? '99+' : count.toString();
}


// --- PREMIUM FLOATING PILL MENU ---
  // --- PREMIUM FLOATING PILL MENU ---
  Widget _buildPremiumBulkMenu(BuildContext context, ReservationsBloc bloc, ReservationsState state, List<Reservation> displayList) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut, 
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 24.w),
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xFF101828), // Dark, sleek background
              borderRadius: BorderRadius.circular(100.r),
              boxShadow: [
                BoxShadow(color: const Color(0xFF101828).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. ✅ NEW: Quick Cancel "X" Button
                InkWell(
                  borderRadius: BorderRadius.circular(100.r),
                  onTap: () => bloc.add(ResClearSelection()), // Instantly clears all selections
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    child: Icon(Icons.close_rounded, color: Colors.white54, size: 20.sp),
                  ),
                ),
                
                Container(width: 1, height: 20.h, color: Colors.white24, margin: EdgeInsets.symmetric(horizontal: 4.w)),
                
                // 2. Select All / Deselect All
                InkWell(
                  borderRadius: BorderRadius.circular(100.r),
                  onTap: () {
                     final allIds = displayList.map((e) => e.id).toList();
                     if (state.selectedIds.length == allIds.length) {
                         bloc.add(ResClearSelection()); 
                     } else {
                         bloc.add(ResSelectAll(allIds));
                     }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                    child: Text(
                      state.selectedIds.length == displayList.length ? "Deselect All" : "Select All",
                      style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13.sp),
                    ),
                  ),
                ),
                
                Container(width: 1, height: 20.h, color: Colors.white24, margin: EdgeInsets.symmetric(horizontal: 4.w)),
                
                // 3. Popping Fulfill Button
                InkWell(
                  borderRadius: BorderRadius.circular(100.r),
                  onTap: state.verificationStatus == VerificationStatus.loading 
                      ? null 
                      : () => _showFulfillConfirmation(context, bloc, state.selectedIds.toList()),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF027A48), // Korra Green
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                    child: Row(
                      children: [
                        state.verificationStatus == VerificationStatus.loading
                            ? SizedBox(width: 16.w, height: 16.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Icon(Icons.check_circle, color: Colors.white, size: 16.sp),
                        SizedBox(width: 8.w),
                        Text(
                          "Fulfill ${state.selectedIds.length}",
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.sp),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  // --- CONFIRMATION DIALOG ---
  void _showFulfillConfirmation(BuildContext context, ReservationsBloc bloc, List<String> ids) {
    showDialog(
      barrierColor: Colors.black54, // Dim the background
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: const Color(0xFF027A48), size: 24.sp),
            SizedBox(width: 10.w),
            Text("Confirm Fulfillment", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18.sp)),
          ],
        ),
        content: Text(
          "Are you sure you want to mark ${ids.length} items as fulfilled? This action will alert the customers.",
          style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14.sp, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              bloc.add(ResMarkFulfilled(ids)); // Fire the event!
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF027A48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: Text("Yes, Fulfill", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }