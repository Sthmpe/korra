// lib/presentation/customer/storefront/widgets/storefront_filter_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';

class StorefrontFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final Set<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final String storeName;

  // Price sorting parameters
  final String priceSort; // 'none' | 'asc' | 'desc'
  final Function(String) onPriceSortChanged;

  const StorefrontFilterBar({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.storeName,
    required this.priceSort,
    required this.onPriceSortChanged,
  });

  // Resolve representative category icons/illustrations
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'all':
        return Icons.grid_view_rounded;
      case 'apparel':
        return Icons.checkroom_rounded;
      case 'footwear':
        return Icons.ice_skating_rounded; // Represents shoes/boots
      case 'household':
        return Icons.home_work_rounded;
      case 'decor':
        return Icons.chair_rounded;
      case 'audio':
        return Icons.headphones_rounded;
      case 'wearables':
        return Icons.watch_rounded;
      case 'peripherals':
        return Icons.keyboard_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input Field ("Search product in [Store Name]")
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
          child: Container(
            height: 46.h,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.r),
                bottomLeft: Radius.circular(10.r),
                topRight: Radius.circular(16.r),
                bottomRight: Radius.circular(16.r),
              ),
              border: Border.all(color: KorraColors.borderLight),
            ),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Icon(Iconsax.search_normal_1, size: 18.sp, color: KorraColors.textHint),
                ),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    style: GoogleFonts.inter(
                      fontSize: 13.5.sp,
                      color: KorraColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: "Search product in $storeName...",
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: KorraColors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                          topRight: Radius.circular(0),
                          bottomRight: Radius.circular(0),
                        ),
                      ),
                      contentPadding: EdgeInsets.only(bottom: 2.h),
                    ),
                  ),
                ),
                if (searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Icon(Icons.close, size: 18.sp, color: KorraColors.textHint),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Shein/Temu Circular Category items row
        if (categories.length > 1) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
            child: Text(
              "Shop by Collection",
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            height: 84.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              children: categories.map((cat) {
                final isSelected = selectedCategory == cat;
                return Padding(
                  padding: EdgeInsets.only(right: 14.w),
                  child: GestureDetector(
                    onTap: () => onCategorySelected(cat),
                    child: Column(
                      children: [
                        // Shein/Temu Circle category icon frame
                        Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFFF4ED) : const Color(0xFFF9FAFB),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: const Color(0xFFEAECF0),
                                    width: 1.w,
                                  ),
                          ),
                          child: Icon(
                            _getCategoryIcon(cat),
                            color: isSelected ? const Color(0xFFA54600) : Colors.grey.shade600,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        // Label
                        Text(
                          cat,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 9.5.sp,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? const Color(0xFFA54600) : KorraColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 8.h),
        ],

        // Sleek Price Sort toggle bar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Filter & Sort",
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade500,
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (priceSort == 'none') {
                    onPriceSortChanged('asc');
                  } else if (priceSort == 'asc') {
                    onPriceSortChanged('desc');
                  } else {
                    onPriceSortChanged('none');
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: priceSort != 'none' ? const Color(0xFFFFF4ED) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(20.r),
                    border: priceSort != 'none'
                        ? null
                        : Border.all(
                            color: const Color(0xFFEAECF0),
                          ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_vert_rounded,
                        size: 14.sp,
                        color: priceSort != 'none' ? const Color(0xFFA54600) : Colors.grey.shade700,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        priceSort == 'none'
                            ? "Price: Default"
                            : (priceSort == 'asc' ? "Price: Low to High" : "Price: High to Low"),
                        style: GoogleFonts.inter(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w700,
                          color: priceSort != 'none' ? const Color(0xFFA54600) : KorraColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFFF2F4F7)),
      ],
    );
  }
}
