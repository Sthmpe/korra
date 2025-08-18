import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class KorraThumb extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText; // e.g., vendor initial
  final double size;         // square
  final double radius;

  const KorraThumb({
    super.key,
    required this.imageUrl,
    required this.fallbackText,
    required this.size,
    this.radius = 12,
  });

  static const _brand = Color(0xFFA54600);

  @override
  Widget build(BuildContext context) {
    final r = Radius.circular(radius.r);

    Widget fallback() => Container(
      width: size.w, height: size.w,
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFEA),
        borderRadius: BorderRadius.only(topLeft: r, topRight: r, bottomLeft: r, bottomRight: r),
        border: Border.all(color: const Color(0xFFEAE6E2)),
      ),
      alignment: Alignment.center,
      child: Text(
        (fallbackText.isNotEmpty ? fallbackText[0] : '?').toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: (size * 0.42).sp,
          fontWeight: FontWeight.w800,
          color: _brand,
        ),
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) return fallback();

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius.r),
      child: Image.network(
        imageUrl!,
        width: size.w,
        height: size.w,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        // graceful placeholder
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return fallback();
        },
        // clean fallback, no error text
        errorBuilder: (context, error, stack) => fallback(),
      ),
    );
  }
}
