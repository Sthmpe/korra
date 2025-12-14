import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart'; // Using Iconsax for consistency
import 'package:share_plus/share_plus.dart';

import '../../../../config/constants/colors.dart'; // Ensure KorraColors is imported

class ShareLinkSheet extends StatefulWidget {
  final String productName;
  final String token; // in-app token, not a URL

  const ShareLinkSheet({
    super.key,
    required this.productName,
    required this.token,
  });

  static Future<void> show(
    BuildContext context, {
    required String productName,
    required String token,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => ShareLinkSheet(productName: productName, token: token),
    );
  }

  @override
  State<ShareLinkSheet> createState() => _ShareLinkSheetState();
}

class _ShareLinkSheetState extends State<ShareLinkSheet> {
  // Using consistent brand colors
  static const _brand = KorraColors.brand; 
  static const _hair = Color(0xFFEAE6E2);

  bool _copied = false;

  String get _code => 'KORRA: ${widget.token}';
  String get _shareUrl => widget.token; // This acts as the deep link code

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _code));
    HapticFeedback.selectionClick();
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(milliseconds: 1100));
    if (mounted) setState(() => _copied = false);
  }

  Future<void> _share() async {
    final message =
        'Reserve this product now on Korra!\nProduct: ${widget.productName}\nCode: $_shareUrl\n\nOpen Korra and paste this code to view.';

    final param = ShareParams(
      text: message,
      title: 'Share Product Code', // More specific title
    );

    // Using the static method directly
    await Share.share(param.text, subject: param.title); 
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h + bottom), // Adjusted padding
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Drag Handle
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // 2. Title Row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4ED), // Light orange bg
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Iconsax.link_2, color: _brand, size: 24.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share Product',
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF101828),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      widget.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: const Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, size: 22.sp, color: Colors.grey),
              ),
            ],
          ),

          SizedBox(height: 32.h),

          // 3. Code Display Area (Tap to Copy)
          GestureDetector(
            onTap: _copy,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFEAECF0)),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.copy, size: 20.sp, color: Colors.grey.shade600),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      _code,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF101828),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _copied
                        ? Row(
                            key: const ValueKey('copied'),
                            children: [
                              Icon(Iconsax.tick_circle, color: Colors.green, size: 18.sp),
                              SizedBox(width: 4.w),
                              Text(
                                "Copied",
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            "Tap to copy",
                            key: const ValueKey('tap'),
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: Colors.grey.shade500,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24.h),

          // 4. Primary Share Button
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: FilledButton.icon(
              onPressed: _share,
              style: FilledButton.styleFrom(
                backgroundColor: _brand,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                elevation: 0,
              ),
              icon: Icon(Iconsax.share, size: 20.sp),
              label: Text(
                "Share Code",
                style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // 5. Helper Text
          Center(
            child: Text(
              'Customers enter this code in the Korra app to find your product.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: const Color(0xFF667085),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShareParams {
  final String text;
  final String title;
  ShareParams({required this.text, required this.title});
}