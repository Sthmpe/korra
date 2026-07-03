import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'product_info_box.dart';

class ProductStrictSettingsCard extends StatelessWidget {
  final bool priceAllowsExtension;

  const ProductStrictSettingsCard({
    super.key,
    required this.priceAllowsExtension,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('strict'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProductInfoBox(
          title: "Strict Model",
          description: "Automated Plan. Korra automatically requires a 30% down payment from the customer. Any cancellations are refunded purely as Store Balance to protect your inventory.",
          icon: MdiIcons.shieldCheck,
        ),
        SizedBox(height: 16.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 16.sp, color: Colors.blue),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                priceAllowsExtension
                    ? "Automatic Extensions: Enabled (Customer gets extra time if 80% paid)."
                    : "Extensions: Not available for this price range.",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
