import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class KorraBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const KorraBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _brand = Color(0xFFA54600);
  static const _stroke = Color(0xFFEAE6E2);

  @override
  Widget build(BuildContext context) {
    final items = const [
      _NavSpec('Home', Icons.home_outlined, Icons.home_rounded),
      _NavSpec('Plans', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
      _NavSpec('Profile', Icons.person_outline, Icons.person_rounded),
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 60.h, // ⬅️ slimmer
        decoration: const BoxDecoration(
          color: Colors.white, // ⬅️ cleaner surface
          border: Border(
            top: BorderSide(color: _stroke, width: 1), // subtle divider
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final slot = constraints.maxWidth / items.length;
            final indicatorLeft = slot * currentIndex + (slot - 24.w) / 2; // center under icon

            return Stack(
              children: [
                Row(
                  children: List.generate(items.length, (i) {
                    final selected = i == currentIndex;
                    final spec = items[i];
                    return Expanded(
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onTap(i);
                        },
                        borderRadius: BorderRadius.circular(12.r),
                        child: Padding(
                          padding: EdgeInsets.only(top: 6.h, bottom: 10.h),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                selected ? spec.filled : spec.outline,
                                size: 22.sp,
                                color: selected ? _brand : const Color(0xFF4D4D4D),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                spec.label,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5.sp,                // ⬅️ smaller label
                                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                                  color: selected ? _brand : const Color(0xFF4D4D4D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                // tiny brand indicator under selected icon
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  left: indicatorLeft,
                  bottom: 6.h,
                  child: Container(
                    width: 24.w,
                    height: 3.h,
                    decoration: BoxDecoration(
                      color: _brand,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavSpec {
  final String label;
  final IconData outline;
  final IconData filled;
  const _NavSpec(this.label, this.outline, this.filled);
}
