// lib/presentation/customer/storefront/widgets/storefront_filter_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';

/// Result object for the storefront Filter & Sort sheet.
class StorefrontFilters {
  final String priceSort; // 'none' | 'asc' | 'desc'
  final bool dealsOnly; // only products carrying a campaign tag
  final double? minPrice;
  final double? maxPrice;

  const StorefrontFilters({
    this.priceSort = 'none',
    this.dealsOnly = false,
    this.minPrice,
    this.maxPrice,
  });

  int get activeCount =>
      (priceSort != 'none' ? 1 : 0) +
      (dealsOnly ? 1 : 0) +
      ((minPrice != null || maxPrice != null) ? 1 : 0);
}

/// Premium bottom sheet: sort order, campaign-deals toggle and a customer-set
/// price range. The range is intentionally free-form — computing the store's
/// true min/max would force the full catalog to load (see Round 7 handover).
class StorefrontFilterSheet extends StatefulWidget {
  final StorefrontFilters initial;

  const StorefrontFilterSheet({super.key, required this.initial});

  /// Opens the sheet; resolves with the chosen filters or null if dismissed.
  static Future<StorefrontFilters?> show(
    BuildContext context,
    StorefrontFilters initial,
  ) {
    return showModalBottomSheet<StorefrontFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => StorefrontFilterSheet(initial: initial),
    );
  }

  @override
  State<StorefrontFilterSheet> createState() => _StorefrontFilterSheetState();
}

class _StorefrontFilterSheetState extends State<StorefrontFilterSheet> {
  late String _priceSort;
  late bool _dealsOnly;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _priceSort = widget.initial.priceSort;
    _dealsOnly = widget.initial.dealsOnly;
    _minController = TextEditingController(
        text: widget.initial.minPrice?.toStringAsFixed(0) ?? '');
    _maxController = TextEditingController(
        text: widget.initial.maxPrice?.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _apply() {
    final min = double.tryParse(_minController.text.trim());
    final max = double.tryParse(_maxController.text.trim());
    // Swap silently if the customer typed them the wrong way round.
    final bool swap = min != null && max != null && min > max;
    Navigator.of(context).pop(StorefrontFilters(
      priceSort: _priceSort,
      dealsOnly: _dealsOnly,
      minPrice: swap ? max : min,
      maxPrice: swap ? min : max,
    ));
  }

  void _reset() => Navigator.of(context).pop(const StorefrontFilters());

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAECF0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),

              Text(
                "Filter & Sort",
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: KorraColors.textDark,
                ),
              ),
              SizedBox(height: 18.h),

              // ── Sort ────────────────────────────────────────────────
              _sectionLabel("SORT BY"),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _choiceChip("Default", _priceSort == 'none',
                      () => setState(() => _priceSort = 'none')),
                  _choiceChip("Price: Low to High", _priceSort == 'asc',
                      () => setState(() => _priceSort = 'asc')),
                  _choiceChip("Price: High to Low", _priceSort == 'desc',
                      () => setState(() => _priceSort = 'desc')),
                ],
              ),
              SizedBox(height: 20.h),

              // ── Deals ───────────────────────────────────────────────
              _sectionLabel("DEALS"),
              SizedBox(height: 8.h),
              GestureDetector(
                onTap: () => setState(() => _dealsOnly = !_dealsOnly),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: _dealsOnly ? const Color(0xFFFFF4ED) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: _dealsOnly ? const Color(0xFFFFD6B2) : const Color(0xFFEAECF0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt_rounded,
                          size: 18.sp,
                          color: _dealsOnly ? const Color(0xFFD92D20) : KorraColors.textMuted),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          "Campaign deals only",
                          style: GoogleFonts.inter(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w700,
                            color: _dealsOnly ? const Color(0xFFA54600) : KorraColors.textDark,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: _dealsOnly,
                        activeColor: KorraColors.brand,
                        onChanged: (v) => setState(() => _dealsOnly = v),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // ── Price range ─────────────────────────────────────────
              _sectionLabel("PRICE RANGE (₦)"),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(child: _priceField(_minController, "Min e.g. 5000")),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Container(width: 12.w, height: 1.5, color: const Color(0xFFD0D5DD)),
                  ),
                  Expanded(child: _priceField(_maxController, "Max e.g. 50000")),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                "Leave empty to see every price.",
                style: GoogleFonts.inter(fontSize: 10.5.sp, color: KorraColors.textHint),
              ),
              SizedBox(height: 24.h),

              // ── Actions ─────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                        side: const BorderSide(color: Color(0xFFEAECF0)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r)),
                      ),
                      child: Text(
                        "Reset",
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: KorraColors.textDark,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [KorraColors.brand, Color(0xFFE05600)],
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _apply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 13.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r)),
                        ),
                        icon: Icon(Iconsax.filter_tick, size: 16.sp, color: Colors.white),
                        label: Text(
                          "Apply",
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10.sp,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: Colors.grey.shade500,
      ),
    );
  }

  Widget _choiceChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF4ED) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFFFD6B2) : const Color(0xFFEAECF0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5.sp,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? const Color(0xFFA54600) : KorraColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _priceField(TextEditingController controller, String hint) {
    return Container(
      height: 44.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.inter(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: KorraColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: KorraColors.textHint,
          ),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}
