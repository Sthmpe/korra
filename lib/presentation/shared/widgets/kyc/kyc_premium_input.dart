import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/constants/colors.dart';

class KycPremiumInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final TextInputType inputType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final bool readOnly;

  const KycPremiumInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    this.inputType = TextInputType.text,
    this.inputFormatters,
    this.suffixIcon,
    this.readOnly = false,
  });

  @override
  State<KycPremiumInput> createState() => _KycPremiumInputState();
}

class _KycPremiumInputState extends State<KycPremiumInput> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocus);
    super.dispose();
  }

  void _handleFocus() => setState(() => _isFocused = widget.focusNode.hasFocus);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111111),
          ),
        ),
        SizedBox(height: 8.h),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.readOnly
                ? const Color(0xFFF9FAFB)
                : (_isFocused ? Colors.white : const Color(0xFFF7F7F7)),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: _isFocused && !widget.readOnly
                  ? KorraColors.brand
                  : const Color(0xFFE5E5E5),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: widget.inputType,
            inputFormatters: widget.inputFormatters,
            readOnly: widget.readOnly,
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: widget.readOnly
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF1B1B1B),
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 14.sp,
                color: const Color(0xFFAAAAAA),
              ),
              suffixIcon: widget.suffixIcon,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(12.r),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(12.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(12.r),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(12.r),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
