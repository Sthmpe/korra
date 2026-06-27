import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PlanImageCarousel extends StatefulWidget {
  final List<dynamic> images;

  const PlanImageCarousel({
    super.key,
    required this.images,
  });

  @override
  State<PlanImageCarousel> createState() => _PlanImageCarouselState();
}

class _PlanImageCarouselState extends State<PlanImageCarousel> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return SizedBox(height: 200.h);
    
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 280.h,
          width: double.infinity,
          child: PageView.builder(
            onPageChanged: (index) =>
                setState(() => _currentImageIndex = index),
            itemCount: widget.images.length,
            itemBuilder: (context, index) => CachedNetworkImage(
              imageUrl: widget.images[index],
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[100],
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 16.h,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.images
                  .asMap()
                  .entries
                  .map(
                    (entry) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentImageIndex == entry.key ? 16.0.w : 6.0.w,
                      height: 4.0.h,
                      margin: const EdgeInsets.symmetric(horizontal: 3.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: _currentImageIndex == entry.key
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
