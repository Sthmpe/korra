import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class VendorKpiBlock extends StatelessWidget {
  final String newCount, ongoingCount, completedCount, cancelledCount;
  final VoidCallback? onTapNew, onTapOngoing, onTapCompleted, onTapCancelled;

  const VendorKpiBlock({
    super.key,
    required this.newCount,
    required this.ongoingCount,
    required this.completedCount,
    required this.cancelledCount,
    required this.onTapNew,
    required this.onTapOngoing,
    required this.onTapCompleted,
    required this.onTapCancelled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w), // Aligned with other cards
      child: Column(
        children: [
          // Row 1: New & Ongoing
          Row(
            children: [
              _buildBigTile(
                label: 'New',
                value: newCount,
                color: const Color(0xFFA54600), // Brand
                bg: const Color(0xFFFFF7ED),    // Warm Orange
                icon: Iconsax.flash_1,
                onTap: onTapNew,
              ),
              SizedBox(width: 12.w),
              _buildBigTile(
                label: 'Ongoing',
                value: ongoingCount,
                color: const Color(0xFF0284C7), // Sky Blue
                bg: const Color(0xFFF0F9FF),
                icon: Iconsax.timer_1,
                onTap: onTapOngoing,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          // Row 2: Completed & Cancelled
          Row(
            children: [
              _buildBigTile(
                label: 'Completed',
                value: completedCount,
                color: const Color(0xFF059669), // Emerald Green
                bg: const Color(0xFFECFDF5),
                icon: Iconsax.tick_circle,
                onTap: onTapCompleted,
              ),
              SizedBox(width: 12.w),
              _buildBigTile(
                label: 'Cancelled',
                value: cancelledCount,
                color: const Color(0xFFDC2626), // Red
                bg: const Color(0xFFFEF2F2),
                icon: Iconsax.close_circle,
                onTap: onTapCancelled,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBigTile({
    required String label,
    required String value,
    required Color color,
    required Color bg,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap?.call();
          },
          child: Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03), 
                  blurRadius: 10, 
                  offset: const Offset(0, 4)
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon Badge
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: bg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 18.sp, color: color),
                    ),
                    // Optional arrow or indicator could go here
                  ],
                ),
                SizedBox(height: 16.h),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1F2937),
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}