import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// import '../../../data/models/activity_item.dart';
import '../../../data/repository/home_repository.dart';
import '../../../logic/bloc/customer_shell/home/home_bloc.dart';
import '../../../logic/bloc/customer_shell/home/home_event.dart';
import '../../../logic/bloc/customer_shell/home/home_state.dart';

// import 'widgets/activity_list.dart';
import 'widgets/activity_timeline.dart';
import '../../shared/widgets/korra_header.dart';
import 'widgets/plan_carousel_slider.dart';
// import 'widgets/plan_media_shape.dart';
import 'widgets/wallet_card.dart';
import '../../shared/widgets/section_header.dart';
// import 'widgets/plan_carousel.dart';
import 'widgets/link_input.dart';
import 'widgets/vendor_chip.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc(HomeRepository())..add(HomeStarted()),
      child: BlocConsumer<HomeBloc, HomeState>(
        listenWhen: (p, c) => p.message != c.message && c.message != null,
        listener: (context, state) {
          if (state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(
                  state.message!,
                  style: GoogleFonts.inter(fontSize: 13.5.sp),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<HomeBloc>();

          return RefreshIndicator(
            onRefresh: () async => bloc.add(HomeStarted()),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent, // still lets inner widgets get taps
              onTap: () => FocusScope.of(context).unfocus(),
              child: Scaffold(
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
                body: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Wallet summary
                          WalletCard(
                            balanceText: state.walletBalance,
                            methodMasked: state.defaultMethodMasked,
                            onTopUp: () {},
                            onManageMethod: () {},
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
                            onSubmit: (v) => bloc.add(PasteLinkSubmitted(v)),
                            onScan: () {}, // TODO
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
            ),
          );
        },
      ),
    );
  }
}
