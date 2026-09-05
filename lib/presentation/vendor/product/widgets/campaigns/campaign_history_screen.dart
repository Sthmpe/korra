// lib/presentation/vendor/product/widgets/campaigns/campaign_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../config/constants/colors.dart';
import '../../../../../data/models/vendor/campaign_model.dart';
import '../../../../shared/widgets/date_group_label.dart';
import 'campaign_analytics_sheet.dart';
import 'campaign_history_tile.dart';

/// Full Campaign History, opened from "View all" on the Campaigns screen.
/// Grouped by month: "This Month", then month names (year appended only when
/// it is not the current year), newest first. Tapping an entry opens the
/// same analytics sheet as active campaigns.
class CampaignHistoryScreen extends StatelessWidget {
  /// Already sorted newest-first by the caller.
  final List<Campaign> history;

  const CampaignHistoryScreen({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: KorraColors.textDark, size: 22.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Campaign History",
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: KorraColors.textDark,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 32.h),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final campaign = history[index];
          final anchor = campaign.endDate ?? campaign.sentAt;
          final label = monthGroupLabel(anchor);
          final prevLabel = index == 0
              ? null
              : monthGroupLabel(
                  history[index - 1].endDate ?? history[index - 1].sentAt);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != prevLabel)
                DateGroupHeader(
                  label: label,
                  padding: EdgeInsets.fromLTRB(2.w, index == 0 ? 8.h : 16.h, 0, 8.h),
                ),
              CampaignHistoryTile(
                campaign: campaign,
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CampaignAnalyticsSheet(campaign: campaign),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
