import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/vendor/payout/payout_bloc.dart';
import '../../../../logic/bloc/vendor/payout/payout_state.dart';

class TransactionStatusOverlay extends StatefulWidget {
  const TransactionStatusOverlay({super.key});

  @override
  State<TransactionStatusOverlay> createState() => _TransactionStatusOverlayState();
}

class _TransactionStatusOverlayState extends State<TransactionStatusOverlay> with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _successController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: const Duration(seconds: 7))..forward();
    _successController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  }
  
  @override
  void dispose() {
    _progressController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This overlay listens to the PayoutBloc to get status updates.
    return BlocConsumer<PayoutBloc, PayoutState>(
      listener: (context, state) {
        // When the BLoC signals "Done", we trigger the success animation.
        if (state.transactionStatusMessage == 'Done') {
          _progressController.stop();
          _successController.forward();
        }
      },
      builder: (context, state) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                margin: EdgeInsets.symmetric(horizontal: 40.w),
                width: 320.w,
                height: 155.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 100),
                      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                      child: state.transactionStatusMessage == 'Done'
                          ? _buildSuccessIcon()
                          : _buildProgressIndicator(),
                    ),
                    SizedBox(height: 20.h),
                    _AnimatingDots(),
                    SizedBox(height: 12.h),
                    Text(
                      state.transactionStatusMessage,
                      style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w800, color: KorraColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return SizedBox(
      key: const ValueKey('progress'),
      width: 64.w,
      height: 64.w,
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, child) {
          return CircularProgressIndicator(
            value: _progressController.value,
            strokeWidth: 5,
            color: KorraColors.brand,
            backgroundColor: KorraColors.brand.withOpacity(0.15),
            strokeCap: StrokeCap.round,
          );
        },
      ),
    );
  }
  
  Widget _buildSuccessIcon() {
    return ScaleTransition(
      key: const ValueKey('success'),
      scale: Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _successController, curve: Curves.elasticOut)),
      child: Container(
        width: 64.w,
        height: 64.w,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: KorraColors.brand),
        child: Icon(Iconsax.tick_circle, color: Colors.white, size: 64.sp),
      ),
    );
  }
}

// A dedicated widget for the three animating dots.
class _AnimatingDots extends StatefulWidget {
  @override
  __AnimatingDotsState createState() => __AnimatingDotsState();
}

class __AnimatingDotsState extends State<_AnimatingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            // This creates the color-chasing effect.
            final dotProgress = (_controller.value - (index * 0.2)).clamp(0.0, 1.0);
            final color = Color.lerp(KorraColors.border, KorraColors.brand, dotProgress)!;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: CircleAvatar(radius: 4.r, backgroundColor: color),
            );
          }),
        );
      },
    );
  }
}