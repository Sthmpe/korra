import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class VendorKpiBlock extends StatelessWidget {
  final String newCount, ongoingCount, readyCount, completedCount;
  final VoidCallback? onTapNew, onTapOngoing, onTapReady, onTapCompleted;

  const VendorKpiBlock({
    super.key,
    required this.newCount,
    required this.ongoingCount,
    required this.readyCount,     // ✅ Swapped Cancelled for Ready
    required this.completedCount,
    required this.onTapNew,
    required this.onTapOngoing,
    required this.onTapReady,     // ✅
    required this.onTapCompleted,
  });

  factory VendorKpiBlock.empty() {
    return const VendorKpiBlock(
      newCount: "0", ongoingCount: "0", readyCount: "0", completedCount: "0",
      onTapNew: null, onTapOngoing: null, onTapReady: null, onTapCompleted: null,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          // Row 1: Ready (High Priority) & New
          Row(
            children: [
              _buildBigTile(
                label: 'Ready to Pickup',
                value: readyCount,
                color: const Color(0xFF027A48), // Success Green
                bg: const Color(0xFFECFDF5),
                icon: Iconsax.box_tick,
                onTap: onTapReady,
              ),
              SizedBox(width: 12.w),
              _buildBigTile(
                label: 'New Orders',
                value: newCount,
                color: const Color(0xFFA54600), // Brand
                bg: const Color(0xFFFFF7ED),    
                icon: Iconsax.flash_1,
                onTap: onTapNew,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          // Row 2: Ongoing & Completed (History)
          Row(
            children: [
              _buildBigTile(
                label: 'Ongoing',
                value: ongoingCount,
                color: const Color(0xFF0284C7), // Blue
                bg: const Color(0xFFF0F9FF),
                icon: Iconsax.timer_1,
                onTap: onTapOngoing,
              ),
              SizedBox(width: 12.w),
              _buildBigTile(
                label: 'History',
                value: completedCount,
                color: const Color(0xFF475467), // Grey
                bg: const Color(0xFFF2F4F7),
                icon: Iconsax.clock,
                onTap: onTapCompleted,
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
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap?.call();
          },
          child: Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF101828).withOpacity(0.04), 
                  blurRadius: 12, 
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
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: bg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 18.sp, color: color),
                    ),
                    if (value != '0')
                      Container(
                        width: 6.w, height: 6.w,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      )
                  ],
                ),
                SizedBox(height: 16.h),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
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