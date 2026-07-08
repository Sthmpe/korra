import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'signal_badge_dot.dart';

class KorraBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavSpec> pageIcons;
  final Map<int, int> countBadges;
  final Set<int> dotBadges;

  /// Tabs that show the animated "broadcasting" red dot (expanding signal
  /// rings) — stronger nudge than [dotBadges], e.g. an abandoned cart.
  final Set<int> signalBadges;

  const KorraBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.pageIcons,
    this.countBadges = const {},
    this.dotBadges = const {},
    this.signalBadges = const {},
  }) : assert(pageIcons.length >= 2);

  static const _brand = Color(0xFFA54600);
  static const _inactiveColor = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    // Using a shadow container instead of border for that "floating" feel
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64.h, // Slightly taller for modern touch targets
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slot = constraints.maxWidth / pageIcons.length;
              // Calculate center position for the indicator
              // slot * index moves it to the slot start
              // (slot - width) / 2 centers it within the slot
              final indicatorWidth = 32.w;
              final indicatorLeft = (slot * currentIndex) + (slot - indicatorWidth) / 2;

              return Stack(
                children: [
                  // 1. The Icons Row
                  Row(
                    children: List.generate(pageIcons.length, (i) {
                      final selected = i == currentIndex;
                      final spec = pageIcons[i];
                      final badge = countBadges[i] ?? 0;
                      final showSignal = signalBadges.contains(i);
                      final showDot = dotBadges.contains(i) && !showSignal;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact(); // Crisper haptic
                            onTap(i);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon + Badge Stack
                              SizedBox(
                                height: 28.h,
                                width: 32.w, // Constrain width for badge positioning
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    // The Icon
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 200),
                                      child: Icon(
                                        selected ? spec.filled : spec.outline,
                                        key: ValueKey(selected),
                                        size: 24.sp,
                                        color: selected ? _brand : _inactiveColor,
                                      ),
                                    ),

                                    // Signal Badge (animated nudge, e.g. saved cart)
                                    if (showSignal)
                                      Positioned(
                                        right: -10.w,
                                        top: -10.h,
                                        child: SignalBadgeDot(size: 8.w),
                                      ),

                                    // Dot Badge (Notification)
                                    if (showDot)
                                      Positioned(
                                        right: -2.w,
                                        top: -2.h,
                                        child: Container(
                                          width: 8.w,
                                          height: 8.w,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 1.5),
                                          ),
                                        ),
                                      ),

                                    // Count Badge (Messages)
                                    if (badge > 0)
                                      Positioned(
                                        left: 14.w, // Offset to the right
                                        top: -5.h,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                                          constraints: BoxConstraints(minWidth: 16.w),
                                          decoration: BoxDecoration(
                                            color: _brand,
                                            borderRadius: BorderRadius.circular(10.r),
                                            border: Border.all(color: Colors.white, width: 1.5),
                                          ),
                                          child: Text(
                                            badge > 99 ? '99+' : '$badge',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                              fontSize: 9.sp,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              
                              SizedBox(height: 4.h),
                              
                              // Label
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                  color: selected ? _brand : _inactiveColor,
                                  letterSpacing: -0.2,
                                ),
                                child: Text(spec.label),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),

                  // 2. The Sliding Indicator (Your Favorite Part)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.fastLinearToSlowEaseIn, // iOS "Springy" feel
                    left: indicatorLeft,
                    bottom: 0, // Align to very bottom edge
                    child: Container(
                      width: indicatorWidth,
                      height: 4.h, // Slightly thicker for visibility
                      decoration: BoxDecoration(
                        color: _brand,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(4.r)),
                        boxShadow: [
                          BoxShadow(
                            color: _brand.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
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