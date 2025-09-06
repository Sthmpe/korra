import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/vendor/payout/payout_state.dart';

class TransactionStatusOverlay extends StatefulWidget {
  final PayoutState state;
  const TransactionStatusOverlay({super.key, required this.state});

  @override
  State<TransactionStatusOverlay> createState() => _TransactionStatusOverlayState();
}

class _TransactionStatusOverlayState extends State<TransactionStatusOverlay> with TickerProviderStateMixin {
  // Controllers for each distinct animation
  late final AnimationController _progressController;
  late final AnimationController _successController;
  late final AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: const Duration(seconds: 7))..forward();
    _successController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _dotController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }
  
  @override
  void dispose() {
    _progressController.dispose();
    _successController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TransactionStatusOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the BLoC signals "Done", we trigger the success animation.
    if (widget.state.transactionStatusMessage == 'Done' && oldWidget.state.transactionStatusMessage != 'Done') {
      _progressController.stop();
      _successController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: widget.state.transactionStatusMessage == 'Done'
                    ? _buildSuccessIcon()
                    : _buildProgressIndicator(),
              ),
              SizedBox(height: 20.h),
              _buildAnimatingDots(),
              SizedBox(height: 12.h),
              Text(
                widget.state.transactionStatusMessage,
                style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w500, color: KorraColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // The main delayed progress indicator
  Widget _buildProgressIndicator() {
    return SizedBox(
      key: const ValueKey('progress'),
      width: 72.w,
      height: 72.w,
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
  
  // The expanding/shrinking success checkmark
  Widget _buildSuccessIcon() {
    return ScaleTransition(
      key: const ValueKey('success'),
      scale: Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _successController, curve: Curves.elasticOut)),
      child: Container(
        width: 72.w,
        height: 72.w,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: KorraColors.brand),
        child: Icon(Iconsax.tick_circle, color: Colors.white, size: 36.sp),
      ),
    );
  }

  // The three animating dots
  Widget _buildAnimatingDots() {
    return AnimatedBuilder(
      animation: _dotController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final dotProgress = (_dotController.value - (index * 0.2)).clamp(0.0, 1.0);
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