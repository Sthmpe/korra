import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/utils/currency_formatters.dart';
import '../../../../data/models/customer/plans.dart';

class PlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback onPayNow;
  final VoidCallback onView;
  final VoidCallback onMenu;

  const PlanCard({
    super.key,
    required this.plan,
    required this.onPayNow,
    required this.onView,
    required this.onMenu,
  });

  static const _brand = Color(0xFFA54600);
  static const _stroke = Color(0xFFEAE6E2);

  @override
  Widget build(BuildContext context) {
    // 1. Logic
    final bool isCompleted = plan.status == 'completed';
    final bool isCancelled = plan.status == 'cancelled';
    final bool isOverdue = plan.isOverdue;
    final bool isPending = plan.status == 'pending_approval'; // ✅ NEW LOGIC
    
    // AutoPay logic
    final bool showAutoPay = plan.commitmentEnabled; 

    // ✅ HELPER 1: Paid Amount (Standard 2DP Display)
    // Prevents long decimals like 5000.333333
    double _clipAmount(double amount) {
      return double.parse(amount.toStringAsFixed(2));
    }

    // ✅ HELPER 2: Remaining Balance (Always Round UP)
    // Ensures you don't lose 0.01 due to rounding down.
    // 33.333 -> 33.34
    double _roundUpAmount(double amount) {
      if (amount == 0) return 0;
      return (amount * 100).ceil() / 100;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _stroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // --- A. IMAGE BANNER ---
          Stack(
            children: [
              Container(
                height: 160.h,
                width: double.infinity,
                color: Colors.grey.shade100,
                child: CachedNetworkImage(
                  imageUrl: plan.imageUrls.isNotEmpty ? plan.imageUrls.first : '',
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[100],
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
              ),
              
              // Status Chip
              Positioned(
                top: 12.h,
                left: 12.w,
                child: _buildStatusBadge(isCompleted, isOverdue, isPending), // ✅ Updated Arg
              ),
            ],
          ),

          // --- B. DETAILS SECTION ---
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Vendor & Flags
                Row(
                  children: [
                    _vendorBadge(plan.storeName),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        plan.storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF101828),
                        ),
                      ),
                    ),
                    if (showAutoPay) ...[
                        SizedBox(width: 6.w),
                        _chip(text: 'AutoPay', color: const Color(0xFF1DB954), filled: true),
                    ]
                  ],
                ),

                SizedBox(height: 10.h),

                // 2. Title
                Text(
                  plan.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF101828),
                    height: 1.2,
                  ),
                ),

                SizedBox(height: 12.h),

                // 3. Progress Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Paid: ${formatToCurrency(_clipAmount(plan.amountPaid))}',
                      style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF667085), fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Left: ${formatToCurrency(_roundUpAmount(plan.amountRemaining))}',
                      style: GoogleFonts.inter(fontSize: 12.sp, color: _brand, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (plan.progressPercent.clamp(0, 100)) / 100.0,
                    minHeight: 6.h,
                    backgroundColor: const Color(0xFFF2F4F7),
                    valueColor: AlwaysStoppedAnimation(
                      isCompleted ? Colors.green : (isPending ? Colors.orange : _brand)
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // 4. Action Buttons
                Row(
                  children: [
                    // ✅ HIDE PAY BUTTON IF PENDING OR COMPLETED
                    if (!isCompleted && !isPending && !isCancelled) ...[
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 44.h,
                          child: FilledButton(
                            onPressed: onPayNow,
                            style: FilledButton.styleFrom(
                              backgroundColor: _brand,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              elevation: 0,
                            ),
                            child: Text(
                              'Pay Now',
                              style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ] else if (isPending) ...[
                      // ✅ SHOW PENDING MESSAGE INSTEAD
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 44.h,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.orange.shade100),
                          ),
                          child: Text(
                            "Waiting for Vendor",
                            style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.orange.shade800),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ] else if (isCancelled) ...[
                      // ✅ OPTIONAL: Show a "Cancelled" label
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 44.h,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            "Plan Cancelled",
                            style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],
                    
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 44.h,
                        child: OutlinedButton(
                          onPressed: onView,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _stroke),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            foregroundColor: const Color(0xFF344054),
                          ),
                          child: Text(
                            'View',
                            style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600),
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
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildStatusBadge(bool isCompleted, bool isOverdue, bool isPending) {
    String text = "Active";
    Color bg = Colors.black.withOpacity(0.6);
    Color fg = Colors.white;
    IconData icon = Icons.circle;

    if (isCompleted) {
      text = "Completed";
      bg = const Color(0xFF1DB954);
      icon = Icons.check_circle;
    } else if (isOverdue) {
      text = "Overdue";
      bg = const Color(0xFFD92D20);
      icon = Icons.warning_amber_rounded;
    } else if (isPending) {
      text = "Pending Approval";
      bg = const Color(0xFFF79009); // Warning Orange
      icon = Iconsax.timer_1;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12.sp), 
          SizedBox(width: 4.w),
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _vendorBadge(String v) {
    return Container(
      width: 24.w, height: 24.w,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      alignment: Alignment.center,
      child: Text(
        (v.isNotEmpty ? v[0] : '?').toUpperCase(),
        style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: _brand),
      ),
    );
  }

  Widget _chip({required String text, required Color color, required bool filled}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: filled ? color.withOpacity(.10) : Colors.white,
        border: Border.all(color: filled ? Colors.transparent : color),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 10.sp, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}