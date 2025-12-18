import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const SectionCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
      child: Container(
        padding: padding ?? EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFEAE6E2)),
        ),
        child: child,
      ),
    );
  }
}
