import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../logic/bloc/vendor/home/vendor_home_state.dart';

class VendorHoldVault extends StatelessWidget {
  final String holdText;          // e.g. '₦1,300,000'
  final int daysRemaining;        // e.g. 9
  final String nextRelease;       // e.g. 'Aug 27'
  final List<HoldEntry> entries;  // upcoming releases
  final VoidCallback? onViewSchedule;

  const VendorHoldVault({
    super.key,
    required this.holdText,
    required this.daysRemaining,
    required this.nextRelease,
    required this.entries,
    required this.onViewSchedule,
  });

  // Premium Colors
  static const _brandDark = Color(0xFF7C2D12); // Deep Rich Brown/Orange
  static const _surface = Color(0xFFFFFBF9);   // Very subtle warm white
  static const _accent = Color(0xFFA54600);    // Korra Brand

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(24.r, 24.r, 0, 24.r), // Right padding 0 for scrolling list
        decoration: BoxDecoration(
          color: _surface, 
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: _brandDark.withOpacity(0.06), width: 1),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Row (With Padding)
            Padding(
              padding: EdgeInsets.only(right: 24.r), // Apply right padding here manually
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.lock_1, size: 18.sp, color: _brandDark.withOpacity(0.5)),
                      SizedBox(width: 8.w),
                      Text(
                        'SETTLEMENT VAULT',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp, 
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: _brandDark.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  if (entries.isNotEmpty)
                    GestureDetector(
                      onTap: onViewSchedule,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Text(
                            'View All',
                            style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _accent),
                          ),
                          SizedBox(width: 4.w),
                          Icon(Icons.arrow_forward_rounded, size: 14.sp, color: _accent)
                        ],
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // 2. The Big Number (Hero)
            Padding(
              padding: EdgeInsets.only(right: 24.r),
              child: Text(
                holdText,
                style: GoogleFonts.inter(
                  fontSize: 32.sp, 
                  fontWeight: FontWeight.w800, 
                  color: _brandDark,
                  letterSpacing: -1.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            
            SizedBox(height: 8.h),

            // 3. Context Line (Natural Language)
            Padding(
              padding: EdgeInsets.only(right: 24.r),
              child: entries.isNotEmpty 
                ? RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(fontSize: 12.sp, color: _brandDark.withOpacity(0.6), height: 1.4),
                      children: [
                        const TextSpan(text: "Incoming payout of "),
                        TextSpan(
                          text: entries.first.amountText,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: _brandDark),
                        ),
                        const TextSpan(text: " arrives in "),
                        TextSpan(
                          text: daysRemaining == 0 ? "less than 24h" : "$daysRemaining days",
                          style: const TextStyle(fontWeight: FontWeight.w700, color: _brandDark),
                        ),
                        const TextSpan(text: "."),
                      ],
                    ),
                  )
                : Text(
                    "No funds currently locked.",
                    style: GoogleFonts.inter(fontSize: 13.sp, color: _brandDark.withOpacity(0.6)),
                  ),
            ),

            // 4. The "Calendar" Horizontal Reel
            if (entries.isNotEmpty) ...[
              SizedBox(height: 24.h),
              SizedBox(
                height: 72.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: entries.length,
                  padding: EdgeInsets.only(right: 24.r), // End padding for scroll
                  separatorBuilder: (_, __) => SizedBox(width: 12.w),
                  itemBuilder: (_, i) {
                    return _CalendarCard(entry: entries[i], isNext: i == 0);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A "Calendar" style card. 
class _CalendarCard extends StatelessWidget {
  final HoldEntry entry;
  final bool isNext;

  const _CalendarCard({required this.entry, required this.isNext});

  @override
  Widget build(BuildContext context) {
    // Logic to split "Aug 27"
    final dateParts = entry.dateLabel.split(' ');
    final month = dateParts.isNotEmpty ? dateParts[0].toUpperCase() : '';
    final day = dateParts.length > 1 ? dateParts[1] : '';

    return Container(
      width: 150.w, // Fixed width for uniformity
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isNext ? const Color(0xFFFFF0EB) : Colors.white, // Highlight next
        borderRadius: BorderRadius.circular(16.r),
        border: isNext 
            ? Border.all(color: const Color(0xFFA54600).withOpacity(0.15), width: 1)
            : Border.all(color: Colors.black.withOpacity(0.04), width: 1),
      ),
      child: Row(
        children: [
          // Left: Calendar Box
          Container(
            width: 36.w,
            decoration: BoxDecoration(
              color: isNext ? Colors.white : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  month, 
                  style: GoogleFonts.inter(
                    fontSize: 9.sp, 
                    fontWeight: FontWeight.w800, 
                    color: isNext ? const Color(0xFFA54600) : Colors.grey
                  ),
                ),
                Text(
                  day, 
                  style: GoogleFonts.inter(
                    fontSize: 14.sp, 
                    fontWeight: FontWeight.w700, 
                    color: const Color(0xFF1B1B1B)
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(width: 10.w),

          // Right: Details (Flexible prevents overflow)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isNext ? "Releasing" : "Upcoming",
                  style: GoogleFonts.inter(
                    fontSize: 10.sp, 
                    color: isNext ? const Color(0xFFA54600) : Colors.grey.shade500, 
                    fontWeight: FontWeight.w600
                  ),
                ),
                SizedBox(height: 2.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    entry.amountText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp, 
                      fontWeight: FontWeight.w700, 
                      color: const Color(0xFF1B1B1B),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
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