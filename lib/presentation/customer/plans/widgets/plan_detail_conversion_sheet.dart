import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../data/models/customer/plans.dart';
import '../../../../logic/bloc/customer/plans/plan_action_cubit.dart';

class PlanDetailConversionSheet extends StatelessWidget {
  final Plan plan;

  const PlanDetailConversionSheet({
    super.key,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 2,
    );

    return BlocBuilder<PlanActionCubit, PlanActionState>(
      builder: (context, state) {
        final bool isLoading = state is PlanActionLoading;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 40.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 24.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),

              // 2. Icon Hero
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: const BoxDecoration(
                  color: Color(0xFFF2F4F7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.wallet_check,
                  color: const Color(0xFF344054),
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 16.h),

              // 3. Headline
              Text(
                "Close Plan & Secure Funds",
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF101828),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "End this plan and move your funds to your Store Balance.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: const Color(0xFF667085),
                ),
              ),

              SizedBox(height: 32.h),

              // 4. The "Receipt" Box
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFEAECF0).withOpacity(0.01), width: 0.0),
                ),
                child: Column(
                  children: [
                    _receiptRow(
                      "Total Funds Paid",
                      currencyFormat.format(plan.amountPaid),
                      isBold: true,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: const Divider(height: 0.1, thickness: 0.1),
                    ),
                    _receiptRow(
                      "Closing Fee",
                      "₦0.00",
                      color: Colors.green,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: const Divider(height: 0.1, thickness: 0.1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Funds to Secure",
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: const Color(0xFF667085),
                          ),
                        ),
                        Text(
                          currencyFormat.format(plan.amountPaid),
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF101828),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // 5. Value Proposition Note
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Iconsax.info_circle,
                    size: 18.sp,
                    color: const Color(0xFF344054),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      "Your funds never expire. Use them to start a new plan anytime.",
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: const Color(0xFF475467),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32.h),

              // 6. Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        side: BorderSide(color: const Color(0xFFD0D5DD).withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        "Keep Plan",
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF344054),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: FilledButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.pop(context);
                              context
                                  .read<PlanActionCubit>()
                                  .convertToStoreCredit(
                                    planId: plan.id,
                                    customerUid: plan.customerId,
                                  );
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF101828),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 20.h,
                              width: 20.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              "Secure Funds",
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _receiptRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: const Color(0xFF667085),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: color ?? const Color(0xFF101828),
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
