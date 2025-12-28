import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

// REPO & MODELS
import '../../../config/constants/colors.dart';
import '../../../config/utils/currency_formatters.dart';
import '../../../data/models/customer/activity_item.dart';
import '../../../data/models/customer/customer_model.dart';
import '../../../data/models/customer/payment_receipt_data.dart';
import '../../../data/models/customer/plans.dart';
import '../../../data/repository/customer/customer_activity_feed.dart';
import '../../../data/repository/customer/customer_repository.dart';
import '../../../data/repository/customer/notification_repository.dart'; // Extension
import '../../../data/repository/customer/plans_repository.dart';

// BLOC
import '../../../logic/bloc/customer/home/home_bloc.dart';
import '../../../logic/bloc/customer/home/home_event.dart';
import '../../../logic/bloc/customer/link/link_bloc.dart';
import '../../../logic/bloc/customer/link/link_event.dart';
import '../../../logic/bloc/customer/link/link_state.dart';
import '../../../logic/core/net/net_cubit.dart';
import '../../../logic/services/notification_service.dart'; // Import Service

// WIDGETS
import '../../shared/widgets/korra_header.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/show_app_snackbar.dart';
import '../plans/create_plan_screen.dart';
import '../plans/widgets/plan_details_screen.dart';
import '../plans/widgets/transaction_receipt_screen.dart';
import '../profile/bank_details_screen.dart';
import 'notification_screen.dart';
import 'widgets/activity_timeline.dart';
import 'widgets/customer_wallet_card.dart';
import 'widgets/link_input.dart';
import 'widgets/plan_carousel_slider.dart';
import 'widgets/shimmer_loading.dart';

class HomePage extends StatefulWidget {
  final CustomerRepository customerRepo;
  final String customerUid;
  final ValueChanged<int> onJumpTo;
  final VoidCallback onJumpToPlan;

