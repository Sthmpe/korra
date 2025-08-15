import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

const _brand = Color(0xFFA54600);

Future<void> showVendorActionsSheet({
  required BuildContext context,
  required String name,
  required String avatarUrl,
  required VoidCallback onOpen,
  required VoidCallback onWhatsapp,
  required VoidCallback onInstagram,
  required VoidCallback onWeb,
  required VoidCallback onRemove,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: false,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // grabber
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFFEAE6E2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            // header
            Row(
              children: [
                ClipOval(
                  child: Image.network(
                    avatarUrl,
                    width: 40.w,
                    height: 40.w,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 40.w, height: 40.w,
                      color: const Color(0xFFF3EFEA),
                      alignment: Alignment.center,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: _brand,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onOpen,
                  child: Text(
                    'Open',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: _brand,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),
            const Divider(height: 1, color: Color(0xFFEAE6E2)),
            SizedBox(height: 12.h),

            // actions grid (3 columns)
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: [
                _ActionBtn(
                  label: 'WhatsApp',
                  icon: Icons.chat_bubble_outline_rounded,
                  onTap: onWhatsapp,
                ),
                _ActionBtn(
                  label: 'Instagram',
                  icon: Icons.photo_camera_outlined,
                  onTap: onInstagram,
                ),
                _ActionBtn(
                  label: 'Website',
                  icon: Icons.public,
                  onTap: onWeb,
                ),
                _ActionBtn(
                  label: 'Remove',
                  icon: Icons.delete_outline,
                  onTap: onRemove,
                  danger: true,
                ),
              ],
            ),

            SizedBox(height: 8.h),
          ],
        ),
      );
    },
  );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFB3261E) : _brand;
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 16.w * 2 - 12.w * 2) / 3,
      child: Material(
        color: const Color(0xFFFAF7F4),
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: () {
            Navigator.of(context).pop();
            onTap();
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20.sp, color: color),
                SizedBox(height: 6.h),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
