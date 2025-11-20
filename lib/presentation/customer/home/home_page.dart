import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:korra/data/repository/customer/wallet_repository.dart';

// import '../../../data/models/activity_item.dart';
import '../../../config/constants/colors.dart';
import '../../../config/utils/currency_formatters.dart';
import '../../../data/repository/customer/customer_repository.dart';
import '../../../data/repository/customer/home_repository.dart';
import '../../../logic/bloc/customer/home/home_bloc.dart';
import '../../../logic/bloc/customer/home/home_event.dart';
import '../../../logic/bloc/customer/home/home_state.dart';

// import 'widgets/activity_list.dart';
import '../../../logic/bloc/customer/link/link_bloc.dart';
import '../../../logic/bloc/customer/link/link_state.dart';
import '../../../logic/bloc/customer/topup/top_up_bloc.dart';
import '../../../logic/bloc/customer/topup/top_up_event.dart';
import '../../../logic/bloc/customer/topup/top_up_state.dart';
import '../../../logic/core/net/net_cubit.dart';
import '../../shared/korra_error_bannar.dart';
import '../topup/topup_screen.dart';
import 'widgets/activity_timeline.dart';
import '../../shared/widgets/korra_header.dart';
import 'widgets/plan_carousel_slider.dart';
// import 'widgets/plan_media_shape.dart';
import 'widgets/customer_wallet_card.dart';
import '../../shared/widgets/section_header.dart';
// import 'widgets/plan_carousel.dart';
import 'widgets/link_input.dart';
import 'widgets/vendor_chip.dart';

