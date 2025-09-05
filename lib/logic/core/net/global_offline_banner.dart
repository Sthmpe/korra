// You can create a new file for this, e.g., lib/presentation/shared/widgets/global_offline_banner.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../logic/core/net/net_cubit.dart';

class GlobalOfflineBanner extends StatelessWidget {
  const GlobalOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<NetCubit, NetState, bool>(
      // Only rebuild if the offline status changes
      selector: (state) => state == NetState.offline,
      builder: (context, isOffline) {
        if (!isOffline) {
          // If online, return an empty container
          return const SizedBox.shrink();
        }

        // If offline, build the banner
        return Container(
          width: double.infinity,
          color: const Color(0xFF121212), // A neutral dark color
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            "You're currently offline",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}