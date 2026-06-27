import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PlanSkeletonCard extends StatefulWidget {
  const PlanSkeletonCard({super.key});

  @override
  State<PlanSkeletonCard> createState() => _PlanSkeletonCardState();
}

class _PlanSkeletonCardState extends State<PlanSkeletonCard>
    with SingleTickerProviderStateMixin {
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (b) => LinearGradient(
            colors: [Colors.grey[100]!, Colors.white, Colors.grey[100]!],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment(-1.0 + (_controller.value * 3), 0.0),
            end: Alignment(1.0 + (_controller.value * 3), 0.0),
          ).createShader(b),
          child: Container(
            height: 110.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
          ),
        ),
      ),
    );
  }
}
