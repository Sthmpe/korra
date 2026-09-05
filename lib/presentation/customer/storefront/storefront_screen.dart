import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../../data/models/customer/customer_model.dart';
import '../../../../data/models/customer/plans.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/vendor/campaign_model.dart';
import '../../shared/widgets/korra_header.dart';
import '../../shared/widgets/show_app_snackbar.dart';

import 'widgets/storefront_cart_button.dart';
import 'widgets/storefront_cart_sheet.dart';
import 'widgets/storefront_filter_bar.dart';
import 'widgets/storefront_filter_sheet.dart';
import 'widgets/storefront_header.dart';
import 'widgets/storefront_product_card.dart';
import 'widgets/storefront_purchase_history_sheet.dart';
import 'widgets/storefront_product_details_sheet.dart';
import 'widgets/storefront_sliver_app_bar.dart';
import 'widgets/storefront_suspended_overlay.dart';
import 'widgets/cart_service.dart';

/// Lightweight vendor lookup result (slug or uid resolved to one shape).
class StorefrontVendor {
  final String id;
  final Map<String, dynamic> data;
  final DocumentSnapshot? doc;

  const StorefrontVendor({required this.id, required this.data, this.doc});
}

class StorefrontScreen extends StatefulWidget {
  final String storeSlug;

  /// When the app is opened from a website product link
  /// (korra.com.ng/store/{slug}?product={id}), the storefront auto-opens that
  /// product so the shopper lands exactly where they were on the web.
  final String? initialProductId;

  const StorefrontScreen({
    super.key,
    required this.storeSlug,
    this.initialProductId,
  });

  @override
  State<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends State<StorefrontScreen> {
  static const int _pageSize = 20;

  // Stores already counted this app session — one visit per store per launch,
  // so scrolling in and out of a store doesn't inflate "Most Visited".
  static final Set<String> _countedVisits = {};

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Future<StorefrontVendor?> _vendorFuture;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _priceSort = 'none';
  bool _dealsOnly = false;
  double? _minPrice;
  double? _maxPrice;
  bool _isPinned = false;
  bool _isMuted = false;
  // Store balance (DB field: storeCredit) at this merchant. A customer can't
  // unsave a store while they still hold a balance there, so unsave stays
  // blocked until it reaches zero.
  double _storeBalance = 0;
  StreamSubscription<DocumentSnapshot>? _pinSubscription;

  // Trust & compliance lock — same source as create-plan/pay checks
  // (vendor_compliance/{vendorId}). While blocked the customer only sees the
  // first screen: no scrolling, no taps, just the suspension overlay.
  String _complianceStatus = 'active';
  String? _complianceMessage;

  bool get _storeBlocked => const {'suspended', 'banned', 'restricted'}
      .contains(_complianceStatus);

  // Pagination: the product stream is capped at [_productLimit] docs and the
  // cap grows as the customer scrolls near the bottom (lazy loading).
  int _productLimit = _pageSize;
  int _loadedCount = 0;

  // Cached product stream — rebuilding it on every setState (search, filter,
  // sort) resets the StreamBuilder to "waiting" and blanks the feed mid-scroll.
  // Recreated only when the vendor or the page cap actually changes.
  Stream<QuerySnapshot>? _productStream;
  String _streamVendorId = '';
  int _streamLimit = 0;
  List<QueryDocumentSnapshot> _lastProductDocs = const [];

  // Guards the one-time auto-open of a deep-linked product.
  bool _openedInitialProduct = false;

  @override
  void initState() {
    super.initState();
    _vendorFuture = _fetchVendorBySlug(widget.storeSlug);
    _scrollController.addListener(_maybeLoadMoreProducts);

    // Deep-linked product (from the website): fetch it and open its sheet once
    // the first frame is up, so the shopper resumes exactly where they were.
    if (widget.initialProductId != null && widget.initialProductId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openInitialProduct());
    }
  }

  Future<void> _openInitialProduct() async {
    if (_openedInitialProduct) return;
    _openedInitialProduct = true;
    try {
      final doc = await _firestore
          .collection('products')
          .doc(widget.initialProductId)
          .get();
      if (!mounted || !doc.exists) return;
      final product = Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      _showProductDetailsSheet(product, doc);
    } catch (e) {
      debugPrint("Could not open deep-linked product: $e");
    }
  }

