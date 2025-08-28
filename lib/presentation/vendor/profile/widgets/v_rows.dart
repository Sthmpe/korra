import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class VRowNav extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final VoidCallback onTap;

  const VRowNav({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 10.h, 10.w, 10.h),
        child: Row(children: [
          _IconCircle(icon: icon),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.inter(fontSize: 14.5.sp, fontWeight: FontWeight.w800)),
              if (subtitle != null) ...[
                SizedBox(height: 3.h),
                Text(subtitle!, style: GoogleFonts.inter(fontSize: 12.5.sp, color: const Color(0xFF5E5E5E), fontWeight: FontWeight.w600)),
              ],
            ]),
          ),
          if (trailingText != null)
            Padding(
              padding: EdgeInsets.only(right: 6.w),
              child: Text(trailingText!, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, color: const Color(0xFF5E5E5E))),
            ),
          const Icon(Icons.chevron_right, color: Color(0xFF8B8B8B)),
        ]),
      ),
    );
  }
}

class VRowSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const VRowSwitch({
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
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 10.h),
      child: Row(children: [
        _IconCircle(icon: icon),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.inter(fontSize: 14.5.sp, fontWeight: FontWeight.w800)),
            if (subtitle != null) ...[
              SizedBox(height: 3.h),
              Text(subtitle!, style: GoogleFonts.inter(fontSize: 12.5.sp, color: const Color(0xFF5E5E5E), fontWeight: FontWeight.w600)),
            ],
          ]),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: const Color(0xFFA54600),
          inactiveThumbColor: const Color(0xFF6F6A78),
          inactiveTrackColor: const Color(0xFFD6D0DC),
        ),
      ]),
    );
  }
}

class VRowLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String trailingText;
  const VRowLabel({super.key, required this.icon, required this.title, required this.trailingText});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 12.h),
      child: Row(children: [
        _IconCircle(icon: icon),
        SizedBox(width: 12.w),
        Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 14.5.sp, fontWeight: FontWeight.w800))),
        Text(trailingText, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, color: const Color(0xFF5E5E5E))),
      ]),
    );
  }
}

class VRadioPill extends StatelessWidget {
  final bool selected;
  final bool leadingCheck;
  final String text;
  final VoidCallback onTap;
  const VRadioPill({super.key, required this.selected, required this.text, required this.onTap, this.leadingCheck = false});

  static const _brand = Color(0xFFA54600);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: selected ? _brand : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: selected ? _brand : const Color(0xFFEAE6E2)),
          boxShadow: selected ? [BoxShadow(color: _brand.withOpacity(.12), blurRadius: 10, offset: const Offset(0, 4))] : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (selected && leadingCheck) ...[
            const Icon(Icons.check, color: Colors.white, size: 16),
            SizedBox(width: 8.w),
          ],
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : const Color(0xFF1B1B1B),
            ),
          ),
        ]),
      ),
    );
  }
}

class VDivider extends StatelessWidget {
  final double? space;
  const VDivider({super.key, this.space});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: Column(children: [
        SizedBox(height: (space ?? 8.h) / 2),
        const Divider(height: 1, color: Color(0xFFEAE6E2)),
        SizedBox(height: (space ?? 8.h) / 2),
      ]),
    );
  }
}

class _IconCircle extends StatelessWidget {
  final IconData icon;
  const _IconCircle({required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36.w, height: 36.w,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EF),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(icon, color: const Color(0xFFA54600), size: 18.sp),
    );
  }
}
