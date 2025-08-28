import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class VendorIdentityHeaderCard extends StatelessWidget {
  final String name, email, phone;
  final bool verified;
  final String tier;
  final VoidCallback onEdit, onShowQr, onShareHandle;

  const VendorIdentityHeaderCard({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.verified,
    required this.tier,
    required this.onEdit,
    required this.onShowQr,
    required this.onShareHandle,
  });

  static const _brand = Color(0xFFA54600);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEAE6E2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _Avatar(name: name),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w900)),
              SizedBox(height: 3.h),
              Text('$email • $phone',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12.5.sp, color: const Color(0xFF5E5E5E), fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              Wrap(spacing: 8.w, runSpacing: 6.h, children: [
                _Chip(
                  icon: Iconsax.verify,
                  text: verified ? 'Verified' : 'Unverified',
                  bg: const Color(0xFFEAF6EE),
                  fg: const Color(0xFF1DB954),
                ),
                _Chip(
                  icon: Iconsax.star_1,
                  text: tier,
                  bg: const Color(0xFFF7F3EF),
                  fg: _brand,
                ),
              ]),
            ]),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Iconsax.edit_2), color: const Color(0xFF5E5E5E)),
        ]),
        SizedBox(height: 12.h),
        Row(children: [
          Expanded(child: _Primary(text: 'Edit profile', icon: Iconsax.user_edit, onTap: onEdit)),
          SizedBox(width: 8.w),
          Expanded(child: _Primary(text: 'Show QR', icon: Iconsax.scan_barcode, onTap: onShowQr)),
          SizedBox(width: 8.w),
          Expanded(child: _Primary(text: 'Share handle', icon: Iconsax.share, onTap: onShareHandle)),
        ]),
      ]),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});
  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '??'
        : name.trim().split(' ').take(2).map((w) => w[0]).join().toUpperCase();
    return Container(
      width: 54.w, height: 54.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EF),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Text(initials, style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w900, color: const Color(0xFFA54600))),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon; final String text; final Color bg; final Color fg;
  const _Chip({required this.icon, required this.text, required this.bg, required this.fg});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999.r)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14.sp, color: fg),
        SizedBox(width: 6.w),
        Text(text, style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w800, color: fg)),
      ]),
    );
  }
}

class _Primary extends StatelessWidget {
  final String text; final IconData icon; final VoidCallback onTap;
  const _Primary({required this.text, required this.icon, required this.onTap});
  static const _brand = Color(0xFFA54600);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42.h,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: _brand,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          padding: EdgeInsets.symmetric(horizontal: 12.w),
        ),
        icon: Icon(icon, size: 18.sp, color: Colors.white),
        label: Text(text, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }
}