  @override
  void dispose() {
    _pinSubscription?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  StorefrontFilters get _currentFilters => StorefrontFilters(
        priceSort: _priceSort,
        dealsOnly: _dealsOnly,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );

  Future<void> _openFilterSheet() async {
    final result = await StorefrontFilterSheet.show(context, _currentFilters);
    if (result == null || !mounted) return;
    setState(() {
      _priceSort = result.priceSort;
      _dealsOnly = result.dealsOnly;
      _minPrice = result.minPrice;
      _maxPrice = result.maxPrice;
    });
  }

  Stream<QuerySnapshot> _productStreamFor(String vendorId) {
    if (_productStream == null ||
        _streamVendorId != vendorId ||
        _streamLimit != _productLimit) {
      _streamVendorId = vendorId;
      _streamLimit = _productLimit;
      _productStream = _firestore
          .collection('products')
          .where('vendorId', isEqualTo: vendorId)
          .where('status', isEqualTo: 'approved')
          .limit(_productLimit)
          .snapshots();
    }
    return _productStream!;
  }

  // This store's campaigns — used to show live deal countdowns on product
  // cards and in the product details sheet. Cached like the product stream.
  Stream<QuerySnapshot>? _campaignsStream;
  String _campaignsVendorId = '';

  Stream<QuerySnapshot> _campaignsStreamFor(String vendorId) {
    if (_campaignsStream == null || _campaignsVendorId != vendorId) {
      _campaignsVendorId = vendorId;
      _campaignsStream = _firestore
          .collection('campaigns')
          .where('vendorId', isEqualTo: vendorId)
          .snapshots();
    }
    return _campaignsStream!;
  }

  /// productId -> the campaign whose countdown to show: a running timer
  /// beats an upcoming one; ties go to the newest campaign.
  Map<String, Campaign> _buildDealMap(List<QueryDocumentSnapshot> campaignDocs) {
    final map = <String, Campaign>{};
    for (final doc in campaignDocs) {
      try {
        if (doc.data() is! Map<String, dynamic>) continue;
        final campaign = Campaign.fromFirestore(doc);
        if (!campaign.hasTimer) continue;
        for (final pid in campaign.productIds) {
          final existing = map[pid];
          if (existing == null) {
            map[pid] = campaign;
          } else if (campaign.timerRunning && !existing.timerRunning) {
            map[pid] = campaign;
          }
        }
      } catch (e) {
        debugPrint('Skipping malformed campaign ${doc.id}: $e');
      }
    }
    return map;
  }

  void _maybeLoadMoreProducts() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final nearBottom = position.pixels >= position.maxScrollExtent - 400;
    // Only grow the limit once the current page has fully arrived
    if (nearBottom && _loadedCount >= _productLimit) {
      setState(() => _productLimit += _pageSize);
    }
  }

  Future<StorefrontVendor?> _fetchVendorBySlug(String slug) async {
    try {
      final slugQuery = await _firestore
          .collection('vendors')
          .where('store.slug', isEqualTo: slug)
          .limit(1)
          .get();

      if (slugQuery.docs.isNotEmpty) {
        final doc = slugQuery.docs.first;
        _checkPinStatus(doc.id);
        _loadMuteStatus(doc.id);
        _checkCompliance(doc.id);
        _recordVisit(doc.id);
        return StorefrontVendor(
          id: doc.id,
          data: doc.data(),
          doc: doc,
        );
      }

      final uidQuery = await _firestore.collection('vendors').doc(slug).get();
      if (uidQuery.exists) {
        _checkPinStatus(uidQuery.id);
        _loadMuteStatus(uidQuery.id);
        _checkCompliance(uidQuery.id);
        _recordVisit(uidQuery.id);
        return StorefrontVendor(
          id: uidQuery.id,
          data: uidQuery.data() as Map<String, dynamic>? ?? {},
          doc: uidQuery,
        );
      }
    } catch (e) {
      debugPrint("Error fetching vendor: $e");
    }
    return null;
  }

