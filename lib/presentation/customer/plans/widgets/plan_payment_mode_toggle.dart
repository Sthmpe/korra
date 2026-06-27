import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../config/constants/colors.dart';

class PlanPaymentModeToggle extends StatelessWidget {
  final bool isPayInFull;
  final ValueChanged<bool> onChanged;

  const PlanPaymentModeToggle({
    super.key,
    required this.isPayInFull,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6), 
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isPayInFull) return;
                onChanged(false);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !isPayInFull ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: !isPayInFull
                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Text(
                  "Installment Plan",
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: !isPayInFull ? FontWeight.w700 : FontWeight.w600,
                    color: !isPayInFull ? KorraColors.text : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isPayInFull) return;
                onChanged(true);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isPayInFull ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: isPayInFull
                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Text(
                  "Pay in Full",
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: isPayInFull ? FontWeight.w700 : FontWeight.w600,
                    color: isPayInFull ? KorraColors.text : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
