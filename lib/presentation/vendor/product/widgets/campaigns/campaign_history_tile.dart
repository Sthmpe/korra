// lib/presentation/vendor/product/widgets/campaigns/campaign_history_tile.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../config/constants/colors.dart';
import '../../../../../data/models/vendor/campaign_model.dart';

/// One past campaign in the Campaign History section: banner thumb, title,
/// caption, tag, run dates and the opens/purchases/conversion line. Tap opens
/// the same analytics sheet as active campaigns. Borderless by design —
/// tone + shadow separate it from the page, not lines.
class CampaignHistoryTile extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback onTap;

  const CampaignHistoryTile({
    super.key,
    required this.campaign,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    final fmt = DateFormat('MMM d');
    final start = fmt.format(c.sentAt);
    final end = c.endDate != null ? fmt.format(c.endDate!) : null;
    final pct = c.openCount == 0
        ? null
        : (c.conversionRate * 100).toStringAsFixed(c.conversionRate >= 0.1 ? 0 : 1);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1C0D00).withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: SizedBox(
                width: 56.w,
                height: 56.w,
                child: c.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: c.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFFF8F5F1),
                          child: const Icon(Icons.campaign_outlined,
                              color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFF8F5F1),
                        child: const Icon(Icons.campaign_outlined,
                            color: Colors.grey),
                      ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w700,
                              color: KorraColors.textDark),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 7.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4ED),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          c.tag.toUpperCase(),
                          style: GoogleFonts.inter(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFA54600)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    c.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 11.5.sp, color: const Color(0xFF475467)),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    end != null ? "$start to $end" : "Started $start",
                    style: GoogleFonts.inter(
                        fontSize: 10.5.sp, color: Colors.grey.shade400),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    pct == null
                        ? "${c.openCount} opens · ${c.purchases} purchases"
                        : "${c.openCount} opens · ${c.purchases} purchases · $pct% conversion",
                    style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFA54600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
