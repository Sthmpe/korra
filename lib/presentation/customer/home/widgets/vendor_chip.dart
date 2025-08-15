import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'vendor_actions_sheet.dart';

class VendorChip extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final VoidCallback onOpen;
  final VoidCallback onRemove;
  final VoidCallback onWhatsapp;
  final VoidCallback onInstagram;
  final VoidCallback onWeb;

  const VendorChip({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.onOpen,
    required this.onRemove,
    required this.onWhatsapp,
    required this.onInstagram,
    required this.onWeb,
  });

  static const _brand = Color(0xFFA54600);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92.w, // tidy width; prevents label overflow
      child: Column(
        children: [
          // Avatar + quick chat dot
          GestureDetector(
            onTap: () {
              // elegant action sheet with all vendor actions
              showVendorActionsSheet(
                context: context,
                name: name,
                avatarUrl: avatarUrl,
                onOpen: onOpen,
                onWhatsapp: onWhatsapp,
                onInstagram: onInstagram,
                onWeb: onWeb,
                onRemove: onRemove,
              );
            },
            onLongPress: onRemove,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // avatar
                Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFEAE6E2), width: 1),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      avatarUrl,
                      width: 56.w,
                      height: 56.w,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFF3EFEA),
                        alignment: Alignment.center,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: _brand,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // quick chat button (bottom-right)
                Positioned(
                  right: -2.w,
                  bottom: -2.h,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onWhatsapp,
                      child: Container(
                        width: 22.w,
                        height: 22.w,
                        decoration: const BoxDecoration(
                          color: _brand,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.chat_bubble_outline_rounded,
                            size: 12.sp, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 8.h),

          // name
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1B1B1B),
            ),
          ),
        ],
      ),
    );
  }
}
