// lib/presentation/vendor/product/widgets/campaigns/web_activity_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../config/constants/colors.dart';

/// "Web Activity" — page loads on the merchant's public storefront
/// (korra.com.ng/store/{slug}), session-deduped per day server-side and
/// bot-filtered. Deliberately its OWN stat: never merged into campaign opens,
/// conversion, or Most Visited, and deliberately NOT called "visitors" —
/// the permanent caption keeps expectations honest. Web purchases show as a
/// raw count with no rate against page views. Borderless design.
class WebActivityCard extends StatelessWidget {
  final String vendorId;

  const WebActivityCard({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('web_activity')
          .doc(vendorId)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? const <String, dynamic>{};
        final daily = Map<String, dynamic>.from(data['daily'] ?? const {});
        final now = DateTime.now();

        int today = 0;
        int week = 0;
        for (var i = 0; i < 7; i++) {
          final day = now.subtract(Duration(days: i));
          final key =
              "${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
          final n = (daily[key] as num?)?.toInt() ?? 0;
          week += n;
          if (i == 0) today = n;
        }
        final webPurchases = (data['purchasesTotal'] as num?)?.toInt() ?? 0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1C0D00).withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(7.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F5F1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.language_rounded,
                        size: 16.sp, color: const Color(0xFFA54600)),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "Web Activity",
                    style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: KorraColors.textDark),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  _stat("Today", "$today"),
                  SizedBox(width: 10.w),
                  _stat("Last 7 days", "$week"),
                  SizedBox(width: 10.w),
                  _stat("Web Purchases", "$webPurchases"),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                "Approximate: counts page visits to your web store, not unique people.",
                style: GoogleFonts.inter(
                    fontSize: 10.sp, color: Colors.grey.shade400),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F5F1),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: KorraColors.textDark),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
