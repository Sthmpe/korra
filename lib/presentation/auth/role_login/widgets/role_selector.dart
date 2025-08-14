import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../config/constants/colors.dart';
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
        return Row(
          children: [
            Expanded(
              child: _RoleChip(
                icon: MdiIcons.account,
                iconSize: 20.sp,
                titleSize: 14.sp,
                subtitleSize: 12.sp,
                title: 'Customer',
                subtitle: 'Reserve • Pay in parts',
                selected: isCustomer,
                onTap: () => context.read<RoleLoginBloc>().add(RoleSelected(KorraRole.customer)),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _RoleChip(
                icon: MdiIcons.store,
                iconSize: 20.sp,
                titleSize: 14.sp,
                subtitleSize: 12.sp,
                title: 'Vendor',
                subtitle: 'List • Manage reservations',
                selected: !isCustomer,
                onTap: () => context.read<RoleLoginBloc>().add(RoleSelected(KorraRole.vendor)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RoleChip extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final double titleSize;
  final double subtitleSize;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.icon,
    required this.iconSize,
    required this.titleSize,
    required this.subtitleSize,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: selected ? KorraColors.brand : Colors.grey.shade300,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: selected ? KorraColors.brand.withOpacity(.10) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: selected ? KorraColors.brand : Colors.black87, size: iconSize),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: titleSize)),
                  SizedBox(height: 2.h),
                  Text(subtitle,
                      style: GoogleFonts.inter(fontSize: subtitleSize, color: Colors.black54)),
                ],
              ),
            ),
            Icon(Iconsax.tick_circle, size: 18.sp,
                color: selected ? KorraColors.brand : Colors.transparent),
          ],
        ),
      ),
    );
  }
}
