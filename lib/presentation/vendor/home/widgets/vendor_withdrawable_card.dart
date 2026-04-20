import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class VendorWithdrawableCard extends StatefulWidget {
  final String balanceText;       
  final String pendingText; // 🚀 ADDED THIS
  final VoidCallback? onPayout;
  final bool loading;

  const VendorWithdrawableCard({
    super.key,
    required this.balanceText,
    required this.pendingText, // 🚀 ADDED THIS
    required this.onPayout,
    required this.loading,
  });

  @override
  State<VendorWithdrawableCard> createState() => _VendorWithdrawableCardState();
}

class _VendorWithdrawableCardState extends State<VendorWithdrawableCard> {
  bool _isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Container(
        height: 200.h,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8B3A00), // Deep Burnt Orange
              Color(0xFFA54600), // Korra Brand
              Color(0xFF5C2600), // Darkest shadow
            ],
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA54600).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 1. Background Decor (Naira Sign with spacing from right edge)
            Positioned(
              right: 24.w, 
              bottom: -40.h,
              top: 10,
              child: Text(
                '₦',
                style: GoogleFonts.inter(
                  fontSize: 200.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withOpacity(0.05),
                  height: 1, 
                ),
              ),
            ),

            // 2. Content
            Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  
                  // TOP ROW: Icon + Label + Eye Toggle
                  Row(
                    children: [
                      // Stacked Coins Icon
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Iconsax.wallet_2, color: Colors.white, size: 16.sp),
                      ),
                      SizedBox(width: 8.w),
                      
                      Text(
                        'Available Balance',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      
                      // Eye Toggle
                      GestureDetector(
                        onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.all(4.r),
                          child: Icon(
                            _isBalanceVisible ? Iconsax.eye : Iconsax.eye_slash,
                            color: Colors.white.withOpacity(0.7),
                            size: 18.sp,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // MIDDLE: The Big Number
                  widget.loading
                      ? SizedBox(
                          height: 30.h,
                          width: 30.w,
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 0),
                            child: Text(
                              _isBalanceVisible ? widget.balanceText : '₦ ••••••',
                              key: ValueKey(_isBalanceVisible),
                              style: GoogleFonts.inter(
                                fontSize: 34.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: _isBalanceVisible ? -1.5 : 4.0,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ),

                  // BOTTOM: Pending Badge & Withdraw Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Action Button (Withdraw)
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        child: InkWell(
                          onTap: widget.onPayout,
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.export_1, size: 18.sp, color: const Color(0xFFA54600)), 
                                SizedBox(width: 6.w),
                                Text(
                                  'Withdraw',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFA54600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Pending Settlement Badge
                      Padding(
                        padding: EdgeInsets.only(bottom: 2.h, left: 4.w),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center, // 🚀 Perfectly centers the divider with the text
                          children: [
                            // Elegant Thin Divider
                            Container(
                              height: 34.h,
                              width: 1.5.w, // 🚀 Thinner line looks much more premium
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                            ),
                            SizedBox(width: 12.w), // 🚀 Slightly more breathing room
                            
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Label Row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.timer, 
                                      size: 13.sp, 
                                      color: Colors.white.withOpacity(0.85)
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'PENDING SETTLEMENT', // 🚀 Uppercase for micro-labels looks extremely polished
                                      style: GoogleFonts.inter(
                                        fontSize: 8.sp, 
                                        letterSpacing: 0.8, // 🚀 Spacing it out adds elegance
                                        color: Colors.white.withOpacity(0.85), 
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                SizedBox(height: 2.h),
                                
                                // Amount Row
                                widget.loading 
                                ? SizedBox(
                                    height: 18.h, 
                                    width: 18.w, 
                                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  )
                                : AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200), // Added a slight crossfade
                                    child: Text(
                                      _isBalanceVisible ? widget.pendingText : '₦ ••••',
                                      key: ValueKey(_isBalanceVisible),
                                      style: GoogleFonts.inter(
                                        fontSize: 16.sp, // 🚀 Slightly bumped up to contrast with the tiny label
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white.withOpacity(0.9),
                                        letterSpacing: _isBalanceVisible ? -0.5 : 2.0,
                                        fontFeatures: const [FontFeature.tabularFigures()],
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}