class HomePage extends StatelessWidget {
  final CustomerRepository customerRepo;
  final String customerUid; 
  const HomePage({super.key, required this.customerRepo, required this.customerUid});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => HomeBloc(
            repo: HomeRepository(),
            customerRepo: customerRepo,
            customerUid: customerUid,
            net: context.read<NetCubit>(),
          )..add(HomeStarted()),
        ),
        BlocProvider(
          create: (_) => TopUpBloc(
            customerUid: customerUid,
            customers: customerRepo,
          )..add(TopUpStarted()),
        ),
        BlocProvider(
          create: (_) => LinkBloc(
            customerRepo: customerRepo,
            customerUid: customerUid,
          ),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<LinkBloc, LinkState>(
            listener: (context, state) {
              if (state.status == LinkStatus.loadingProduct) return;

              if (state.error != null) {
                Get.snackbar("Error", state.error!);
              } else if (state.product != null) {
                // Navigate to create plan screen
                Get.to(() => CreatePlanScreen(product: state.product!));
              }
            },
          ),
        ],
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            final bloc = context.read<HomeBloc>();
        
            return Scaffold(
              backgroundColor: Colors.white,
              appBar: KorraHeader(
                title: 'Home',
                onHistory: () {
                  // Get.to(() => const HistoryPage());
                },
                onSupport: () {
                  // Get.to(() => const SupportChatPage());
                },
                showHistoryDot: true, // set based on bloc later
              ),
              body: RefreshIndicator(
                onRefresh: () async => bloc.add(HomeStarted()),
                elevation: 0,
                displacement: 0,
                child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ▼ Subtle loading indicator at the top when refreshing
                          if (state.status == HomeStatus.loading)
                            const LinearProgressIndicator(minHeight: 2),
                          if (state.status == HomeStatus.failure)
                            ErrorBanner(
                              message: 'failed to load data, drag down to refresh',
                            ),
        
                            // Wallet summary
                            BlocBuilder<TopUpBloc, TopUpState>(
                              builder: (context, topUpState) {
                                return FutureBuilder<num>(
                                  future: customerRepo.getWalletBalance(topUpState.details.walletAccountNumber),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return CustomerWalletCard(
                                        balanceText: 'Loading...',
                                        loading: true,
                                        onTopUp: null,
                                      );
                                    }
        
                                    final availableBalance = snapshot.data ?? topUpState.details.availableBalance;
                                    context.read<HomeBloc>().add(WalletBalanceUpdated(availableBalance.toDouble()));

                                    return CustomerWalletCard(
                                      balanceText: '₦${formatToCurrency(availableBalance)}', 
                                      loading: false,
                                      onTopUp: () {
                                        final topUpBloc = context.read<TopUpBloc>();
                                        Get.to(
                                          () => BlocProvider.value(
                                            value: topUpBloc,
                                            child: const TopUpScreen(),
                                          ),
                                        );
                                      }, 
                                    );
                                  }
                                );
                              }
                            ),
                
                            // Plans
                            SectionHeader(
                              title: 'Your reserve plans',
                              actionText: state.plans.isEmpty ? null : 'View all',
                              topPadding: 0,
                              onAction: () {},
                            ),
                            
                            if (state.plans.isEmpty)
                              Padding(
                                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                                child: Container(
                                  padding: EdgeInsets.all(16.r),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: const Color(0xFFEAE6E2),
                                    ),
                                  ),
                                  child: Text(
                                    'No active plans yet.\nPaste or scan a reserve link to start.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF5E5E5E),
                                    ),
                                  ),
                                ),
                              )
                            else
                              PlanCarouselSlider(plans: state.plans),
                
                            // New plan input
                            SectionHeader(title: 'Start a new plan', topPadding: 12, actionText: '',),
                            LinkInput(
                              onSubmit: (v) {
                                bloc.add(PasteLinkSubmitted(v, double.parse(state.walletBalance)));
                              },
                              onScan: (v) {
                                bloc.add(PasteLinkSubmitted(v, double.parse(state.walletBalance)));
                              },
                            ),
                            SizedBox(height: 4.h),
                            // --- Loading status under link input ---
                            BlocBuilder<LinkBloc, LinkState>(
                              builder: (context, state) {
                                final showLoader =
                                    state.status == LinkStatus.validating ||
                                    state.status == LinkStatus.loadingProduct ||
                                    state.status == LinkStatus.valid ||
                                    state.status == LinkStatus.loaded;

                                return showLoader
                                    ? Row(
                                        children: [
                                          SizedBox(
                                            width: 16.w,
                                            height: 16.w,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: KorraColors.brand,
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Expanded(
                                            child: Text(
                                              state.message ?? '',
                                              style: GoogleFonts.inter(
                                                fontSize: 13.sp,
                                                fontStyle: FontStyle.italic,
                                                color: KorraColors.textMuted,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink();
                              },
                            ),  
                
                            SizedBox(height: 16.h),
                
                            // Saved vendors
                            SectionHeader(title: 'Your vendors', actionText: '',),
                            SizedBox(
                              height: 82.h,
                              child: ListView.separated(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                scrollDirection: Axis.horizontal,
                                itemCount: state.vendors.length,
                                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                                itemBuilder: (_, i) {
                                  final v = state.vendors[i];
                                  return VendorChip(
                                    name: v.name,
                                    avatarUrl: v.avatarUrl,
                                    onOpen: () {},
                                    onRemove: () {},
                                    onWhatsapp: () {},
                                    onInstagram: () {},
                                    onWeb: () {},
                                  );
                                },
                              ),
                            ),
                
                            // Activity (clean list-style bubbles)
                            SectionHeader(title: 'Activity', actionText: ''),
                            ActivityTimeline(
                              items: state.activity,
                              onPayNow: (a) {}, // Get.to(PayPage(...))
                              onViewPlan: (a) {}, // Get.to(PlanDetails(...))
                              onViewReceipt: (a) {}, // open receipt
                              onReviewLink: (a) {}, // link review flow
                              onEnableAutopay: (a) {}, // setup autopay
                            ),
                
                            // Keep content above bottom bar
                            SizedBox(height: 8.h),
                          ],
                        ),
                      ),
                    ],
                  ),
              ),
            );
          },
        ),
      ),
    );
  }
}
