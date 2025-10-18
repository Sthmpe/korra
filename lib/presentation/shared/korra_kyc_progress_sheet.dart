import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';

class KycProgressSheet<B extends StateStreamable<S>, S> extends StatelessWidget {
  final bool Function(S, S)? buildWhen;
  final bool Function(S state)? allVerified;
  final bool Function(S state)? anyError;
  final bool Function(S state)? ninVerifying;
  final bool Function(S state)? bvnVerifying;
  final bool Function(S state)? ninVerified;
  final bool Function(S state)? bvnVerified;
  final String? Function(S state)? ninError;
  final String? Function(S state)? bvnError;
  final String title;

  const KycProgressSheet({
    super.key,
    this.buildWhen,
    this.allVerified,
    this.anyError,
    this.ninVerifying,
    this.bvnVerifying,
    this.ninVerified,
    this.bvnVerified,
    this.ninError,
    this.bvnError,
    this.title = 'Verifying your identity',
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        child: BlocBuilder<B, S>(
          buildWhen: buildWhen,
          builder: (_, s) {
            final verified = allVerified?.call(s) ?? false;
            final error = anyError?.call(s) ?? false;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAE6E2),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8.h),

                _line(
                  'NIN',
                  running: ninVerifying?.call(s) ?? false,
                  ok: ninVerified?.call(s) ?? false,
                  err: ninError?.call(s),
                ),
                SizedBox(height: 8.h),
                _line(
                  'BVN',
                  running: bvnVerifying?.call(s) ?? false,
                  ok: bvnVerified?.call(s) ?? false,
                  err: bvnError?.call(s),
                ),

                SizedBox(height: 10.h),
                if (verified) ...[
                  Text('Done', style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600))
                ] else if (error) ...[
                  Text(
                    'There was an issue',
                    style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.red),
                  )
                ] else ...[
                  Text(
                    'This won’t take long…',
                    style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.black54),
                  )
                ],
                SizedBox(height: 6.h),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _line(
    String title, {
    required bool running,
    required bool ok,
    String? err,
  }) {
    IconData icon;
    Color color;
    String subtitle;
    Widget? tail;

    if (running) {
      icon = Iconsax.timer;
      color = Colors.orange;
      subtitle = 'Checking…';
      tail = SizedBox(
        width: 16.r,
        height: 16.r,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (ok) {
      icon = Iconsax.tick_circle;
      color = Colors.green;
      subtitle = 'Verified';
    } else if (err != null) {
      icon = Iconsax.close_circle;
      color = Colors.red;
      subtitle = 'Failed';
    } else {
      icon = Iconsax.more;
      color = Colors.grey;
      subtitle = 'Waiting';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16.sp, color: color),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600)),
              Text(
                ok ? subtitle : (err ?? 'Pending'),
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: ok ? Colors.green : err != null ? Colors.red : Colors.black54,
                ),
              ),
            ],
          ),
        ),
        if (tail != null) tail,
      ],
    );
  }
}
