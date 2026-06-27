import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class PenaltyExplainerSheet extends StatelessWidget {
  final String policyString; // Kept for interface compatibility, but logic is now Universal.

  const PenaltyExplainerSheet({
    super.key,
    required this.policyString,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Logic Simplified: No more "50% Penalty" checks. It's always Store Balance.
    
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- HEADER ---
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: const BoxDecoration(
                  // ✅ Changed from Red (Error) to Brand Blue (Safe/Info)
                  color: Color(0xFFEFF6FF), 
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.shield_tick, // ✅ Changed from "Cross" to "Tick/Shield"
                  color: const Color(0xFF1570EF), // Brand Blue
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Store Balance Terms", // ✅ Professional Title
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF101828),
                      ),
                    ),
                    Text(
                      "How your funds are secured", // ✅ Reassuring Subtitle
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: const Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // --- REASON 1: The Value of Reservation ---
          _buildReasonRow(
            icon: Iconsax.shop,
            title: "Confirmed Reservation",
            desc: "When you start a plan, the merchant removes this item from the shelf. It is reserved exclusively for you.",
          ),
          SizedBox(height: 16.h),

          // --- REASON 2: The Safety Net ---
          _buildReasonRow(
            icon: Iconsax.wallet_check,
            title: "100% Funds Secured",
            desc: "If you stop a plan, you don't lose money. Your payments are moved to your Store Balance.",
          ),
          SizedBox(height: 16.h),

          // --- REASON 3: Liquidity ---
          _buildReasonRow(
            icon: Iconsax.refresh_circle,
            title: "Flexible Usage",
            desc: "Your Store Balance is available immediately. You can use it to purchase any other item from this merchant.",
          ),
          
          SizedBox(height: 32.h),

          // --- FOOTER BUTTON ---
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                foregroundColor: Colors.black,
              ),
              child: Text(
                "I Understand",
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildReasonRow({required IconData icon, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20.sp, color: Colors.grey.shade700),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14.sp, 
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF344054)
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 12.sp, 
                  color: const Color(0xFF667085),
                  height: 1.4
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
