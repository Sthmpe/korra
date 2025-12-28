import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../config/constants/colors.dart';
import '../../../../data/models/vendor/reservation.dart';

class ReservationStatusTabs extends StatelessWidget {
  final ReservationStatus current;
  final String newCount;
  final String ongoingCount;
  final String readyCount; // ✅ NEW
  final String completedCount;
  final String cancelledCount;
  final Function(ReservationStatus) onChanged;

  const ReservationStatusTabs({
    super.key,
    required this.current,
    required this.newCount,
    required this.ongoingCount,
    required this.readyCount,
    required this.completedCount,
    required this.cancelledCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // 1. READY (High Priority - Green)
          _Tab(
            label: "Ready",
            count: readyCount,
            isActive: current == ReservationStatus.readyForPickup,
            onTap: () => onChanged(ReservationStatus.readyForPickup),
            activeColor: const Color(0xFF027A48), // Green
            activeBg: const Color(0xFFECFDF5),
          ),
          
          // 2. NEW
          _Tab(
            label: "New",
            count: newCount,
            isActive: current == ReservationStatus.newRes,
            onTap: () => onChanged(ReservationStatus.newRes),
          ),

          // 3. ONGOING
          _Tab(
            label: "Ongoing",
            count: ongoingCount,
            isActive: current == ReservationStatus.ongoing,
            onTap: () => onChanged(ReservationStatus.ongoing),
          ),

          // 4. COMPLETED
          _Tab(
            label: "Completed",
            count: completedCount,
            isActive: current == ReservationStatus.completed,
            onTap: () => onChanged(ReservationStatus.completed),
          ),

          // 5. CANCELLED
          _Tab(
            label: "Cancelled",
            count: cancelledCount,
            isActive: current == ReservationStatus.cancelled,
            onTap: () => onChanged(ReservationStatus.cancelled),
          ),
          
          SizedBox(width: 16.w),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final String count;
  final bool isActive;
  final VoidCallback onTap;
  final Color? activeColor;
  final Color? activeBg;

  const _Tab({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
    this.activeColor,
    this.activeBg,
  });

  @override
  Widget build(BuildContext context) {
    final mainColor = activeColor ?? KorraColors.brand;
    // If specific BG not provided, use transparent (standard tab) or brand pill? 
    // Let's stick to your pill style: Solid fill when active.
    final bg = isActive ? mainColor : Colors.transparent;
    final textCol = isActive ? Colors.white : Colors.grey.shade600;
    final borderCol = isActive ? mainColor : Colors.grey.shade300;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: borderCol),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: textCol,
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
              ),
            ),
            if (count != '0') ...[
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white.withOpacity(0.2) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  count,
                  style: GoogleFonts.inter(
                    color: isActive ? Colors.white : Colors.grey.shade700,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}