import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

const _brand = Color(0xFFA54600);

class IdentityHeaderCard extends StatelessWidget {
  final String initials;
  final String name;
  final String email;
  final String phone;
  final bool kycVerified; // true
  final bool basicTier;   // true
  final VoidCallback? onEdit;

  const IdentityHeaderCard({
    super.key,
    required this.initials,
    required this.name,
    required this.email,
    required this.phone,
    required this.kycVerified,
    required this.basicTier,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFEAE6E2)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // initials-only avatar
                Container(
                  width: 56.w, height: 56.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F4),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFEAE6E2)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.w800, color: _brand),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700)),
                      SizedBox(height: 2.h),
                      Text('$email • $phone',
                          style: GoogleFonts.inter(fontSize: 12.5.sp, color: const Color(0xFF5E5E5E))),
                      SizedBox(height: 6.h),
                      Wrap(
                        spacing: 6.w,
                        children: [
                          if (kycVerified) const _Chip(text: 'Verified', type: _ChipType.success),
                          if (basicTier)   const _Chip(text: 'Basic', type: _ChipType.outline),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined, size: 20.sp, color: const Color(0xFF1B1B1B)),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            Row(
              children: [
                _ActionPill(text: 'Edit profile', icon: Icons.person_outline, onTap: onEdit),
                SizedBox(width: 6.w),
                _ActionPill(text: 'Show QR', icon: Icons.qr_code_2_outlined, onTap: () {}),
                SizedBox(width: 6.w),
                _ActionPill(text: 'Share handle', icon: Icons.share_outlined, onTap: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _ChipType { success, outline }

class _Chip extends StatelessWidget {
  final String text;
  final _ChipType type;
  const _Chip({required this.text, required this.type});

  @override
  Widget build(BuildContext context) {
    final success = type == _ChipType.success;
    final bg = success ? const Color(0xFFEAF4EC) : Colors.white;
    final fg = success ? const Color(0xFF1B5E20) : const Color(0xFF1B1B1B);
    final border = success ? const Color(0xFFD3E5D7) : const Color(0xFFEAE6E2);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap;
  const _ActionPill({required this.text, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 36.h,
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: _brand,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            padding: EdgeInsets.symmetric(horizontal: 8.w),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16.sp, color: Colors.white),
              SizedBox(width: 4.w),
              SizedBox(width: 80.w, child: Text(text, overflow: TextOverflow.clip,style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w800, color: Colors.white))),
            ],
          ),
        ),
      ),
    );
  }
}
