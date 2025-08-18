import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

const _brand = Color(0xFFA54600);

class RowWithChevron extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const RowWithChevron({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          children: [
            Container(
              width: 34.w, height: 34.w,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F4),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFEAE6E2)),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18.sp, color: _brand),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(fontSize: 14.5.sp, fontWeight: FontWeight.w700)),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(subtitle!,
                        style: GoogleFonts.inter(fontSize: 12.5.sp, color: const Color(0xFF5E5E5E))),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: const Color(0xFF8B8B8B), size: 22.sp),
          ],
        ),
      ),
    );
  }
}

class SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SwitchRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          Container(
            width: 34.w, height: 34.w,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F4),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFFEAE6E2)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18.sp, color: _brand),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14.5.sp, fontWeight: FontWeight.w700)),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(subtitle!, style: GoogleFonts.inter(fontSize: 12.5.sp, color: const Color(0xFF5E5E5E))),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: _brand,
          ),
        ],
      ),
    );
  }
}
