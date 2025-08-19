import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class KorraBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavSpec> items;

  /// Optional: numeric badges per index (e.g., {2: 5} for Reservations)
  final Map<int, int> countBadges;

  /// Optional: dot badges per index (e.g., {0} for Home dot)
  final Set<int> dotBadges;

  const KorraBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.countBadges = const {},
    this.dotBadges = const {},
  }) : assert(items.length >= 2);

  static const _brand  = Color(0xFFA54600);
  static const _stroke = Color(0xFFEAE6E2);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 60.h,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _stroke, width: 1)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final slot = constraints.maxWidth / items.length;
            final indicatorLeft = slot * currentIndex + (slot - 24.w) / 2;

            return Stack(
              children: [
                Row(
                  children: List.generate(items.length, (i) {
                    final selected = i == currentIndex;
                    final spec = items[i];
                    final badge = countBadges[i] ?? 0;
                    final showDot = dotBadges.contains(i);

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
                              SizedBox(
                                height: 24.h,
                                width: 28.w,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Align(
                                      alignment: Alignment.center,
                                      child: Icon(
                                        selected ? spec.filled : spec.outline,
                                        size: 22.sp,
                                        color: selected ? _brand : const Color(0xFF4D4D4D),
                                      ),
                                    ),
                                    if (showDot)
                                      Positioned(
                                        right: -2.w, top: -2.h,
                                        child: Container(
                                          width: 8.w, height: 8.w,
                                          decoration: const BoxDecoration(
                                            color: _brand, shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    if (badge > 0)
                                      Positioned(
                                        right: -8.w, top: -8.h,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                          constraints: BoxConstraints(minWidth: 18.w),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent,
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            badge > 99 ? '99+' : '$badge',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                spec.label,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5.sp,
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

                // Tiny brand indicator under selected icon
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

class NavSpec {
  final String label;
  final IconData outline;
  final IconData filled;
  const NavSpec(this.label, this.outline, this.filled);
}
