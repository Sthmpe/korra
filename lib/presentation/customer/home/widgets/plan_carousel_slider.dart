import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../data/models/customer/plan.dart'; // adjust if your path differs
import 'plan_card_compact.dart';

class PlanCarouselSlider extends StatefulWidget {
  final List<Plan> plans;
  const PlanCarouselSlider({super.key, required this.plans});

  @override
  State<PlanCarouselSlider> createState() => _PlanCarouselSliderState();
}

class _PlanCarouselSliderState extends State<PlanCarouselSlider> {
  final CarouselSliderController _controller = CarouselSliderController();

  static const double _viewport = 0.7;
  static const double _aspect = 4 / 3; // product-friendly

  @override
  Widget build(BuildContext context) {
    if (widget.plans.isEmpty) return const SizedBox.shrink();

    final screenW = MediaQuery.sizeOf(context).width;
    final itemW = screenW * _viewport;
    final imageH = itemW / _aspect; // keeps 4:3 image
    final metaH  = 136.h;           // was ~120.h; gives comfy room for new strip
    final totalH = imageH + metaH + 24.h;

    return SizedBox(
      height: totalH,
      child: CarouselSlider.builder(
        carouselController: _controller,
        options: CarouselOptions(
          viewportFraction: _viewport,
          height: totalH,
          autoPlay: true,
          pauseAutoPlayOnTouch: true,
          autoPlayInterval: const Duration(seconds: 3),
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          autoPlayCurve: Curves.easeInOut,
          enableInfiniteScroll: widget.plans.length > 1,
          enlargeCenterPage: true,
          enlargeFactor: 0.2,
          padEnds: false,
          scrollPhysics: const BouncingScrollPhysics(),
        ),
        itemCount: widget.plans.length,
        itemBuilder: (context, i, realIndex) {
          final p = widget.plans[i];
          return Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? 16.w : 8.w,
              right: i == widget.plans.length - 1 ? 16.w : 8.w,
            ),
            child: PlanCardCompact(
              // image + title
              imageUrl: p.imageUrl,
              title: p.title,
              vendor: p.vendor,

              // payments summary (map your model here)
              progressPercent: p.progress,                    // 0..100
              amountPaidText: p.amountPaidText ?? '₦75,500', // placeholders ok
              amountRemainText: p.amountRemainText ?? '₦224,500',
              cadenceText: p.cadenceText ?? 'Weekly plan',   // Daily / Weekly / Monthly
              nextDueText: p.nextDue,                         // “Due Fri”
              nextAmountText: p.nextAmountText ?? '₦12,500',

              aspectRatio: _aspect,
              onPay: () {},
              onDetails: () {},
            ),
          );
        },
      ),
    );
  }
}
