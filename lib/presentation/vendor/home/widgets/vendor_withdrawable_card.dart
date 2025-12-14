import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';

class VendorWithdrawableCard extends StatefulWidget {
  final String balanceText;       
  final String? totalBalanceText; 
  final VoidCallback? onPayout;
  final bool loading;

  const VendorWithdrawableCard({
    super.key,
    required this.balanceText,
    this.totalBalanceText,
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
              right: 24.w, // Added positive spacing from the right edge
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
                  
                  // TOP ROW: Icon + Label + Eye + Total Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: Icon + Label + Toggle
                      Row(
                        children: [
                          // Stacked Coins Icon
                          Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Iconsax.coin, color: Colors.white, size: 16.sp),
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

                      // Right: Total Ledger Badge (With Overflow Protection)
                      if (widget.totalBalanceText != null) ...[
                        SizedBox(width: 12.w),
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                children: [
                                  Text(
                                    'Net Worth: ',
                                    style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white70),
                                  ),
                                  Text(
                                    _isBalanceVisible ? widget.totalBalanceText! : '••••',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.sp, 
                                      fontWeight: FontWeight.w700, 
                                      color: Colors.white
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ]
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

                  // BOTTOM: Action Button (Withdraw)
                  Row(
                    children: [
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        child: InkWell(
                          onTap: widget.onPayout,
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.export_1, size: 18.sp, color: const Color(0xFFA54600)), 
                                SizedBox(width: 8.w),
                                Text(
                                  'Withdraw Funds',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFA54600),
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