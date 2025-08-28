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
      buildWhen: (p, c) => p != c,
      builder: (context, state) {
        final isOffline = state == NetState.offline;
        final isChecking = state == NetState.checking;

        return Stack(
          children: [
            child,

            // Non-blocking checking banner (top)
            if (isChecking) const _CheckingBanner(),

            // Blocking offline sheet (bottom) + barrier
            if (isOffline) ...[
              const ModalBarrier(dismissible: false, color: Colors.black54),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: const _OfflineSheet(),
                  ),
                ),
              ),
            ],
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
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: const Color(0xFFEEEFF3),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8.w),
              Text(
                'Checking connection…',
                style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF333333)),
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
      elevation: 10,
      borderRadius: BorderRadius.circular(24.r),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w, height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFEAE6E2),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Icon(Icons.wifi_off, size: 36.sp, color: const Color(0xFFA54600)),
            SizedBox(height: 12.h),
            Text(
              'No internet connection',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B1B)),
            ),
            SizedBox(height: 8.h),
            Text(
              'You’re offline. We’ll resume automatically once you’re back online.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14.sp, fontWeight: FontWeight.w400, color: const Color(0xFF5E5E5E)),
            ),
            SizedBox(height: 16.h),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.read<NetCubit>().retryNow(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.fromHeight(48.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    side: const BorderSide(color: Color(0xFFA54600)),
                  ),
                  child: Text('Retry now',
                    style: GoogleFonts.inter(
                      fontSize: 15.sp, fontWeight: FontWeight.w600, color: const Color(0xFFA54600))),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}





// final ok = await context.read<NetCubit>().preflight();
// if (!ok) return; // will show offline state; skip request
// // proceed with the action...