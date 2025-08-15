import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class LinkInput extends StatefulWidget {
  final void Function(String value) onSubmit;
  final VoidCallback onScan;
  const LinkInput({super.key, required this.onSubmit, required this.onScan});

  @override
  State<LinkInput> createState() => _LinkInputState();
}

class _LinkInputState extends State<LinkInput> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: GoogleFonts.inter(
                fontSize: 13.5.sp,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Paste reserve link or code',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13.5.sp,
                  color: const Color(0xFF8B8B8B),
                ),
                prefixIcon: Icon(Icons.link_outlined, size: 18.sp),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Color(0xFFEAE6E2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Color(0xFFEAE6E2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Color(0xFFA54600)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 12.h,
                ),
              ),
              onSubmitted: widget.onSubmit,
            ),
          ),
          SizedBox(width: 4.w),
          IconButton(
            splashRadius: 30.r,
            color: const Color(0xFFA54600).withOpacity(0.055),
            onPressed: widget.onScan,
            icon: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: const Color(0xFFA54600).withOpacity(0.055),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.qr_code_scanner, size: 24.sp, color: Color(0xFFA54600),)),
          ),
        ],
      ),
    );
  }
}
