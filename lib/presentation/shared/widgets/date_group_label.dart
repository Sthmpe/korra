// lib/presentation/shared/widgets/date_group_label.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Shared date bucketing for history-style lists so every screen groups the
/// same way (David's spec):
///
/// [recencyGroupLabel] — notifications, orders, reservations, purchases:
///   Today · Yesterday · Last Week · Last Month · June · May · "July, 2025"
///   (month names only for older buckets; the year is appended ONLY when it
///   is not the current year). Never starts with "This Month".
///
/// [monthGroupLabel] — monthly histories (e.g. Campaign History):
///   This Month · June · May · "July, 2025".
String recencyGroupLabel(DateTime date, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(date.year, date.month, date.day);
  final diffDays = today.difference(day).inDays;

  if (diffDays <= 0) return 'Today';
  if (diffDays == 1) return 'Yesterday';
  if (diffDays < 7) return 'Last Week';

  // Older than a week but still this month, or anywhere in the previous
  // calendar month → Last Month.
  final prevMonth = DateTime(n.year, n.month - 1);
  final sameMonth = date.year == n.year && date.month == n.month;
  final inPrevMonth = date.year == prevMonth.year && date.month == prevMonth.month;
  if (sameMonth || inPrevMonth) return 'Last Month';

  return _monthName(date, n);
}

String monthGroupLabel(DateTime date, {DateTime? now}) {
  final n = now ?? DateTime.now();
  if (date.year == n.year && date.month == n.month) return 'This Month';
  return _monthName(date, n);
}

String _monthName(DateTime date, DateTime now) {
  final month = DateFormat('MMMM').format(date);
  return date.year == now.year ? month : "$month, ${date.year}";
}

/// The standard little section header the grouped lists render between
/// buckets. Borderless: it is just quiet uppercase text with breathing room.
class DateGroupHeader extends StatelessWidget {
  final String label;
  final EdgeInsetsGeometry? padding;

  const DateGroupHeader({super.key, required this.label, this.padding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10.5.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}
