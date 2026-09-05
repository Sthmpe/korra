import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductTimelineLogicBox extends StatelessWidget {
  final int calculatedDurationInt;
  final String noticePeriod;
  final String extensionDuration;
  final String totalMaxTime;
  final bool priceAllowsExtension;

  const ProductTimelineLogicBox({
    super.key,
    required this.calculatedDurationInt,
    required this.noticePeriod,
    required this.extensionDuration,
    required this.totalMaxTime,
    required this.priceAllowsExtension,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Timeline Logic",
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          _buildTimelineRow("Base Duration", "$calculatedDurationInt Days"),
          _buildTimelineRow("Notice Period", noticePeriod, isAlert: true),
          _buildTimelineRow("Potential Extension", extensionDuration),
          _buildTimelineRow("Total Max Time", totalMaxTime, isBold: true),
          if (priceAllowsExtension) ...[
            SizedBox(height: 4.h),
            Text(
              "* Extension unlocks only if customer pays 80% of the product price.",
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineRow(
    String label,
    String value, {
    bool isBold = false,
    bool isAlert = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: isAlert ? const Color(0xFFA54600) : Colors.grey.shade600,
              fontWeight: isAlert ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: const Color(0xFF101828),
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
