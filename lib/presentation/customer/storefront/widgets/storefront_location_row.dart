// lib/presentation/customer/storefront/widgets/storefront_location_row.dart
//
// "Walk-in store" chip on the storefront header. Only rendered when the
// merchant has provided an address in their store settings. Tapping the chip
// expands the full address inline right below it (no sheet, no navigation).
// Borderless by design — tinted fills only.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';

class StorefrontLocationRow extends StatefulWidget {
  /// Full display address ("12 Allen Avenue, Ikeja, Lagos"). Empty = no row.
  final String address;

  const StorefrontLocationRow({super.key, required this.address});

  @override
  State<StorefrontLocationRow> createState() => _StorefrontLocationRowState();
}

class _StorefrontLocationRowState extends State<StorefrontLocationRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.address.trim().isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: KorraColors.brandLight,
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.location5, size: 14.sp, color: KorraColors.brand),
                SizedBox(width: 6.w),
                Text(
                  "Walk-in store",
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: KorraColors.brand,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  _expanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                  size: 12.sp,
                  color: KorraColors.brand,
                ),
              ],
            ),
          ),
        ),

        // Address revealed inline below the chip
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topLeft,
          child: _expanded
              ? Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Iconsax.location, size: 14.sp, color: KorraColors.textMuted),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          widget.address,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: KorraColors.textBody,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
