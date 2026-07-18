// lib/presentation/customer/store/widgets/last_viewed_strip.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/services/analytics_service.dart';
import '../../../../logic/services/recent_views_service.dart';
import '../../../shared/widgets/section_header.dart';

/// "Last Viewed" rail on the Stores page: products the customer dwelled on
/// (5+ seconds) across ANY store within the last 24 hours, newest first.
/// Purchased products are removed the moment they're bought, and the whole
/// section disappears when nothing qualifies — no empty state by design.
/// Tapping re-opens the product inside its merchant's storefront.
class LastViewedStrip extends StatelessWidget {
  const LastViewedStrip({super.key});

  Future<void> _openInStore(Map<String, dynamic> view) async {
    final vendorId = (view['vendorId'] ?? '').toString();
    final productId = (view['productId'] ?? '').toString();
    if (vendorId.isEmpty || productId.isEmpty) return;

    Analytics.log(AnalyticsEvents.custLastViewedTapped, {
      'vendor_id': vendorId,
      'product_id': productId,
    });

    // Prefer the slug snapshotted with the view; resolve it live otherwise.
    var slug = (view['slug'] ?? '').toString().trim();
    if (slug.isEmpty) {
      slug = vendorId;
      try {
        final doc = await FirebaseFirestore.instance
            .collection('vendors')
            .doc(vendorId)
            .get();
        final storeMap = doc.data()?['store'] as Map<String, dynamic>? ?? {};
        final s = (storeMap['slug'] ?? '').toString().trim();
        if (s.isNotEmpty) slug = s;
      } catch (_) {}
    }
    Get.toNamed('/store/$slug', parameters: {'product': productId});
  }

  @override
  Widget build(BuildContext context) {
    final stream = RecentViewsService.instance.watchRecentViews();
    if (stream == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        final cutoff =
            DateTime.now().subtract(RecentViewsService.viewLifetime);
        final views = (snap.data?.docs ?? const [])
            .map((d) => d.data())
            .where((v) {
          // serverTimestamp is briefly null on the local echo of a fresh
          // write — that's the newest view, so it always qualifies.
          final ts = v['viewedAt'];
          if (ts is! Timestamp) return true;
          return ts.toDate().isAfter(cutoff);
          // Rail shows at most 5 entries, newest first (David, 16 July 2026).
        }).take(5).toList();

        if (views.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Last viewed',
              subtitle: 'Pick up where you left off',
              icon: Iconsax.eye,
            ),
            SizedBox(
              height: 168.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: views.length,
                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                itemBuilder: (context, i) => _LastViewedCard(
                  view: views[i],
                  onTap: () => _openInStore(views[i]),
                ),
              ),
            ),
            SizedBox(height: 8.h),
          ],
        );
      },
    );
  }
}

class _LastViewedCard extends StatelessWidget {
  final Map<String, dynamic> view;
  final VoidCallback onTap;

  const _LastViewedCard({required this.view, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = (view['name'] ?? '').toString();
    final storeName = (view['storeName'] ?? '').toString();
    final imageUrl = (view['imageUrl'] ?? '').toString();
    final price = (view['price'] as num?)?.toDouble() ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 118.w,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFF0EBE7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.25,
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade100,
                        child:
                            Icon(Iconsax.image, size: 20.sp, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade100,
                      child:
                          Icon(Iconsax.image, size: 20.sp, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 7.h, 10.w, 7.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1B1B),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    '₦${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: KorraColors.brand,
                    ),
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
