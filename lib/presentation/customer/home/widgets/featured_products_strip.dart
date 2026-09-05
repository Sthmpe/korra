import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/services/analytics_service.dart';
import '../../../shared/widgets/section_header.dart';

/// One featured pick: enough of the product doc to draw a card and deep-link
/// into its store.
class _FeaturedPick {
  final String productId;
  final String vendorId;
  final String name;
  final String storeName;
  final double price;
  final String? imageUrl;

  const _FeaturedPick({
    required this.productId,
    required this.vendorId,
    required this.name,
    required this.storeName,
    required this.price,
    this.imageUrl,
  });
}

/// Random discovery rail on the customer home: up to 5 approved, in-stock
/// products spread across as many different vendors as exist (one vendor's
/// catalogue fills the gaps when there are fewer vendors). Fresh shuffle per
/// session. Tapping a card opens the merchant's storefront with the product's
/// detail sheet auto-opened.
class FeaturedProductsStrip extends StatefulWidget {
  const FeaturedProductsStrip({super.key});

  @override
  State<FeaturedProductsStrip> createState() => _FeaturedProductsStripState();
}

class _FeaturedProductsStripState extends State<FeaturedProductsStrip> {
  static const int _maxPicks = 5;

  late final Future<List<_FeaturedPick>> _picksFuture;

  @override
  void initState() {
    super.initState();
    _picksFuture = _loadPicks();
  }

  Future<List<_FeaturedPick>> _loadPicks() async {
    try {
      // Closed marketplace: featured picks only come from stores the customer
      // has saved (their my_vendors network). No saved stores => nothing here.
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return const [];
      final networkSnap = await FirebaseFirestore.instance
          .collection('customers')
          .doc(uid)
          .collection('my_vendors')
          .get();
      final allNetworkIds = networkSnap.docs.map((d) => d.id).toList();
      if (allNetworkIds.isEmpty) return const [];
      // Sample up to 8 saved stores so reads stay flat as the network grows:
      // we only need 5 varied picks, never every saved store's catalogue.
      final vendorIds = (allNetworkIds..shuffle(Random())).take(8).toList();

      // Pull approved products only from those saved stores (whereIn is capped
      // at 30, so batch in chunks of 10). Status is filtered in memory to
      // avoid needing a vendorId+status composite index.
      final docs = <QueryDocumentSnapshot>[];
      for (var i = 0; i < vendorIds.length; i += 10) {
        final chunk = vendorIds.sublist(i, min(i + 10, vendorIds.length));
        final snap = await FirebaseFirestore.instance
            .collection('products')
            .where('vendorId', whereIn: chunk)
            .limit(40)
            .get();
        docs.addAll(snap.docs);
      }

      final rng = Random();
      docs.shuffle(rng);

      // Round-robin over shuffled vendors so picks spread across stores;
      // with few vendors the same store just fills the remaining slots.
      final byVendor = <String, List<QueryDocumentSnapshot>>{};
      for (final doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        if ((data['status'] ?? '') != 'approved') continue;
        final stock = (data['availableStock'] as num?)?.toInt() ?? 0;
        if (stock <= 0) continue;
        final vendorId = (data['vendorId'] ?? '').toString();
        if (vendorId.isEmpty) continue;
        byVendor.putIfAbsent(vendorId, () => []).add(doc);
      }

      final vendorQueues = byVendor.values.toList()..shuffle(rng);
      final picks = <_FeaturedPick>[];
      var added = true;
      while (picks.length < _maxPicks && added) {
        added = false;
        for (final queue in vendorQueues) {
          if (queue.isEmpty || picks.length >= _maxPicks) continue;
          final doc = queue.removeAt(0);
          final data = doc.data() as Map<String, dynamic>;
          final images = (data['images'] as List?)?.cast<String>() ?? const [];
          final disc = (data['discountedPrice'] as num?)?.toDouble() ?? 0;
          final base = (data['price'] as num?)?.toDouble() ?? 0;
          // A timed campaign's discount lapses at campaignEndsAt; past that,
          // show the full price.
          final ends = data['campaignEndsAt'];
          final discountActive =
              ends is! Timestamp || DateTime.now().isBefore(ends.toDate());
          picks.add(_FeaturedPick(
            productId: doc.id,
            vendorId: (data['vendorId'] ?? '').toString(),
            name: (data['name'] ?? '').toString(),
            storeName: (data['storeName'] ?? '').toString(),
            price: (disc > 0 && discountActive) ? disc : base,
            imageUrl: images.isNotEmpty ? images.first : null,
          ));
          added = true;
        }
      }
      return picks;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _openInStore(_FeaturedPick pick) async {
    Analytics.log(AnalyticsEvents.custFeaturedTapped, {
      'vendor_id': pick.vendorId,
      'product_id': pick.productId,
    });
    // Prefer the store slug; the storefront route also resolves a raw uid.
    var slug = pick.vendorId;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(pick.vendorId)
          .get();
      final storeMap = doc.data()?['store'] as Map<String, dynamic>? ?? {};
      final s = (storeMap['slug'] ?? '').toString().trim();
      if (s.isNotEmpty) slug = s;
    } catch (_) {}
    Get.toNamed('/store/$slug', parameters: {'product': pick.productId});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_FeaturedPick>>(
      future: _picksFuture,
      builder: (context, snap) {
        final picks = snap.data ?? const <_FeaturedPick>[];
        if (picks.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Featured products',
              subtitle: 'Fresh picks from your stores',
              icon: Iconsax.shop,
            ),
            SizedBox(
              height: 208.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: picks.length,
                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                itemBuilder: (context, i) => _FeaturedCard(
                  pick: picks[i],
                  onTap: () => _openInStore(picks[i]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final _FeaturedPick pick;
  final VoidCallback onTap;

  const _FeaturedCard({required this.pick, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140.w,
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
              aspectRatio: 1.15,
              child: pick.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: pick.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade100,
                        child: Icon(Iconsax.image,
                            size: 22.sp, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade100,
                      child:
                          Icon(Iconsax.image, size: 22.sp, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pick.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1B1B),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    pick.storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '₦${pick.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
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
