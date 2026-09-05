// lib/presentation/vendor/product/widgets/product_variants_editor.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../data/models/product_model.dart';

/// Optional flat variants editor for the product create/edit forms.
/// Each row is a free-text label ("S", "40", "XL / Red", "Ankara 500ml")
/// with its own stock. No attribute matrix by design; a size-and-color
/// combination is just written into the label. Rows with an empty label
/// are ignored, so a half-typed row never blocks saving.
///
/// Reports the parsed list upward on every change; the parent decides what
/// to do with the total (the flat Stock field becomes the computed sum).
class ProductVariantsEditor extends StatefulWidget {
  final List<ProductVariant> initialVariants;
  final ValueChanged<List<ProductVariant>> onChanged;

  const ProductVariantsEditor({
    super.key,
    this.initialVariants = const [],
    required this.onChanged,
  });

  static const int maxVariants = 30;

  @override
  State<ProductVariantsEditor> createState() => _ProductVariantsEditorState();
}

class _VariantRow {
  final TextEditingController label;
  final TextEditingController stock;
  _VariantRow(String labelText, String stockText)
      : label = TextEditingController(text: labelText),
        stock = TextEditingController(text: stockText);

  void dispose() {
    label.dispose();
    stock.dispose();
  }
}

class _ProductVariantsEditorState extends State<ProductVariantsEditor> {
  final List<_VariantRow> _rows = [];

  @override
  void initState() {
    super.initState();
    for (final v in widget.initialVariants) {
      _rows.add(_VariantRow(v.label, v.stock.toString()));
    }
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  List<ProductVariant> _parse() {
    final out = <ProductVariant>[];
    for (final r in _rows) {
      final label = r.label.text.trim();
      if (label.isEmpty) continue;
      final stock = int.tryParse(r.stock.text.trim()) ?? 0;
      out.add(ProductVariant(label: label, stock: stock));
    }
    return out;
  }

  void _emit() => widget.onChanged(_parse());

  void _addRow() {
    if (_rows.length >= ProductVariantsEditor.maxVariants) return;
    setState(() => _rows.add(_VariantRow('', '')));
  }

  void _removeRow(int index) {
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
    _emit();
  }

  int get _total => _parse().fold(0, (acc, v) => acc + v.stock);

  @override
  Widget build(BuildContext context) {
    final hasRows = _rows.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Variants",
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF344054),
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              "Optional",
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
            const Spacer(),
            if (hasRows)
              Text(
                "Total stock: $_total",
                style: GoogleFonts.inter(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: KorraColors.brand,
                ),
              ),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          "Sizes, colors or any option, each with its own stock. e.g. S, 40, XL / Red.",
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: Colors.grey.shade500,
            height: 1.35,
          ),
        ),
        SizedBox(height: 10.h),
        ...List.generate(_rows.length, (i) => _buildRow(i)),
        if (_rows.length < ProductVariantsEditor.maxVariants)
          GestureDetector(
            onTap: _addRow,
            child: Container(
              margin: EdgeInsets.only(top: hasRows ? 4.h : 0),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFEAECF0)),
                color: const Color(0xFFF9FAFB),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.add, size: 16.sp, color: KorraColors.brand),
                  SizedBox(width: 6.w),
                  Text(
                    hasRows ? "Add another variant" : "Add variants",
                    style: GoogleFonts.inter(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: KorraColors.brand,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRow(int index) {
    final row = _rows[index];
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: _rowInput(
              controller: row.label,
              hint: "e.g. XL or XL / Red",
              maxLength: 40,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            flex: 3,
            child: _rowInput(
              controller: row.stock,
              hint: "Qty",
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          SizedBox(width: 6.w),
          GestureDetector(
            onTap: () => _removeRow(index),
            child: Padding(
              padding: EdgeInsets.all(6.w),
              child: Icon(
                Iconsax.trash,
                size: 18.sp,
                color: const Color(0xFFD92D20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowInput({
    required TextEditingController controller,
    required String hint,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      onChanged: (_) {
        setState(() {}); // refresh the running total
        _emit();
      },
      style: GoogleFonts.inter(
        fontSize: 13.5.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF101828),
      ),
      decoration: InputDecoration(
        hintText: hint,
        counterText: "",
        hintStyle: GoogleFonts.inter(
          fontSize: 12.5.sp,
          color: Colors.grey.shade400,
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFEAECF0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFEAECF0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: KorraColors.brand, width: 1.5),
        ),
      ),
    );
  }
}
