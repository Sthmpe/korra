// lib/presentation/vendor/product/widgets/campaigns/campaign_analytics_sheet.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../config/constants/colors.dart';
import '../../../../../data/models/vendor/campaign_model.dart';

/// Campaign analytics, revealed by tapping a campaign banner on the Campaigns
/// screen. Opens are UNIQUE (one per customer per day, in-app only), purchases
/// are attributed by campaign ID at checkout, conversion = purchases / opens.
/// Design: borderless — separation comes from background tone and spacing.
class CampaignAnalyticsSheet extends StatefulWidget {
  final Campaign campaign;

  const CampaignAnalyticsSheet({super.key, required this.campaign});

  @override
  State<CampaignAnalyticsSheet> createState() => _CampaignAnalyticsSheetState();
}

class _CampaignAnalyticsSheetState extends State<CampaignAnalyticsSheet> {
  // Open by default so the day-by-day trend is immediately visible; the
  // header still collapses it.
  bool _dailyExpanded = true;

  @override
  Widget build(BuildContext context) {
    final c = widget.campaign;
    final conversionPct = (c.conversionRate * 100);
    final dailyEntries = c.dailyOpens.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key)); // newest day first

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 12.h, bottom: 16.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- BANNER ---
                  if (c.imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: CachedNetworkImage(
                        imageUrl: c.imageUrl,
                        height: 110.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          height: 110.h,
                          color: const Color(0xFFF9FAFB),
                          child: const Icon(Icons.image_not_supported_outlined,
                              color: Colors.grey),
                        ),
                      ),
                    ),
                  SizedBox(height: 16.h),

                  // --- TAG + STATUS ---
                  Row(
                    children: [
                      _chip(c.tag.toUpperCase(), const Color(0xFFFFF4ED),
                          const Color(0xFFA54600)),
                      SizedBox(width: 8.w),
                      c.isActive
                          ? _chip("ACTIVE", const Color(0xFFECFDF3),
                              const Color(0xFF027A48))
                          : _chip("ENDED", const Color(0xFFF2F4F7),
                              const Color(0xFF475467)),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    c.title,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: KorraColors.textDark),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    c.caption,
                    style: GoogleFonts.inter(
                        fontSize: 12.5.sp,
                        color: const Color(0xFF475467),
                        height: 1.4),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    _dateRangeText(c),
                    style: GoogleFonts.inter(
                        fontSize: 11.sp, color: Colors.grey.shade400),
                  ),

                  SizedBox(height: 20.h),

                  // --- HEADLINE: "142 opens · 9 purchases" ---
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C0D00),
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "${c.openCount} open${c.openCount == 1 ? '' : 's'} · ${c.purchases} purchase${c.purchases == 1 ? '' : 's'}",
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFDF6EE)),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "Opens are unique: one per customer per day",
                          style: GoogleFonts.inter(
                              fontSize: 10.5.sp,
                              color: const Color(0xFFC27641)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // --- STAT TILES (tone-separated, no borders) ---
                  Row(
                    children: [
                      _statTile("Unique opens", "${c.openCount}"),
                      SizedBox(width: 10.w),
                      _statTile("Purchases", "${c.purchases}"),
                      SizedBox(width: 10.w),
                      _statTile(
                        "Conversion",
                        c.openCount == 0
                            ? "–"
                            : "${conversionPct.toStringAsFixed(conversionPct >= 10 ? 0 : 1)}%",
                      ),
                    ],
                  ),

                  // --- DAILY BREAKDOWN (always present; expandable) ---
                  ...[
                    SizedBox(height: 20.h),
                    InkWell(
                      onTap: () =>
                          setState(() => _dailyExpanded = !_dailyExpanded),
                      borderRadius: BorderRadius.circular(12.r),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        child: Row(
                          children: [
                            Text(
                              "DAILY BREAKDOWN",
                              style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade400,
                                  letterSpacing: 1.2),
                            ),
                            const Spacer(),
                            AnimatedRotation(
                              turns: _dailyExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 180),
                              child: Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 20.sp, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 200),
                      crossFadeState: _dailyExpanded
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      secondChild: const SizedBox(width: double.infinity),
                      firstChild: Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: dailyEntries.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                    vertical: 16.h, horizontal: 14.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F5F1),
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                                child: Text(
                                  "No daily data recorded yet. Day-by-day opens start collecting from each customer's next visit.",
                                  style: GoogleFonts.inter(
                                      fontSize: 11.5.sp,
                                      color: Colors.grey.shade500,
                                      height: 1.4),
                                ),
                              )
                            : Column(
                                children: dailyEntries
                                    .map((e) => _dayRow(e.key, e.value,
                                        dailyEntries.first.value))
                                    .toList(),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dateRangeText(Campaign c) {
    final fmt = DateFormat('MMM d, yyyy');
    final start = fmt.format(c.sentAt);
    final end = c.endDate;
    if (c.isActive) {
      return end != null ? "$start until ${fmt.format(end)}" : "Started $start";
    }
    return end != null ? "$start to ${fmt.format(end)}" : "Started $start";
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
            fontSize: 9.sp, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F5F1),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: KorraColors.textDark),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  /// One breakdown row: date, a soft proportional bar, and the count.
  Widget _dayRow(String isoDay, int opens, int _) {
    final maxOpens = widget.campaign.dailyOpens.values
        .fold<int>(1, (m, v) => v > m ? v : m);
    final fraction = (opens / maxOpens).clamp(0.05, 1.0);
    DateTime? day;
    try {
      day = DateTime.parse(isoDay);
    } catch (_) {}
    final label = day != null ? DateFormat('EEE, MMM d').format(day) : isoDay;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          SizedBox(
            width: 92.w,
            child: Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475467)),
            ),
          ),
          Expanded(
            child: Container(
              height: 8.h,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5F1),
                borderRadius: BorderRadius.circular(99),
              ),
              child: FractionallySizedBox(
                widthFactor: fraction,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFA54600),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          SizedBox(
            width: 56.w,
            child: Text(
              "$opens open${opens == 1 ? '' : 's'}",
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: KorraColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
