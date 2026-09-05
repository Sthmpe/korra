// lib/presentation/vendor/product/widgets/campaigns/product_selector_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../config/constants/colors.dart';
import '../../../../../config/constants/sizes.dart';
import '../../../../../data/models/product_model.dart';

class ProductSelectorPage extends StatefulWidget {
  final String vendorId;
  final List<String> initiallySelectedIds;

  const ProductSelectorPage({
    super.key,
    required this.vendorId,
    required this.initiallySelectedIds,
  });

  @override
  State<ProductSelectorPage> createState() => _ProductSelectorPageState();
}

class _ProductSelectorPageState extends State<ProductSelectorPage> {
  final List<Product> _allProducts = [];
  final List<Product> _filteredProducts = [];
  final Set<String> _selectedIds = {};
  
  bool _isLoading = true;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.initiallySelectedIds);
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('products')
          .where('vendorId', isEqualTo: widget.vendorId)
          .get();

      final List<Product> list = snap.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
      
      // Selectable = in stock AND not already in a live campaign. One campaign,
      // one tag per product: a product whose tag/discount is still active is
      // hidden so its UI can never carry two campaigns at once. Once its
      // campaign ends/expires/deletes (promoActive false), it reappears here
      // and can take a fresh campaign and tag.
      final List<Product> inStockList =
          list.where((p) => p.availableStock > 0 && !p.promoActive).toList();

      setState(() {
        _allProducts.clear();
        _allProducts.addAll(inStockList);
        _filterProducts();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading products: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterProducts() {
    setState(() {
      if (_searchQuery.trim().isEmpty) {
        _filteredProducts.clear();
        _filteredProducts.addAll(_allProducts);
      } else {
        final query = _searchQuery.toLowerCase();
        _filteredProducts.clear();
        _filteredProducts.addAll(
          _allProducts.where((p) => p.name.toLowerCase().contains(query)),
        );
      }
    });
  }

  void _toggleSelection(Product product) {
    setState(() {
      if (_selectedIds.contains(product.id)) {
        _selectedIds.remove(product.id);
      } else {
        _selectedIds.add(product.id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      for (final p in _filteredProducts) {
        _selectedIds.add(p.id);
      }
    });
  }

  void _deselectAll() {
    setState(() {
      for (final p in _filteredProducts) {
        _selectedIds.remove(p.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _filteredProducts.isNotEmpty &&
        _filteredProducts.every((p) => _selectedIds.contains(p.id));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: KorraColors.textDark),
        ),
        title: Text(
          "Select Target Products",
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: KorraColors.textDark,
          ),
        ),
        actions: [
          if (!_isLoading && _filteredProducts.isNotEmpty)
            TextButton(
              onPressed: allSelected ? _deselectAll : _selectAll,
              child: Text(
                allSelected ? "Deselect All" : "Select All",
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFA54600),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _filterProducts();
                });
              },
              style: GoogleFonts.inter(fontSize: 13.sp),
              decoration: InputDecoration(
                hintText: "Search in-stock inventory...",
                prefixIcon: const Icon(Icons.search, size: 18),
                fillColor: const Color(0xFFF9FAFB),
                filled: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Main Inventory Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFA54600)))
                : (_filteredProducts.isEmpty
                    ? Center(
                        child: Text(
                          "No in-stock products found",
                          style: GoogleFonts.inter(color: Colors.grey.shade500),
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.all(16.w),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12.h,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          final isSelected = _selectedIds.contains(product.id);

                          return GestureDetector(
                            onTap: () => _toggleSelection(product),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(KorraSizes.cardRadius.r),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFA54600)
                                      : const Color(0xFFEAECF0),
                                  width: isSelected ? 2.w : 1.w,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Product Image
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(KorraSizes.cardRadius.r - 1.r),
                                          ),
                                          child: product.images.isNotEmpty
                                              ? Image.network(
                                                  product.images.first,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  color: Colors.grey.shade100,
                                                  alignment: Alignment.center,
                                                  child: Icon(
                                                    Icons.shopping_bag_outlined,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      // Title & Price
                                      Padding(
                                        padding: EdgeInsets.all(8.w),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w700,
                                                color: KorraColors.textDark,
                                              ),
                                            ),
                                            SizedBox(height: 2.h),
                                            Text(
                                              "₦${product.price.toStringAsFixed(0)}",
                                              style: GoogleFonts.inter(
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFFA54600),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Selection overlay indicator
                                  if (isSelected)
                                    Positioned(
                                      top: 8.w,
                                      right: 8.w,
                                      child: Container(
                                        padding: EdgeInsets.all(2.w),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFA54600),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      )),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: ElevatedButton(
            onPressed: _selectedIds.isEmpty
                ? null
                : () {
                    // Collect selected products and pop
                    final selectedProducts = _allProducts
                        .where((p) => _selectedIds.contains(p.id))
                        .toList();
                    Navigator.pop(context, selectedProducts);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA54600),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
              ),
              elevation: 0,
            ),
            child: Text(
              "Done (${_selectedIds.length} Selected)",
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
