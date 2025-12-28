import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

// REPO & LOGIC
import '../../../data/models/vendor/reservation.dart';
import '../../../data/models/vendor/vendor_activity_type.dart';
import '../../../data/models/vendor/vendor_compliance.dart';
import '../../../data/repository/vendors/reservations_repository.dart';
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
import '../reservation/reservations_page.dart';
import 'widgets/vendor_capacity_card.dart';
import 'widgets/vendor_withdrawable_card.dart';
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

                      // 1. BALANCE CARD WITH COMPLIANCE STREAM
                      // We wrap only this card to listen for liveness status
                      StreamBuilder<VendorCompliance>(
                        stream: vendors.streamComplianceStatus(vendorUid),
                        builder: (context, complianceSnap) {
                          // Default to bypass=true if loading, so we don't block user prematurely
                          final compliance = complianceSnap.data ?? VendorCompliance.initial();
                          
                          return VendorWithdrawableCard(
                            balanceText: '₦${formatToCurrency(s.withdrawable)}',
                            totalBalanceText: '₦${formatToCurrency(s.walletBalance)}',
                            loading: s.status == VendorHomeStatus.loading,
                            onPayout: isEnabled ? () {
                              
                              // 🔒 LIVENESS CHECK LOGIC
                              final bool canWithdraw = compliance.livenessPassed || compliance.livenessBypass;

                              if (!canWithdraw) {
                                _showLivenessBlocker(context);
                                return;
                              }

                              Get.to(() => BlocProvider(
                                create: (_) => PayoutBloc(
                                  vendorUid: vendorUid, repo: vendors,
                                )..add(PayoutStarted(s.withdrawable)),
                                child: PayoutScreen(),
                              ));
                            } : null,
                          );
                        },
                      ),

                      // 3. CAPACITY
                      VendorCapacityCard(
                        maxLimit: s.maxLimit,
                        activePlanValue: s.activePlanValue,
                        storeCreditValue: s.liabilityValue,
                      ),
                      
                      SizedBox(height: 16.h), 

                      // 4. KPI BUTTONS
                     StreamBuilder<Map<ReservationStatus, int>>(
                      stream: vendors.streamCounts(vendorUid),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          debugPrint("KPI Stream Error: ${snapshot.error}"); // 🔍 Debugging
                        }

                        // 1. Handle Default Data (Include ALL Enum Keys)
                        final counts = snapshot.data ?? {
                          ReservationStatus.newRes: 0,
                          ReservationStatus.ongoing: 0,
                          ReservationStatus.readyForPickup: 0, // ✅ Critical Missing Key
                          ReservationStatus.completed: 0,
                          ReservationStatus.cancelled: 0,
                        };

                        return VendorKpiBlock(
                          // 2. Map Data Correctly
                          newCount: (counts[ReservationStatus.newRes] ?? 0).toString(),
                          ongoingCount: (counts[ReservationStatus.ongoing] ?? 0).toString(),
                          
                          // ✅ Show "Ready" count. 
                          // If you want to show "Ready" instead of "Cancelled" on the dashboard:
                          readyCount: (counts[ReservationStatus.readyForPickup] ?? 0).toString(),
                          
                          completedCount: (counts[ReservationStatus.completed] ?? 0).toString(),
                          
                          // 3. Navigation Actions
                          onTapNew: () => Get.to(() => ReservationsPage(vendorId: vendorUid, initialFilter: ReservationStatus.newRes, vendors: vendors, showLeadingIcon: true)),
                          onTapOngoing: () => Get.to(() => ReservationsPage(vendorId: vendorUid, initialFilter: ReservationStatus.ongoing, vendors: vendors, showLeadingIcon: true)),
                          
                          // Navigate to Ready Tab
                          onTapReady: () => Get.to(() => ReservationsPage(vendorId: vendorUid, initialFilter: ReservationStatus.readyForPickup, vendors: vendors, showLeadingIcon: true)),
                          
                          onTapCompleted: () => Get.to(() => ReservationsPage(vendorId: vendorUid, initialFilter: ReservationStatus.completed, vendors: vendors, showLeadingIcon: true)),
                        );
                      },
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
                                actionText: hasActivities ? '' : null, 
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
                                  items: activities.take(3).toList(), // Show top 3
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

  // 🛑 LIVENESS FAILURE SHEET (Matches Korra Failure UI)
  void _showLivenessBlocker(BuildContext context) {
    HapticFeedback.lightImpact(); // Haptic feedback on block
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Important for rounded corners
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 34.h),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- HANDLE BAR ---
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              SizedBox(height: 32.h),

              // --- ICON WITH SOFT BACKGROUND ---
              Container(
                width: 64.w,
                height: 64.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2), // Soft Red Background
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Iconsax.user_search, // Liveness/Identity Icon
                  size: 32.sp,
                  color: const Color(0xFFDC2626), // Deep Red
                ),
              ),
              SizedBox(height: 24.h),

              // --- TITLE ---
              Text(
                "Liveness Check Required",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111111), // Almost Black
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 12.h),

              // --- MESSAGE ---
              Text(
                "We need to verify your identity before you can withdraw funds. This is a security measure to protect your account.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  height: 1.5,
                  color: const Color(0xFF666666), // Modern Grey
                ),
              ),
              SizedBox(height: 24.h),

              // --- CONTACT SUPPORT BOX ---
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB), // Very light grey
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFEAECF0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // Hug content
                  children: [
                    Icon(Iconsax.sms, size: 18.sp, color: Colors.grey.shade600),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        "Contact support@korra.com.ng to continue",
                        style: GoogleFonts.inter(
                          fontSize: 13.sp, 
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 32.h),

              // --- CLOSE BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111111), // Black brand
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text(
                    "Close",
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}