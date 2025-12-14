import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:korra/data/repository/customer/plans_repository.dart';
import 'package:korra/presentation/customer/plans/create_plan_screen.dart';

import '../../../data/models/customer/customer_model.dart';
import '../../../data/models/customer/plans.dart';
import '../../../data/repository/customer/customer_repository.dart';
import '../../../logic/bloc/customer/link/link_bloc.dart';
import '../../../logic/bloc/customer/link/link_event.dart';
import '../../../logic/bloc/customer/link/link_state.dart';
import '../../../logic/bloc/customer/plans/plan_action_bloc.dart';
import '../../shared/widgets/korra_header.dart';
import '../customer_failure_sheet.dart';
import 'widgets/new_plan_sheer.dart';
import 'widgets/pay_plan_input_screen.dart';
import 'widgets/plan_card.dart';
import 'widgets/plan_details_screen.dart';
import 'widgets/plan_search_delegate.dart';
import 'widgets/plans_filter_sheet.dart';
import 'widgets/segmented_tabs.dart';
import 'widgets/empty_state_card.dart';

// Enum for your tabs
//import '../../../logic/bloc/customer/plans/plans_event.dart'; // Import the correct SortBy enum

class PlansPage extends StatefulWidget {
  final CustomerRepository customerRepo;
  final String customerUid;
  final VoidCallback onJumpToHome;
  final VoidCallback onJumpToPlan;
  

  const PlansPage({
    super.key,
    required this.customerRepo,
    required this.customerUid,
    required this.onJumpToHome,
    required this.onJumpToPlan,
  });

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  // Filters State
  PlansTab _currentTab = PlansTab.active;

  SortBy _sortBy = SortBy.nextDue; // Default sort
  bool _autopayOnly = false;
  bool _overdueOnly = false;
  bool _highValueOnly = false;

  static const _brand = Color(0xFFA54600);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LinkBloc(
        customerRepo: widget.customerRepo,
        customerUid: widget.customerUid,
      ),
      child: StreamBuilder<Customer?>(
        stream: widget.customerRepo.streamCustomer(widget.customerUid),
        builder: (context, snapshot) {
          final customer = snapshot.data;
          final currentBalance = customer?.availableBalance ?? 0.00;

          return BlocListener<LinkBloc, LinkState>(
            listenWhen: (p, c) => p.status != c.status,
            listener: (context, state) {
              if (state.status == LinkStatus.empty) {
                showKorraFailureSheetCustomer(
                  context,
                  title: 'Empty Link',
                  message: 'Please enter a link to proceed.',
                  onCancel: () => Get.back(),
                );
              }

              if (state.status == LinkStatus.invalid) {
                showKorraFailureSheetCustomer(
                  context,
                  title: 'Invalid Link',
                  message: 'The link you provided is invalid.',
                  onCancel: () => Get.back(),
                );
              } else if (state.status == LinkStatus.loaded) {
                // 1. Get the product from the LinkBloc state
                final product =
                    state.productFetch ?? ProductFetchResult.empty();

                // 2. Navigate directly (No BlocProvider needed here)
                // CreatePlanScreen will instantiate its own 'CreatePlanBloc' automatically.
                Get.to(
                  () => CreatePlanScreen(
                    product: product,
                    customerRepo: widget.customerRepo,
                    customerUid: widget.customerUid,
                    walletBalance: currentBalance,
                    onJumpToHome: widget.onJumpToHome,
                    onJumpToPlan: () => widget.onJumpToPlan,
                  ),
                );
              }
            },
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: KorraHeader(
                title: 'Plans',
                trailingActions: [
                  // Search Icon
                  StreamBuilder<List<Plan>>(
                    // Optimization: We need data for search, so we can grab it from repo or
                    // just use the builder below. For cleaner UI, we usually access the stream
                    // inside the SearchDelegate, or pass the current list if we have it.
                    // Here, we'll wait for the body stream to load.
                    stream: widget.customerRepo.streamCustomerPlans(
                      widget.customerUid,
                    ),
                    builder: (context, snapshot) {
                      final plans = snapshot.data ?? [];
                      return IconButton(
                        onPressed: () {
                          // --- 2. FIXED SEARCH IMPLEMENTATION ---
                          showSearch(
                            context: context,
                            delegate: PlanSearchDelegate(sourcePlans: plans),
                          );
                        },
                        icon: const Icon(
                          Icons.search,
                          color: Color(0xFF1B1B1B),
                        ),
                        iconSize: 22.sp,
                      );
                    },
                  ),
                  // Filter Icon
                  IconButton(
                    onPressed: () {
                      // --- 3. FIXED FILTER IMPLEMENTATION ---
                      showPlansFilterSheet(
                        context: context,
                        currentSort: _sortBy,
                        autopayOnly: _autopayOnly,
                        overdueOnly: _overdueOnly,
                        highValueOnly: _highValueOnly,
                        onApply: (sort, auto, over, high) {
                          // Update state to trigger rebuild of the list
                          setState(() {
                            // Cast to the correct SortBy enum
                            _sortBy = sort;
                            _autopayOnly = auto;
                            _overdueOnly = over;
                            _highValueOnly = high;
                          });
                        },
                        onReset: () {
                          setState(() {
                            _sortBy = SortBy.nextDue;
                            _autopayOnly = false;
                            _overdueOnly = false;
                            _highValueOnly = false;
                          });
                        },
                      );
                    },
                    icon: Stack(
                      children: [
                        const Icon(Icons.tune, color: Color(0xFF1B1B1B)),
                        // Engineering Polish: Show a dot if filters are active
                        if (_autopayOnly || _overdueOnly || _highValueOnly)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: const BoxDecoration(
                                color: _brand,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    iconSize: 22.sp,
                  ),
                ],
              ),

              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors
                        .transparent, // Important: Let the sheet handle its own rounded corners
                    isScrollControlled:
                        true, // <--- ⚠️ THIS IS THE CRITICAL FIX
                    builder: (_) => BlocProvider.value(
                      value: context.read<LinkBloc>(),
                      child: NewPlanSheet(
                        onSubmit: (v) {
                          FocusManager.instance.primaryFocus?.unfocus();
                          context.read<LinkBloc>().add(LinkSubmitted(v));
                        },
                      ),
                    ),
                  );
                },
                backgroundColor: _brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),

              // THE CORE: Real-Time Data Stream
              body: StreamBuilder<List<Plan>>(
                stream: widget.customerRepo.streamCustomerPlans(
                  widget.customerUid,
                ),
                builder: (context, snapshot) {
                  // 1. Loading State
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingSkeleton();
                  }

                  // 2. Error State
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Something went wrong",
                        style: GoogleFonts.inter(),
                      ),
                    );
                  }

                  final allPlans = snapshot.data ?? [];

                  // 3. Client-Side Filtering
                  final visiblePlans = _processPlans(allPlans);

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Sticky Tab Header
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: PlansTabsSliver(
                          current: _currentTab,
                          onChanged: (tab) => setState(() => _currentTab = tab),
                        ),
                      ),

