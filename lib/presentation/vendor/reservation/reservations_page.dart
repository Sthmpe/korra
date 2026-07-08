// lib/presentation/vendor/reservation/reservations_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/vendor/outright_order.dart';
import '../../../data/models/vendor/reservation.dart';
import '../../../data/repository/vendors/vendor_repository.dart';
import '../../../logic/bloc/vendor/outright_order/outright_orders_bloc.dart';
import '../../../logic/bloc/vendor/outright_order/outright_orders_event.dart';
import '../../../logic/bloc/vendor/outright_order/outright_orders_state.dart';
import '../../shared/widgets/show_app_snackbar.dart';
import '../../../logic/bloc/vendor/reservation/reservations_bloc.dart';
import '../../../logic/bloc/vendor/reservation/reservations_event.dart';
import '../../../logic/bloc/vendor/reservation/reservations_state.dart';
import '../../shared/widgets/korra_header.dart';
import 'widgets/orders_panel_switcher.dart';
import 'widgets/outright_orders_panel.dart';
import 'widgets/reservations_panel.dart';

class ReservationsPage extends StatefulWidget {
  final String vendorId;
  final ReservationStatus initialFilter;

  /// Which panel to open first: 0 = Reservations, 1 = Outright Purchases.
  final int initialPanel;

  /// Starting status tab for the outright panel (when opened via a KPI).
  final OutrightOrderStatus? initialOutrightFilter;
  final bool showLeadingIcon;

