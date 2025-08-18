import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/repository/home_repository.dart';
import '../../../logic/bloc/customer_shell/plans/plans_bloc.dart';
import '../../../logic/bloc/customer_shell/plans/plans_event.dart';
import '../../../logic/bloc/customer_shell/plans/plans_state.dart';
import '../home/widgets/korra_header.dart';
import 'widgets/plan_card.dart';
import 'widgets/plans_filter_sheet.dart';
import 'widgets/segmented_tabs.dart';
import 'widgets/empty_state_card.dart';
import 'search/plan_search_delegate.dart';

class PlansPage extends StatelessWidget {
  const PlansPage({super.key});

  static const _brand = Color(0xFFA54600);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlansBloc(HomeRepository())..add(PlansStarted()),
      child: BlocBuilder<PlansBloc, PlansState>(
        builder: (context, state) {
          final bloc = context.read<PlansBloc>();

          return Scaffold(
            appBar: KorraHeader(
              title: 'Plans',
              trailingActions: [
                IconButton(
                  onPressed: () async {
                    final q = await showSearch<String?>(
                      context: context,
                      delegate: PlanSearchDelegate(initial: state.query),
                    );
                    if (q != null) bloc.add(PlansSearchChanged(q));
                  },
                  icon: const Icon(Icons.search, color: Color(0xFF1B1B1B)),
                  iconSize: 22.sp,
                ),
                IconButton(
                  onPressed: () {
                    showPlansFilterSheet(
                      context: context,
                      currentSort: state.sortBy,
                      autopayOnly: state.autopayOnly,
                      overdueOnly: state.overdueOnly,
                      highValueOnly: state.highValueOnly,
                      onApply: (s,a,o,h) => bloc.add(PlansApplyFilters(
                        sortBy: s, autopayOnly: a, overdueOnly: o, highValueOnly: h,
                      )),
                      onReset: () => bloc.add(PlansResetFilters()),
                    );
                  },
                  icon: const Icon(Icons.tune, color: Color(0xFF1B1B1B)),
                  iconSize: 22.sp,
                ),
              ],
            ),

            floatingActionButton: FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                  ),
                  builder: (_) => const _NewPlanSheet(),
                );
              },
              backgroundColor: _brand,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              child: const Icon(Icons.add, color: Colors.white),
            ),

            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: PlansTabsSliver(
                    current: state.tab,
                    onChanged: (t) => bloc.add(PlansTabChanged(t)),
                  ),
                ),

                if (state.loading)
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                if (state.loading)
                  SliverList.builder(
                    itemCount: 3,
                    itemBuilder: (_, __) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      child: _SkeletonCard(),
                    ),
                  )
                else if (state.visible.isEmpty)
                  SliverToBoxAdapter(
                    child: EmptyStateCard(text: _emptyText(state.tab)),
                  )
                else
                  SliverList.separated(
                    itemCount: state.visible.length,
                    separatorBuilder: (_, __) => SizedBox(height: 0.h),
                    itemBuilder: (_, i) {
                      final p = state.visible[i];
                      return PlanCard(
                        plan: p,
                        onPayNow: () {},
                        onView: () {},
                        onMenu: () {},
                      );
                    },
                  ),

                SliverToBoxAdapter(child: SizedBox(height: 90.h)),
              ],
            ),
          );
        },
      ),
    );
  }

  String _emptyText(PlansTab t) {
    switch (t) {
      case PlansTab.active:    return 'No active plans yet.\nPaste a link or scan to start.';
      case PlansTab.completed: return 'No completed plans yet.';
      case PlansTab.overdue:   return 'No overdue payments.\nYou’re all caught up 🎉';
    }
  }
}

// sheet for + New Plan
class _NewPlanSheet extends StatelessWidget {
  const _NewPlanSheet();
  static const _brand = Color(0xFFA54600);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h + MediaQuery.of(context).viewInsets.bottom),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: () {/* TODO paste flow */},
              style: FilledButton.styleFrom(
                backgroundColor: _brand,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
              child: Text('Paste link', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14.sp, color: Colors.white)),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: OutlinedButton(
              onPressed: () {/* TODO scan */},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEAE6E2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                foregroundColor: _brand,
              ),
              child: Text('Scan QR', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14.sp)),
            ),
          ),
        ],
      ),
    );
  }
}

// skeleton while loading
class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEAE6E2)),
      ),
    );
  }
}
