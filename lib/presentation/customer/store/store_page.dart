import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/constants/colors.dart';
import '../../../data/models/vendor/campaign_model.dart';
import '../storefront/widgets/cart_service.dart';
import 'widgets/discover_store_list_item.dart';
import 'widgets/hot_deals_strip.dart';
import 'widgets/recommended_stores_section.dart';
import 'widgets/store_hero_header.dart';

/// Unified row model so Firestore merchants and demo stores render through
/// the same list item.
class _StoreEntry {
  final String id;
  final String name;
  final String description;
  final String logoUrl;
  final String slug;

  const _StoreEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.logoUrl,
    required this.slug,
  });
}

class StorePage extends StatefulWidget {
  final String customerUid;

  const StorePage({super.key, required this.customerUid});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  static const int _pageSize = 10;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final Stream<QuerySnapshot> _vendorsStream;

  /// Recent campaigns, used to flag stores with a live deal right now (the
  /// broadcasting dot on the Stores tab, same signal as an unfinished cart).
  late final Stream<QuerySnapshot> _campaignsStream;

  String _searchQuery = '';

  // Store rows render in pages: the cap grows as the customer scrolls.
  int _storeLimit = _pageSize;
  int _totalEntries = 0;

  @override
  void initState() {
    super.initState();
    // Cached once — recreating a Firestore stream on every rebuild resets
    // the list to its loading state and re-reads the whole query.
    _vendorsStream = _firestore
        .collection('vendors')
        .where('status', isNotEqualTo: 'banned')
        .snapshots();
    _campaignsStream = _firestore
        .collection('campaigns')
        .orderBy('sentAt', descending: true)
        .limit(100)
        .snapshots();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 600 &&
        _storeLimit < _totalEntries) {
      setState(() => _storeLimit += _pageSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KorraColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏷️ PREMIUM GRADIENT HERO + FLOATING SEARCH
          StoreHeroHeader(
            searchController: _searchController,
            searchQuery: _searchQuery,
            onSearchChanged: (val) => setState(() {
              _searchQuery = val;
              _storeLimit = _pageSize; // new search → back to page one
            }),
            onClearSearch: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _storeLimit = _pageSize;
              });
            },
          ),
          // Breathing room for the search bar overlapping the hero edge
          SizedBox(height: 38.h),

          Expanded(child: _buildDiscoverStores()),
        ],
      ),
    );
  }

  // DISCOVER STORES — one lazy CustomScrollView; rows build on demand only.
  Widget _buildDiscoverStores() {
    return StreamBuilder<QuerySnapshot>(
      stream: _vendorsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: EdgeInsets.all(24.r),
            child: const Center(child: CircularProgressIndicator(color: KorraColors.brand)),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final query = _searchQuery.toLowerCase();

        // Vendor data by id — lets the Hot Deals strip resolve store
        // names/slugs for real campaigns without extra Firestore reads.
        final vendorsById = <String, Map<String, dynamic>>{
          for (final doc in docs) doc.id: doc.data() as Map<String, dynamic>? ?? {},
        };

        // Real merchants (search-filtered)
        final entries = <_StoreEntry>[];
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final storeMap = data['store'] as Map<String, dynamic>? ?? {};

          final name = (storeMap['storeName'] ?? '').toString();
          final slug = (storeMap['slug'] ?? '').toString();
          final code = (storeMap['storeCode'] ?? '').toString().toLowerCase();
          final vendorId = doc.id;

          final matches = name.toLowerCase().contains(query) ||
              slug.toLowerCase().contains(query) ||
              code.contains(query) ||
              vendorId.toLowerCase().contains(query);
          if (!matches) continue;

          entries.add(_StoreEntry(
            id: vendorId,
            name: name.isEmpty ? 'Unknown Merchant' : name,
            description: (storeMap['description'] ?? 'No store description available.').toString(),
            logoUrl: (storeMap['logoUrl'] ?? '').toString(),
            slug: slug.isEmpty ? vendorId : slug,
          ));
        }

        // Stores with an unfinished checkout rank first (live via cart notifier).
        return StreamBuilder<QuerySnapshot>(
          stream: _campaignsStream,
          builder: (context, campaignSnapshot) {
            final activeCampaigns = (campaignSnapshot.data?.docs ?? const [])
                .map(Campaign.fromFirestore)
                .where((c) => c.isActive);
            final activeCampaignVendorIds = activeCampaigns.map((c) => c.vendorId).toSet();

            return ValueListenableBuilder<Map<String, List<CartItem>>>(
              valueListenable: CartService.instance.cartsNotifier,
              builder: (context, carts, _) {
                final pendingIds = carts.keys.toSet();
                final ordered = [
                  ...entries.where((e) => pendingIds.contains(e.id)),
                  ...entries.where((e) => !pendingIds.contains(e.id)),
                ];

            _totalEntries = ordered.length;
            final shown = _storeLimit < ordered.length ? _storeLimit : ordered.length;
            final hasMore = shown < ordered.length;

            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 🔥 Auto-playing deals carousel (hidden while searching)
                if (_searchQuery.isEmpty)
                  SliverToBoxAdapter(child: HotDealsStrip(vendorsById: vendorsById)),

                // 🏅 Badge-holding merchants from the customer's own network
                if (_searchQuery.isEmpty)
                  SliverToBoxAdapter(
                    child: RecommendedStoresSection(
                      customerUid: widget.customerUid,
                      vendorsById: vendorsById,
                    ),
                  ),

                // Section header + live count pill
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
                    child: Row(
                      children: [
                        Text(
                          _searchQuery.isEmpty ? "Explore Stores" : "Search Results",
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: KorraColors.textDark,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.5.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4ED),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            "${ordered.length}",
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              color: KorraColors.brand,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (ordered.isEmpty)
                  SliverToBoxAdapter(child: _buildSearchEmptyState())
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    sliver: SliverList.builder(
                      itemCount: shown,
                      itemBuilder: (context, index) {
                        final entry = ordered[index];
                        return RepaintBoundary(
                          child: DiscoverStoreListItem(
                            vendorId: entry.id,
                            name: entry.name,
                            description: entry.description,
                            logoUrl: entry.logoUrl,
                            slug: entry.slug,
                            hasPendingCart: pendingIds.contains(entry.id),
                            hasActiveCampaign: activeCampaignVendorIds.contains(entry.id),
                          ),
                        );
                      },
                    ),
                  ),

                // Load-more spinner while more pages remain
                if (hasMore)
                  SliverToBoxAdapter(
                    child: Padding(
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
                    ),
                  ),

                SliverToBoxAdapter(child: SizedBox(height: 24.h)),
              ],
            );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSearchEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.shop_add, size: 40.sp, color: KorraColors.textHint),
            SizedBox(height: 12.h),
            Text(
              "No matching stores",
              style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: KorraColors.textDark),
            ),
            SizedBox(height: 4.h),
            Text(
              "Try searching with a different name or store code.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12.sp, color: KorraColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom simple divider
class SliverDivider extends StatelessWidget {
  const SliverDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Divider(height: 1.h, color: KorraColors.borderLight),
    );
  }
}
