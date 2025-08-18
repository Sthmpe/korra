import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../logic/bloc/customer_shell/plans/plans_event.dart';

const _brand = Color(0xFFA54600);
const _stroke = Color(0xFFEAE6E2);

Future<void> showPlansFilterSheet({
  required BuildContext context,
  required SortBy currentSort,
  required bool autopayOnly,
  required bool overdueOnly,
  required bool highValueOnly,
  required void Function(SortBy sort, bool autopay, bool overdue, bool highValue) onApply,
  required VoidCallback onReset,
}) {
  SortBy sort = currentSort;
  bool auto = autopayOnly;
  bool over = overdueOnly;
  bool high = highValueOnly;

  Widget _chip(String text, bool selected, void Function(bool) onSel) {
    return FilterChip(
      selected: selected,
      onSelected: onSel,
      label: Text(text, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700)),
      side: const BorderSide(color: _stroke),
      backgroundColor: Colors.white,
      selectedColor: _brand.withOpacity(.10),
      checkmarkColor: _brand,
      labelStyle: TextStyle(color: selected ? _brand : const Color(0xFF1B1B1B)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    );
  }

  Widget _radio(String label, SortBy value) {
    final selected = sort == value;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.sp)),
      selected: selected,
      onSelected: (_) => sort = value,
      selectedColor: _brand,
      labelStyle: TextStyle(color: selected ? Colors.white : const Color(0xFF1B1B1B)),
      backgroundColor: Colors.white,
      side: const BorderSide(color: _stroke),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    );
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
    builder: (_) {
      final bottom = MediaQuery.of(context).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40.w, height: 4.h,
                decoration: BoxDecoration(color: _stroke, borderRadius: BorderRadius.circular(999)),
                margin: EdgeInsets.only(bottom: 8.h),
              ),
            ),
            Text('Filter Plans', style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800)),
            SizedBox(height: 16.h),

            Text('Sort', style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, color: const Color(0xFF5E5E5E))),
            SizedBox(height: 8.h),
            Wrap(spacing: 8.w, runSpacing: 8.h, children: [
              _radio('Next due', SortBy.nextDue),
              _radio('Amount',  SortBy.amount),
              _radio('Progress',SortBy.progress),
            ]),

            SizedBox(height: 16.h),
            Text('Filters', style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, color: const Color(0xFF5E5E5E))),
            SizedBox(height: 8.h),
            Wrap(spacing: 8.w, runSpacing: 8.h, children: [
              _chip('AutoPay enabled', auto, (v) => auto = v),
              _chip('Overdue only', over, (v) => over = v),
              _chip('High value', high, (v) => high = v),
            ]),

            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () { onReset(); Navigator.pop(context); },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _stroke),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      foregroundColor: _brand,
                    ),
                    child: Text('Reset', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14.sp)),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: FilledButton(
                    onPressed: () { onApply(sort, auto, over, high); Navigator.pop(context); },
                    style: FilledButton.styleFrom(
                      backgroundColor: _brand,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                    child: Text('Apply', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14.sp, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
