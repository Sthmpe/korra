import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// REPO & LOGIC
import '../../../data/models/vendor/vendor_activity_type.dart';
import '../../../data/repository/vendors/vendor_repository.dart';
import '../../../logic/bloc/vendor/home/vendor_home_bloc.dart';
import '../../../logic/bloc/vendor/home/vendor_home_event.dart';
import '../../../logic/bloc/vendor/home/vendor_home_state.dart';
import '../../../logic/bloc/vendor/payout/payout_bloc.dart';
import '../../../logic/bloc/vendor/payout/payout_event.dart';
import '../../../logic/core/net/net_cubit.dart';

// UI HELPERS
import '../../../config/utils/currency_formatters.dart';
import '../../shared/korra_error_bannar.dart';
import '../../shared/widgets/section_header.dart';
import '../payout/payout_screen_ui.dart';

// WIDGETS
import 'widgets/vault_screen.dart';
import 'widgets/vendor_capacity_card.dart';
import 'widgets/vendor_withdrawable_card.dart';
import 'widgets/vendor_hold_vault.dart';
import 'widgets/vendor_kpi_block.dart';
import 'widgets/vendor_activity_timeline.dart';

class VendorHomeBody extends StatelessWidget {
  final VendorRepository vendors;
  final String vendorUid;

  const VendorHomeBody({
    super.key,
    required this.vendors,
    required this.vendorUid,
  });

  @override
  Widget build(BuildContext context) {
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

                      // 1. BALANCE CARD
                      VendorWithdrawableCard(
                        balanceText: '₦${formatToCurrency(s.withdrawable)}',
                        totalBalanceText: '₦${formatToCurrency(s.walletBalance)}',
                        loading: s.status == VendorHomeStatus.loading,
                        onPayout: isEnabled ? () {
                          Get.to(() => BlocProvider(
                            create: (_) => PayoutBloc(
                              vendorUid: vendorUid, repo: vendors,
                            )..add(PayoutStarted(s.withdrawable)),
                            child: PayoutScreen(),
                          ));
                        } : null,
                      ),

                      // 2. VAULT
                      VendorHoldVault(
                        holdText: '₦${formatToCurrency(s.onHold)}', 
                        daysRemaining: s.daysRemaining, 
                        nextRelease: s.nextReleaseDate,
                        entries: s.upcomingReleases, 
                        onViewSchedule: isEnabled ? () {
                           Get.to(() => VendorVaultScreen(
                             repo: vendors, 
                             vendorUid: vendorUid
                           ));
                        } : null,
                      ),

                      // 3. CAPACITY
                      VendorCapacityCard(
                        maxLimit: s.maxLimit,
                        activePlanValue: s.activePlanValue,
                        storeCreditValue: s.liabilityValue,
                      ),
                      
                      SizedBox(height: 16.h), 

                      // 4. KPI BUTTONS
                      VendorKpiBlock(
                        newCount: s.newCount,
                        ongoingCount: s.ongoingCount,
                        completedCount: s.completedCount,
                        cancelledCount: s.cancelledCount,
                        onTapNew: isEnabled
                            ? () => context.read<VendorHomeBloc>().add(const OpenReservations(filter: ResvFilter.newRes))
                            : null,
                        onTapOngoing: isEnabled
                            ? () => context.read<VendorHomeBloc>().add(const OpenReservations(filter: ResvFilter.ongoing))
                            : null,
                        onTapCompleted: isEnabled
                            ? () => context.read<VendorHomeBloc>().add(const OpenReservations(filter: ResvFilter.completed))
                            : null,
                        onTapCancelled: isEnabled
                            ? () => context.read<VendorHomeBloc>().add(const OpenReservations(filter: ResvFilter.cancelled))
                            : null,
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
                                actionText: hasActivities ? 'View all' : null, 
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
                                  items: activities.take(5).toList(), // Show top 5
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