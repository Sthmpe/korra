import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96.w,
      child: Column(
        children: [
          GestureDetector(
            onLongPress: onRemove,
            onTap: onOpen,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundImage: NetworkImage(avatarUrl),
                ),
                SizedBox(height: 8.h),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                onPressed: onWhatsapp,
                iconSize: 18.sp,
              ),
              IconButton(
                icon: const Icon(Icons.photo_camera_outlined),
                onPressed: onInstagram,
                iconSize: 18.sp,
              ),
              IconButton(
                icon: const Icon(Icons.public),
                onPressed: onWeb,
                iconSize: 18.sp,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
