import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../logic/bloc/vendor/product/vendor_products_state.dart';

class ProductListItem extends StatelessWidget {
  final ProductItem p;
  final VoidCallback? onShare;
  final VoidCallback onEdit;
  final VoidCallback onRestock;

  const ProductListItem({
    super.key,
    required this.p,
    required this.onEdit,
    required this.onRestock,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final (badgeColor, badgeBg, badgeLabel) = _badgeFor(p.status);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFEAE6E2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // image / letter
            Container(
              width: 54.w, height: 54.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F2F1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              alignment: Alignment.center,
              child: Text(
                p.name.isEmpty ? '?' : p.name.trim()[0].toUpperCase(),
                style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800),
              ),
            ),
            SizedBox(width: 12.w),

            // details
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(p.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 14.5.sp, fontWeight: FontWeight.w800)),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(999.r),
                      border: Border.all(color: badgeColor.withOpacity(.25)),
                    ),
                    child: Text(badgeLabel,
                        style: GoogleFonts.inter(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: badgeColor)),
                  ),
                ]),
                SizedBox(height: 4.h),
                Row(children: [
                  Text(p.priceText, style: GoogleFonts.inter(fontSize: 13.5.sp, fontWeight: FontWeight.w700)),
                  SizedBox(width: 10.w),
                  _dot(),
                  SizedBox(width: 10.w),
                  Text('Stock: ${p.stock}', style: GoogleFonts.inter(fontSize: 12.5.sp, color: const Color(0xFF5E5E5E))),
                ]),

                SizedBox(height: 10.h),

                Wrap(spacing: 8.w, runSpacing: 8.h, children: [
                  if (onShare != null)
                    _primary('Share link', onShare!),
                  _secondary('Edit', onEdit),
                  if (p.status == ProductStatus.outOfStock) _secondary('Restock', onRestock),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color, String) _badgeFor(ProductStatus s) {
    switch (s) {
      case ProductStatus.approved:
        return (const Color(0xFF1B5E20), const Color(0xFFEAF4EC), 'Approved');
      case ProductStatus.pending:
        return (const Color(0xFF7A4E00), const Color(0xFFFEF4E6), 'Pending');
      case ProductStatus.rejected:
        return (const Color(0xFFE53935), const Color(0xFFFFF0EF), 'Rejected');
      case ProductStatus.hidden:
        return (const Color(0xFF5E5E5E), const Color(0xFFF3F2F1), 'Hidden');
      case ProductStatus.outOfStock:
        return (const Color(0xFFE53935), const Color(0xFFFFF0EF), 'Out of stock');
    }
  }

  Widget _dot() => Container(width: 4.w, height: 4.w, decoration: const BoxDecoration(
    color: Color(0xFFD0CCC8), shape: BoxShape.circle));

  Widget _primary(String text, VoidCallback onTap) {
    return SizedBox(
      height: 36.h,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFA54600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          elevation: 0,
        ),
        child: Text(text, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }

  Widget _secondary(String text, VoidCallback onTap) {
    return SizedBox(
      height: 36.h,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFEAE6E2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          foregroundColor: const Color(0xFFA54600),
        ),
        child: Text(text, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
