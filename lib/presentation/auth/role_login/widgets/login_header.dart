import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../../../config/constants/colors.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // final titleStyle = GoogleFonts.inter(
    //   fontSize: 20.sp, // moderate
    //   fontWeight: FontWeight.w800,
    // );
    final subtitleStyle = GoogleFonts.inter(
      fontSize: 14.sp,
      color: Colors.black54,
      height: 1.35,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              // Rounded square behind crown logo
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: KorraColors.brand.withOpacity(1),
                  borderRadius: BorderRadius.circular(12.r), // rounded box
                ),
                child: Icon(
                  MdiIcons.crown,
                  color: Colors.white,
                  size: 40.sp, // moderate
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'Korra',
                style: GoogleFonts.inter(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Reserve now — pay in parts, own with ease.',
                style: subtitleStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
