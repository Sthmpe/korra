import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'net_cubit.dart';

class KorraOfflineGate extends StatelessWidget {
  const KorraOfflineGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetCubit, NetState>(
      builder: (context, state) {
        final isOffline = state == NetState.offline;
        final isChecking = state == NetState.checking;

        return Stack(
          children: [
            // 1. The App Content (Disable interaction if offline)
            IgnorePointer(
              ignoring: isOffline, 
              child: child
            ),

            // Dark Overlay (Fade in)
            if (isOffline)
              const ModalBarrier(dismissible: false, color: Colors.black54),

            // 2. Top Banner (Animated Slide In)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: isChecking ? 0 : -100, // Hide off-screen when not checking
              left: 0,
              right: 0,
              child: const _CheckingBanner(),
            ),

            // 3. Bottom Sheet (Animated Slide Up)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              bottom: isOffline ? 0 : -350, // Hide off-screen
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: const _OfflineSheet(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CheckingBanner extends StatelessWidget {
  const _CheckingBanner();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: EdgeInsets.only(top: 8.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: const Color(0xFF333333), // Darker for contrast
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0,4))]
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14.w, height: 14.w,
                child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 10.w),
              Text(
                'Reconnecting...',
                style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineSheet extends StatelessWidget {
  const _OfflineSheet();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 20,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(24.r),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w, height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 24.h),
            
            // Visual Anchor
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(color: const Color(0xFFFFF1F0), shape: BoxShape.circle),
              child: Icon(Icons.wifi_off_rounded, size: 32.sp, color: const Color(0xFFD92D20)),
            ),
            
            SizedBox(height: 16.h),
            Text(
              'No Connection',
              style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800, color: const Color(0xFF101828)),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please check your internet settings. We will reconnect automatically when you are back online.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14.sp, height: 1.5, color: const Color(0xFF667085)),
            ),
            SizedBox(height: 24.h),
            
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: OutlinedButton(
                onPressed: () => context.read<NetCubit>().retryNow(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFA54600)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  foregroundColor: const Color(0xFFA54600),
                ),
                child: Text('Try Again', style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}