                      // Empty State for Tab
                      if (visiblePlans.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40.h),
                            child: EmptyStateCard(
                              text: _emptyText(_currentTab),
                            ),
                          ),
                        )
                      else
                        // The Real List
                        SliverList.builder(
                          itemCount: visiblePlans.length,
                          itemBuilder: (context, index) {
                            final plan = visiblePlans[index];
                            return PlanCard(
                              plan: plan,
                              onPayNow: () {
                                Get.to(() => PayPlanInputScreen(plan: plan, repo: widget.customerRepo));  
                              },
                              onView: () {
                                Get.to(() => PlanDetailsScreen(plan: plan, customerRepo: widget.customerRepo));
                              },
                              onMenu: () {},
                            );
                          },
                        ),

                      // Bottom Padding for FAB
                      SliverToBoxAdapter(child: SizedBox(height: 100.h)),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // --- 5. ROBUST FILTERING & SORTING LOGIC ---
  List<Plan> _processPlans(List<Plan> all) {
    // A. Filter by Tab
    var list = all.where((p) {
      if (_currentTab == PlansTab.active)
        return p.status == 'active' && !p.isOverdue;
      if (_currentTab == PlansTab.pending) return p.status == 'pending';
      if (_currentTab == PlansTab.completed) return p.status == 'completed';
      if (_currentTab == PlansTab.overdue) return p.isOverdue;
      if (_currentTab == PlansTab.cancelled) return p.status == 'cancelled';
      return true;
    }).toList();

    // B. Apply Filter Sheet Options
    if (_autopayOnly) {
      list = list.where((p) => p.commitmentEnabled).toList();
    }
    if (_overdueOnly) {
      list = list.where((p) => p.isOverdue).toList();
    }
    if (_highValueOnly) {
      list = list.where((p) => p.totalAmount > 50000).toList();
    }

    // C. Apply Sorting
    list.sort((a, b) {
      switch (_sortBy) {
        case SortBy.nextDue:
          return a.nextDueDate.compareTo(b.nextDueDate);
        case SortBy.amount:
          return b.totalAmount.compareTo(a.totalAmount); // Highest first
        case SortBy.progress:
          return b.progressPercent.compareTo(
            a.progressPercent,
          ); // Highest progress first
      }
    });

    return list;
  }

  String _emptyText(PlansTab t) {
    switch (t) {
      case PlansTab.active:
        return 'No active plans yet.\nPaste a link or scan to start.';
      case PlansTab.completed:
        return 'No completed plans yet.';
      case PlansTab.overdue:
        return 'No overdue payments.\nYou’re all caught up 🎉';
      case PlansTab.cancelled:
        return 'No cancelled plans.';
      case PlansTab.pending:
        return 'No pending plans.';
    }
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 4,
      padding: EdgeInsets.only(top: 60.h),
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }
}

// --- HELPER WIDGETS ---

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (b) => LinearGradient(
            colors: [Colors.grey[100]!, Colors.white, Colors.grey[100]!],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment(-1.0 + (_controller.value * 3), 0.0),
            end: Alignment(1.0 + (_controller.value * 3), 0.0),
          ).createShader(b),
          child: Container(
            height: 110.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
          ),
        ),
      ),
    );
  }
}
