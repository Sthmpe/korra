import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/constants/colors.dart';

class ProductDetailsGallery extends StatefulWidget {
  final List<String> images;

  const ProductDetailsGallery({
    super.key,
    required this.images,
  });

  @override
  State<ProductDetailsGallery> createState() => _ProductDetailsGalleryState();
}

class _ProductDetailsGalleryState extends State<ProductDetailsGallery> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: 250.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(MdiIcons.imageOutline, size: 48.sp, color: Colors.grey.shade400),
            SizedBox(height: 8.h),
            Text("No images", style: GoogleFonts.inter(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 300.h,
            viewportFraction: 1.0,
            enableInfiniteScroll: widget.images.length > 1,
            autoPlay: false,
            onPageChanged: (index, _) => setState(() => _currentImageIndex = index),
          ),
          items: widget.images.map((url) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: CachedNetworkImage(
                imageUrl: url,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey.shade100),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.error),
                ),
              ),
            );
          }).toList(),
        ),
        if (widget.images.length > 1) ...[
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.images.asMap().entries.map((entry) {
              final isActive = _currentImageIndex == entry.key;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 24.w : 6.w,
                height: 6.w,
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                decoration: BoxDecoration(
                  color: isActive ? KorraColors.brand : const Color(0xFFEAECF0),
                  borderRadius: BorderRadius.circular(100.r),
                ),
              );
            }).toList(),
          ),
        ]
      ],
    );
  }
}
