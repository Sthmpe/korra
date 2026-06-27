import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

// REPO & LOGIC
import '../../../config/routes/app_routes.dart';
import '../../../data/models/vendor/reservation.dart';
import '../../../data/models/vendor/vendor_activity_type.dart';
import '../../../data/models/vendor/vendor_compliance.dart';
import '../../../data/repository/vendors/reservations_repository.dart';
import '../../../data/repository/vendors/vendor_repository.dart';
import '../../../logic/bloc/vendor/home/vendor_home_bloc.dart';
import '../../../logic/bloc/vendor/home/vendor_home_event.dart';
import '../../../logic/bloc/vendor/home/vendor_home_state.dart';
import '../../../logic/core/net/net_cubit.dart';

// UI HELPERS
import '../../../config/utils/currency_formatters.dart';
import '../../shared/korra_error_bannar.dart';
import '../../shared/widgets/section_header.dart';

// WIDGETS
import 'widgets/vendor_capacity_card.dart';
import 'widgets/vendor_withdrawable_card.dart';
import 'widgets/vendor_kpi_block.dart';
import 'widgets/vendor_activity_timeline.dart';
import 'widgets/liveness_blocker_sheet.dart';

class VendorHomeBody extends StatelessWidget {
  final String vendorUid;

  const VendorHomeBody({
    super.key,
    required this.vendorUid,
  });

