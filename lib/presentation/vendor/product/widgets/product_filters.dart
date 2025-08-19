import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../logic/bloc/vendor/product/vendor_products_state.dart';

class ProductFilters extends StatelessWidget {
  final ProductFilter active;
  final ValueChanged<ProductFilter> onChanged;

  const ProductFilters({
    super.key,
    required this.active,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const all = ProductFilter.values;
    String label(ProductFilter f) => switch (f) {
          ProductFilter.all => 'All',
          ProductFilter.approved => 'Approved',
          ProductFilter.pending => 'Pending',
          ProductFilter.outOfStock => 'Out of stock',
          ProductFilter.hidden => 'Hidden',
        };

    return SizedBox(
      height: 42.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) {
          final f = all[i];
          final selected = f == active;
          return InkWell(
            borderRadius: BorderRadius.circular(999.r),
            onTap: () => onChanged(f),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFF7F3EF) : Colors.white,
                borderRadius: BorderRadius.circular(999.r),
                border: Border.all(color: selected ? const Color(0xFFA54600) : const Color(0xFFEAE6E2)),
              ),
              child: Center(
                child: Text(label(f),
                    style: GoogleFonts.inter(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: selected ? const Color(0xFFA54600) : const Color(0xFF1B1B1B),
                    )),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemCount: all.length,
      ),
    );
  }
}
