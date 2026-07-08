// lib/presentation/customer/storefront/widgets/storefront_cart_item_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants/colors.dart';
import 'cart_service.dart';
import 'storefront_lazy_image.dart';

/// Premium cart row: lazy image, name, unit price, line total,
/// pill quantity stepper and a subtle remove action.
class StorefrontCartItemTile extends StatelessWidget {
  final CartItem item;
  final void Function(int delta) onQuantityChanged;
  final VoidCallback onRemove;

  const StorefrontCartItemTile({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image (lazy, blurred placeholder)
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: SizedBox(
              width: 70.w,
              height: 70.w,
              child: item.imageUrl.isNotEmpty
                  ? StorefrontLazyImage(url: item.imageUrl, memCacheWidth: 200)
                  : Container(
                      color: const Color(0xFFF4F5F7),
                      child: Icon(Iconsax.image, size: 20.sp, color: Colors.grey),
                    ),
            ),
          ),
          SizedBox(width: 12.w),

          // Name, unit price, line total
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                    color: KorraColors.textDark,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "${currencyFormat.format(item.price)} each",
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: KorraColors.textMuted,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  currencyFormat.format(item.price * item.quantity),
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFA54600),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),

          // Remove + stepper column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: EdgeInsets.all(5.w),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3F2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Iconsax.trash, color: const Color(0xFFB42318), size: 14.sp),
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5F7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _stepBtn(Icons.remove, item.quantity > 1, () => onQuantityChanged(-1)),
                    Container(
                      constraints: BoxConstraints(minWidth: 28.w),
                      alignment: Alignment.center,
                      child: Text(
                        item.quantity.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: KorraColors.textDark,
                        ),
                      ),
                    ),
                    _stepBtn(Icons.add, true, () => onQuantityChanged(1)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 26.w,
        width: 26.w,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, size: 14.sp, color: enabled ? KorraColors.textDark : Colors.grey.shade400),
      ),
    );
  }
}