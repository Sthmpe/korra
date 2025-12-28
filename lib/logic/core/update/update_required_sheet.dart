import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:korra/presentation/shared/widgets/show_app_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/constants/colors.dart'; // Adjust path

class UpdateRequiredSheet extends StatelessWidget {
  final String version;
  final String url;

  const UpdateRequiredSheet({super.key, required this.version, required this.url});

  @override
  Widget build(BuildContext context) {
    // 🎨 Full Screen Modal Design
    return Container(
      color: Colors.white, // Covers the whole screen
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),
          
          // 🚀 Icon
          Container(
            padding: EdgeInsets.all(32.r),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED), // Soft Orange
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFEDD5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Icon(Icons.rocket_launch_rounded, size: 56.sp, color: KorraColors.brand),
          ),
          
          SizedBox(height: 40.h),

          Text(
            "Time to Update!",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111111),
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 12.h),
          
          Text(
            "We've added new features and fixes. Update to v$version to continue.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              color: const Color(0xFF667085),
              height: 1.5,
            ),
          ),

          const Spacer(flex: 2),

          // ⚡ Button
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: () => _launchURL(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Download Update",
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(Iconsax.arrow_right_1, size: 20.sp, color: Colors.white),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // Optional: Retry (in case they updated and came back)
          GestureDetector(
            onTap: () {
               // Trigger a check via context logic or app restart
               // Since this is a stateless sheet, simpler to leave this for now.
            },
            child: Text(
              "Already updated? Restart App",
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Future<void> _launchURL(BuildContext context) async {
    final Uri uri = Uri.parse(url);

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");

      if (await canLaunchUrl(uri)) {
         await launchUrl(uri);
      } else {  
        showAppSnackbar("Could not open link. Please visit korra.com.ng manually", SnackbarType.error); 
      }
    }
  }
}