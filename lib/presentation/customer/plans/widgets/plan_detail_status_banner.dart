import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class PlanDetailStatusBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bg;

  const PlanDetailStatusBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: bg,
      padding: EdgeInsets.all(16.r),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlanDetailOverdueBanner extends StatelessWidget {
  const PlanDetailOverdueBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFB42318),
      padding: EdgeInsets.all(12.r),
      child: Row(
        children: [
          const Icon(Iconsax.danger, color: Colors.white, size: 18),
          SizedBox(width: 8.w),
          Text(
            "Reservation Past Due. Resolve to secure item.",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