  const HomePage({
    super.key,
    required this.customerRepo,
    required this.customerUid,
    required this.onJumpTo,
    required this.onJumpToPlan,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  
  @override
  void initState() {
    super.initState();
    // 1. ENGINEERING: Initialize Push Notifications (One-time setup)
    // This asks for permission (iOS) and saves the token to Firestore.
    NotificationService(widget.customerRepo).initialize(widget.customerUid);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => HomeBloc(
            customerRepo: widget.customerRepo,
            customerUid: widget.customerUid,
            net: context.read<NetCubit>(),
          )..add(HomeStarted()), // Start fetching vendors/data
        ),
        BlocProvider(
          create: (_) => LinkBloc(customerRepo: widget.customerRepo, customerUid: widget.customerUid),
        ),
      ],
      
      // 2. Single Source of Truth (Stream)
      child: StreamBuilder<Customer?>(
        stream: widget.customerRepo.streamCustomer(widget.customerUid),
        builder: (context, snapshot) {
          final customer = snapshot.data;
          final currentBalance = customer?.availableBalance ?? 0.00;

          return MultiBlocListener(
            listeners: [
              BlocListener<LinkBloc, LinkState>(
                listenWhen: (p, c) => p.status != c.status,
                listener: (context, state) {
                  if (state.status == LinkStatus.loaded) {
                    final product = state.productFetch ?? ProductFetchResult.empty();
                    
                    if (customer == null) {
                      showAppSnackbar('Customer data not available', SnackbarType.error);
                      return;
                    }

                    Get.to(() => CreatePlanScreen(
                      product: product,
                      customerRepo: widget.customerRepo,
                      customer: customer, // Non-null due to stream state
                      customerUid: widget.customerUid,
                      walletBalance: currentBalance,
                      onJumpToHome: () => widget.onJumpTo(0),
                      onJumpToPlan: () => widget.onJumpToPlan,
                    ));
                  }
                },
              ),
            ],
            child: Scaffold(
              backgroundColor: Colors.white,
              // 3. APP BAR WITH NOTIFICATION BADGE
              appBar: KorraHeader(
                title: 'Home',
                trailingActions: [
                  StreamBuilder<int>(
                    stream: widget.customerRepo.streamUnreadCount(widget.customerUid),
                    initialData: 0,
                    builder: (context, notifSnap) {
                      final count = notifSnap.data ?? 0;
                      final hasUnread = count > 0;

                      return IconButton(
                        onPressed: () {
                          Get.to(() => NotificationScreen(
                            repo: widget.customerRepo, 
                            uid: widget.customerUid,
                            onJumpToPlans: () => widget.onJumpTo(1),
                          ));
                        },
                        icon: Stack(
                          clipBehavior: Clip.none, // Allow badge to overflow slightly
                          children: [
                            Icon(Iconsax.notification, color: const Color(0xFF1B1B1B), size: 24.sp),
                            if (hasUnread)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 10.w, // Slightly larger for visibility
                                  height: 10.w,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5), // White ring makes it pop
                                  ),
                                ),
                              )
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              
              body: RefreshIndicator(
                onRefresh: () async => context.read<HomeBloc>().add(HomeStarted()),
                color: KorraColors.brand,
                backgroundColor: Colors.white,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // A. WALLET CARD
                          CustomerWalletCard(
                            balanceText: snapshot.connectionState == ConnectionState.waiting
                                ? '...'
                                : '₦${formatToCurrency(currentBalance)}',
                            loading: snapshot.connectionState == ConnectionState.waiting,
                            onTopUp: () {
                              if (customer == null) {
                                showAppSnackbar('Customer data not available', SnackbarType.error);
                                return;
                              }

                              Get.to(() => BankDetailsScreen(customer: customer));
                            },
                          ),

                          // B. ACTIVE PLANS (Filtered Stream)
                          StreamBuilder<List<Plan>>(
                            stream: widget.customerRepo.streamCustomerPlans(widget.customerUid),
                            builder: (context, planSnap) {
                              // Loading
                              if (planSnap.connectionState == ConnectionState.waiting) {
                                return Column(children: [
                                   SectionHeader(title: 'Your reserve plans', actionText: '', topPadding: 10),
                                   const PlanCarouselLoading(),
                                ]);
                              }
                              
                              final allPlans = planSnap.data ?? [];
                              // Filter out Completed/Cancelled for Home view
                              final activePlans = allPlans.where((p) => !p.isCompleted && !p.isCancelled).toList();

                              return Column(
                                children: [
                                  SectionHeader(
                                    title: 'Your reserve plans',
                                    actionText: activePlans.isEmpty ? null : 'View all',
                                    onAction: activePlans.isEmpty ? null : () => widget.onJumpTo(1),
                                    topPadding: 10,
                                  ),
                                  SizedBox(height: 8.h),
                                  
                                  activePlans.isEmpty 
                                    ? _buildEmptyPlanState()
                                    : PlanCarouselSlider(
                                        plans: activePlans.take(5).toList(),
                                        customerRepo: widget.customerRepo,
                                      ),
                                ],
                              );
                            },
                          ),

                          // C. START NEW PLAN
                          SectionHeader(title: 'Start a new plan', topPadding: 24, actionText: ''),
                          LinkInput(
                            onSubmit: (v) {
                              FocusManager.instance.primaryFocus?.unfocus();
                              context.read<LinkBloc>().add(LinkSubmitted(v));
                            },
                            onScan: (v) {
                              context.read<LinkBloc>().add(LinkSubmitted(v));
                            },
                          ),
                          
                          SizedBox(height: 4.h),

                          // Link Loading State
                          BlocBuilder<LinkBloc, LinkState>(
                            builder: (context, state) {
                              final showLoader = state.status == LinkStatus.validating || state.status == LinkStatus.loadingProduct;

                              if (state.status == LinkStatus.empty) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 16.w, height: 16.w, child: Icon(Iconsax.warning_2, size: 16.sp, color: Colors.red),),
                                      SizedBox(width: 8.w),
                                      Expanded(child: Text('Please enter a link to proceed', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13.sp, color: KorraColors.textMuted))),
                                    ],
                                  ),
                                );
                              }

                              if (state.status == LinkStatus.invalid) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 16.w, height: 16.w, child: Icon(Iconsax.warning_2, size: 16.sp, color: Colors.red),),
                                      SizedBox(width: 8.w),
                                      Expanded(child: Text('The link you provided is invalid', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13.sp, color: KorraColors.textMuted))),
                                    ],
                                  ),
                                );
                              }
                              
                              if (state.status == LinkStatus.failed) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 16.w, height: 16.w, child: Icon(Iconsax.warning_2, size: 16.sp, color: Colors.red),),
                                      SizedBox(width: 8.w),
                                      Expanded(child: Text(state.message ?? 'Error occurred', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13.sp, color: KorraColors.textMuted))),
                                    ],
                                  ),
                                );
                              }

                              if (!showLoader) return const SizedBox.shrink();
                              
                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.w),
                                child: Row(
                                  children: [
                                    SizedBox(width: 16.w, height: 16.w, child: const CircularProgressIndicator(strokeWidth: 2, color: KorraColors.brand)),
                                    SizedBox(width: 8.w),
                                    Expanded(child: Text(state.message ?? 'Processing...', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13.sp, fontStyle: FontStyle.italic, color: KorraColors.textMuted))),
                                  ],
                                ),
                              );
                            },
                          ),

                          // E. RECENT ACTIVITY
                          SectionHeader(title: 'Recent Activity', actionText: ''),
                          StreamBuilder<List<ActivityItem>>(
                            stream: widget.customerRepo.streamActivityFeed(widget.customerUid),
                            builder: (context, feedSnap) {
                              if (feedSnap.connectionState == ConnectionState.waiting) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
                                  child: const BouncingLoader(),
                                );
                              }

                              final allItems = feedSnap.data ?? [];
                              final finalItems = allItems.take(3).toList();

                              return ActivityTimeline(
                                items: finalItems,
                                onViewReceipt: (item) {
                                  PaymentReceiptData receiptData;

                                  // Check if the item carries the full receipt suitcase
                                  if (item.receiptData != null && item.receiptData!.isNotEmpty) {
                                    receiptData = PaymentReceiptData.fromJson(item.receiptData!);
                                  } else {
                                    // Fallback: Construct a Lite Receipt on the fly
                                    receiptData = PaymentReceiptData.fromPartial(
                                      amount: item.amount.abs(),
                                      date: item.date,
                                      title: item.title, // e.g. "Installment Paid"
                                      status: 'SUCCESSFUL'
                                    );
                                  }

                                  Get.to(() => TransactionReceiptScreen(data: receiptData));
                                },
                                onViewPlan: (item) {
                                  if (item.planId == null || item.planId!.isEmpty) return;
                                  // Use shell plan for instant nav
                                  final shellPlan = Plan.empty(id: item.planId!);
                                  Get.to(() => PlanDetailsScreen(
                                    plan: shellPlan, 
                                    customerRepo: widget.customerRepo
                                  ));
                                },
                              );
                            },
                          ),

                          SizedBox(height: 40.h),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyPlanState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 24.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Icon(Icons.receipt_long_rounded, size: 24.sp, color: Colors.grey.shade400),
            ),
            SizedBox(height: 12.h),
            Text('No active plans yet', style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1B1B1B))),
            SizedBox(height: 4.h),
            Text('Paste a link below to start reserving.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade500, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

// --- LOADING ANIMATION ---
class BouncingLoader extends StatelessWidget {
  final Color color;
  final double size;
  final int dotCount;

  const BouncingLoader({
    super.key,
    this.color = const Color(0xFFA54600), // KorraColors.brand equivalent
    this.size = 6.0,
    this.dotCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size * 3, // Provide space for the bounce
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(dotCount, (index) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: _BouncingDot(
                delay: Duration(milliseconds: 150 * index),
                color: color,
                size: size,
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _BouncingDot extends StatefulWidget {
  final Duration delay;
  final Color color;
  final double size;

  const _BouncingDot({
    required this.delay,
    required this.color,
    required this.size,
  });

  @override
  _BouncingDotState createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Duration should be long enough for the loop but short enough for bounce
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: -widget.size * 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.2,
          0.8,
          curve: Curves.easeInOut,
        ), // Only bounce in the middle of the cycle
      ),
    );

    // Start with a delay
    _startAnimationWithDelay();
  }

  void _startAnimationWithDelay() async {
    await Future.delayed(widget.delay);
    if (mounted) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            width: widget.size.w,
            height: widget.size.w,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
