// lib/presentation/customer/store/widgets/hot_deals_strip.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/campaign_tags.dart';
import '../../../../config/constants/colors.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../../data/models/vendor/campaign_model.dart';
import '../../storefront/widgets/storefront_lazy_image.dart';
import 'deal_countdown_badge.dart';

/// A store that currently runs one or more active campaigns.
class StoreDeal {
  final String vendorId;
  final String storeName;
  final String slug;
  final String logoUrl;

  /// Newest first — "the later one first, the early one later".
  /// Always non-empty (enforced where deals are built).
  final List<Campaign> campaigns;

  const StoreDeal({
    required this.vendorId,
    required this.storeName,
    required this.slug,
    required this.logoUrl,
    required this.campaigns,
  });

  Campaign get latest => campaigns.first;
  List<String> get tags =>
      campaigns.map((c) => c.tag).where((t) => t.trim().isNotEmpty).toList();

  /// The campaign whose countdown to show: a running timer beats an upcoming
  /// one; ties go to the newest campaign (list is already newest-first).
  Campaign? get timedCampaign {
    Campaign? upcoming;
    for (final c in campaigns) {
      if (c.timerRunning) return c;
      if (c.timerUpcoming) upcoming ??= c;
    }
    return upcoming;
  }
}

/// Auto-playing "Hot Deals" carousel shown above Explore Stores.
/// Advances one card at a time (snapping, like a true carousel), pauses while
/// a finger is down, and jumps back to the first card after the last one.
/// Cards show the campaign image + running tag chips only (no titles);
/// tapping opens that merchant's storefront. "View all" opens the deals page.
class HotDealsStrip extends StatefulWidget {
  /// Vendor docs already streamed by the Stores page (`vendors/{id}` data),
  /// used to resolve store name/slug/logo for real campaigns without extra reads.
  final Map<String, Map<String, dynamic>> vendorsById;

  const HotDealsStrip({super.key, required this.vendorsById});

  @override
  State<HotDealsStrip> createState() => _HotDealsStripState();
}

class _HotDealsStripState extends State<HotDealsStrip> {
  // One card fills ~72% of the strip so the next card peeks in from the right.
  final PageController _pageController = PageController(viewportFraction: 0.72);
  late final Stream<QuerySnapshot> _campaignsStream;
  Timer? _autoTimer;
  bool _userTouching = false;
  int _dealCount = 0;

