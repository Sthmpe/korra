import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/vendor/product/vendor_products_state.dart';

class ProductDetailsTimeline extends StatelessWidget {
  final ProductItem product;

  const ProductDetailsTimeline({
    super.key,
    required this.product,
  });

  String _formatCurrency(double amount) {
    return NumberFormat("#,##0", "en_US").format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (!product.allowReservation) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 5. TERMS OF SALE
        Text(
          "Terms of Sale",
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF344054),
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            children: [
              // Model Type
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      product.modelType == ProductModelType.strict
                          ? MdiIcons.shieldCheck
                          : Icons.handshake_rounded,
                      size: 18.sp,
                      color: KorraColors.brand,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.modelType == ProductModelType.strict
                            ? "Strict Lock"
                            : "Korra Direct",
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF101828),
                        ),
                      ),
                      Text(
                        "Sales Model",
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: const Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: const Divider(height: 1, color: Color(0xFFEAECF0)),
              ),

              // Policy Details Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDetailColumn("Cancellation", product.cancellationPolicy),
                  if (product.modelType == ProductModelType.direct && product.directDownPayment != null)
                    _buildDetailColumn(
                      "Down Payment",
                      "₦${_formatCurrency(product.directDownPayment!)}",
                    ),
                  _buildDetailColumn("Extensions", product.extensionsEnabled ? "Allowed" : "No"),
                ],
              )
            ],
          ),
        ),

        SizedBox(height: 24.h),

        // 6. TIMELINE CARD
        Text(
          "Lock Duration",
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF344054),
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFEAECF0).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimelineItem(product.baseDuration, "Base Time", false),
              Icon(Icons.add, size: 14.sp, color: Colors.grey),
              _buildTimelineItem(product.noticePeriod, "Notice", true),
              Icon(Icons.arrow_forward, size: 14.sp, color: Colors.grey),
              _buildTimelineItem(product.totalMaxTime, "Total Max", false, isBold: true),
            ],
          ),
        ),

        SizedBox(height: 32.h),
      ],
    );
  }

  Widget _buildDetailColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF667085),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF344054),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    String value,
    String label,
    bool isAlert, {
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: isAlert ? const Color(0xFFA54600) : Colors.grey.shade500,
            fontWeight: isAlert ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: const Color(0xFF101828),
          ),
        ),
      ],
    );
  }
}