  void _checkPinStatus(String vendorId) {
    final user = _auth.currentUser;
    if (user == null) return;

    // Keep the subscription so it is cancelled in dispose — it used to leak
    // one live Firestore listener per storefront visit.
    _pinSubscription?.cancel();
    _pinSubscription = _firestore
        .collection('customers')
        .doc(user.uid)
        .collection('my_vendors')
        .doc(vendorId)
        .snapshots()
        .listen((doc) {
      if (mounted) {
        setState(() {
          _isPinned = doc.exists;
          _storeBalance = (doc.data()?['storeCredit'] ?? 0).toDouble();
        });
      }
    });
  }

  /// Records one storefront visit per store per app session. Feeds the
  /// "Most Visited" badge — a scheduled backend (compute-visibility) ranks
  /// stores by their rolling visit totals. Fire-and-forget: a failed count
  /// must never block the storefront.
  Future<void> _recordVisit(String vendorId) async {
    if (_countedVisits.contains(vendorId)) return;
    _countedVisits.add(vendorId);

    // Firestore rules are locked, so the count goes through the record-visit
    // edge function (admin SDK) instead of a direct write. Fire-and-forget.
    // customerId lets the backend dedupe campaign opens per customer per day.
    try {
      await Supabase.instance.client.functions.invoke('record-visit', body: {
        'vendorId': vendorId,
        'customerId': _auth.currentUser?.uid ?? '',
      });
    } catch (e) {
      _countedVisits.remove(vendorId); // allow a retry next open
      debugPrint("Visit count failed for $vendorId: $e");
    }
  }

  Future<void> _checkCompliance(String vendorId) async {
    try {
      final doc =
          await _firestore.collection('vendor_compliance').doc(vendorId).get();
      if (!doc.exists || !mounted) return;
      final data = doc.data()!;
      setState(() {
        _complianceStatus = data['status']?.toString() ?? 'active';
        _complianceMessage = data['publicMessage']?.toString();
      });
    } catch (e) {
      debugPrint("Error checking store compliance: $e");
    }
  }

