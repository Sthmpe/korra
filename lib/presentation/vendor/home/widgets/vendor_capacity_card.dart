import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../config/constants/colors.dart';
import '../../../../config/utils/currency_formatters.dart';

class VendorCapacityCard extends StatelessWidget {
  final double maxLimit;        // e.g. 250,000
  final double activePlanValue; // e.g. 100,000
  final double storeCreditValue;// e.g. 50,000

  const VendorCapacityCard({
    super.key,
    required this.maxLimit,
    required this.activePlanValue,
    required this.storeCreditValue,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Percentages
    // Clamp ensures we don't crash if logic goes slightly over 100%
    double totalUsed = activePlanValue + storeCreditValue;
    double remaining = (maxLimit - totalUsed).clamp(0, maxLimit);
    
    double planPercent = (activePlanValue / maxLimit).clamp(0.0, 1.0);
    double creditPercent = (storeCreditValue / maxLimit).clamp(0.0, 1.0 - planPercent); // Stack it

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFEAE6E2).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Iconsax.chart_2, size: 18.sp, color: const Color(0xFF101828)),
                    SizedBox(width: 8.w),
                    Text(
                      "Business Capacity",
                      style: GoogleFonts.inter(
                        fontSize: 13.sp, 
                        fontWeight: FontWeight.w700, 
                        color: const Color(0xFF101828)
                      ),
                    ),
                  ],
                ),
                Text(
                  "Tier 1", // You can pass this in dynamically later
                  style: GoogleFonts.inter(
                    fontSize: 11.sp, 
                    fontWeight: FontWeight.w600, 
                    color: Colors.grey.shade500
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // THE STACKED BAR (Apple Style)
            ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: SizedBox(
                height: 8.h,
                child: Row(
                  children: [
                    // A. Active Plans (Blue)
                    if (planPercent > 0)
                      Flexible(
                        flex: (planPercent * 100).toInt(),
                        child: Container(color: KorraColors.brandDark) // iOS Blue
                      ),
                    
                    // B. Store Credit (Orange - Liability)
                    if (creditPercent > 0)
                      Flexible(
                        flex: (creditPercent * 100).toInt(),
                        child: Container(color: const Color(0xFFF59E0B)), // Warning Orange
                      ),
                    
                    // C. Empty Space (Grey)
                    Flexible(
                      flex: ((1.0 - planPercent - creditPercent) * 100).toInt(),
                      child: Container(color: const Color(0xFFF2F4F7)),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // LEGEND & STATS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Available (Left)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Available Limit",
                      style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      "₦${formatToCurrency(remaining)}",
                      style: GoogleFonts.inter(
                        fontSize: 16.sp, 
                        fontWeight: FontWeight.w700, 
                        color: const Color(0xFF101828)
                      ),
                    ),
                  ],
                ),

                // 2. Breakdown (Right)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Active Plans Legend
                    if (activePlanValue > 0)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
                        child: Row(
                          children: [
                            Container(width: 6.w, height: 6.w, decoration: const BoxDecoration(color: KorraColors.brandDark, shape: BoxShape.circle)),
                            SizedBox(width: 6.w),
                            Text(
                              "Active Plans: ₦${formatToCurrency(activePlanValue)}",
                              style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF344054), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),  
                  
                      // Store Credit Legend (Clickable Button)
                      if (storeCreditValue > 0)
                        GestureDetector(
                          onTap: () {
                            // 🚀 Navigates to the new Store Balances screen
                            Get.toNamed(
                              '/vendor/profile/store-balances', // or Routes.vendorStoreBalances
                              arguments: {'uid': FirebaseAuth.instance.currentUser?.uid},
                            );
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED), // Premium subtle orange background
                              borderRadius: BorderRadius.circular(12.r),
                              //border: Border.all(color: const Color(0xFFFFEDD5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6.w, 
                                  height: 6.w, 
                                  decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  "Store Balance: ₦${formatToCurrency(storeCreditValue)}",
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp, 
                                    color: const Color(0xFFB54D08), 
                                    fontWeight: FontWeight.w700
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Icon(Icons.chevron_right, size: 14.sp, color: const Color(0xFFB54D08)),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}