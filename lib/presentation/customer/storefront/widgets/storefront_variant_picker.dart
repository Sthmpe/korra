// lib/presentation/customer/storefront/widgets/storefront_variant_picker.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../data/models/product_model.dart';

/// Multi-variant quantity list for Add to Cart: one row per variant, each
/// with its own stepper, so a customer can take 5 of XL and 2 of XXL and add
/// everything in one tap. Rows are capped at (variant stock - already in
/// this vendor's cart), passed in as [maxFor].
class VariantQuantityList extends StatelessWidget {
  final List<ProductVariant> variants;

  /// Selected quantity per variant label.
  final Map<String, int> quantities;

  /// Max addable per variant label (variant stock minus units already in cart).
  final int Function(ProductVariant) maxFor;

  final void Function(String label, int delta) onChanged;

  const VariantQuantityList({
    super.key,
    required this.variants,
    required this.quantities,
    required this.maxFor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Choose your options",
          style: GoogleFonts.inter(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w700,
            color: KorraColors.textDark,
          ),
        ),
        SizedBox(height: 10.h),
        ...variants.map((v) {
          final max = maxFor(v);
          final qty = quantities[v.label] ?? 0;
          final out = v.stock <= 0;
          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: qty > 0 ? const Color(0xFFA54600) : const Color(0xFFEAECF0),
                width: qty > 0 ? 1.2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: out ? Colors.grey.shade400 : KorraColors.textDark,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        out
                            ? "Out of stock"
                            : max <= 0
                                ? "All stock in cart"
                                : v.stock < 5
                                    ? "Only ${v.stock} left"
                                    : "${v.stock} available",
                        style: GoogleFonts.inter(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w600,
                          color: out
                              ? const Color(0xFFB42318)
                              : v.stock < 5
                                  ? const Color(0xFFB95000)
                                  : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!out)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _step(
                        icon: Icons.remove,
                        enabled: qty > 0,
                        onTap: () => onChanged(v.label, -1),
                      ),
                      Container(
                        constraints: BoxConstraints(minWidth: 34.w),
                        alignment: Alignment.center,
                        child: Text(
                          qty.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: qty > 0
                                ? const Color(0xFFA54600)
                                : KorraColors.textDark,
                          ),
                        ),
                      ),
                      _step(
                        icon: Icons.add,
                        enabled: qty < max,
                        onTap: () => onChanged(v.label, 1),
                      ),
                    ],
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _step({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 30.w,
        width: 30.w,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? const Color(0xFFEAECF0) : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          size: 15.sp,
          color: enabled ? KorraColors.textDark : Colors.grey.shade400,
        ),
      ),
    );
  }
}

/// Single-select variant chooser for Pay Installments: a plan reserves
/// exactly ONE unit, so the customer must pick which variant before the
/// plan flow opens. Returns the chosen label, or null if dismissed.
Future<String?> showVariantChooser(
  BuildContext context,
  List<ProductVariant> variants,
) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "Pick an option",
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: KorraColors.textDark,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                "An installment plan reserves one item. Choose which one.",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: KorraColors.textBody,
                ),
              ),
              SizedBox(height: 16.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: variants.map((v) {
                  final out = v.stock <= 0;
                  return GestureDetector(
                    onTap: out ? null : () => Navigator.pop(ctx, v.label),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: out ? const Color(0xFFF2F4F7) : const Color(0xFFFFF4ED),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: out ? const Color(0xFFEAECF0) : const Color(0xFFA54600),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            v.label,
                            style: GoogleFonts.inter(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w700,
                              color: out ? Colors.grey.shade400 : const Color(0xFFA54600),
                            ),
                          ),
                          if (out) ...[
                            SizedBox(width: 6.w),
                            Icon(Iconsax.slash, size: 12.sp, color: Colors.grey.shade400),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    },
  );
}