  @override
  void initState() {
    super.initState();
    _campaignsStream = FirebaseFirestore.instance
        .collection('campaigns')
        .orderBy('sentAt', descending: true)
        .limit(30)
        .snapshots();
    // Carousel cadence: one card advance every 3.2s.
    _autoTimer = Timer.periodic(const Duration(milliseconds: 3200), (_) => _advance());
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _advance() {
    if (_userTouching || !mounted || !_pageController.hasClients || _dealCount < 2) {
      return;
    }
    // Never animate while another route (deals page, a storefront) sits on
    // top — animating a covered route during pop transitions can corrupt the
    // navigator's gesture state and freeze input.
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    final current = _pageController.page?.round() ?? 0;
    if (current >= _dealCount - 1) {
      // Past the last card — glide back to the first and keep going.
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _pageController.animateToPage(
        current + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Group live campaigns into per-store deals.
  /// Defensive on purpose: a malformed campaign doc is skipped, never thrown.
  List<StoreDeal> _buildDeals(List<QueryDocumentSnapshot> campaignDocs) {
    final byVendor = <String, List<Campaign>>{};
    for (final doc in campaignDocs) {
      try {
        if (doc.data() is! Map<String, dynamic>) continue;
        final campaign = Campaign.fromFirestore(doc);
        if (campaign.vendorId.isEmpty || !campaign.isActive) continue;
        byVendor.putIfAbsent(campaign.vendorId, () => []).add(campaign);
      } catch (e) {
        debugPrint('Skipping malformed campaign ${doc.id}: $e');
      }
    }

    final deals = <StoreDeal>[];
    byVendor.forEach((vendorId, campaigns) {
      final vendorData = widget.vendorsById[vendorId];
      if (vendorData == null || campaigns.isEmpty) return; // banned/unknown vendor
      final storeMap = vendorData['store'] as Map<String, dynamic>? ?? {};
      campaigns.sort((a, b) => b.sentAt.compareTo(a.sentAt));
      deals.add(StoreDeal(
        vendorId: vendorId,
        storeName: (storeMap['storeName'] ?? 'Merchant Store').toString(),
        slug: (storeMap['slug'] ?? vendorId).toString(),
        logoUrl: (storeMap['logoUrl'] ?? '').toString(),
        campaigns: campaigns,
      ));
    });

    // Freshest deal first across stores.
    deals.sort((a, b) => b.latest.sentAt.compareTo(a.latest.sentAt));
    return deals;
  }

  void _openDealsPage(List<StoreDeal> deals) {
    // Named GetX route — anonymous Get.to() throws a null-check here, and a
    // raw Navigator.push corrupts GetX's back-gesture bookkeeping
    // (_userGesturesInProgress assertion + frozen input after popping).
    Get.toNamed(Routes.customerDeals, arguments: {'deals': deals});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _campaignsStream,
      builder: (context, snapshot) {
        final deals = _buildDeals(snapshot.data?.docs ?? const []);
        _dealCount = deals.length;
        if (deals.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
              child: Row(
                children: [
                  Text("🔥", style: TextStyle(fontSize: 15.sp)),
                  SizedBox(width: 6.w),
                  Text(
                    "Hot Deals",
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: KorraColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _openDealsPage(deals),
                    child: Row(
                      children: [
                        Text(
                          "View all",
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: KorraColors.brand,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Icon(Iconsax.arrow_right_3, size: 13.sp, color: KorraColors.brand),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Snapping auto-carousel (pauses while the finger is down)
            SizedBox(
              height: 150.h,
              child: Listener(
                onPointerDown: (_) => _userTouching = true,
                onPointerUp: (_) => _userTouching = false,
                onPointerCancel: (_) => _userTouching = false,
                child: PageView.builder(
                  controller: _pageController,
                  padEnds: false,
                  physics: const BouncingScrollPhysics(),
                  itemCount: deals.length,
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.only(left: 16.w, right: 4.w),
                    child: RepaintBoundary(
                      child: HotDealCard(deal: deals[index], width: double.infinity),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 22.h),
          ],
        );
      },
    );
  }
}

/// One deal card: campaign image, tag chips (latest first), store identity
/// and discount badge. No campaign title by design. Everything is layered in
/// a Stack, so the card never vertically overflows its given height.
class HotDealCard extends StatelessWidget {
  final StoreDeal deal;
  final double? width;

  const HotDealCard({super.key, required this.deal, this.width});

  @override
  Widget build(BuildContext context) {
    final latest = deal.latest;
    final showDiscount = latest.discountType == 'percentage' && latest.discountValue > 0;
    final timed = deal.timedCampaign;

    return GestureDetector(
      onTap: () => Get.toNamed('/store/${deal.slug}'),
      child: Container(
        width: width ?? 240.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              StorefrontLazyImage(url: latest.imageUrl, memCacheWidth: 600),

              // Readability scrim
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                    stops: [0.4, 1.0],
                  ),
                ),
              ),

              // Tag chips — newest campaign's tag first
              Positioned(
                top: 10.h,
                left: 10.w,
                right: 10.w,
                child: Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: deal.tags.take(3).map((tag) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.5.h),
                      decoration: BoxDecoration(
                        color: KorraCampaignTags.colorFor(tag),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 8.5.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Live countdown for merchant-timed deals
              if (timed != null)
                Positioned(
                  left: 10.w,
                  bottom: 40.h,
                  child: DealCountdownBadge(campaign: timed),
                ),

              // Discount badge
              if (showDiscount)
                Positioned(
                  right: 10.w,
                  bottom: 40.h,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      "-${latest.discountValue.toStringAsFixed(0)}%",
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFD92D20),
                      ),
                    ),
                  ),
                ),

              // Store identity footer
              Positioned(
                left: 10.w,
                right: 10.w,
                bottom: 10.h,
                child: Row(
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: deal.logoUrl.isNotEmpty
                            ? StorefrontLazyImage(url: deal.logoUrl, memCacheWidth: 100)
                            : Container(
                                color: Colors.white,
                                alignment: Alignment.center,
                                child: Text(
                                  deal.storeName.isNotEmpty ? deal.storeName[0] : 'S',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w800,
                                    color: KorraColors.brand,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: 7.w),
                    Expanded(
                      child: Text(
                        deal.storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Icon(Iconsax.arrow_right_3, size: 13.sp, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
