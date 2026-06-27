import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../../config/constants/colors.dart';

// =============================================================================
// DYNAMIC GOAL TABS SELECTOR
// =============================================================================
class PlanGoalSelector extends StatelessWidget {
  final int maxDays;
  final int selectedGoalDays;
  final ValueChanged<int> onChanged;

  const PlanGoalSelector({
    super.key,
    required this.maxDays,
    required this.selectedGoalDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    List<int> options = [];
    if (maxDays >= 7) options.add(7);
    if (maxDays >= 14) options.add(14);
    if (maxDays >= 28) options.add(28);

    if (!options.contains(maxDays)) options.add(maxDays);

    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: options.map((days) {
          final isSelected = selectedGoalDays == days;

          String label;
          if (days == 7) {
            label = "1 Week";
          } else if (days == 14) {
            label = "2 Weeks";
          } else if (days == 28) {
            label = "4 Weeks";
          } else {
            label = "$days Days";
          }

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(days),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 0),
                margin: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? KorraColors.text
                        : KorraColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// SCHEDULE / CADENCE GRID SELECTOR
// =============================================================================
class PlanCadenceSelector extends StatelessWidget {
  final String? cadenceType;
  final int selectedGoalDays;
  final double remainingBalance;
  final ValueChanged<String?> onChanged;
  final NumberFormat currencyFormat;

  const PlanCadenceSelector({
    super.key,
    required this.cadenceType,
    required this.selectedGoalDays,
    required this.remainingBalance,
    required this.onChanged,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final daily = remainingBalance / selectedGoalDays;
    final weekly = remainingBalance / (selectedGoalDays / 7);

    final showMonthly = selectedGoalDays >= 30;
    final showWeekly = selectedGoalDays >= 14;

    return Column(
      children: [
        Row(
          children: [
            _buildSmartCadenceOption(
              label: "Daily",
              value: "daily",
              calculatedAmount: daily,
            ),
            SizedBox(width: 10.w),
            if (showWeekly)
              _buildSmartCadenceOption(
                label: "Weekly",
                value: "weekly",
                calculatedAmount: weekly,
              )
            else
              const Spacer(),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            if (showMonthly) ...[
              _buildSmartCadenceOption(
                label: "Monthly",
                value: "monthly",
                calculatedAmount: remainingBalance / (selectedGoalDays / 30),
              ),
              SizedBox(width: 10.w),
            ],
            _buildFlexibleOption(),
          ],
        ),
      ],
    );
  }

  Widget _buildSmartCadenceOption({
    required String label,
    required String value,
    required double calculatedAmount,
  }) {
    final isSelected = cadenceType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          decoration: BoxDecoration(
            color: isSelected ? KorraColors.brand : const Color(0xFFE5E7EB).withOpacity(0.5),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: KorraColors.brand.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white.withOpacity(0.9)
                      : KorraColors.textMuted,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                currencyFormat.format(calculatedAmount),
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : KorraColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlexibleOption() {
    final isSelected = cadenceType == 'flexible';
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged('flexible'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE5E7EB).withOpacity(0.5),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Text(
                "Flexible",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white.withOpacity(0.9)
                      : KorraColors.textMuted,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                "Anytime",
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : KorraColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// COMMITMENT / FINISH DATE MESSAGE CARD
// =============================================================================
class PlanCommitmentMessage extends StatelessWidget {
  final String? cadenceType;
  final int days;

  const PlanCommitmentMessage({
    super.key,
    required this.cadenceType,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    if (cadenceType == null) return const SizedBox.shrink();
    final isFlex = cadenceType == 'flexible';
    final date = DateFormat('MMM d').format(DateTime.now().add(Duration(days: days)));

    return Padding(
      padding: EdgeInsets.only(top: 20.h),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: isFlex
              ? const Color(0xFFECFDF5)
              : Colors.blue.shade50.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Icon(
              isFlex ? Icons.verified_user_outlined : Icons.flag_rounded,
              color: isFlex ? const Color(0xFF059669) : Colors.blue.shade700,
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                "Finish by $date.",
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  height: 1.4,
                  color: KorraColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
