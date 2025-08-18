import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class KorraNetImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? radius;
  final Color fallbackTint;

  const KorraNetImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius,
    this.fallbackTint = const Color(0xFFF3EFEA),
  });

  @override
  Widget build(BuildContext context) {
    final child = (url == null || url!.isEmpty)
        ? _fallback()
        : Image.network(
            url!,
            width: width,
            height: height,
            fit: fit,
            filterQuality: FilterQuality.medium,
            loadingBuilder: (c, w, p) => _fallback(),
            errorBuilder: (c, e, s) => _fallback(),
          );

    return radius == null
        ? child
        : ClipRRect(borderRadius: radius!, child: child);
  }

  Widget _fallback() => Container(
        width: width, height: height,
        color: fallbackTint,
        alignment: Alignment.center,
        child: Container(
          width: 20.w, height: 20.w,
          decoration: BoxDecoration(
            color: const Color(0xFFEAE6E2),
            borderRadius: BorderRadius.circular(6.r),
          ),
        ),
      );
}
