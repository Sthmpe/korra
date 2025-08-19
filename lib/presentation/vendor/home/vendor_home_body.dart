import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:korra/config/constants/sizes.dart';

import '../../../logic/bloc/vendor/home/vendor_home_bloc.dart';
import '../../../logic/bloc/vendor/home/vendor_home_event.dart';
import '../../../logic/bloc/vendor/home/vendor_home_state.dart';

import '../../shared/widgets/section_header.dart';
import 'widgets/vendor_withdrawable_card.dart';
// ▼ add these two imports
import 'widgets/vendor_hold_vault.dart';
import 'widgets/vendor_hold_strip.dart';

import 'widgets/vendor_kpi_block.dart';
import 'widgets/vendor_activity_timeline.dart';

class VendorHomeBody extends StatelessWidget {
  const VendorHomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VendorHomeBloc, VendorHomeState>(
      builder: (context, s) {
        return RefreshIndicator(
          elevation: 1,
          displacement: 10,
          onRefresh: () async =>
              context.read<VendorHomeBloc>().add(const VendorHomeRefresh()),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // WALLET (withdrawable)
                    VendorWithdrawableCard(
                      balanceText: s.withdrawable,
                      methodMasked: s.payoutMethodMasked,
                      onPayout: () => context.read<VendorHomeBloc>().add(const StartPayout()),
                      onManageMethod: () => context.read<VendorHomeBloc>().add(const ManagePayoutMethod()),
                    ),

                    // =======================
                    // SETTLEMENT — OPTION A: VAULT
                    // =======================
                    VendorHoldVault(
                      holdText: s.onHold,
                      daysRemaining: 9, // replace with your remaining-days value
                      nextRelease: s.nextReleaseDate,
                      entries: const [
                        HoldEntry(dateLabel: 'Aug 27', amountText: '₦240,000', released: false),
                        HoldEntry(dateLabel: 'Sep 03', amountText: '₦510,000', released: false),
                        HoldEntry(dateLabel: 'Sep 10', amountText: '₦120,000', released: false),
                      ],
                      onViewSchedule: () => context.read<VendorHomeBloc>().add(const ViewHoldSchedule()),
                    ),

                    
                    // ===== Reservations KPIs =====
                    SectionHeader(title: 'Reservations', actionText: ''),
                    VendorKpiBlock(
                      newCount: s.newCount,
                      ongoingCount: s.ongoingCount,
                      completedCount: s.completedCount,
                      cancelledCount: s.cancelledCount,
                      onTapNew: () => context.read<VendorHomeBloc>()
                          .add(const OpenReservations(filter: ResvFilter.newRes)),
                      onTapOngoing: () => context.read<VendorHomeBloc>()
                          .add(const OpenReservations(filter: ResvFilter.ongoing)),
                      onTapCompleted: () => context.read<VendorHomeBloc>()
                          .add(const OpenReservations(filter: ResvFilter.completed)),
                      onTapCancelled: () => context.read<VendorHomeBloc>()
                          .add(const OpenReservations(filter: ResvFilter.cancelled)),
                    ),

                    // ===== Activity Timeline =====
                    SectionHeader(title: 'Recent activity', actionText: 'View all'),
                    VendorActivityTimeline(
                      items: s.activities,
                      onOpenReservation: (a) =>
                          context.read<VendorHomeBloc>().add(OpenReservationDetail(a.id)),
                      onAdjustStock: (a) =>
                          context.read<VendorHomeBloc>().add(AdjustStockFor(a.refId)),
                      onViewPlan: (a) =>
                          context.read<VendorHomeBloc>().add(OpenPlanFor(a.refId)),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
