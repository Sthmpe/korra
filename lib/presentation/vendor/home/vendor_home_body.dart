import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../logic/bloc/vendor/home/vendor_home_bloc.dart';
import '../../../logic/bloc/vendor/home/vendor_home_event.dart';
import '../../../logic/bloc/vendor/home/vendor_home_state.dart';
import '../../../logic/core/net/net_cubit.dart';
import '../../shared/widgets/section_header.dart';
import '../payout/payout_screen.dart';
import 'widgets/vendor_withdrawable_card.dart';
import 'widgets/vendor_hold_vault.dart';
import 'widgets/vendor_kpi_block.dart';
import 'widgets/vendor_activity_timeline.dart';

class VendorHomeBody extends StatelessWidget {
  const VendorHomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<NetCubit, NetState>(
          listener: (context, state) {
            if (state == NetState.online) {
              // When the app comes online, we find the VendorHomeBloc that is
              // a child of this widget and command it to refresh its data.
              context.read<VendorHomeBloc>().add(const VendorHomeRefresh());
            }
          },
        ),
        BlocListener<VendorHomeBloc, VendorHomeState>(
          listener: (context, homeState) async {},
        ),
      ],
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
                        _ErrorBanner(
                          message: 'failed to load data, drag down to refresh',
                        ),

                      // WALLET (withdrawable)
                      VendorWithdrawableCard(
                        balanceText: s.withdrawable,
                        methodMasked: s.payoutMethodMasked,
                        onPayout: isEnabled
                            ? () => context.read<VendorHomeBloc>().add(
                                const StartPayout(),
                              )
                            : null,
                        onManageMethod: isEnabled
                            ? () {
                                final bloc = context.read<VendorHomeBloc>();
                                Get.to(
                                  () => BlocProvider.value(
                                    value: bloc,
                                    child: PayoutScreen(
                                      vendors: bloc.vendors,
                                      vendorUid: bloc.vendorUid,
                                    ),
                                  ),
                                );
                              }
                            : null,
                      ),

                      // =======================
                      // SETTLEMENT — OPTION A: VAULT
                      // =======================
                      VendorHoldVault(
                        holdText: s.onHold,
                        daysRemaining:
                            9, // replace with your remaining-days value
                        nextRelease: s.nextReleaseDate,
                        entries: const [
                          HoldEntry(
                            dateLabel: 'Aug 27',
                            amountText: '₦240,000',
                            released: false,
                          ),
                          HoldEntry(
                            dateLabel: 'Sep 03',
                            amountText: '₦510,000',
                            released: false,
                          ),
                          HoldEntry(
                            dateLabel: 'Sep 10',
                            amountText: '₦120,000',
                            released: false,
                          ),
                        ],
                        onViewSchedule: isEnabled
                            ? () => context.read<VendorHomeBloc>().add(
                                const ViewHoldSchedule(),
                              )
                            : null,
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    // This banner is designed to be a subtle, floating 'chip' that
    // informs without disrupting the overall premium feel of the UI.
    return Container(
      margin: EdgeInsets.only(top: 12.h, left: 60.w, right: 60.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        // Using a dark, semi-transparent color for a sophisticated, modern feel.
        color: const Color(0xFF262626).withOpacity(0.9),
        borderRadius: BorderRadius.circular(
          100,
        ), // A pill shape is modern and clean.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // The icon is subtle and uses a less alarming color.
          Icon(
            Icons.cloud_off_outlined,
            color: const Color(0xFFAAAAAA),
            size: 16.sp,
          ),
          SizedBox(width: 4.w),
          // Typography is key: clean font, readable size, and soft color.
          SizedBox(
            width: 245.w,
            child: Center(
              child: Text(
                message,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFFE0E0E0),
                  fontWeight: FontWeight.w500,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
