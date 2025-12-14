import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:korra/config/constants/colors.dart'; // Your brand colors

class KorraSpinner extends StatefulWidget {
  final double size;
  final Color color;

  const KorraSpinner({
    super.key, 
    this.size = 50.0, 
    this.color = KorraColors.brand
  });

  @override
  State<KorraSpinner> createState() => _KorraSpinnerState();
}

class _KorraSpinnerState extends State<KorraSpinner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size.w,
      height: widget.size.h,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return Transform.rotate(
            angle: _controller.value * 2 * pi,
            child: CustomPaint(
              painter: _SpinnerPainter(color: widget.color),
            ),
          );
        },
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  final Color color;
  _SpinnerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round; // Rounded ends for that "Opay" look

    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw the "Track" (Faint circle background)
    paint.color = color.withOpacity(0.2);
    canvas.drawArc(rect, 0, 2 * pi, false, paint);

    // Draw the "Active Spinner" (The moving part)
    // We draw an arc that is about 75% of the circle
    paint.color = color;
    canvas.drawArc(rect, -pi / 2, 1.5 * pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}