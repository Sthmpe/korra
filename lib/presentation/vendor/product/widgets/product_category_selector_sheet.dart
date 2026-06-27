import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/constants/product_categories.dart';

class ProductCategorySelectorSheet extends StatefulWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const ProductCategorySelectorSheet({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  State<ProductCategorySelectorSheet> createState() =>
      _ProductCategorySelectorSheetState();
}

class _ProductCategorySelectorSheetState
    extends State<ProductCategorySelectorSheet> {
  late List<String> _filteredCategories;
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _filteredCategories = List.from(ProductCategories.flatList);
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            SizedBox(height: 12.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "Select Category",
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 16.h),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (query) {
                  setState(() {
                    _filteredCategories =
                        ProductCategories.searchCategories(query);
                  });
                },
                style: GoogleFonts.inter(fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: "Search categories...",
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                  prefixIcon: const Icon(
                    Iconsax.search_normal,
                    color: Colors.grey,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xFFEAECF0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xFFEAECF0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: KorraColors.brand),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // List View
            Expanded(
              child: _filteredCategories.isEmpty
                  ? Center(
                      child: Text(
                        "No categories found",
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: _filteredCategories.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFF2F4F7)),
                      itemBuilder: (context, index) {
                        final cat = _filteredCategories[index];
                        return ListTile(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 20.w),
                          title: Text(
                            cat,
                            style: GoogleFonts.inter(fontSize: 15.sp),
                          ),
                          onTap: () {
                            widget.onCategorySelected(cat);
                            Navigator.pop(context);
                          },
                          trailing: widget.selectedCategory == cat
                              ? const Icon(
                                  Iconsax.tick_circle,
                                  color: KorraColors.brand,
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
