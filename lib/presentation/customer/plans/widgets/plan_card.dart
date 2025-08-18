import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../data/models/plan.dart';
import '../../../shared/korra_net_image.dart';

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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: _stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // --- Product image banner (prestige, compact) ---
            KorraNetImage(
              url: plan.imageUrl,
              height: 250.h,
              width: double.infinity,
              fit: BoxFit.cover,
              radius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: vendor + Autopay
                  Row(
                    children: [
                      _vendorBadge(plan.vendor),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          plan.vendor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF101828),
                          ),
                        ),
                      ),
                      _chip(text: 'AutoPay', color: const Color(0xFF1DB954), filled: true),
                    ],
                  ),

                  SizedBox(height: 8.h),

                  // Title
                  Text(
                    plan.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF101828),
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // Amount summary
                  Text(
                    '${plan.amountPaidText ?? "—"} paid · ${plan.amountRemainText ?? "—"} remaining',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF667085),
                    ),
                  ),

                  SizedBox(height: 10.h),

                  // Progress
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (plan.progress.clamp(0, 100)) / 100.0,
                      minHeight: 4.h,
                      backgroundColor: const Color(0xFFEEEEEE),
                      valueColor: const AlwaysStoppedAnimation(_brand),
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Due + status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${plan.nextDue} · ${plan.nextAmountText ?? ""}'.trim(),
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF101828),
                        ),
                      ),
                      _statusChip(plan.progress),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: onPayNow,
                          style: FilledButton.styleFrom(
                            backgroundColor: _brand,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                          child: Text(
                            'Pay now',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onView,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _stroke),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            foregroundColor: _brand,
                          ),
                          child: Text(
                            'View plan',
                            style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onMenu,
                        icon: const Icon(Icons.more_vert, color: Color(0xFF1B1B1B)),
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

  Widget _vendorBadge(String v) {
    return Container(
      width: 32.w, height: 32.w,
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFEA),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFEAE6E2)),
      ),
      alignment: Alignment.center,
      child: Text(
        (v.isNotEmpty ? v[0] : '?').toUpperCase(),
        style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w800, color: _brand),
      ),
    );
  }

  Widget _statusChip(int progress) {
    if (progress >= 100) {
      return _chip(text: 'Completed', color: const Color(0xFF1DB954), filled: false);
    }
    if (progress < 15) {
      return _chip(text: 'Overdue', color: const Color(0xFFE53935), filled: true);
    }
    return _chip(text: 'Active', color: _brand, filled: false);
  }

  Widget _chip({required String text, required Color color, required bool filled}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: filled ? color.withOpacity(.10) : Colors.white,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
