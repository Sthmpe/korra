import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../../../data/repository/vendors/vendor_repository.dart';
import '../../../logic/bloc/vendor/home/vendor_home_bloc.dart';
import '../../../logic/bloc/vendor/home/vendor_home_event.dart';
import '../../../logic/bloc/vendor/home/vendor_home_state.dart';
import '../../../logic/bloc/vendor/payout/payout_bloc.dart';
import '../../../logic/bloc/vendor/payout/payout_event.dart';
import '../../../config/utils/currency_formatters.dart';
import '../../../logic/core/net/net_cubit.dart';
import '../../shared/korra_error_bannar.dart';
import '../../shared/widgets/section_header.dart';
import '../payout/payout_screen_ui.dart';
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
        // Trigger refresh automatically
        context.read<VendorHomeBloc>().add(const VendorHomeRefresh());
      },
      child: BlocBuilder<VendorHomeBloc, VendorHomeState>(
        builder: (context, s) {
          // Determine if the UI should be interactive.
          // It's enabled only on success. During loading/failure, buttons are frozen.
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
                      // ▼ Subtle loading indicator at the top when refreshing
                      if (s.status == VendorHomeStatus.loading)
                        const LinearProgressIndicator(minHeight: 2),
                      if (s.status == VendorHomeStatus.failure)
                        ErrorBanner(
                          message: 'failed to load data, drag down to refresh',
                        ),

                      VendorWithdrawableCard(
                        balanceText: '₦${formatToCurrency(s.withdrawable)}', //s.withdrawable
                        // Pass Total Balance if you add a property for it later
                        totalBalanceText: '₦${formatToCurrency(s.walletBalance)}', //s.walletBalance
                        loading: s.status == VendorHomeStatus.loading,
                        onPayout: isEnabled ? () {
                          Get.to(
                                () => BlocProvider(
                                  create: (_) => PayoutBloc(
                                    vendorUid: vendorUid, repo: vendors,
                                  )..add(PayoutStarted(s.withdrawable)),
                                  child: PayoutScreen(),
                                ),
                              );
                        } : null,
                      ),

                      // =======================
                      // 2. VAULT (Locked Funds)
                      // =======================
                      VendorHoldVault(
                        // 1. Format the Double to String
                        holdText: '₦${formatToCurrency(s.onHold)}', 
                        
                        // 2. Pass the Integer calculated in Bloc
                        daysRemaining: s.daysRemaining, 
                        
                        // 3. Pass the Date String
                        nextRelease: s.nextReleaseDate,
                        
                        // 4. Pass the List<HoldEntry> from State
                        entries: s.upcomingReleases, 
                        
                        onViewSchedule: isEnabled
                            ? () {
                                // context.read<VendorHomeBloc>().add(const ViewHoldSchedule());
                              }
                            : null,
                      ),

                      VendorCapacityCard(
                        maxLimit: s.maxLimit,
                        activePlanValue: s.activePlanValue,
                        storeCreditValue: s.liabilityValue,
                      ),
                      
                      // ===== Reservations KPIs =====
                      SectionHeader(title: 'Reservations', actionText: ''),
                      VendorKpiBlock(
                        newCount: s.newCount,
                        ongoingCount: s.ongoingCount,
                        completedCount: s.completedCount,
                        cancelledCount: s.cancelledCount,
                        onTapNew: isEnabled
                            ? () => context.read<VendorHomeBloc>().add(
                                const OpenReservations(
                                  filter: ResvFilter.newRes,
                                ),
                              )
                            : null,
                        onTapOngoing: isEnabled
                            ? () => context.read<VendorHomeBloc>().add(
                                const OpenReservations(
                                  filter: ResvFilter.ongoing,
                                ),
                              )
                            : null,
                        onTapCompleted: isEnabled
                            ? () => context.read<VendorHomeBloc>().add(
                                const OpenReservations(
                                  filter: ResvFilter.completed,
                                ),
                              )
                            : null,
                        onTapCancelled: isEnabled
                            ? () => context.read<VendorHomeBloc>().add(
                                const OpenReservations(
                                  filter: ResvFilter.cancelled,
                                ),
                              )
                            : null,
                      ),

                      // ===== Activity Timeline =====
                      SectionHeader(
                        title: 'Recent activity',
                        actionText: 'View all',
                      ),
                      VendorActivityTimeline(
                        items: s.activities,
                        onOpenReservation: isEnabled
                            ? (a) => context.read<VendorHomeBloc>().add(
                                OpenReservationDetail(a.id),
                              )
                            : null,
                        onAdjustStock: isEnabled
                            ? (a) => context.read<VendorHomeBloc>().add(
                                AdjustStockFor(a.refId),
                              )
                            : null,
                        onViewPlan: isEnabled
                            ? (a) => context.read<VendorHomeBloc>().add(
                                OpenPlanFor(a.refId),
                              )
                            : null,
                      ),
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
