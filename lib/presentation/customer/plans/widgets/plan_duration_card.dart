import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../data/models/customer/plans.dart';
import '../../../../logic/bloc/vendor/product/vendor_products_state.dart';

class PlanDurationCard extends StatelessWidget {
  final int duration;
  final bool canExtend;
  final ProductModelType modelType;

  const PlanDurationCard({
    super.key,
    required this.duration,
    required this.canExtend,
    required this.modelType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Iconsax.timer_1, size: 20.sp, color: const Color(0xFFB95000)),
          SizedBox(width: 10.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: const Color(0xFF96490B),
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: "Duration: "),
                  TextSpan(
                    text: "$duration Days.\n",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: modelType == ProductModelType.strict
                        ? "Incomplete plans convert your reservation to Store Balance."
                        : "Flexible timeline. Refunds are secured in Store Balance.",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
