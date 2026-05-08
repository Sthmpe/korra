import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/constants/sizes.dart';
import '../../../../logic/bloc/auth/role_login/role_login_bloc.dart';
import '../../../../logic/bloc/auth/role_login/role_login_event.dart';
import '../../../../logic/bloc/auth/role_login/role_login_state.dart';

class RoleSelector extends StatelessWidget {
  const RoleSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoleLoginBloc, RoleLoginState>(
      buildWhen: (p, c) => p.role != c.role,
      builder: (context, state) {
        final isCustomer = state.role == KorraRole.customer;

        return Container(
          height: 52.h, // Compact, standard mobile height
          padding: EdgeInsets.all(4.r), // The gap between edge and pill
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7), // The specific "iOS System Grey"
            borderRadius: BorderRadius.circular(14.r), // Slightly tighter radius
          ),
          child: Stack(
            children: [
              // 1. The Sliding White Pill (The "Active" Background)
              AnimatedAlign(
                alignment: isCustomer ? Alignment.centerLeft : Alignment.centerRight,
                duration: const Duration(milliseconds: 200), // FAST
                curve: Curves.easeOut, // SNAPPY
                child: Container(
                  width: (MediaQuery.of(context).size.width - (KorraSizes.gutter.w * 2) - 8.w) / 2, 
                  // Math: (Screen - PagePadding - InternalPadding) / 2
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12), // Apple-style shadow
                        blurRadius: 3, // Tight blur
                        offset: const Offset(0, 1), // Slight drop
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. The Text/Icon Layers
              Row(
                children: [
                  Expanded(
                    child: _RoleTab(
                      title: 'Customer',
                      icon: MdiIcons.accountOutline, // Outline icons look cleaner here
                      activeIcon: MdiIcons.account,
                      isActive: isCustomer,
                      onTap: () {
                        HapticFeedback.mediumImpact(); // Physical click feel
                        context.read<RoleLoginBloc>().add(RoleSelected(KorraRole.customer));
                      },
                    ),
                  ),
                  Expanded(
                    child: _RoleTab(
                      title: 'Vendor',
                      icon: MdiIcons.storeOutline,
                      activeIcon: MdiIcons.store,
                      isActive: !isCustomer,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        context.read<RoleLoginBloc>().add(RoleSelected(KorraRole.vendor));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoleTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;

  const _RoleTab({
    required this.title,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // Catches taps even on empty space
      child: SizedBox(
        height: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon Switcher
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                size: 18.sp,
                color: isActive ? const Color(0xFF1C1C1E) : KorraColors.textSecondary,
              ),
            ),
            SizedBox(width: 6.w),
            // Animated Text Style
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.inter(
                fontSize: KorraSizes.fontSmPlusH.sp,
                fontWeight: isActive ? KorraSizes.weightSemiBold : KorraSizes.weightMedium,
                color: isActive ? const Color(0xFF1C1C1E) : KorraColors.textSecondary,
                letterSpacing: KorraSizes.trackingMinus3,
              ),
              child: Text(title),
            ),
          ],
        ),
      ),
    );
  }
}