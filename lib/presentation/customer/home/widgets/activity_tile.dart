// lib/presentation/customer/home/widgets/activity_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/customer/activity_item.dart';

class ActivityTile extends StatelessWidget {
  final ActivityItem item;
  final void Function(ActivityItem)? onPayNow;
  final void Function(ActivityItem)? onViewPlan;
  final void Function(ActivityItem)? onViewReceipt;
  final void Function(ActivityItem)? onReviewLink;
  final void Function(ActivityItem)? onEnableAutopay;

  const ActivityTile({
    super.key,
    required this.item,
    this.onPayNow,
    this.onViewPlan,
    this.onViewReceipt,
    this.onReviewLink,
    this.onEnableAutopay,
  });

  static const _brand = Color(0xFFA54600);

  @override
  Widget build(BuildContext context) {
    // visual spec by type
    final _Spec s = _specFor(item.type);

    // decide actions by type (hide if callback not supplied)
    final List<Widget> actions = switch (item.type) {
      ActivityType.payment => [
          if (onViewReceipt != null)
            _Primary(text: 'View receipt', onTap: () => onViewReceipt!(item)),
          if (onViewPlan != null)
            _Secondary(text: 'View plan', onTap: () => onViewPlan!(item)),
        ],
      ActivityType.dueSoon => [
          if (onPayNow != null)
            _Primary(text: 'Pay now', onTap: () => onPayNow!(item)),
          if (onViewPlan != null)
            _Secondary(text: 'View plan', onTap: () => onViewPlan!(item)),
        ],
      ActivityType.link => [
          if (onReviewLink != null)
            _Primary(text: 'Review link', onTap: () => onReviewLink!(item)),
        ],
      ActivityType.autopay => [
          if (onEnableAutopay != null)
            _Primary(text: 'Enable AutoPay', onTap: () => onEnableAutopay!(item)),
          if (onViewPlan != null)
            _Secondary(text: 'View plan', onTap: () => onViewPlan!(item)),
        ],
      ActivityType.expired => [
          if (onViewPlan != null)
            _Primary(text: 'View plan', onTap: () => onViewPlan!(item)),
        ],
    };

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // leading icon capsule
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: s.bg,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: s.stroke),
            ),
            alignment: Alignment.center,
            child: Icon(s.icon, size: 18.sp, color: s.fg),
          ),
          SizedBox(width: 8.w),

          // bubble
          Expanded(
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFEAE6E2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // title
                  Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1B1B),
                    ),
                  ),
                  SizedBox(height: 4.h),

                  // subtitle / meta
                  Text(
                    item.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF5E5E5E),
                    ),
                  ),

                  if (actions.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: actions,
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

  _Spec _specFor(ActivityType t) {
    switch (t) {
      case ActivityType.payment:
        return const _Spec(
          icon: Icons.check_circle_outline,
          fg: Color(0xFF1B5E20),
          bg: Color(0xFFEAF4EC),
          stroke: Color(0xFFD3E5D7),
        );
      case ActivityType.dueSoon:
        return const _Spec(
          icon: Icons.warning_amber_outlined,
          fg: Color(0xFF7A4E00),
          bg: Color(0xFFFEF4E6),
          stroke: Color(0xFFF4E2C7),
        );
      case ActivityType.link:
        return const _Spec(
          icon: Icons.link_outlined,
          fg: _brand,
          bg: Color(0xFFF6F1ED),
          stroke: Color(0xFFEAE6E2),
        );
      case ActivityType.autopay:
        return const _Spec(
          icon: Icons.autorenew,
          fg: Color(0xFF1A237E),
          bg: Color(0xFFE8EAF6),
          stroke: Color(0xFFD7DAEC),
        );
      case ActivityType.expired:
        return const _Spec(
          icon: Icons.timer_off_outlined,
          fg: Color(0xFF5E5E5E),
          bg: Color(0xFFF2F2F2),
          stroke: Color(0xFFE3E3E3),
        );
    }
  }
}

class _Spec {
  final IconData icon;
  final Color fg;
  final Color bg;
  final Color stroke;
  const _Spec({required this.icon, required this.fg, required this.bg, required this.stroke});
}

// Buttons (compact, premium)
class _Primary extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _Primary({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36.h,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFA54600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          padding: EdgeInsets.symmetric(horizontal: 14.w),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
    );
  }
}

class _Secondary extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _Secondary({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36.h,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFEAE6E2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          foregroundColor: const Color(0xFFA54600),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
