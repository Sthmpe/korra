import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/constants/colors.dart';
import '../../../config/constants/sizes.dart';
import '../../../config/routes/app_routes.dart';
import 'widgets/discover_store_list_item.dart';
import '../storefront/widgets/mock_marketplace_data.dart';

class StorePage extends StatefulWidget {
  final String customerUid;

  const StorePage({super.key, required this.customerUid});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KorraColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏷️ PAGE TITLE & HEADER
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Stores",
                  style: GoogleFonts.inter(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: KorraColors.textDark,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "Discover and browse your favorite merchants",
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    color: KorraColors.textBody,
                  ),
                ),
              ],
            ),
          ),

          // 🔍 GLOBAL STORE SEARCH INPUT
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: KorraColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.015),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                children: [
                  Icon(Iconsax.search_normal, size: 20.sp, color: KorraColors.textHint),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: "Search store name or store code...",
                        hintStyle: GoogleFonts.inter(fontSize: 14.sp, color: KorraColors.textHint),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: GoogleFonts.inter(fontSize: 14.sp, color: KorraColors.textDark),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: Icon(Icons.close, size: 18.sp, color: KorraColors.textHint),
                    ),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🌐 DISCOVER MERCHANTS SECTION
                  _buildDiscoverStoresSection(),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. DISCOVER STORES SECTION
  Widget _buildDiscoverStoresSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('vendors')
          .where('status', isNotEqualTo: 'banned')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: EdgeInsets.all(24.r),
            child: const Center(child: CircularProgressIndicator(color: KorraColors.brand)),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final bool useMock = docs.isEmpty;

        final List<Map<String, dynamic>> mockFiltered = [];
        if (useMock) {
          final query = _searchQuery.toLowerCase();
          for (final vendor in MockMarketplaceData.mockVendors) {
            final storeMap = vendor['store'] as Map<String, dynamic>? ?? {};
            final name = (storeMap['storeName'] ?? '').toString().toLowerCase();
            final slug = (storeMap['slug'] ?? '').toString().toLowerCase();
            final vendorId = vendor['uid'].toString().toLowerCase();
            if (name.contains(query) || slug.contains(query) || vendorId.contains(query)) {
              mockFiltered.add(vendor);
            }
          }
        }

        // Apply local search filter
        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final storeMap = data['store'] as Map<String, dynamic>? ?? {};

          final name = (storeMap['storeName'] ?? '').toString().toLowerCase();
          final slug = (storeMap['slug'] ?? '').toString().toLowerCase();
          final code = (storeMap['storeCode'] ?? '').toString().toLowerCase(); // Support unique code lookup
          final vendorId = doc.id.toLowerCase();

          final query = _searchQuery.toLowerCase();
          return name.contains(query) || slug.contains(query) || code.contains(query) || vendorId.contains(query);
        }).toList();

        final totalCount = useMock ? mockFiltered.length : filteredDocs.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Text(
                _searchQuery.isEmpty ? "Explore Stores" : "Search Results ($totalCount)",
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: KorraColors.textDark,
                ),
              ),
            ),
            if (totalCount == 0)
              _buildSearchEmptyState()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: totalCount,
                itemBuilder: (context, index) {
                  final String vendorId;
                  final String name;
                  final String description;
                  final String logoUrl;
                  final String slug;

                  if (useMock) {
                    final vendor = mockFiltered[index];
                    vendorId = vendor['uid'];
                    final storeMap = vendor['store'] as Map<String, dynamic>? ?? {};
                    name = storeMap['storeName'] ?? 'Unknown Merchant';
                    description = storeMap['description'] ?? 'No store description available.';
                    logoUrl = storeMap['logoUrl'] ?? '';
                    slug = storeMap['slug'] ?? vendorId;
                  } else {
                    final doc = filteredDocs[index];
                    vendorId = doc.id;
                    final vendorData = doc.data() as Map<String, dynamic>? ?? {};
                    final storeMap = vendorData['store'] as Map<String, dynamic>? ?? {};
                    name = storeMap['storeName'] ?? 'Unknown Merchant';
                    description = storeMap['description'] ?? 'No store description available.';
                    logoUrl = storeMap['logoUrl'] ?? '';
                    slug = storeMap['slug'] ?? vendorId;
                  }

                  return DiscoverStoreListItem(
                    vendorId: vendorId,
                    name: name,
                    description: description,
                    logoUrl: logoUrl,
                    slug: slug,
                  );
                },
              ),
          ],
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
