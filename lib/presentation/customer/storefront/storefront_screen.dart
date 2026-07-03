import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import 'widgets/marketplace_seeder_util.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../../data/models/customer/customer_model.dart';
import '../../../../data/models/customer/plans.dart';
import '../../../../data/models/product_model.dart';
import '../../shared/widgets/korra_header.dart';
import '../../shared/widgets/show_app_snackbar.dart';

import 'widgets/storefront_cart_sheet.dart';
import 'widgets/storefront_filter_bar.dart';
import 'widgets/storefront_header.dart';
import 'widgets/storefront_product_card.dart';
import 'widgets/storefront_purchase_history_sheet.dart';
import 'widgets/storefront_product_details_sheet.dart';
import 'widgets/cart_service.dart';
import 'widgets/mock_marketplace_data.dart';

class StorefrontScreen extends StatefulWidget {
  final String storeSlug;

  const StorefrontScreen({super.key, required this.storeSlug});

  @override
  State<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends State<StorefrontScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Future<DocumentSnapshot?> _vendorFuture;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _priceSort = 'none';
  bool _isPinned = false;

  @override
  void initState() {
    super.initState();
    _vendorFuture = _fetchVendorBySlug(widget.storeSlug);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<DocumentSnapshot?> _fetchVendorBySlug(String slug) async {
    try {
      final slugQuery = await _firestore
          .collection('vendors')
          .where('store.slug', isEqualTo: slug)
          .limit(1)
          .get();

      if (slugQuery.docs.isNotEmpty) {
        final doc = slugQuery.docs.first;
        _checkPinStatus(doc.id);
        return doc;
      }

      final uidQuery = await _firestore.collection('vendors').doc(slug).get();
      if (uidQuery.exists) {
        _checkPinStatus(uidQuery.id);
        return uidQuery;
      }
    } catch (e) {
      debugPrint("Error fetching vendor: $e");
    }
    return null;
  }

  void _checkPinStatus(String vendorId) {
    final user = _auth.currentUser;
    if (user == null) return;

    _firestore
        .collection('customers')
        .doc(user.uid)
        .collection('my_vendors')
        .doc(vendorId)
        .snapshots()
        .listen((doc) {
      if (mounted) {
        setState(() {
          _isPinned = doc.exists;
        });
      }
    });
  }

  Future<void> _togglePin(String vendorId) async {
    final user = _auth.currentUser;
    if (user == null) {
      showAppSnackbar("Please log in to follow this merchant.", SnackbarType.info);
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
        showAppSnackbar("Store unpinned successfully.", SnackbarType.success);
      } else {
        await docRef.set({
          'vendorId': vendorId,
          'pinnedAt': FieldValue.serverTimestamp(),
          'lastInteraction': FieldValue.serverTimestamp(),
        });
        showAppSnackbar("Store pinned to My Merchants!", SnackbarType.success);
      }
    } catch (e) {
      debugPrint("Error toggling storefront pin: $e");
      showAppSnackbar("Could not update pin status. Please try again.", SnackbarType.error);
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
    return FutureBuilder<DocumentSnapshot?>(
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

        final vendorDoc = snapshot.data!;
        final vendorId = vendorDoc.id;
        final vendorData = vendorDoc.data() as Map<String, dynamic>? ?? {};

        final storeMap = vendorData['store'] as Map<String, dynamic>? ?? {};
        final personalMap = vendorData['personal'] as Map<String, dynamic>? ?? {};
        final socialsMap = vendorData['socials'] as Map<String, dynamic>? ?? {};

        final storeName = storeMap['storeName'] ?? 'Merchant Store';
        final description = storeMap['description'] ?? 'Welcome to my online store. Feel free to browse and reserve items.';
        final logoUrl = storeMap['logoUrl'] ?? '';
        final coverUrl = storeMap['coverUrl'] ?? '';
        final phone = storeMap['contactPhone'] ?? personalMap['phone'] ?? '';
        final email = personalMap['email'] ?? '';

        final whatsapp = socialsMap['whatsappGroup'];
        final instagram = socialsMap['instagram'];
        final twitter = socialsMap['twitter'];

        return Scaffold(
          backgroundColor: KorraColors.surface,
          appBar: KorraHeader(
            title: storeName,
            showLeadingIcon: true,
            trailingActions: [
              IconButton(
                icon: Icon(Icons.playlist_add_rounded, size: 22.sp, color: Colors.grey.shade600),
                onPressed: () => seedMockMarketplace(context, _auth.currentUser?.uid ?? ''),
                tooltip: "Seed Mock Marketplace",
              ),
              ValueListenableBuilder<Map<String, List<CartItem>>>(
                valueListenable: CartService.instance.cartsNotifier,
                builder: (context, carts, _) {
                  final items = carts[vendorId] ?? [];
                  final count = items.fold(0, (sum, item) => sum + item.quantity);

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.shopping_bag_rounded, size: 24.sp, color: const Color(0xFFA54600)),
                        onPressed: () => _showCartSheet(vendorId, storeName),
                        tooltip: "View Cart",
                      ),
                      if (count > 0)
                        Positioned(
                          top: 4.h,
                          right: 4.w,
                          child: Container(
                            padding: EdgeInsets.all(3.w),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: BoxConstraints(
                              minWidth: 18.w,
                              minHeight: 18.w,
                            ),
                            child: Center(
                              child: Text(
                                count.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              IconButton(
                icon: Icon(Iconsax.receipt_item, size: 22.sp, color: Colors.grey.shade700),
                onPressed: () => _showPurchaseHistorySheet(vendorId, storeName),
                tooltip: "Purchase History",
              ),
            ],
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Branded Cover Banner & Store details header
              SliverToBoxAdapter(
                child: StorefrontHeader(
                  vendorId: vendorId,
                  storeName: storeName,
                  description: description,
                  logoUrl: logoUrl,
                  coverUrl: coverUrl,
                  phone: phone,
                  email: email,
                  whatsapp: whatsapp,
                  instagram: instagram,
                  twitter: twitter,
                  isPinned: _isPinned,
                  onPinToggle: () => _togglePin(vendorId),
                  onLaunchSocial: _launchSocial,
                ),
              ),

              // Product Feed Selector and Search Filters
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('products')
                    .where('vendorId', isEqualTo: vendorId)
                    .where('status', isEqualTo: 'approved')
                    .snapshots(),
                builder: (context, productSnapshot) {
                  if (productSnapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator(color: KorraColors.brand)),
                    );
                  }

                  final docs = productSnapshot.data?.docs ?? [];
                  final dbProducts = docs
                      .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                      .toList();
                  final products = dbProducts.isNotEmpty
                      ? dbProducts
                      : MockMarketplaceData.getProductsForVendor(vendorId);

                  // Get unique categories
                  final categories = {'All', ...products.map((p) => p.category)};

                  // Filter products based on search query and category
                  final filteredProducts = products.where((p) {
                    final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        p.code.toLowerCase().contains(_searchQuery.toLowerCase());
                    final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
                    return matchesSearch && matchesCategory;
                  }).toList();

                  // Sort products if priceSort is active
                  if (_priceSort == 'asc') {
                    filteredProducts.sort((a, b) {
                      final ap = (a.discountedPrice != null && a.discountedPrice! > 0) ? a.discountedPrice! : a.price;
                      final bp = (b.discountedPrice != null && b.discountedPrice! > 0) ? b.discountedPrice! : b.price;
                      return ap.compareTo(bp);
                    });
                  } else if (_priceSort == 'desc') {
                    filteredProducts.sort((a, b) {
                      final ap = (a.discountedPrice != null && a.discountedPrice! > 0) ? a.discountedPrice! : a.price;
                      final bp = (b.discountedPrice != null && b.discountedPrice! > 0) ? b.discountedPrice! : b.price;
                      return bp.compareTo(ap);
                    });
                  }

                  final featuredProducts = products.where((p) => p.isFeatured).toList();

                  return SliverMainAxisGroup(
                    slivers: [
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
                                            onTap: _showProductDetailsSheet,
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
                                    onTap: _showProductDetailsSheet,
                                  );
                                },
                                childCount: filteredProducts.length,
                              ),
                            ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 🛍️ PRODUCT DETAILS BOTTOM SHEET
  void _showProductDetailsSheet(Product product, DocumentSnapshot? rawDoc) {
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
              scrollController: scrollController,
              onAddToCart: (prod, qty) {
                _addToCart(prod, qty);
              },
              onPayInstallments: (doc) {
                Navigator.pop(context); // Close sheet
                _navigateToProductPlan(product, doc);
              },
            );
          },
        );
      },
    );
  }

  void _addToCart(Product product, int quantity) {
    final user = _auth.currentUser;
    if (user == null) {
      showAppSnackbar("Please log in to add items to your cart.", SnackbarType.info);
      return;
    }

    CartService.instance.addToCart(product.vendorId, product, quantity);
    showAppSnackbar("Added $quantity x ${product.name} to cart!", SnackbarType.success);
  }



  void _navigateToProductPlan(Product product, DocumentSnapshot? rawDoc) async {
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
              'campaignTag': product.campaignTag,
              'discountedPrice': product.discountedPrice,
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
