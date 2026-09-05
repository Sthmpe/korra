// lib/presentation/customer/storefront/widgets/storefront_lazy_image.dart

import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';

/// Lazy-loading network image for the storefront.
///
/// * Shows a soft blurred placeholder while bytes stream in.
/// * Renders a thin linear progress line at the bottom of the frame
///   reflecting real download progress.
/// * Downsizes the decoded bitmap via [memCacheWidth] to keep grid
///   scrolling memory-light.
/// * Falls back to a plain [Image.network] if the caching pipeline fails
///   (some oversized/CORS-restricted images decode fine over the plain
///   network path — this keeps grid cards consistent with the details sheet).
class StorefrontLazyImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final int memCacheWidth;

  const StorefrontLazyImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.memCacheWidth = 600,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const _ImageFallbackIcon();

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      memCacheWidth: memCacheWidth,
      fadeInDuration: const Duration(milliseconds: 250),
      progressIndicatorBuilder: (context, _, progress) =>
          _BlurLoadingPlaceholder(progress: progress.progress),
      errorWidget: (_, __, ___) => Image.network(
        url,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          final total = progress.expectedTotalBytes;
          return _BlurLoadingPlaceholder(
            progress: total != null ? progress.cumulativeBytesLoaded / total : null,
          );
        },
        errorBuilder: (_, __, ___) => const _ImageFallbackIcon(),
      ),
    );
  }
}

/// Frosted blur placeholder with a bottom loading line.
class _BlurLoadingPlaceholder extends StatelessWidget {
  final double? progress;

  const _BlurLoadingPlaceholder({this.progress});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF4F5F7), Color(0xFFFAF3ED), Color(0xFFEFF1F4)],
              ),
            ),
          ),
        ),
        Center(
          child: Icon(Iconsax.gallery, size: 22.sp, color: const Color(0xFFD0D5DD)),
        ),
        // Thin download progress line pinned to the bottom of the image frame
        Align(
          alignment: Alignment.bottomCenter,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 2.5,
            color: KorraColors.brand,
            backgroundColor: Colors.transparent,
          ),
        ),
      ],
    );
  }
}

class _ImageFallbackIcon extends StatelessWidget {
  const _ImageFallbackIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F5F7),
      alignment: Alignment.center,
      child: Icon(Iconsax.image, size: 28.sp, color: Colors.grey),
    );
  }
}
