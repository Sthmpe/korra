// lib/presentation/customer/store/widgets/recommended_stores_section.dart
//
// "Recommended From Your Stores" — customer-facing counterpart to the
// merchant visibility dashboard. STRICT BOUNDARY: only ever surfaces
// merchants already in THIS customer's own network (their my_vendors), never
// a discovery feed. Badge-holders only; merchants without a badge simply
// stay in the regular Explore Stores list (absence is never a penalty).
// Earned badges (Top Seller, Most Visited) rank above the Highlighted tier.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../data/models/vendor/vendor_visibility.dart';
import '../../storefront/widgets/storefront_lazy_image.dart';
import 'store_badge.dart';

class _RecommendedStore {
  final String vendorId;
  final String name;
  final String slug;
  final String logoUrl;
  final List<StoreBadgeType> badges;

  const _RecommendedStore({
    required this.vendorId,
    required this.name,
    required this.slug,
    required this.logoUrl,
    required this.badges,
  });

  /// Earned badges first; among earned, Top Seller outranks Most Visited.
  int get rank {
    if (badges.contains(StoreBadgeType.topSeller)) return 0;
    if (badges.contains(StoreBadgeType.mostVisited)) return 1;
    return 2; // Highlighted only
  }
}

class RecommendedStoresSection extends StatefulWidget {
  final String customerUid;

  /// Vendor docs already streamed by the Stores page — no extra vendor reads.
  final Map<String, Map<String, dynamic>> vendorsById;

  const RecommendedStoresSection({
    super.key,
    required this.customerUid,
    required this.vendorsById,
  });

  @override
  State<RecommendedStoresSection> createState() => _RecommendedStoresSectionState();
}

class _RecommendedStoresSectionState extends State<RecommendedStoresSection> {
  late final Stream<QuerySnapshot> _networkStream;

  // Visibility fetches memoized per network signature so rebuilds don't
  // refire Firestore gets.
  Future<Map<String, VendorVisibility>>? _visibilityFuture;
  String _visibilitySignature = '';

  @override
  void initState() {
    super.initState();
    _networkStream = FirebaseFirestore.instance
        .collection('customers')
        .doc(widget.customerUid)
        .collection('my_vendors')
        .snapshots();
  }

  Future<Map<String, VendorVisibility>> _fetchVisibility(List<String> ids) async {
    final firestore = FirebaseFirestore.instance;
    final map = <String, VendorVisibility>{};
    await Future.wait(ids.map((id) async {
      try {
        final doc = await firestore.collection('vendor_visibility').doc(id).get();
        map[id] = VendorVisibility.fromFirestore(doc);
      } catch (_) {
        // Unreadable/missing visibility → simply no badge for this merchant.
      }
    }));
    return map;
  }

  Future<Map<String, VendorVisibility>> _visibilityFor(List<String> ids) {
    final signature = (List<String>.from(ids)..sort()).join(',');
    if (_visibilityFuture == null || signature != _visibilitySignature) {
      _visibilitySignature = signature;
      _visibilityFuture = _fetchVisibility(ids);
    }
    return _visibilityFuture!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _networkStream,
      builder: (context, networkSnapshot) {
        // Only merchants in the customer's own network, joined to vendor
        // docs the page already has.
        final networkIds = (networkSnapshot.data?.docs ?? const [])
            .map((d) => d.id)
            .where(widget.vendorsById.containsKey)
            .toList();

        if (networkIds.isEmpty) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<Map<String, VendorVisibility>>(
          future: _visibilityFor(networkIds),
          builder: (context, visibilitySnapshot) {
            final visibilityById = visibilitySnapshot.data ?? const {};

            final recommended = <_RecommendedStore>[];
            for (final id in networkIds) {
              final badges = badgesFromVisibility(visibilityById[id]);
              if (badges.isEmpty) continue; // stays in the regular list
              final storeMap =
                  widget.vendorsById[id]?['store'] as Map<String, dynamic>? ?? {};
              recommended.add(_RecommendedStore(
                vendorId: id,
                name: (storeMap['storeName'] ?? 'Merchant Store').toString(),
                slug: (storeMap['slug'] ?? id).toString(),
                logoUrl: (storeMap['logoUrl'] ?? '').toString(),
                badges: badges,
              ));
            }

            if (recommended.isEmpty) return const SizedBox.shrink();
            recommended.sort((a, b) => a.rank.compareTo(b.rank));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                  child: Row(
                    children: [
                      Icon(Iconsax.medal_star, size: 16.sp, color: KorraColors.brand),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          "Recommended From Your Stores",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: KorraColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 132.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: recommended.length,
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.only(right: 12.w),
                      child: RepaintBoundary(
                        child: _RecommendedCard(store: recommended[index]),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 22.h),
              ],
            );
          },
        );
      },
    );
  }
}

/// Compact premium card: ringed logo, store name and the badge(s) that
/// explain at a glance why this merchant is being surfaced.
class _RecommendedCard extends StatelessWidget {
  final _RecommendedStore store;

  const _RecommendedCard({required this.store});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed('/store/${store.slug}'),
      child: Container(
        width: 168.w,
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: const Color(0xFFF2F4F7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38.w,
                  height: 38.w,
                  padding: EdgeInsets.all(2.w),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [KorraColors.brand, Color(0xFFE05600)],
                    ),
                  ),
                  child: ClipOval(
                    child: store.logoUrl.isNotEmpty
                        ? StorefrontLazyImage(url: store.logoUrl, memCacheWidth: 120)
                        : Container(
                            color: Colors.white,
                            alignment: Alignment.center,
                            child: Text(
                              store.name.isNotEmpty ? store.name[0] : 'S',
                              style: GoogleFonts.inter(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                                color: KorraColors.brand,
                              ),
                            ),
                          ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    store.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: KorraColors.textDark,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Wrap(
              spacing: 5.w,
              runSpacing: 5.h,
              children: [
                for (final badge in store.badges.take(2))
                  StoreBadgeChip(type: badge, compact: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
