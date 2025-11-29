import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../logic/core/net/net_cubit.dart';

class GlobalOfflineBanner extends StatelessWidget {
  const GlobalOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetCubit, NetState>(
      builder: (context, state) {
        final isOffline = state == NetState.offline;

        // 1. Animation: Use AnimatedSize or AnimatedSwitcher for smooth entry
        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Container(
            height: isOffline ? null : 0, // Collapses to 0 when online
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF1B1B1B), // Premium Dark
              border: Border(
                bottom: BorderSide(color: Colors.white10, width: 0.5),
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
            child: isOffline 
              ? SafeArea(
                  bottom: false, // Only respect top safe area
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 12.w, 
                        height: 12.w, 
                        child: const CircularProgressIndicator(
                          strokeWidth: 2, 
                          color: Colors.white54
                        )
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "You are currently offline",
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      // const Spacer(),
                      
                      // // 2. Action: Retry Button
                      // GestureDetector(
                      //   onTap: () => context.read<NetCubit>().retryNow(),
                      //   child: Text(
                      //     "Retry",
                      //     style: GoogleFonts.inter(
                      //       fontSize: 12.sp,
                      //       fontWeight: FontWeight.w700,
                      //       color: const Color(0xFFA54600), // Brand Color pops on black
                      //     ),
                      //   ),
                      // )
                    ],
                  ),
                )
              : const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}