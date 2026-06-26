import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/constants/paddings.dart';
import '../../../../config/constants/sizes.dart';

class RoleDivider extends StatelessWidget {
  const RoleDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: KorraPaddings.pageH,
      child: Row(
        children: [
          const Expanded(child: Divider(thickness: 1)),
          Text(
            '  Or use biometric authentication  ',
            style: TextStyle(
              fontSize: KorraSizes.fontSmPlus.sp,
              color: KorraColors.greyCancel,
              fontWeight: KorraSizes.weightSemiBold,
              fontFamily: GoogleFonts.inter().fontFamily,
            ),
          ),
          // Container(
          //   margin: EdgeInsets.symmetric(horizontal: 10.w),
          //   padding: EdgeInsets.all(8.r),
          //   decoration: BoxDecoration(
          //     color: Colors.white,
          //     borderRadius: BorderRadius.circular(10.r),
          //     border: Border.all(color: Colors.grey.shade300),
          //   ),
          //   child: Container(
          //         padding: EdgeInsets.all(4.r),
          //         decoration: BoxDecoration(
          //           color: KorraColors.brand.withOpacity(1),
          //           borderRadius: BorderRadius.circular(10.r), // rounded box
          //         ),
          //         child: Icon(
          //           MdiIcons.crown,
          //           color: Colors.white,
          //           size: 32.sp, // moderate
          //         ),
          //       ),
          // ),
          const Expanded(child: Divider(thickness: 1)),
        ],
      ),
    );
  }
}
