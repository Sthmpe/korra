import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:korra/data/repository/customer/plans_repository.dart';

import '../../../config/constants/colors.dart';
import '../../../config/routes/app_routes.dart';
import '../../../data/models/customer/customer_model.dart';
import '../../../data/models/customer/plans.dart';
import '../../../data/repository/customer/customer_repository.dart';
import '../../../logic/bloc/customer/link/link_bloc.dart';
import '../../../logic/bloc/customer/link/link_event.dart';
import '../../../logic/bloc/customer/link/link_state.dart';
import '../../../logic/bloc/customer/plans/plan_action_cubit.dart';
import '../../shared/widgets/korra_header.dart';
import 'dart:async';
import 'widgets/new_plan_sheet.dart';
import 'widgets/plan_card.dart';
import 'widgets/plan_search_delegate.dart';
import 'widgets/plans_filter_sheet.dart';
import 'widgets/segmented_tabs.dart';
import 'widgets/empty_state_card.dart';
import 'widgets/plan_skeleton_card.dart';

// Enum for your tabs
//import '../../../logic/bloc/customer/plans/plans_event.dart'; // Import the correct SortBy enum

class PlansPage extends StatefulWidget {
  final String customerUid;
  final VoidCallback onJumpToHome;
  final VoidCallback onJumpToPlan;

  const PlansPage({
    super.key,
    required this.customerUid,
    required this.onJumpToHome,
    required this.onJumpToPlan,
  });

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  late final CustomerRepository _repo;

  // Owned by the state (NOT a BlocProvider created inside build): the FAB and
  // the bottom sheet need this bloc from contexts that sit ABOVE any provider
  // created in build — reading it there threw ProviderNotFoundException.
  late final LinkBloc _linkBloc;
  // Filters State
  PlansTab _currentTab = PlansTab.active;
  SortBy _sortBy = SortBy.recent;
  bool _autopayOnly = false;
  bool _overdueOnly = false;
  bool _highValueOnly = false;

  // 1. 👇 Add a single stream variable here
  int _currentLimit = 15;
  late Stream<List<Plan>> _plansStream;
  Customer? _latestCustomer;
  StreamSubscription<Customer?>? _customerSub;
  final ScrollController _scrollController = ScrollController();
  List<Plan> _cachedPlans = [];
  bool _isLoadingMore = false;
  int _lastLoadedLimit = 0;
  DateTime? _lastScrollLoadTime;

  static const _brand = Color(0xFFA54600);

  @override
  void initState() {
    super.initState();
    _repo = context.read<CustomerRepository>();
    _linkBloc = LinkBloc(
      customerRepo: _repo,
      customerUid: widget.customerUid,
    );
    _customerSub = _repo.streamCustomer(widget.customerUid).listen((customer) {
      _latestCustomer = customer;
    });
    _loadPlansStream();
    
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_isLoadingMore) return;
    if (!_scrollController.hasClients) return;

    final pos = _scrollController.position;
    if (!pos.hasContentDimensions) return; // guard against rebuild mid-layout

    // Debounce: ignore if we loaded more less than 1.5 seconds ago
    final now = DateTime.now();
    if (_lastScrollLoadTime != null &&
        now.difference(_lastScrollLoadTime!) < const Duration(milliseconds: 1500)) {
      return;
    }

