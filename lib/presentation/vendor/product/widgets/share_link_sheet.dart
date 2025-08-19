import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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
  static const _brand = Color(0xFFA54600);
  static const _hair  = Color(0xFFEAE6E2);

  bool _copied = false;

  String get _code => 'KORRA:${widget.token}';

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _code));
    HapticFeedback.selectionClick();
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(milliseconds: 1100));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // drag handle
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: _hair,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 12.h),

          // title row
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4ECE7),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                alignment: Alignment.center,
                child: Icon(MdiIcons.linkVariant, color: _brand, size: 20.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Share reserve link',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              // optional close (kept subtle)
              IconButton(
                splashRadius: 22.r,
                icon: Icon(MdiIcons.close, size: 20.sp, color: const Color(0xFF1B1B1B)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          SizedBox(height: 6.h),
          Text(
            widget.productName,
            style: GoogleFonts.inter(fontSize: 13.5.sp, fontWeight: FontWeight.w700,color: const Color(0xFF5E5E5E)),
          ),

          // token field (tap anywhere to copy)
          SizedBox(height: 12.h),
          InkWell(
            borderRadius: BorderRadius.circular(12.r),
            onTap: _copy,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F3EF),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: _hair),
              ),
              child: Row(
                children: [
                  Icon(MdiIcons.link, color: _brand, size: 18.sp),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      _code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B1B1B),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 140),
                    transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
                    child: _copied
                        ? Row(
                            key: const ValueKey('copied'),
                            children: [
                              Icon(MdiIcons.clipboardCheckOutline,
                                  size: 18.sp, color: const Color(0xFF1B5E20)),
                              SizedBox(width: 6.w),
                              Text('Copied',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1B5E20),
                                  )),
                            ],
                          )
                        : IconButton(
                            key: const ValueKey('copy'),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: Icon(MdiIcons.contentCopy,
                                size: 18.sp, color: const Color(0xFF1B1B1B)),
                            onPressed: _copy,
                          ),
                  ),
                ],
              ),
            ),
          ),

          // primary actions
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: FilledButton(
              onPressed: _copy,
              style: FilledButton.styleFrom(
                backgroundColor: _brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 0,
              ),
              child: Text(
                _copied ? 'Copied' : 'Copy code',
                style: GoogleFonts.inter(
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          SizedBox(height: 10.h),

          // secondary: regenerate
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: OutlinedButton(
              onPressed: () {
                // TODO: generate new token flow
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _hair),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(
                'Generate new link',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: _brand,
                ),
              ),
            ),
          ),

          SizedBox(height: 8.h),
          Center(
            child: Text(
              'Customers paste this in korra to open the product.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: const Color(0xFF8B8B8B),
              ),
            ),
          ),
          SizedBox(height: 6.h),
        ],
      ),
    );
  }
}
