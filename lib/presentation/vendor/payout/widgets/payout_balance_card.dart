import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/utils/currency_formatters.dart';
import '../../../../logic/bloc/vendor/payout/payout_state.dart';
import '../../../../logic/services/balance_visibility.dart';

class PayoutBalanceCard extends StatelessWidget {
  final PayoutState state;
  const PayoutBalanceCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    // Access the balance directly from your state
    final balance = state.withdrawableBalance;
    // Same app-wide switch as everywhere else money shows
    BalanceVisibility.ensureLoaded();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        // Premium Gradient: Deep Burnt Orange -> Brand Orange -> Dark Shadow
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B3A00), 
            Color(0xFFA54600), 
            Color(0xFF5C2600),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA54600).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 1. Background Watermark (Naira Sign)
          Positioned(
            right: -10.w,
            bottom: -30.h,
            child: Text(
              '₦',
              style: GoogleFonts.inter(
                fontSize: 160.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white.withOpacity(0.05),
                height: 1, 
              ),
            ),
          ),

          // 2. Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Iconsax.wallet_3, color: Colors.white, size: 16.sp),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Available for Payout',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12.h),

              // Balance Text + eye toggle (hide/show, synced app-wide)
              ValueListenableBuilder<bool>(
                valueListenable: BalanceVisibility.visible,
                builder: (context, isVisible, _) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          isVisible ? '₦${formatToCurrency(balance)}' : '₦ ••••••',
                          style: GoogleFonts.inter(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: isVisible ? -1.0 : 3.0,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: BalanceVisibility.toggle,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.all(6.r),
                          child: Icon(
                            isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: Colors.white.withOpacity(0.85),
                            size: 22.sp,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}