import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/auth/role_login/role_login_bloc.dart';
import '../../../../logic/bloc/auth/role_login/role_login_event.dart';
import '../../../../logic/bloc/auth/role_login/role_login_state.dart';

class BiometricButton extends StatelessWidget {
  const BiometricButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoleLoginBloc, RoleLoginState>(
      buildWhen: (p, c) => p.bioUi != c.bioUi,
      builder: (context, state) {
        Widget icon;
        switch (state.bioUi) {
          case BiometricUi.inProgress:
            icon = const SizedBox(
              height: 50, width: 50,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            );
            break;
          case BiometricUi.success:
            icon = const Icon(Iconsax.tick_circle, color: Colors.white, size: 50);
            break;
          case BiometricUi.failure:
            icon = const Icon(Iconsax.close_circle, color: Colors.white, size:50);
            break;
          case BiometricUi.pressed:
          case BiometricUi.idle:
          icon = const Icon(Iconsax.finger_scan, color: Colors.white, size: 50);
        }

        final pressed = state.bioUi == BiometricUi.pressed || state.bioUi == BiometricUi.inProgress;

        return Center(
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                width: pressed ? 120.r : 100.r,
                height: pressed ? 120.r : 100.r,
                decoration: BoxDecoration(
                  color: KorraColors.brand,
                  shape: BoxShape.circle,
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<RoleLoginBloc>().add(BiometricsPressed());
                  },
                  child: Center(child: icon),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                state.bioUi == BiometricUi.success ? 'Verified'
                  : state.bioUi == BiometricUi.failure ? 'Try again'
                  : '',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.5.sp),
              ),
            ],
          ),
        );
      },
    );
  }
}