    if (pos.maxScrollExtent > 0 && pos.pixels >= pos.maxScrollExtent - 200) {
      _isLoadingMore = true;
      _lastScrollLoadTime = now;
      setState(() {
        _currentLimit += 15;
        _loadPlansStream();
      });

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) setState(() => _isLoadingMore = false);
      });
    }
  }

  void _loadPlansStream() {
    if (_currentLimit == _lastLoadedLimit) return;
    _lastLoadedLimit = _currentLimit;
    _plansStream = _repo.streamCustomerPlans(
      widget.customerUid,
      limit: _currentLimit,
    );
  }

  @override
  void dispose() {
    _customerSub?.cancel();
    _scrollController.dispose();
    _linkBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LinkBloc, LinkState>(
        bloc: _linkBloc,
        listenWhen: (p, c) => p.status != c.status,
        listener: (context, state) async {
          if (state.status == LinkStatus.loaded) {
            // 1. Get the product from the LinkBloc state
            final product =
                state.productFetch ?? ProductFetchResult.empty();

            final customer = _latestCustomer;
            final currentBalance = customer?.availableBalance ?? 0.00;

            // 2. Navigate directly (No BlocProvider needed here)
            // CreatePlanScreen will instantiate its own 'CreatePlanBloc' automatically.
            final result = await Get.toNamed(
              Routes.customerCreatePlan,
              arguments: {
                'product': product,
                'customer': customer,
                'customerUid': widget.customerUid,
                'walletBalance': currentBalance,
              },
            );

            // 🦘 JUMP LOGIC: Check the result sent back from Create Screen
            if (result == 'jump_to_home') {
              widget.onJumpToHome();
            } else if (result == 'jump_to_plans') {
              widget
                  .onJumpToPlan(); // (Even though we are already on Plans, this might refresh or reset tab)
            }
          }
        },
        child: Scaffold(
          backgroundColor: KorraColors.surface,
          appBar: KorraHeader(
            title: 'Plans',
            trailingActions: [
              // Search Icon
              IconButton(
                onPressed: () {
                  // --- 2. FIXED SEARCH IMPLEMENTATION ---
                  showSearch(
                    context: context,
                    delegate: PlanSearchDelegate(sourcePlans: _cachedPlans),
                  );
                },
                icon: const Icon(
                  Icons.search,
                  color: Color(0xFF1B1B1B),
                ),
                iconSize: 22.sp,
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

          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors
                    .transparent, // Important: Let the sheet handle its own rounded corners
                isScrollControlled:
                    true, // <--- ⚠️ THIS IS THE CRITICAL FIX
                builder: (_) => BlocProvider.value(
                  value: _linkBloc,
                  child: NewPlanSheet(
                    onSubmit: (v) {
                      FocusManager.instance.primaryFocus?.unfocus();
                      _linkBloc.add(LinkSubmitted(v));
                    },
                  ),
                ),
              );
            },
            backgroundColor: _brand,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.r),
            ),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              'New Plan',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),

          // THE CORE: Real-Time Data Stream
          body: StreamBuilder<List<Plan>>(
            stream: _plansStream,
            builder: (context, snapshot) {

              // 1. Cache the data so the screen doesn't flicker when loading more
              if (snapshot.hasData) {
                _cachedPlans = snapshot.data!;
              }

              // 2. Only show loading skeleton if we have NO data cached at all
              if (snapshot.connectionState == ConnectionState.waiting && _cachedPlans.isEmpty) {
                return _buildLoadingSkeleton();
              }

              if (snapshot.hasError && _cachedPlans.isEmpty) {
                return Center(child: Text("Something went wrong", style: GoogleFonts.inter()));
              }

              // 3. Use the cached plans while waiting for the new chunk
              final allPlans = snapshot.hasData ? snapshot.data! : _cachedPlans;
              final visiblePlans = _processPlans(allPlans);

              return CustomScrollView(
                controller: _scrollController,
                key: const PageStorageKey('korra_plans_list_key'),
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
                          // 🔄 CHANGE: Named Route
                          onPayNow: () {
                            Get.toNamed(
                              Routes.customerPayPlan,
                              arguments: {
                                'plan': plan,
                              },
                            );
                          },

                          // 🔄 CHANGE: Named Route
                          onView: () {
                            Get.toNamed(
                              Routes.customerPlanDetails,
                              preventDuplicates: true,
                              arguments: {
                                'plan': plan,
                              },
                            );
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
  }

  // --- 5. ROBUST FILTERING & SORTING LOGIC ---
  List<Plan> _processPlans(List<Plan> all) {
    // A. Filter by Tab
    var list = all.where((p) {
      if (_currentTab == PlansTab.active) {
        // Active = Status Active AND Not Overdue
        return p.status == 'active' && !p.isOverdue;
      }

      if (_currentTab == PlansTab.pending) return p.status == 'pending';

      // Completed Tab Logic Change:
      // Should "Completed" show EVERYTHING finished, or only Picked Up ones?
      // Usually "History" implies fully done.
      // Let's make "Completed" show ONLY fulfilled items so it doesn't duplicate "Ready".
      if (_currentTab == PlansTab.completed) {
        return p.status == 'completed';
      }

      if (_currentTab == PlansTab.overdue) return p.isOverdue;
      if (_currentTab == PlansTab.cancelled) return p.status == 'cancelled';

      return true;
    }).toList();

    // B. Apply Filter Sheet Options (Keep existing)
    if (_autopayOnly) {
      list = list.where((p) => p.commitmentEnabled).toList();
    }
    if (_overdueOnly) {
      list = list.where((p) => p.isOverdue).toList();
    }
    if (_highValueOnly) {
      list = list.where((p) => p.totalAmount > 50000).toList();
    }

    // C. Apply Sorting (Keep existing)
    list.sort((a, b) {
      switch (_sortBy) {
        case SortBy.recent:
          return b.updatedAt.compareTo(a.updatedAt);
        case SortBy.nextDue:
          return a.nextDueDate.compareTo(b.nextDueDate);
        case SortBy.amount:
          return b.totalAmount.compareTo(a.totalAmount);
        case SortBy.progress:
          return b.progressPercent.compareTo(a.progressPercent);
      }
    });

    return list;
  }

  String _emptyText(PlansTab t) {
    switch (t) {
      case PlansTab.active:
        return 'No active plans yet.\nStart a plan to build ownership.';
      case PlansTab.completed:
        return 'No completed plans yet.';
      case PlansTab.overdue:
        return 'No plans past due.\nYour standing is excellent. 🛡️';
      case PlansTab.cancelled:
        return 'No closed plans.';
      case PlansTab.pending:
        return 'No pending approvals.';
    }
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 4,
      padding: EdgeInsets.only(top: 60.h),
      itemBuilder: (_, __) => const PlanSkeletonCard(),
    );
  }
}
