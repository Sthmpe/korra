import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/constants/colors.dart';
import '../../../../config/utils/currency_formatters.dart';

class ProductDirectSettingsCard extends StatelessWidget {
  final TextEditingController downPaymentCtrl;
  final bool priceAllowsExtension;
  final bool isDirectExtensionEnabled;
  final ValueChanged<bool> onExtensionChanged;

  const ProductDirectSettingsCard({
    super.key,
    required this.downPaymentCtrl,
    required this.priceAllowsExtension,
    required this.isDirectExtensionEnabled,
    required this.onExtensionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('direct'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4ED),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.settings,
                size: 20,
                color: Color(0xFFA54600),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  "Flexible Plan. You control the required down payment and extensions. Cancellations are still refunded as Store Balance.",
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFF344054),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        Text(
          "Required Down Payment",
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF344054),
          ),
        ),
        SizedBox(height: 8.h),
        _buildInput(
          controller: downPaymentCtrl,
          hint: "0.00",
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 14.w, right: 4.w),
            child: Text(
              "₦",
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CurrencyInputFormatter(),
          ],
        ),
        if (priceAllowsExtension) ...[
          SizedBox(height: 20.h),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: KorraColors.brand,
            title: Text(
              "Allow Extension?",
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              "If enabled, gives customer extra time if they reach 80% payment.",
              style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
            ),
            value: isDirectExtensionEnabled,
            onChanged: onExtensionChanged,
          ),
        ],
      ],
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    Widget? prefixIcon,
    BoxConstraints? prefixIconConstraints,
    Widget? suffixIcon,
    int maxLines = 1,
    bool enabled = true,
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      readOnly: readOnly,
      style: GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF101828),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14.sp,
          color: Colors.grey.shade400,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade50,
        prefixIcon: prefixIcon,
        prefixIconConstraints: prefixIconConstraints,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFFA54600), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFFD92D20)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFFD92D20), width: 1.5),
        ),
      ),
    );
  }
}
