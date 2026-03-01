import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

Future<void> _showSheet(
  BuildContext context, {
  required String title,
  required List<_Section> sections,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // Handle visuals inside
    builder: (_) => _LegalSheet(title: title, sections: sections),
  );
}

class _LegalSheet extends StatelessWidget {
  final String title;
  final List<_Section> sections;
  const _LegalSheet({required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      margin: EdgeInsets.only(top: 40.h), // Prevent hitting very top
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min, // Hug content or expand
          children: [
            // --- HEADER (Fixed) ---
            Container(
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111111),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.close_circle,
                        size: 20.sp,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- CONTENT (Scrollable) ---
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
                itemCount: sections.length,
                separatorBuilder: (_, __) => SizedBox(height: 24.h),
                itemBuilder: (_, i) => sections[i],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String heading;
  final List<String> items;
  const _Section({required this.heading, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111111), // Almost black
          ),
        ),
        SizedBox(height: 8.h),
        ...items.map(
          (t) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Styled Bullet Point
                Container(
                  margin: EdgeInsets.only(top: 7.h, right: 10.w),
                  width: 5.r,
                  height: 5.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9CA3AF), // Muted grey bullet
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    t,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      height: 1.5, // Readable line height
                      color: const Color(
                        0xFF4B5563,
                      ), // Grey-600 (Standard reading grey)
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