  @override
  Widget build(BuildContext context) {
    final vendors = context.read<VendorRepository>();
    return BlocListener<NetCubit, NetState>(
      listenWhen: (previous, current) =>
          previous == NetState.offline && current == NetState.online,
      listener: (context, state) {
        context.read<VendorHomeBloc>().add(const VendorHomeRefresh());
      },
      child: BlocBuilder<VendorHomeBloc, VendorHomeState>(
        builder: (context, s) {
          final bool isEnabled = s.status == VendorHomeStatus.success;

          return RefreshIndicator(
            elevation: 0,
            displacement: 0,
            onRefresh: () async =>
                context.read<VendorHomeBloc>().add(const VendorHomeRefresh()),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (s.status == VendorHomeStatus.loading)
                        const LinearProgressIndicator(minHeight: 2),
                      if (s.status == VendorHomeStatus.failure)
                        const ErrorBanner(
                          message: 'Failed to load data, drag down to refresh',
                        ),

                      // 1. BALANCE CARD WITH COMPLIANCE STREAM
                      // We wrap only this card to listen for liveness status
                      StreamBuilder<VendorCompliance>(
                        stream: vendors.streamComplianceStatus(vendorUid),
                        builder: (context, complianceSnap) {
                          // Default to bypass=true if loading, so we don't block user prematurely
                          final compliance = complianceSnap.data ?? VendorCompliance.initial();
                          
                         return VendorWithdrawableCard(
                            balanceText: '₦${formatToCurrency(s.withdrawable)}',
                            // 🚀 PASS THE PENDING BALANCE HERE
                            pendingText: '₦${formatToCurrency(s.onHold)}', 
                            loading: s.status == VendorHomeStatus.loading,
                            onPayout: isEnabled ? () {
                              
                              // 🔒 LIVENESS CHECK LOGIC
                              final bool canWithdraw = compliance.livenessPassed || compliance.livenessBypass;

                              if (!canWithdraw) {
                                HapticFeedback.lightImpact();
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  builder: (_) => const LivenessBlockerSheet(),
                                );
                                return;
                              }

                              Get.toNamed(
                                Routes.vendorPayout,
                                arguments: {
                                  'uid': vendorUid,
                                  // 'repo': vendors,
                                  'withdrawableAmount': s.withdrawable,
                                }
                              );
                            } : null,
                          );
                        },
                      ),

                      // 3. CAPACITY
                      VendorCapacityCard(
                        maxLimit: s.maxLimit,
                        activePlanValue: s.activePlanValue,
                        storeCreditValue: s.liabilityValue,
                      ),
                      
                      SizedBox(height: 16.h), 

                      // 4. KPI BUTTONS
                     StreamBuilder<Map<ReservationStatus, int>>(
                      stream: vendors.streamCounts(vendorUid),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          debugPrint("KPI Stream Error: ${snapshot.error}"); // 🔍 Debugging
                        }

                        // 1. Handle Default Data (Include ALL Enum Keys)
                        final counts = snapshot.data ?? {
                          ReservationStatus.newRes: 0,
                          ReservationStatus.ongoing: 0,
                          ReservationStatus.readyForPickup: 0, // ✅ Critical Missing Key
                          ReservationStatus.completed: 0,
                          ReservationStatus.cancelled: 0,
                        };

                        return VendorKpiBlock(
                          // 2. Map Data Correctly
                          newCount: (counts[ReservationStatus.newRes] ?? 0).toString(),
                          ongoingCount: (counts[ReservationStatus.ongoing] ?? 0).toString(),
                          
                          // ✅ Show "Ready" count. 
                          // If you want to show "Ready" instead of "Cancelled" on the dashboard:
                          readyCount: (counts[ReservationStatus.readyForPickup] ?? 0).toString(),
                          
                          completedCount: (counts[ReservationStatus.completed] ?? 0).toString(),
                          
                          // 3. Navigation Actions
                          onTapNew: () => Get.toNamed(
                            Routes.vendorReservations,
                            arguments: {
                              'uid': vendorUid,
                              // 'repo': vendors,
                              'filter': ReservationStatus.newRes,
                              'showLeadingIcon': true,
                            }
                          ),
                          // Ongoing
                          onTapOngoing: () => Get.toNamed(
                            Routes.vendorReservations,
                            arguments: {
                              'uid': vendorUid,
                              // 'repo': vendors,
                              'filter': ReservationStatus.ongoing,
                              'showLeadingIcon': true,
                            }
                          ),    
                          // Ready
                          onTapReady: () => Get.toNamed(
                            Routes.vendorReservations,
                            arguments: {
                              'uid': vendorUid,
                              // 'repo': vendors,
                              'filter': ReservationStatus.readyForPickup,
                              'showLeadingIcon': true,
                            }
                          ),
                          // Completed
                          onTapCompleted: () => Get.toNamed(
                            Routes.vendorReservations,
                            arguments: {
                              'uid': vendorUid,
                              // 'repo': vendors,
                              'filter': ReservationStatus.completed,
                              'showLeadingIcon': true,
                            }
                          ),
                        );
                      },
                    ),

                      // 5. STREAMING ACTIVITY TIMELINE (Real-Time)
                      StreamBuilder<List<VendorActivityItem>>(
                        stream: vendors.streamActivityFeed(vendorUid),
                        builder: (context, snapshot) {
                          // Default to empty list while loading/error
                          final activities = snapshot.data ?? [];
                          final bool hasActivities = activities.isNotEmpty;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // HEADER IS NOW INSIDE STREAM BUILDER
                              SectionHeader(
                                title: 'Recent activity',
                                // Only show 'View all' if there are items
                                actionText: hasActivities ? '' : null, 
                                onAction: hasActivities ? () {
                                  // Navigate to full activity feed
                                } : null,
                              ),

                              if (snapshot.connectionState == ConnectionState.waiting) 
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20.h),
                                  child: const Center(child: CircularProgressIndicator()),
                                )
                              else if (!hasActivities)
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20.h),
                                  child: Center(
                                    child: Text("No recent activity", style: GoogleFonts.inter(color: Colors.grey)),
                                  ),
                                )
                              else
                                VendorActivityTimeline(
                                  items: activities.take(3).toList(), // Show top 3
                                  onOpenReservation: isEnabled
                                      ? (a) => context.read<VendorHomeBloc>().add(OpenReservationDetail(a.refId))
                                      : null,
                                  onAdjustStock: isEnabled
                                      ? (a) => context.read<VendorHomeBloc>().add(AdjustStockFor(a.refId))
                                      : null,
                                  onViewPlan: isEnabled
                                      ? (a) => context.read<VendorHomeBloc>().add(OpenPlanFor(a.refId))
                                      : null,
                                ),
                            ],
                          );
                        },
                      ),
                      
                      SizedBox(height: 40.h),
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

}