  /// One-off read — mute state lives in `customers/{uid}.mutedStores` so the
  /// backend campaign fan-out can honour it too. Toggling updates locally.
  Future<void> _loadMuteStatus(String vendorId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc = await _firestore.collection('customers').doc(user.uid).get();
      final muted = List<String>.from((doc.data()?['mutedStores'] ?? []) as List);
      if (mounted) setState(() => _isMuted = muted.contains(vendorId));
    } catch (e) {
      debugPrint("Error loading mute status: $e");
    }
  }

  Future<void> _toggleMute(String vendorId, String storeName) async {
    final user = _auth.currentUser;
    if (user == null) {
      showAppSnackbar("Please log in to manage store notifications.", SnackbarType.info);
      return;
    }

    final muting = !_isMuted;
    setState(() => _isMuted = muting);
    try {
      await _firestore.collection('customers').doc(user.uid).set({
        'mutedStores': muting
            ? FieldValue.arrayUnion([vendorId])
            : FieldValue.arrayRemove([vendorId]),
      }, SetOptions(merge: true));
      showAppSnackbar(
        muting
            ? "Muted. You won't get notifications from $storeName."
            : "Unmuted. Notifications from $storeName are back on.",
        SnackbarType.success,
      );
    } catch (e) {
      if (mounted) setState(() => _isMuted = !muting); // roll back
      debugPrint("Error toggling mute: $e");
      showAppSnackbar("Could not update notifications. Please try again.", SnackbarType.error);
    }
  }

  Future<void> _togglePin(String vendorId) async {
    final user = _auth.currentUser;
    if (user == null) {
      showAppSnackbar("Please log in to save this store.", SnackbarType.info);
      return;
    }

    // A store you still hold a balance with can't be unsaved: the my_vendors
    // doc carries that balance, so removing it would orphan it. Spend it down
    // to zero to unsave.
    if (_isPinned && _storeBalance > 0) {
      showAppSnackbar(
        "You have a store balance here, so this store stays saved. Use it up to unsave.",
        SnackbarType.info,
      );
      return;
    }

    try {
      final docRef = _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('my_vendors')
          .doc(vendorId);

      if (_isPinned) {
        await docRef.delete();
        showAppSnackbar("Store unsaved.", SnackbarType.success);
      } else {
        await docRef.set({
          'vendorId': vendorId,
          'pinnedAt': FieldValue.serverTimestamp(),
          'lastInteraction': FieldValue.serverTimestamp(),
        });
        showAppSnackbar("Store saved.", SnackbarType.success);
      }
    } catch (e) {
      debugPrint("Error toggling storefront save: $e");
      showAppSnackbar("Could not update saved status. Please try again.", SnackbarType.error);
    }
  }

  void _showCartSheet(String vendorId, String storeName) {
    final user = _auth.currentUser;
    if (user == null) {
      showAppSnackbar("Please log in to view your shopping cart.", SnackbarType.info);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return StorefrontCartSheet(
              vendorId: vendorId,
              storeName: storeName,
              customerUid: user.uid,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StorefrontVendor?>(
      future: _vendorFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: KorraColors.surface,
            appBar: KorraHeader(title: "Loading...", showLeadingIcon: true),
            body: Center(child: CircularProgressIndicator(color: KorraColors.brand)),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            backgroundColor: KorraColors.surface,
            appBar: const KorraHeader(title: "Not Found", showLeadingIcon: true),
            body: _buildErrorState("Storefront Not Found", "We couldn't locate this storefront. The link might be broken or expired."),
          );
        }

        final vendor = snapshot.data!;
        final vendorId = vendor.id;
        final vendorData = vendor.data;

        final storeMap = vendorData['store'] as Map<String, dynamic>? ?? {};
        final personalMap = vendorData['personal'] as Map<String, dynamic>? ?? {};
        final socialsMap = vendorData['socials'] as Map<String, dynamic>? ?? {};

        final storeName = storeMap['storeName'] ?? 'Merchant Store';
        final description = storeMap['description'] ?? 'Welcome to my online store. Feel free to browse and reserve items.';
        final logoUrl = storeMap['logoUrl'] ?? '';
        final coverUrl = storeMap['coverUrl'] ?? '';
        final phone = storeMap['contactPhone'] ?? personalMap['phone'] ?? '';

        // Walk-in address: only shown when the merchant filled it in settings
        final locationMap = vendorData['location'] as Map<String, dynamic>? ?? {};
        final walkInAddress = [
          (locationMap['address'] ?? '').toString().trim(),
          (locationMap['city'] ?? '').toString().trim(),
          (locationMap['state'] ?? '').toString().trim(),
        ].where((part) => part.isNotEmpty).join(', ');

        final whatsapp = socialsMap['whatsappGroup'];
        final instagram = socialsMap['instagram'];
        final tiktok = socialsMap['tiktok'];

        final blocked = _storeBlocked;

        return Scaffold(
          backgroundColor: KorraColors.surface,
          body: Stack(
            children: [
              // Frozen while blocked: touches absorbed, scrolling disabled —
              // the customer keeps only the first screen behind the overlay.
              AbsorbPointer(
                absorbing: blocked,
                child: CustomScrollView(
            controller: _scrollController,
            physics: blocked
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            slivers: [
              // Parallax cover photo collapsing into a pinned app bar,
              // with a glassmorphic logo card floating over the cover.
              StorefrontSliverAppBar(
                storeName: storeName,
                logoUrl: logoUrl,
                coverUrl: coverUrl,
                actions: [
                  GlassIconButton(
                    icon: _isMuted ? Icons.notifications_off_outlined : Iconsax.notification,
                    onPressed: () => _toggleMute(vendorId, storeName),
                    tooltip: _isMuted ? "Unmute store" : "Mute store",
                  ),
                  SizedBox(width: 4.w),
                  StorefrontCartButton(
                    vendorId: vendorId,
                    onPressed: () => _showCartSheet(vendorId, storeName),
                  ),
                  SizedBox(width: 4.w),
                  GlassIconButton(
                    icon: Iconsax.receipt_item,
                    onPressed: () => _showPurchaseHistorySheet(vendorId, storeName),
                    tooltip: "Purchase History",
                  ),
                ],
              ),

              // Store details header (rating, pin, description, contacts)
              SliverToBoxAdapter(
                child: StorefrontHeader(
                  vendorId: vendorId,
                  storeName: storeName,
                  description: description,
                  address: walkInAddress,
                  phone: phone,
                  whatsapp: whatsapp,
                  instagram: instagram,
                  tiktok: tiktok,
                  isPinned: _isPinned,
                  onPinToggle: () => _togglePin(vendorId),
                  onLaunchSocial: _launchSocial,
                ),
              ),

              // Product Feed — paginated Firestore stream. Nested inside the
              // store's campaigns stream so cards can show a live deal
              // countdown (StreamBuilder is transparent to the sliver
              // protocol — only the innermost builder's return matters).
              StreamBuilder<QuerySnapshot>(
                  stream: _campaignsStreamFor(vendorId),
                  builder: (context, campaignSnapshot) {
                    final dealMap = _buildDealMap(campaignSnapshot.data?.docs ?? []);
                    return StreamBuilder<QuerySnapshot>(
                  stream: _productStreamFor(vendorId),
                  builder: (context, productSnapshot) {
                    // Keep the previous page on screen while a bigger page (or
                    // the first page) streams in — never blank an active feed.
                    final liveDocs = productSnapshot.data?.docs;
                    if (liveDocs == null && _lastProductDocs.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator(color: KorraColors.brand)),
                      );
                    }

                    final docs = liveDocs ?? _lastProductDocs;
                    if (liveDocs != null) {
                      _lastProductDocs = liveDocs;
                      _loadedCount = liveDocs.length;
                    }
                    // A full page means there may be more products behind the cap
                    final hasMore = docs.length >= _productLimit;
                    final products = docs
                        .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                        .toList();

                    return _buildProductSlivers(
                      products: products,
                      docs: docs,
                      hasMore: hasMore,
                      storeName: storeName,
                      dealMap: dealMap,
                    );
                  },
                );
                  },
                ),
            ],
                ),
              ),

              if (blocked)
                StorefrontSuspendedOverlay(
                  storeName: storeName,
                  message: _complianceMessage,
                ),
            ],
          ),
        );
      },
    );
  }

  /// Product feed slivers: featured strip, filter bar, masonry grid and the
  /// load-more spinner.
  Widget _buildProductSlivers({
    required List<Product> products,
    required List<DocumentSnapshot> docs,
    required bool hasMore,
    required String storeName,
    Map<String, Campaign> dealMap = const {},
  }) {
    // Get unique categories
                  final categories = {'All', ...products.map((p) => p.category)};

                  // Filter products: search, category, deals-only, price range
                  final filteredProducts = products.where((p) {
                    final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        p.code.toLowerCase().contains(_searchQuery.toLowerCase());
                    final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
                    final matchesDeals = !_dealsOnly ||
                        (p.activeCampaignTag != null && p.activeCampaignTag!.trim().isNotEmpty);
                    final effectivePrice = (p.activeDiscountedPrice != null && p.activeDiscountedPrice! > 0)
                        ? p.activeDiscountedPrice!
                        : p.price;
                    final matchesPrice = (_minPrice == null || effectivePrice >= _minPrice!) &&
                        (_maxPrice == null || effectivePrice <= _maxPrice!);
                    return matchesSearch && matchesCategory && matchesDeals && matchesPrice;
                  }).toList();

                  // Sort products if priceSort is active
                  if (_priceSort == 'asc') {
                    filteredProducts.sort((a, b) {
                      final ap = (a.activeDiscountedPrice != null && a.activeDiscountedPrice! > 0) ? a.activeDiscountedPrice! : a.price;
                      final bp = (b.activeDiscountedPrice != null && b.activeDiscountedPrice! > 0) ? b.activeDiscountedPrice! : b.price;
                      return ap.compareTo(bp);
                    });
                  } else if (_priceSort == 'desc') {
                    filteredProducts.sort((a, b) {
                      final ap = (a.activeDiscountedPrice != null && a.activeDiscountedPrice! > 0) ? a.activeDiscountedPrice! : a.price;
                      final bp = (b.activeDiscountedPrice != null && b.activeDiscountedPrice! > 0) ? b.activeDiscountedPrice! : b.price;
                      return bp.compareTo(ap);
                    });
                  }

                  final featuredProducts = products.where((p) => p.isFeatured).toList();

                  return SliverMainAxisGroup(
                    slivers: [
                      // Search bar sits above Featured/Flash strips (matches
                      // the website); collections + sort stay by the grid.
                      SliverToBoxAdapter(
                        child: StorefrontSearchField(
                          searchController: _searchController,
                          searchQuery: _searchQuery,
                          onSearchChanged: (val) => setState(() => _searchQuery = val),
                          storeName: storeName,
                        ),
                      ),

                      // Featured Products horizontal scroll view (Pinterest push)
                      if (featuredProducts.isNotEmpty && _selectedCategory == 'All' && _searchQuery.isEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.star_rounded, color: Colors.amber, size: 20.sp),
                                    SizedBox(width: 6.w),
                                    Text(
                                      "Featured Products",
                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w800,
                                        color: KorraColors.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                SizedBox(
                                  height: 185.h,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: featuredProducts.length,
                                    itemBuilder: (context, index) {
                                      final product = featuredProducts[index];
                                      final matchIndex = docs.indexWhere((d) => d.id == product.id);
                                      final rawDoc = matchIndex >= 0 ? docs[matchIndex] : null;
                                      return Padding(
                                        padding: EdgeInsets.only(right: 12.w),
                                        child: SizedBox(
                                          width: 145.w,
                                          child: StorefrontProductCard(
                                            product: product,
                                            rawDoc: rawDoc,
                                            onTap: (p, doc) => _showProductDetailsSheet(p, doc, dealMap[p.id]),
                                            // Fixed-height strip: image flexes,
                                            // name/price always visible.
                                            fixedHeight: true,
                                            deal: dealMap[product.id],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                const Divider(color: Color(0xFFF2F4F7)),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Search & Category Bar
                      SliverToBoxAdapter(
                        child: StorefrontFilterBar(
                          searchController: _searchController,
                          searchQuery: _searchQuery,
                          onSearchChanged: (val) => setState(() => _searchQuery = val),
                          categories: categories,
                          selectedCategory: _selectedCategory,
                          onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
                          storeName: storeName,
                          priceSort: _priceSort,
                          onPriceSortChanged: (sort) => setState(() => _priceSort = sort),
                          onOpenFilters: _openFilterSheet,
                          activeFilterCount: _currentFilters.activeCount,
                          hideSearch: true,
                        ),
                      ),

                      // Pinterest/Temu Masonry grid layout
                      filteredProducts.isEmpty
                          ? SliverFillRemaining(
                              hasScrollBody: false,
                              child: _buildEmptyState(),
                            )
                          : SliverPadding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                              sliver: SliverMasonryGrid.count(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12.h,
                                crossAxisSpacing: 12.w,
                                itemBuilder: (context, index) {
                                  final product = filteredProducts[index];
                                  final matchIndex = docs.indexWhere((d) => d.id == product.id);
                                  final rawDoc = matchIndex >= 0 ? docs[matchIndex] : null;
                                  return StorefrontProductCard(
                                    product: product,
                                    rawDoc: rawDoc,
                                    onTap: (p, doc) => _showProductDetailsSheet(p, doc, dealMap[p.id]),
                                    deal: dealMap[product.id],
                                  );
                                },
                                childCount: filteredProducts.length,
                              ),
                            ),

                      // Lazy-load indicator: visible while more pages remain
                      if (hasMore && filteredProducts.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.h),
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
                    ],
                  );
  }

  // 🛍️ PRODUCT DETAILS BOTTOM SHEET
  void _showProductDetailsSheet(Product product, DocumentSnapshot? rawDoc, [Campaign? deal]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return StorefrontProductDetailsSheet(
              product: product,
              rawDoc: rawDoc,
              deal: deal,
              storeSlug: widget.storeSlug,
              scrollController: scrollController,
              onAddToCart: (prod, qty, variantLabel) {
                _addToCart(prod, qty, variantLabel);
              },
              onPayInstallments: (doc, variantLabel) {
                Navigator.pop(context); // Close sheet
                _navigateToProductPlan(product, doc, variantLabel);
              },
            );
          },
        );
      },
    );
  }

  void _addToCart(Product product, int quantity, [String? variantLabel]) {
    final user = _auth.currentUser;
    if (user == null) {
      showAppSnackbar("Please log in to add items to your cart.", SnackbarType.info);
      return;
    }

    CartService.instance
        .addToCart(product.vendorId, product, quantity, variantLabel: variantLabel);
    final what =
        variantLabel != null ? "${product.name} ($variantLabel)" : product.name;
    showAppSnackbar("Added $quantity x $what to cart!", SnackbarType.success);
  }



  void _navigateToProductPlan(Product product, DocumentSnapshot? rawDoc,
      [String? variantLabel]) async {
    final user = _auth.currentUser;
    final productFetch = ProductFetchResult(
      data: rawDoc != null
          ? (rawDoc.data() as Map<String, dynamic>? ?? {})
          : {
              'vendorId': product.vendorId,
              'storeName': product.storeName,
              'code': product.code,
              'name': product.name,
              'description': product.description,
              'price': product.price,
              'availableStock': product.availableStock,
              'images': product.images,
              'category': product.category,
              'allowReservation': product.allowReservation,
              'modelType': product.modelType,
              'isFeatured': product.isFeatured,
              // Active values only, so an expired campaign never carries a
              // stale tag/discount into installment plan creation.
              'campaignTag': product.activeCampaignTag,
              'discountedPrice': product.activeDiscountedPrice,
            },
      id: rawDoc?.id ?? product.id,
    );

    if (user == null) {
      showAppSnackbar("Please log in to purchase or reserve this item.", SnackbarType.info);
      Get.toNamed(
        Routes.roleLoginScreen,
        arguments: {
          'redirect': Routes.customerCreatePlan,
          'redirectArgs': {
            'product': productFetch,
            'customerUid': '',
            'walletBalance': 0.0,
            'variantLabel': variantLabel,
          }
        },
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: KorraColors.brand)),
      );

      final customerDoc = await _firestore.collection('customers').doc(user.uid).get();

      if (mounted) Navigator.pop(context);

      if (!customerDoc.exists || customerDoc.data() == null) {
        showAppSnackbar("Customer profile data not found.", SnackbarType.error);
        return;
      }

      final customer = Customer.fromMap(customerDoc.data()!);

      Get.toNamed(
        Routes.customerCreatePlan,
        arguments: {
          'product': productFetch,
          'customer': customer,
          'customerUid': user.uid,
          'walletBalance': customer.availableBalance,
          'variantLabel': variantLabel,
        },
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Error fetching customer for plan: $e");
      showAppSnackbar("Failed to load customer profile. Please try again.", SnackbarType.error);
    }
  }

  void _showPurchaseHistorySheet(String vendorId, String storeName) {
    final user = _auth.currentUser;
    if (user == null) {
      showAppSnackbar("Please log in to view your purchases.", SnackbarType.info);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return StorefrontPurchaseHistorySheet(
              vendorId: vendorId,
              storeName: storeName,
              customerUid: user.uid,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  Future<void> _launchSocial(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        showAppSnackbar("Could not open link.", SnackbarType.error);
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }
  }

  Widget _buildErrorState(String title, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.info_circle5, size: 48.sp, color: KorraColors.brand),
            SizedBox(height: 16.h),
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800, color: KorraColors.textDark),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13.5.sp, color: KorraColors.textBody, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.box, size: 40.sp, color: KorraColors.textHint),
            SizedBox(height: 16.h),
            Text(
              "No products found",
              style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700, color: KorraColors.textDark),
            ),
            SizedBox(height: 6.h),
            Text(
              "This merchant hasn't listed any active products in this category yet.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12.5.sp, color: KorraColors.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
