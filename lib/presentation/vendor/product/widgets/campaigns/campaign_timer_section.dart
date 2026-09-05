// lib/presentation/vendor/product/widgets/campaigns/campaign_timer_section.dart
//
// "Deal Countdown Timer" block inside CreateCampaignSheet. Independent of the
// campaign tag — any campaign (discount, new arrival, promo...) can carry a
// timer. When toggled on, the merchant picks a start and end time; customers
// see a live countdown for that window on the marketplace.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

const _brand = Color(0xFFA54600);

class CampaignTimerSection extends StatelessWidget {
  final bool enabled;
  final DateTime? startAt;
  final DateTime? endAt;
  final ValueChanged<bool> onToggled;
  final ValueChanged<DateTime> onStartPicked;
  final ValueChanged<DateTime> onEndPicked;

  const CampaignTimerSection({
    super.key,
    required this.enabled,
    required this.startAt,
    required this.endAt,
    required this.onToggled,
    required this.onStartPicked,
    required this.onEndPicked,
  });

  static final DateFormat _fmt = DateFormat('EEE d MMM, h:mm a');

  Future<void> _pick(BuildContext context, {required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? (startAt ?? now) : (endAt ?? now.add(const Duration(hours: 24)));

    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now.subtract(const Duration(minutes: 1)),
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    isStart ? onStartPicked(picked) : onEndPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(
            "Deal Countdown Timer",
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF101828),
            ),
          ),
          subtitle: Text(
            "Customers see a live countdown between your start and end time.",
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey),
          ),
          value: enabled,
          onChanged: onToggled,
          activeColor: _brand,
          contentPadding: EdgeInsets.zero,
        ),
        if (enabled) ...[
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(child: _timeTile(context, label: "Starts", value: startAt, isStart: true)),
              SizedBox(width: 10.w),
              Expanded(child: _timeTile(context, label: "Ends", value: endAt, isStart: false)),
            ],
          ),
          if (startAt != null && endAt != null && !endAt!.isAfter(startAt!)) ...[
            SizedBox(height: 8.h),
            Text(
              "End time must be after the start time.",
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD92D20),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _timeTile(BuildContext context,
      {required String label, required DateTime? value, required bool isStart}) {
    return GestureDetector(
      onTap: () => _pick(context, isStart: isStart),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isStart ? Iconsax.play_circle : Iconsax.timer_1, size: 14.sp, color: _brand),
                SizedBox(width: 5.w),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 5.h),
            Text(
              value == null ? "Set time" : _fmt.format(value),
              maxLines: 2,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: value == null ? Colors.grey.shade400 : const Color(0xFF101828),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
