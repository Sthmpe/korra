import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class WalletCard extends StatelessWidget {
  final String balanceText;
  final String methodMasked;      // e.g. "•••• 4242" or "—"
  final VoidCallback onTopUp;
  final VoidCallback onManageMethod;

  const WalletCard({
    super.key,
    required this.balanceText,
    required this.methodMasked,
    required this.onTopUp,
    required this.onManageMethod,
  });

  static const _brand = Color(0xFFA54600);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onManageMethod,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: _brand.withOpacity(0.055),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFEAE6E2).withOpacity(0.1), width: 1),
            ),
            child: Row(
              children: [
                // left brand tile
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4ECE7),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: const Icon(Iconsax.card, color: _brand),
                ),

                SizedBox(width: 12.w),

                // center text block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Wallet balance',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5E5E5E),
                          )),
                      SizedBox(height: 2.h),
                      Text(
                        balanceText,
                        style: GoogleFonts.inter(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1B1B1B),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            methodMasked.trim().isEmpty || methodMasked == '—'
                                ? 'Add payment method'
                                : 'Default  $methodMasked',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF5E5E5E),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(Icons.chevron_right, size: 18.sp, color: const Color(0xFF5E5E5E)),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 12.w),

                // right CTA
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 96.w),
                  child: SizedBox(
                    height: 44.h,
                    child: FilledButton(
                      onPressed: onTopUp,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        backgroundColor: _brand,
                      ),
                      child: Text(
                        'Top up',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
