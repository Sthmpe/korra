// lib/presentation/customer/plans/widgets/plan_detail_product_header.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants/colors.dart';
import '../../../../data/models/customer/plans.dart';
import 'vendor_header.dart';

/// Floating product card at the top of Plan Details: image carousel, store
/// row, title/price and the plan-model chip. Owns its own page-index state so
/// swiping images never rebuilds the rest of the screen.
class PlanDetailProductHeader extends StatefulWidget {
  final Plan plan;

  const PlanDetailProductHeader({super.key, required this.plan});

  @override
  State<PlanDetailProductHeader> createState() =>
      _PlanDetailProductHeaderState();
}

class _PlanDetailProductHeaderState extends State<PlanDetailProductHeader> {
  static final _currency =
      NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 2);

  int _imageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.plan;
    final bool isStrict = p.cancellationPolicy.contains("Store");
    final String modelName = isStrict ? "Strict Lock" : "Korra Direct";
    final Color modelColor =
        isStrict ? const Color(0xFF9E0A05) : const Color(0xFF026AA2);

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _carousel(p.imageUrls),
          Padding(
            padding: EdgeInsets.all(18.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VendorHeader(storeName: p.storeName),
                SizedBox(height: 14.h),
                Text(
                  p.title,
                  style: GoogleFonts.inter(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w800,
                    color: KorraColors.textDark,
                    height: 1.25,
                  ),
                ),
                if (p.variantLabel != null) ...[
                  SizedBox(height: 6.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4ED),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      p.variantLabel!,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: KorraColors.brand,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _currency.format(p.totalAmount),
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: KorraColors.brand,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: modelColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        modelName,
                        style: GoogleFonts.inter(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w800,
                          color: modelColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _carousel(List<dynamic> images) {
    if (images.isEmpty) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          child: Container(
            color: KorraColors.surface,
            alignment: Alignment.center,
            child: Icon(Iconsax.gallery,
                size: 36.sp, color: KorraColors.textHint),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              onPageChanged: (i) => setState(() => _imageIndex = i),
              itemCount: images.length,
              itemBuilder: (context, index) => CachedNetworkImage(
                imageUrl: images[index].toString(),
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  color: KorraColors.surface,
                  child: Icon(Iconsax.gallery_slash,
                      size: 30.sp, color: KorraColors.textHint),
                ),
              ),
            ),
            if (images.length > 1)
              Positioned(
                bottom: 12.h,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(images.length, (i) {
                      final active = _imageIndex == i;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: active ? 16.w : 6.w,
                        height: 4.h,
                        margin: EdgeInsets.symmetric(horizontal: 3.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                        ),
                      );
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
