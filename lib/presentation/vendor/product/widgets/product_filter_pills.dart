import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../logic/bloc/vendor/product/vendor_products_state.dart';

class ProductFilterPills extends StatelessWidget {
  final ProductFilter activeFilter;
  final Map<ProductFilter, int> counts;
  final Function(ProductFilter) onChanged;

  // The Korra Burnt Orange
  static const _brandColor = Color(0xFFA54600);

  const ProductFilterPills({
    super.key,
    required this.activeFilter,
    required this.counts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      ProductFilter.all,
      ProductFilter.approved,
      ProductFilter.pending,
      ProductFilter.outOfStock,
      ProductFilter.rejected,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: filters.map((filter) {
          final isActive = filter == activeFilter;
          final count = counts[filter] ?? 0;
          final label = _getLabel(filter);

          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: GestureDetector(
              onTap: () => onChanged(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  // Active: Brand Orange, Inactive: White
                  color: isActive ? _brandColor : Colors.white, 
                  borderRadius: BorderRadius.circular(100.r),
                  border: Border.all(
                    // Active: Brand Orange, Inactive: Subtle Grey
                    color: isActive ? _brandColor : const Color(0xFFEAECF0),
                    width: 1,
                  ),
                  boxShadow: isActive 
                    ? [
                        BoxShadow(
                          color: _brandColor.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
                ),
                child: Row(
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        // Active: White, Inactive: Dark Grey
                        color: isActive ? Colors.white : const Color(0xFF344054),
                      ),
                    ),
                    if (count > 0) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          // Active: Translucent White (Glass effect on Orange)
                          // Inactive: Light Grey background
                          color: isActive 
                              ? Colors.white.withOpacity(0.2) 
                              : const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          "$count",
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            // Active: White, Inactive: Dark Grey
                            color: isActive ? Colors.white : const Color(0xFF344054),
                          ),
                        ),
                      )
                    ]
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getLabel(ProductFilter f) {
    return switch (f) {
      ProductFilter.all => "All",
      ProductFilter.approved => "Active",
      ProductFilter.pending => "Review",
      ProductFilter.outOfStock => "Out of Stock",
      ProductFilter.rejected => "Rejected",
    };
  }
}