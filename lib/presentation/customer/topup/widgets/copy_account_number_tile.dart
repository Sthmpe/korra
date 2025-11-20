import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../config/constants/colors.dart';

class CopyAccountNumberTile extends StatefulWidget {
  final String accountNumber;

  const CopyAccountNumberTile({super.key, required this.accountNumber});

  @override
  State<CopyAccountNumberTile> createState() => _CopyAccountNumberTileState();
}

class _CopyAccountNumberTileState extends State<CopyAccountNumberTile> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.accountNumber));
    setState(() => _copied = true);

    // Reset to normal after 1.5s
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color hair = const Color(0xFFE0E0E0);

    return GestureDetector(
      //borderRadius: BorderRadius.circular(12.r),
      onTap: _copy,
      child: Container(
        height: 58.h,
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F3EF),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: hair),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Account Number",
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: KorraColors.textMuted,
                    ),
                  ),
                  Text(
                    widget.accountNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                      color: KorraColors.text,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
              child: _copied
                  ? Row(
                      key: const ValueKey('copied'),
                      children: [
                        Icon(
                          MdiIcons.clipboardCheckOutline,
                          size: 18.sp,
                          color: const Color(0xFF1B5E20),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Copied',
                          style: GoogleFonts.inter(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                    width: 24.w,
                    height: 24.h,
                    child: IconButton(
                        key: const ValueKey('copy'),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          MdiIcons.contentCopy,
                          size: 18.sp,
                          color: const Color(0xFF1B1B1B),
                        ),
                        onPressed: _copy,
                      ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
