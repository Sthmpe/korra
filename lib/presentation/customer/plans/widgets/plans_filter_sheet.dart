import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ✅ IMPORT THE SOURCE OF TRUTH (Do not define enum locally)
import '../../../../logic/bloc/customer/plans/plan_action_bloc.dart';

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
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
    builder: (_) => _FilterSheetContent(
      initialSort: currentSort,
      initialAuto: autopayOnly,
      initialOver: overdueOnly,
      initialHigh: highValueOnly,
      onApply: onApply,
      onReset: onReset,
    ),
  );
}

class _FilterSheetContent extends StatefulWidget {
  final SortBy initialSort;
  final bool initialAuto;
  final bool initialOver;
  final bool initialHigh;
  final Function(SortBy, bool, bool, bool) onApply;
  final VoidCallback onReset;

  const _FilterSheetContent({
    required this.initialSort,
    required this.initialAuto,
    required this.initialOver,
    required this.initialHigh,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterSheetContent> createState() => _FilterSheetContentState();
}

class _FilterSheetContentState extends State<_FilterSheetContent> {
  late SortBy _sort;
  late bool _auto;
  late bool _over;
  late bool _high;

  @override
  void initState() {
    super.initState();
    _sort = widget.initialSort;
    _auto = widget.initialAuto;
    _over = widget.initialOver;
    _high = widget.initialHigh;
  }

  @override
  Widget build(BuildContext context) {
    // Handle iPhone bottom notch padding
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40.w, height: 4.h,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(999)),
              margin: EdgeInsets.only(bottom: 20.h),
            ),
          ),
          
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter Plans', style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800, color: const Color(0xFF101828))),
              TextButton(
                onPressed: () {
                  widget.onReset();
                  Navigator.pop(context); // ✅ Close on Reset
                },
                child: Text("Reset", style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
              )
            ],
          ),
          
          SizedBox(height: 24.h),

          // SORT SECTION
          Text('Sort by', style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF667085))),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 10.w, 
            runSpacing: 10.h, 
            children: [
              _buildChoiceChip('Most recent', SortBy.recent),
              _buildChoiceChip('Next due', SortBy.nextDue),
              _buildChoiceChip('Total Amount',  SortBy.amount),
              _buildChoiceChip('Progress %', SortBy.progress),
            ]
          ),

          SizedBox(height: 24.h),

          // FILTERS SECTION
          Text('Show only', style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF667085))),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 10.w, 
            runSpacing: 10.h, 
            children: [
              _buildFilterChip('AutoPay enabled', _auto, (v) => setState(() => _auto = v)),
              _buildFilterChip('Past due', _over, (v) => setState(() => _over = v)),
              _buildFilterChip('High value (> 50k)', _high, (v) => setState(() => _high = v)),
            ]
          ),

          SizedBox(height: 32.h),

          // APPLY BUTTON
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: FilledButton(
              onPressed: () {
                widget.onApply(_sort, _auto, _over, _high);
                Navigator.pop(context); // ✅ CRITICAL FIX: Close the sheet
              },
              style: FilledButton.styleFrom(
                backgroundColor: _brand,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                elevation: 0,
              ),
              child: Text('Apply Filters', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15.sp, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, SortBy value) {
    final selected = _sort == value;
    return GestureDetector(
      onTap: () => setState(() => _sort = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? _brand.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: selected ? _brand.withOpacity(0) : _stroke.withOpacity(0.25)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? _brand : const Color(0xFF344054),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? _brand.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: isSelected ? _brand.withOpacity(0) : _stroke.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check, size: 14.sp, color: _brand),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _brand : const Color(0xFF344054),
              ),
            ),
          ],
        ),
      ),
    );
  }
}