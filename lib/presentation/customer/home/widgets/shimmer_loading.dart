import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PlanCarouselLoading extends StatelessWidget {
  const PlanCarouselLoading({super.key});

  @override
  Widget build(BuildContext context) {
    // FIX 1: Increased height to 320.h (Matches real carousel size)
    return SizedBox(
      height: 320.h, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 2, 
        padding: EdgeInsets.only(left: 20.w),
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: const _ShimmerCard(),
            ),
          );
        },
      ),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + (_controller.value * 3), 0.0),
              end: Alignment(1.0 + (_controller.value * 3), 0.0),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias, // Ensures the Expanded image respects corners
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FIX 2: Use EXPANDED here. 
            // This prevents overflow by letting the image shrink if needed.
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black, 
                ),
              ),
            ),
            
            // Content Placeholders (Fixed Heights)
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Line
                  Container(height: 16.h, width: 140.w, color: Colors.black),
                  SizedBox(height: 12.h),
                  
                  // Cadence + Button Line
                  Row(
                    children: [
                      Container(
                        height: 24.h, 
                        width: 80.w, 
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.black)
                      ),
                      const Spacer(),
                      Container(
                        height: 36.h, 
                        width: 60.w, 
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.black)
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  
                  // Stats Strip
                  Container(
                    height: 40.h, 
                    width: double.infinity, 
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.black)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}