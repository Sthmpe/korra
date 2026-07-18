import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:korra/data/repository/customer/customer_repository.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../data/models/customer/plans.dart';
import 'plan_card_compact.dart';

class PlanCarouselSlider extends StatefulWidget {
  final List<Plan> plans;
  
  const PlanCarouselSlider({
    super.key, 
    required this.plans, 
  });

  @override
  State<PlanCarouselSlider> createState() => _PlanCarouselSliderState();
}

class _PlanCarouselSliderState extends State<PlanCarouselSlider> {
  final CarouselSliderController _controller = CarouselSliderController();
  
  // 1. State to track active slide
  int _current = 0; 

  static const double _viewport = 0.75; // Slightly wider for better focus
  // Wider aspect = shorter image, so wallet + code field + this carousel
  // all fit one home screen (David, 10 July 2026).
  static const double _aspect = 16 / 9;

  @override
  Widget build(BuildContext context) {
    if (widget.plans.isEmpty) return const SizedBox.shrink();

    final screenW = MediaQuery.sizeOf(context).width;
    final itemW = screenW * _viewport;
    final imageH = itemW / _aspect; 
    final metaH  = 136.h;
    final totalH = imageH + metaH + 24.h;

    // ✅ HELPER 1: Paid Amount (Standard 2DP Display)
    // Prevents long decimals like 5000.333333
    double _clipAmount(double amount) {
      return double.parse(amount.toStringAsFixed(2));
    }

    // ✅ HELPER 2: Remaining Balance (Always Round UP)
    // Ensures you don't lose 0.01 due to rounding down.
    // 33.333 -> 33.34
    double _roundUpAmount(double amount) {
      if (amount == 0) return 0;
      return (amount * 100).ceil() / 100;
    }

    return Column(
      children: [
        // 2. The Slider
        SizedBox(
          height: totalH,
          child: CarouselSlider.builder(
            carouselController: _controller,
            options: CarouselOptions(
              viewportFraction: _viewport,
              height: totalH,
              autoPlay: false, // User usually wants to read details, auto-play can be annoying here
              enableInfiniteScroll:  false,//widget.plans.length > 1,
              enlargeCenterPage: true,
              enlargeFactor: 0.2,
              padEnds: false,
              scrollPhysics: const BouncingScrollPhysics(),
              // 3. Update State on Change
              onPageChanged: (index, reason) {
                setState(() {
                  _current = index;
                });
              },
            ),
            itemCount: widget.plans.length,
            itemBuilder: (context, i, realIndex) {
              final p = widget.plans[i];
              
              final String dueText = "Next milestone ${p.nextDueDate.day}/${p.nextDueDate.month}";


              return Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 16.w : 8.w,
                  right: i == widget.plans.length - 1 ? 16.w : 8.w,
                ),
                child: PlanCardCompact(
                  imageUrls: p.imageUrls.isNotEmpty 
                      ? p.imageUrls 
                      : ['https://placehold.co/400x300.png?text=No+Image'], 
                  
                  title: p.title,
                  storeName: p.storeName,
                  progressPercent: p.progressPercent.toInt(), 
                  amountPaid: _clipAmount(p.amountPaid),
                  amountRemain: _roundUpAmount(p.amountRemaining),
                  cadenceText: p.cadenceType != null 
                      ? "${p.cadenceType![0].toUpperCase()}${p.cadenceType!.substring(1)} Plan"
                      : "Flexible Plan",
                  nextDueText: dueText,
                  nextAmount: p.nextAmount,
                  aspectRatio: _aspect,
                  
                  onPay: () {
                    Get.toNamed(
                      Routes.customerPayPlan, 
                      arguments: {'plan': p}
                    );
                  },
                  onDetails: () {
                    Get.toNamed(
                      Routes.customerPlanDetails, 
                      arguments: {'plan': p}
                    );
                  },
                ),
              );
            },
          ),
        ),

        SizedBox(height: 12.h),

        // 4. The Indicator Row (Only if more than 1 plan)
        if (widget.plans.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.plans.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => _controller.animateToPage(entry.key),
                child: Container(
                  width: _current == entry.key ? 18.w : 6.w, // Active expands
                  height: 6.w,
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: _current == entry.key 
                        ? const Color(0xFFA54600) // Brand Color
                        : Colors.grey.shade300,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}