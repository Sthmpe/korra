import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:korra/data/repository/customer/plans_repository.dart';

import '../../../../config/utils/currency_formatters.dart';
import '../../../../data/models/customer/plans.dart';
import '../../../../data/repository/customer/customer_repository.dart';
import '../../../shared/widgets/korra_header.dart';
import 'pay_plan_input_screen.dart';
import 'vendor_header.dart';


class PlanDetailsScreen extends StatelessWidget {
  final Plan plan;
  final CustomerRepository customerRepo;

  const PlanDetailsScreen({
    super.key,
    required this.plan,
    required this.customerRepo,
  });

  static const _brand = Color(0xFFA54600);
  static const _stroke = Color(0xFFEAE6E2);

  @override
  Widget build(BuildContext context) {
    // 1. ENGINEERING: Listen to the specific plan document.
    // If the user pays, the progress bar updates instantly without navigating back.
    return StreamBuilder<Plan?>(
      stream: customerRepo.streamSinglePlan(plan.id), // You need to add this method to repo
      initialData: plan, // Render immediately while connecting
      builder: (context, snapshot) {
        final currentPlan = snapshot.data ?? plan;
        
        // State Logic
        final isCompleted = currentPlan.status == 'completed';
        final isCancelled = currentPlan.status == 'cancelled';
        final canPay = !isCompleted && !isCancelled;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: KorraHeader(
            title: 'Plan Details',
            showLeadingIcon: true,
          ),
          
          // 2. Sticky Bottom Button (Engineering Best Practice for "Conversion" screens)
          bottomNavigationBar: canPay 
            ? _buildStickyPayButton(context, currentPlan)
            : null,

          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- A. PRODUCT HERO ---
                _buildProductHeader(currentPlan),

                // --- B. FINANCIAL PROGRESS ---
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildFinancialCard(currentPlan),
                ),

                SizedBox(height: 24.h),

                // --- C. PAYMENT SCHEDULE ---
                if (!isCompleted && !isCancelled) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text("Next Payment", style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.black)),
                  ),
                  SizedBox(height: 12.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: _buildNextPaymentCard(currentPlan),
                  ),
                  SizedBox(height: 32.h),
                ],

                // --- D. PLAN INFO / METADATA ---
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Text("Plan Information", style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.black)),
                ),
                SizedBox(height: 12.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildInfoGrid(currentPlan),
                ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- WIDGETS ---

  Widget _buildProductHeader(Plan p) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Banner
          Container(
            width: double.infinity,
            height: 220.h,
            color: Colors.grey.shade50,
            child: Image.network(
              p.imageUrls.isNotEmpty ? p.imageUrls.first : '',
              fit: BoxFit.cover,
              errorBuilder: (_,__,___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
            ),
          ),
          
          Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. REUSABLE VENDOR HEADER (Consistent with Create Screen)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    VendorHeader(storeName: p.storeName),
                    _buildStatusChip(p),
                  ],
                ),
                
                SizedBox(height: 12.h), // Increased slightly for spacing
                
                // 2. Title
                Text(
                  p.title,
                  style: GoogleFonts.inter(
                    fontSize: 20.sp, 
                    fontWeight: FontWeight.w800, 
                    color: const Color(0xFF101828), 
                    height: 1.2
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(Plan p) {
    // Math for progress
    final double paid = p.amountPaid;
    final double total = p.totalAmount;
    final double percent = p.progressPercent / 100;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _stroke),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0,4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Total Paid", style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade500)),
                  SizedBox(height: 4.h),
                  Text(formatToCurrency(paid), style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800, color: _brand)),
                ],
              ),
              Container(width: 1, height: 40.h, color: _stroke),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Remaining", style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade500)),
                  SizedBox(height: 4.h),
                  Text(formatToCurrency(p.amountRemaining), style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800, color: const Color(0xFF101828))),
                ],
              ),
            ],
          ),
          SizedBox(height: 20.h),
          // Big Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 12.h,
              backgroundColor: const Color(0xFFF2F4F7),
              valueColor: AlwaysStoppedAnimation(
                p.status == 'cancelled' ? Colors.grey.shade400 : (p.status == 'completed' ? Colors.green : _brand)
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "${(percent * 100).toInt()}% completed",
              style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNextPaymentCard(Plan p) {
    // Format Date
    final dateStr = DateFormat('MMM d, yyyy').format(p.nextDueDate);
    
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F5), // Light Orange tint
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _brand.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _brand.withOpacity(0.1))),
            child: Icon(Icons.calendar_today_rounded, size: 20.sp, color: _brand),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Next Due: $dateStr", style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: const Color(0xFF101828))),
                SizedBox(height: 2.h),
                Text(
                  p.isOverdue ? "Payment is overdue!" : "Autopay scheduled",
                  style: GoogleFonts.inter(
                    fontSize: 12.sp, 
                    fontWeight: FontWeight.w500, 
                    color: p.isOverdue ? Colors.red : Colors.grey.shade600
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(Plan p) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _stroke),
      ),
      child: Column(
        children: [
          _infoRow("Plan ID", p.id, isCopyable: true),
          Divider(color: _stroke, height: 24.h),
          _infoRow("Created On", DateFormat('MMM d, yyyy').format(p.createdAt)),
          Divider(color: _stroke, height: 24.h),
          _infoRow("Duration", "${p.durationMonths} Months"),
          Divider(color: _stroke, height: 24.h),
          _infoRow("Total Price", formatToCurrency(p.totalAmount)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isCopyable = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        GestureDetector(
          onTap: isCopyable ? () {
            Clipboard.setData(ClipboardData(text: value));
            // Show toast
          } : null,
          child: Row(
            children: [
              Text(value, style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF101828), fontWeight: FontWeight.w600)),
              if (isCopyable) ...[
                SizedBox(width: 6.w),
                Icon(Icons.copy, size: 14.sp, color: _brand),
              ]
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(Plan p) {
    Color bg = Colors.grey.shade100;
    Color text = Colors.grey.shade700;
    String label = "Active";

    if (p.status == 'completed') {
      bg = const Color(0xFFECFDF5);
      text = const Color(0xFF059669);
      label = "Completed";
    } else if (p.status == 'cancelled') {
      bg = Colors.grey.shade200;
      text = Colors.grey.shade600;
      label = "Canceled";
    } else if (p.isOverdue) {
      bg = const Color(0xFFFEF2F2);
      text = const Color(0xFFDC2626);
      label = "Overdue";
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8.r)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: text)),
    );
  }

  Widget _buildStickyPayButton(BuildContext context, Plan p) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _stroke)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,-5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Next payment", style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500)),
                Text(formatToCurrency(p.nextAmount), style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w800, color: const Color(0xFF101828))),
              ],
            ),
          ),
          SizedBox(
            width: 140.w,
            height: 48.h,
            child: FilledButton(
              onPressed: () {
                Get.to(() => PayPlanInputScreen(plan: p, repo: customerRepo));
              },
              style: FilledButton.styleFrom(
                backgroundColor: _brand,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              ),
              child: Text("Pay Now", style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}