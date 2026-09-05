import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/services/balance_visibility.dart';

class CustomerWalletCard extends StatefulWidget {
  final String balanceText;
  final VoidCallback? onTopUp;
  final bool loading;

  const CustomerWalletCard({
    super.key,
    required this.balanceText,
    required this.onTopUp,
    required this.loading,
  });

  @override
  State<CustomerWalletCard> createState() => _CustomerWalletCardState();
}

class _CustomerWalletCardState extends State<CustomerWalletCard> {
  // Shared app-wide state: hiding here also hides the Bank Details balance.
  bool get _isBalanceVisible => BalanceVisibility.visible.value;

  @override
  void initState() {
    super.initState();
    BalanceVisibility.ensureLoaded();
    BalanceVisibility.visible.addListener(_onVisibilityChanged);
  }

  @override
  void dispose() {
    BalanceVisibility.visible.removeListener(_onVisibilityChanged);
    super.dispose();
  }

  void _onVisibilityChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Container(
        height: 180.h,
        width: double.infinity,
        decoration: BoxDecoration(
          // Premium Gradient
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFA54600), // Brand Color
              Color(0xFF7A3300), // Darker shade for depth
            ],
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA54600).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 1. Background Abstract Decoration
            Positioned(
              right: -30.w,
              top: -30.h,
              child: Icon(
                Iconsax.wallet_1,
                size: 200.sp,
                color: Colors.white.withOpacity(0.05),
              ),
            ),

            // 2. Content
            Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Label + Hide Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Iconsax.flash_1,
                              color: Colors.white,
                              size: 14.sp,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Available Balance',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),

                      // The Visibility Toggle
                      GestureDetector(
                        onTap: BalanceVisibility.toggle,
                        child: Container(
                          padding: EdgeInsets.all(6.r),
                          color: Colors.transparent, // Hit target area
                          child: Icon(
                            _isBalanceVisible ? Iconsax.eye : Iconsax.eye_slash,
                            color: Colors.white.withOpacity(0.6),
                            size: 20.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Middle: The Big Number
                  widget.loading
                      ? SizedBox(
                          height: 35.h,
                          width: 35.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3.0,
                          ),
                        )
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
                          child: Text(
                            _isBalanceVisible
                                ? widget.balanceText
                                : '₦ ••••', // Use Bullets (Alt+7 or Copy this)
                            key: ValueKey<bool>(_isBalanceVisible),
                            style: GoogleFonts.inter(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              // Increase spacing for bullets so they don't bunch up
                              letterSpacing: _isBalanceVisible ? -1.0 : 4.0,
                            ),
                          ),
                        ),
                  // Bottom: Action Button
                  Row(
                    children: [
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        child: InkWell(
                          onTap: widget.onTopUp,
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.add,
                                  size: 18.sp,
                                  color: KorraColors.brand,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'Fund Wallet',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: KorraColors.brand,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
