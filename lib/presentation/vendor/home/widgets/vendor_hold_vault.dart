import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

/// A calm, premium "vault" that shows: on-hold amount, time-to-release,
/// next release date, and a horizontal reel of upcoming releases.
/// No outer padding — parent decides spacing.
class VendorHoldVault extends StatelessWidget {
  final String holdText;          // e.g. '₦1,300,000'
  final int daysRemaining;        // e.g. 9
  final String nextRelease;       // e.g. 'Aug 27'
  final List<HoldEntry> entries;  // upcoming releases (date/amount/released)
  final VoidCallback onViewSchedule;

  const VendorHoldVault({
    super.key,
    required this.holdText,
    required this.daysRemaining,
    required this.nextRelease,
    required this.entries,
    required this.onViewSchedule,
  });

  static const _brand = Color(0xFFA54600);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F3EF),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFEAE6E2), width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          Row(children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.r)),
              child: const Icon(Iconsax.lock_1, color: _brand, size: 18),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text('Settlement vault',
                style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w800)),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(10.r),
              onTap: onViewSchedule,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                child: Text('Schedule',
                  style: GoogleFonts.inter(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: _brand)),
              ),
            ),
          ]),
      
          SizedBox(height: 10.h),
      
          // Amount + meta chips
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('On hold',
                    style: GoogleFonts.inter(fontSize: 12.5.sp, color: const Color(0xFF5E5E5E), fontWeight: FontWeight.w600)),
                SizedBox(height: 2.h),
                SizedBox(
                  width: 200.w,
                  child: Text(
                    holdText,
                    overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B1B))),
                ),
              ]),
            ),
            _chip(text: 'Releases in $daysRemaining days'),
            SizedBox(width: 4.w),
            _chip(text: 'Next • $nextRelease'),
          ]),
      
          if (entries.isNotEmpty) ...[
            SizedBox(height: 16.h),
            SizedBox(
              height: 38.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: entries.length,
                separatorBuilder: (_, __) => SizedBox(width: 6.w),
                itemBuilder: (_, i) {
                  final e = entries[i];
                  return _ReleasePill(entry: e);
                },
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _chip({required String text}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEAE6E2)),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600)),
    );
  }
}

/// Small rounded “pill” showing a release date + amount.
/// If released==true it shows a subtle check style.
class _ReleasePill extends StatelessWidget {
  final HoldEntry entry;
  const _ReleasePill({required this.entry});

  @override
  Widget build(BuildContext context) {
    final released = entry.released;
    final fg = released ? const Color(0xFF1B5E20) : const Color(0xFF1B1B1B);
    final dot = released ? Iconsax.tick_circle : Iconsax.calendar_1;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEAE6E2)),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(dot, size: 14.sp, color: released ? const Color(0xFF1B5E20) : const Color(0xFF8B8B8B)),
        SizedBox(width: 6.w),
        Text('${entry.dateLabel} • ${entry.amountText}',
          style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: fg)),
      ]),
    );
  }
}

/// Simple data for each release row.
class HoldEntry {
  final String dateLabel;   // e.g. 'Aug 27'
  final String amountText;  // e.g. '₦240,000'
  final bool released;
  const HoldEntry({required this.dateLabel, required this.amountText, this.released = false});
}