  const ReservationsPage({
    super.key,
    required this.vendorId,
    this.initialFilter = ReservationStatus.ongoing,
    this.initialPanel = 0,
    this.initialOutrightFilter,
    this.showLeadingIcon = false,
  });

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialPanel;
    _pageController = PageController(initialPage: widget.initialPanel);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPanelChanged(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendors = context.read<VendorRepository>();

    return MultiBlocProvider(
      providers: [
        BlocProvider<ReservationsBloc>(
          create: (_) => ReservationsBloc(
            repo: vendors,
            vendorId: widget.vendorId,
            initial: widget.initialFilter,
          )..add(ResStarted(widget.initialFilter)),
        ),
        BlocProvider<OutrightOrdersBloc>(
          create: (_) {
            final outrightInitial =
                widget.initialOutrightFilter ?? OutrightOrderStatus.pending;
            return OutrightOrdersBloc(
              repo: vendors,
              vendorId: widget.vendorId,
              initial: outrightInitial,
            )..add(OutrightOrdersStarted(outrightInitial));
          },
        ),
      ],
      child: BlocBuilder<ReservationsBloc, ReservationsState>(
        builder: (context, resState) {
          final resBloc = context.read<ReservationsBloc>();

          final query = resState.query.toLowerCase();
          final displayList = resState.query.isEmpty
              ? resState.visible
              : resState.visible.where((r) {
                  return r.customerName.toLowerCase().contains(query) ||
                         r.productTitle.toLowerCase().contains(query) ||
                         r.productCode.toLowerCase().contains(query) ||
                         r.id.toLowerCase().contains(query);
                }).toList();

          return Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
            appBar: KorraHeader(
              title: 'Orders',
              showLeadingIcon: widget.showLeadingIcon,
              isSearchable: true,
              searchHint: _currentIndex == 0 ? 'Search reservations...' : 'Search outright orders...',
              onSearchChanged: (q) {
                if (_currentIndex == 0) {
                  context.read<ReservationsBloc>().add(ResSearchChanged(q));
                } else {
                  context.read<OutrightOrdersBloc>().add(OutrightOrdersSearchChanged(q));
                }
              },
              onSearchClosed: () {
                context.read<ReservationsBloc>().add(const ResSearchChanged(''));
                context.read<OutrightOrdersBloc>().add(const OutrightOrdersSearchChanged(''));
              },
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: _currentIndex == 0
                ? (resState.selectedIds.isNotEmpty
                    ? _buildPremiumBulkMenu(context, resBloc, resState, displayList)
                    : null)
                : BlocBuilder<OutrightOrdersBloc, OutrightOrdersState>(
                    builder: (context, outState) {
                      if (outState.selectedIds.isEmpty) return const SizedBox.shrink();
                      return _buildOutrightBulkMenu(
                          context, context.read<OutrightOrdersBloc>(), outState);
                    },
                  ),
            body: Column(
              children: [
                // Panel Switcher (Reservations | Outright Purchases)
                OrdersPanelSwitcher(
                  currentIndex: _currentIndex,
                  onTap: _onPanelChanged,
                ),
                // PageView content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    children: const [
                      ReservationsPanel(),
                      OutrightOrdersPanel(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

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
              color: const Color(0xFF101828), 
              borderRadius: BorderRadius.circular(100.r),
              boxShadow: [
                BoxShadow(color: const Color(0xFF101828).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(100.r),
                  onTap: () => bloc.add(ResClearSelection()), 
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    child: Icon(Icons.close_rounded, color: Colors.white54, size: 20.sp),
                  ),
                ),
                
                Container(width: 1, height: 20.h, color: Colors.white24, margin: EdgeInsets.symmetric(horizontal: 4.w)),
                
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
                
                InkWell(
                  borderRadius: BorderRadius.circular(100.r),
                  onTap: state.verificationStatus == VerificationStatus.loading 
                      ? null 
                      : () => _showFulfillConfirmation(context, bloc, state.selectedIds.toList()),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF027A48), 
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                    child: Row(
                      children: [
                        state.verificationStatus == VerificationStatus.loading
                            ? SizedBox(width: 16.w, height: 16.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Icon(Icons.check_circle, color: Colors.white, size: 16.sp),
                        SizedBox(width: 8.w),
                        Text(
                          "Deliver ${state.selectedIds.length}",
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

  // --- OUTRIGHT BULK PILL (UI only — bulk delivery write not connected yet) ---
  Widget _buildOutrightBulkMenu(
      BuildContext context, OutrightOrdersBloc bloc, OutrightOrdersState state) {
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
              color: const Color(0xFF101828),
              borderRadius: BorderRadius.circular(100.r),
              boxShadow: [
                BoxShadow(color: const Color(0xFF101828).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(100.r),
                  onTap: () => bloc.add(const OutrightClearSelection()),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    child: Icon(Icons.close_rounded, color: Colors.white54, size: 20.sp),
                  ),
                ),
                Container(width: 1, height: 20.h, color: Colors.white24, margin: EdgeInsets.symmetric(horizontal: 4.w)),
                InkWell(
                  borderRadius: BorderRadius.circular(100.r),
                  onTap: () {
                    // Only New + Ready-to-Deliver orders are selectable.
                    final eligibleIds = state.visible
                        .where((e) => e.isPending || e.isReadyToDeliver)
                        .map((e) => e.id)
                        .toList();
                    if (state.selectedIds.length == eligibleIds.length) {
                      bloc.add(const OutrightClearSelection());
                    } else {
                      bloc.add(OutrightSelectAll(eligibleIds));
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                    child: Text(
                      state.selectedIds.length ==
                              state.visible
                                  .where((e) => e.isPending || e.isReadyToDeliver)
                                  .length
                          ? "Deselect All"
                          : "Select All",
                      style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13.sp),
                    ),
                  ),
                ),
                Container(width: 1, height: 20.h, color: Colors.white24, margin: EdgeInsets.symmetric(horizontal: 4.w)),
                InkWell(
                  borderRadius: BorderRadius.circular(100.r),
                  onTap: state.deliveryStatus == DeliveryStatus.loading
                      ? null
                      : () => _showOutrightFulfillConfirmation(context, bloc, state.selectedIds.toList()),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF027A48),
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                    child: Row(
                      children: [
                        state.deliveryStatus == DeliveryStatus.loading
                            ? SizedBox(width: 16.w, height: 16.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Icon(Icons.check_circle, color: Colors.white, size: 16.sp),
                        SizedBox(width: 8.w),
                        Text(
                          "Deliver ${state.selectedIds.length}",
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
      },
    );
  }

  void _showOutrightFulfillConfirmation(BuildContext context, OutrightOrdersBloc bloc, List<String> ids) {
    showDialog(
      barrierColor: Colors.black54,
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: const Color(0xFF027A48), size: 24.sp),
            SizedBox(width: 10.w),
            Text("Confirm Delivery", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18.sp)),
          ],
        ),
        content: Text(
          "Are you sure you want to mark ${ids.length} order(s) as delivered? This action will alert the customers.",
          style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14.sp, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Bulk delivery is now connected — marks each selected outright
              // order delivered via the same backend write as single delivery.
              bloc.add(OutrightBulkMarkDelivered(ids));
              showAppSnackbar(
                "Marking ${ids.length} order(s) as delivered…",
                SnackbarType.success,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF027A48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: Text("Yes, Deliver", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // --- CONFIRMATION DIALOG ---
  void _showFulfillConfirmation(BuildContext context, ReservationsBloc bloc, List<String> ids) {
    showDialog(
      barrierColor: Colors.black54, 
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: const Color(0xFF027A48), size: 24.sp),
            SizedBox(width: 10.w),
            Text("Confirm Delivery", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18.sp)),
          ],
        ),
        content: Text(
          "Are you sure you want to mark ${ids.length} item(s) as delivered? This action will alert the customers.",
          style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14.sp, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx); 
              bloc.add(ResMarkFulfilled(ids)); 
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF027A48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: Text("Yes, Deliver", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}