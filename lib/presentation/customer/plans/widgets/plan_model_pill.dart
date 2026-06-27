import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../data/models/customer/plans.dart';
import '../../../../logic/bloc/vendor/product/vendor_products_state.dart';

class PlanModelPill extends StatelessWidget {
  final ProductModelType modelType;

  const PlanModelPill({
    super.key,
    required this.modelType,
  });

  @override
  Widget build(BuildContext context) {
    final isStrict = modelType == ProductModelType.strict;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Icon(
            isStrict ? Iconsax.shield_tick : Icons.handshake_rounded,
            size: 14.sp,
            color: isStrict ? const Color(0xFF9A3412) : const Color(0xFF0369A1),
          ),
          SizedBox(width: 4.w),
          Text(
            isStrict ? "Strict Lock" : "Korra Direct",
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: isStrict
                  ? const Color(0xFF9A3412)
                  : const Color(0xFF0369A1),
            ),
          ),
        ],
      ),
    );
  }
}
