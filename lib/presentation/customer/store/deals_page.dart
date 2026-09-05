// lib/presentation/customer/store/deals_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../config/constants/campaign_tags.dart';
import '../../../config/constants/colors.dart';
import '../../shared/widgets/korra_header.dart';
import '../storefront/widgets/storefront_lazy_image.dart';
import 'widgets/hot_deals_strip.dart' show StoreDeal, HotDealCard;

/// "View all" destination for the Hot Deals strip: every store currently
/// running campaigns, each with a large deal card and a direct route into
/// that merchant's storefront. Renders in pages of [_pageSize] — more cards
/// load as the customer scrolls near the bottom.
class DealsPage extends StatefulWidget {
  final List<StoreDeal> deals;

  const DealsPage({super.key, required this.deals});

  @override
  State<DealsPage> createState() => _DealsPageState();
}

class _DealsPageState extends State<DealsPage> {
  static const int _pageSize = 6;

  final ScrollController _scrollController = ScrollController();
  int _visible = _pageSize;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 500 &&
        _visible < widget.deals.length) {
      setState(() => _visible += _pageSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deals = widget.deals;
    final shown = _visible < deals.length ? _visible : deals.length;
    final hasMore = shown < deals.length;

    return Scaffold(
      backgroundColor: KorraColors.surface,
      appBar: const KorraHeader(title: "Hot Deals", showLeadingIcon: true),
      body: deals.isEmpty
          ? _emptyState()
          : ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
              itemCount: shown + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= shown) {
                  // Load-more spinner row at the tail of the current page
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    child: Center(
                      child: SizedBox(
                        height: 22.w,
                        width: 22.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: KorraColors.brand,
                        ),
                      ),
                    ),
                  );
                }
                return RepaintBoundary(child: _DealListCard(deal: deals[index]));
              },
            ),
    );
  }

  Widget _emptyState() {
    // Scrollable so a squeezed viewport (open keyboard, small screens)
    // can never make the column overflow.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: EdgeInsets.all(32.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.discount_shape, size: 42.sp, color: KorraColors.textHint),
                SizedBox(height: 14.h),
                Text(
                  "No live deals right now",
                  style: GoogleFonts.inter(
                      fontSize: 15.sp, fontWeight: FontWeight.w700, color: KorraColors.textDark),
                ),
                SizedBox(height: 6.h),
                Text(
                  "Check back soon. Merchants drop new campaigns daily.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12.5.sp, color: KorraColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DealListCard extends StatelessWidget {
  final StoreDeal deal;

  const _DealListCard({required this.deal});

  static final DateFormat _windowFmt = DateFormat('EEE d MMM, h:mm a');

  @override
  Widget build(BuildContext context) {
    final timed = deal.timedCampaign;
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Large deal visual (reuses the strip card, full width).
            // AspectRatio follows the card's width, so it can never clash
            // with the screen's height scale the way a fixed .h box can.
            Padding(
              padding: EdgeInsets.all(10.r),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: HotDealCard(deal: deal, width: double.infinity),
              ),
            ),

            // Store row + all running tags + CTA
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 2.h, 14.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The card overlays only the latest campaign's tag; list the
                  // store's OTHER running campaign tags here (below the image,
                  // so there's no old-tag-on-new-image mismatch).
                  if (deal.tags.length > 1) ...[
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      children: deal.tags.skip(1).map((tag) {
                        final color = KorraCampaignTags.colorFor(tag);
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tag.toUpperCase(),
                            style: GoogleFonts.inter(
                                fontSize: 9.sp, fontWeight: FontWeight.w800, color: color),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 10.h),
                  ],
                  // Merchant-set deal window (timed campaigns only)
                  if (timed != null && timed.hasTimer) ...[
                    Row(
                      children: [
                        Icon(Iconsax.timer_15, size: 13.sp, color: const Color(0xFFD92D20)),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            "${_windowFmt.format(timed.dealStartAt!)}  →  ${_windowFmt.format(timed.dealEndAt!)}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: KorraColors.textBody,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                  ],
                  Row(
                    children: [
                      ClipOval(
                        child: SizedBox(
                          width: 34.w,
                          height: 34.w,
                          child: deal.logoUrl.isNotEmpty
                              ? StorefrontLazyImage(url: deal.logoUrl, memCacheWidth: 120)
                              : Container(
                                  color: KorraColors.brandLight,
                                  alignment: Alignment.center,
                                  child: Text(
                                    deal.storeName.isNotEmpty ? deal.storeName[0] : 'S',
                                    style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w800,
                                        color: KorraColors.brand),
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              deal.storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: KorraColors.textDark),
                            ),
                            Text(
                              "${deal.campaigns.length} live campaign${deal.campaigns.length == 1 ? '' : 's'}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w500,
                                  color: KorraColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      ElevatedButton(
                        onPressed: () => Get.toNamed('/store/${deal.slug}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KorraColors.brand,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999)),
                        ),
                        child: Text(
                          "Visit Store",
                          style: GoogleFonts.inter(
                              fontSize: 11.5.sp, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
