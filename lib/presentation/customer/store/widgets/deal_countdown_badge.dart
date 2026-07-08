// lib/presentation/customer/store/widgets/deal_countdown_badge.dart
//
// Live countdown pill for timed campaigns (merchant-set start/end window,
// independent of the campaign tag). Two states:
//   • upcoming — "STARTS IN 2H 10M" (muted dark pill)
//   • running  — "⏱ 04:12:33 LEFT" (urgent red pill), or "2D 04H LEFT" for
//     windows longer than a day.
// Owns a 1-second ticker; renders nothing once the window has closed or if
// the campaign has no timer, so it is always safe to drop on any deal card.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/models/vendor/campaign_model.dart';

class DealCountdownBadge extends StatefulWidget {
  final Campaign campaign;

  const DealCountdownBadge({super.key, required this.campaign});

  @override
  State<DealCountdownBadge> createState() => _DealCountdownBadgeState();
}

class _DealCountdownBadgeState extends State<DealCountdownBadge> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    if (widget.campaign.hasTimer) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _label(Duration d) {
    if (d.inDays >= 1) {
      return "${d.inDays}D ${_two(d.inHours % 24)}H";
    }
    return "${_two(d.inHours)}:${_two(d.inMinutes % 60)}:${_two(d.inSeconds % 60)}";
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.campaign;
    if (!c.hasTimer) return const SizedBox.shrink();

    final now = DateTime.now();
    final bool upcoming = now.isBefore(c.dealStartAt!);
    final bool running = !upcoming && now.isBefore(c.dealEndAt!);
    if (!upcoming && !running) return const SizedBox.shrink(); // window closed

    final remaining = upcoming
        ? c.dealStartAt!.difference(now)
        : c.dealEndAt!.difference(now);
    final text =
        upcoming ? "STARTS IN ${_label(remaining)}" : "${_label(remaining)} LEFT";

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: upcoming ? Colors.black.withValues(alpha: 0.65) : const Color(0xFFD92D20),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.timer_15, size: 11.sp, color: Colors.white),
          SizedBox(width: 4.w),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 9.5.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: Colors.white,
              // Tabular figures stop the pill jittering as digits tick
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
