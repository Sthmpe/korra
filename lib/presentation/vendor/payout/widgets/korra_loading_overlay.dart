import 'dart:ui'; // Needed for BackdropFilter (Blur)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/widgets/korra_spinner.dart';

class KorraLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message; // Optional text like "Processing..."

  const KorraLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. The Content (Your Payout Screen)
        child,

        if (isLoading)
          Positioned.fill(
            child: ClipRect(        // VERY IMPORTANT — enables BackdropFilter!
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0.1, sigmaY: 0.1),
                child: Center(
                  heightFactor: 0.1,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const KorraSpinner(size: 40),
                          if (message != null && message!.isNotEmpty) ...[
                            SizedBox(height: 16.h),
                            Text(
                              message!,
                              style: TextStyle(
                                fontSize: 14.sp, 
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                decoration: TextDecoration.none, // Fixes weird yellow underline
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
              ),
            ),
          ),
      
      ],
    );
  }
}