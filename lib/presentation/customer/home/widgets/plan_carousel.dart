import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../data/models/plan.dart';
import 'plan_card.dart';
import 'plan_media_shape.dart';

class PlanCarousel extends StatefulWidget {
  final List<Plan> plans;
  /// Optional: shape per item. If null, all items use wide16x9.
  final List<PlanMediaShape>? shapes;

  const PlanCarousel({super.key, required this.plans, this.shapes});

  @override
  State<PlanCarousel> createState() => _PlanCarouselState();
}

class _PlanCarouselState extends State<PlanCarousel> {
  late final PageController _ctl;

  static const double _viewport = 0.86; // consistent width for smooth paging

  @override
  void initState() {
    super.initState();
    _ctl = PageController(viewportFraction: _viewport);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shapes = widget.shapes ??
        List.generate(widget.plans.length, (_) => PlanMediaShape.wide16x9);

    // compute a safe height (image + text/buttons) based on widest page
    final screenW = MediaQuery.sizeOf(context).width;
    final pageW = screenW * _viewport;
    final mediaHeights = shapes.map((s) => pageW / s.ratio).toList(); // height = width / ratio
    final mediaMaxH = mediaHeights.fold<double>(0, math.max);
    final metaH = 110.h; // title + due row + pay + details + paddings
    final totalH = mediaMaxH + metaH;

    return SizedBox(
      height: totalH,
      child: PageView.builder(
        controller: _ctl,
        itemCount: widget.plans.length,
        padEnds: false,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _ctl,
            builder: (context, child) {
              double delta = 0;
              if (_ctl.position.hasPixels && _ctl.position.haveDimensions) {
                delta = (_ctl.page ?? _ctl.initialPage.toDouble()) - index;
              }
              final scale = (1 - (delta.abs() * 0.06)).clamp(0.94, 1.0);
              final opacity = (1 - (delta.abs() * 0.25)).clamp(0.75, 1.0);
              return Transform.scale(scale: scale, child: Opacity(opacity: opacity, child: child));
            },
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 16.w : 8.w,
                right: index == widget.plans.length - 1 ? 16.w : 8.w,
              ),
              child: SizedBox(
                width: pageW,
                child: PlanCard(
                  imageUrl: widget.plans[index].imageUrl,
                  title: widget.plans[index].title,
                  vendor: widget.plans[index].vendor,
                  progressPercent: widget.plans[index].progress,
                  nextDue: widget.plans[index].nextDue,
                  aspectRatio: shapes[index].ratio,
                  onPay: () {},
                  onDetails: () {},
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
