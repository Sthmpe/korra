import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../logic/bloc/vendor/product/vendor_products_state.dart';

class ProductModelTabs extends StatelessWidget {
  final ProductModelType selectedModel;
  final ValueChanged<ProductModelType> onModelChanged;

  const ProductModelTabs({
    super.key,
    required this.selectedModel,
    required this.onModelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          _buildModelTab("Strict Lock", ProductModelType.strict),
          _buildModelTab("Korra Direct", ProductModelType.direct),
        ],
      ),
    );
  }

  Widget _buildModelTab(String label, ProductModelType model) {
    final isSelected = selectedModel == model;
    return Expanded(
      child: GestureDetector(
        onTap: () => onModelChanged(model),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF101828)
                  : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }
}
