import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart'; // Assuming you use Iconsax, or change to Icons.map_outlined
import '../../config/routes/app_routes.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Premium Icon Container
              Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade100, width: 2),
                ),
                child: Center(
                  child: Icon(
                    Iconsax.radar_2, // Or Icons.route_outlined
                    size: 40.sp,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // 2. Headline
              Text(
                "Navigation Error",
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 8.h),

              // 3. Subtext
              Text(
                "The screen you are looking for doesn't exist or has been moved to a secure location.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 40.h),

              // 4. "Go Home" Button
              SizedBox(
                width: 160.w,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () {
                    // Smart Redirect: Sends them to Login, which auto-redirects 
                    // to the correct Dashboard based on their role.
                    Get.offAllNamed(Routes.roleLoginScreen);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    "Back to Safety",
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}