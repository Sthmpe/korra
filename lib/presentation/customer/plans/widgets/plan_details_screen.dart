import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:korra/data/repository/customer/plans_repository.dart';

import '../../../../config/constants/colors.dart';
import '../../../../data/models/customer/plans.dart';
import '../../../../data/repository/customer/customer_repository.dart';
import '../../../shared/widgets/korra_header.dart';
import '../../../shared/widgets/show_app_snackbar.dart';
import 'pay_plan_input_screen.dart';
import 'vendor_header.dart'; // ✅ Imported your widget

class PlanDetailsScreen extends StatelessWidget {
  final Plan plan;
  final CustomerRepository customerRepo;

  PlanDetailsScreen({
    super.key,
    required this.plan,
    required this.customerRepo,
  });


  final currencyFormat = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 0,
  );

  static const _brand = KorraColors.brand;
  static const _stroke = Color(0xFFEAE6E2);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Plan?>(
      stream: customerRepo.streamSinglePlan(plan.id),
      initialData: plan,
      builder: (context, snapshot) {
        final currentPlan = snapshot.data ?? plan;
        
        final isCompleted = currentPlan.status == 'completed';
        final isCancelled = currentPlan.status == 'cancelled';
        final canInteract = !isCompleted && !isCancelled;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: KorraHeader(
            title: 'Plan Details',
            showLeadingIcon: true,
          ),
          
          // Sticky Bottom Bar (Pay Button) - Only if active
          bottomNavigationBar: canInteract 
            ? _buildStickyPayButton(context, currentPlan)
            : null,

          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- A. PRODUCT HERO (With VendorHeader) ---
                _buildProductHeader(currentPlan),

                // --- B. FINANCIAL PROGRESS ---
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildFinancialCard(currentPlan),
                ),

                SizedBox(height: 24.h),

                // --- C. TIMELINE & DEADLINE ---
                if (canInteract) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: _buildTimelineCard(currentPlan),
                  ),
                  SizedBox(height: 24.h),
                ],

                // --- D. PAYMENT INFO ---
                if (canInteract) ...[
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

                // --- E. PLAN METADATA ---
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

                // --- F. SUBTLE CANCEL BUTTON ---
                // "The button is not like a focus button" -> We use TextButton.icon with red tint
                if (canInteract)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 40.h),
                      child: TextButton.icon(
                        onPressed: () => _showCancelDialog(context, currentPlan),
                        icon: Icon(Iconsax.close_circle, size: 18.sp, color: Colors.red.shade700),
                        label: Text(
                          "Cancel Plan", 
                          style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.red.shade700)
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                          backgroundColor: Colors.red.shade50, // Very light red bg
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100.r))
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- WIDGETS ---

  Widget _buildProductHeader(Plan p) {
    // Determine Model Type from policy string for the badge
    final bool isStrict = p.cancellationPolicy.contains("50%");
    final String modelName = isStrict ? "Strict Lock" : "Korra Direct";
    final Color modelColor = isStrict ? const Color(0xFF9A3412) : const Color(0xFF075985);
    final Color modelBg = isStrict ? const Color(0xFFFFF7ED) : const Color(0xFFF0F9FF);

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ✅ USING YOUR VENDOR HEADER WIDGET
                    VendorHeader(storeName: p.storeName),
                    _buildStatusChip(p),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  p.title,
                  style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.w800, color: const Color(0xFF101828), height: 1.2),
                ),
                SizedBox(height: 8.h),
                
                // Price + Model Badge Row
                Row(
                  children: [
                    Text(
                      currencyFormat.format(p.totalAmount),
                      style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
                    ),
                    SizedBox(width: 12.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: modelBg,
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(color: modelColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        modelName,
                        style: GoogleFonts.inter(fontSize: 10.sp, fontWeight: FontWeight.w700, color: modelColor),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(Plan p) {
    // Calculate progress based on Amount Paid vs Total
    // Use safe division to avoid NaN
    final double percent = p.totalAmount == 0 ? 0 : (p.amountPaid / p.totalAmount);

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
                  Text("Total Equity", style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade500)),
                  SizedBox(height: 4.h),
                  Text(currencyFormat.format(p.amountPaid), style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800, color: _brand)),
                ],
              ),
              Container(width: 1, height: 40.h, color: _stroke),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Outstanding", style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade500)),
                  SizedBox(height: 4.h),
                  Text(currencyFormat.format(p.outstandingLoanAmount), style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800, color: const Color(0xFF101828))),
                ],
              ),
            ],
          ),
          SizedBox(height: 20.h),
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

  Widget _buildTimelineCard(Plan p) {
    final expiry = p.planExpiryDate;
    final now = DateTime.now();
    final daysLeft = expiry.difference(now).inDays;
    
    final isCritical = daysLeft <= 5;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isCritical ? const Color(0xFFFFF4F2) : const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isCritical ? const Color(0xFFFFE4E1) : const Color(0xFFE0F2FE)),
      ),
      child: Row(
        children: [
          Icon(Iconsax.timer_1, size: 24.sp, color: isCritical ? Colors.red : Colors.blue),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  daysLeft < 0 ? "Deadline Exceeded" : "$daysLeft Days Remaining",
                  style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: const Color(0xFF101828)),
                ),
                SizedBox(height: 2.h),
                Text(
                  "Expires on ${DateFormat('MMM d, yyyy').format(expiry)}",
                  style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextPaymentCard(Plan p) {
    final dateStr = DateFormat('MMM d, yyyy').format(p.nextDueDate);
    final amountStr = currencyFormat.format(p.nextAmount);
    
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F5), 
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
                Text("Next Due: $amountStr", style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: const Color(0xFF101828))),
                SizedBox(height: 2.h),
                Text(
                  p.isOverdue ? "Payment is overdue!" : "Due on $dateStr",
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
          _infoRow("Duration", "${p.baseDurationDays} Days"),
          Divider(color: _stroke, height: 24.h),
          _infoRow("One-time Fee", currencyFormat.format(p.processingFee)), // Show Fee here
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
            showAppSnackbar("Copied to clipboard", SnackbarType.success);
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
      label = "Cancelled";
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
                Text("Outstanding", style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500)),
                Text(currencyFormat.format(p.outstandingLoanAmount), style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w800, color: const Color(0xFF101828))),
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

  // --- CANCEL DIALOG LOGIC ---
  void _showCancelDialog(BuildContext context, Plan p) {
    final TextEditingController reasonCtrl = TextEditingController();
    
    // 1. Determine Logic based on Policy (saved in Plan)
    final bool isStrict50 = p.cancellationPolicy.contains("50%");
    
    // 2. Calculate Math (Estimates for display)
    // Only 'amountPaid' is refundable (fees are usually non-refundable)
    final double totalPaid = p.amountPaid; 
    final double penalty = isStrict50 ? (totalPaid * 0.50) : 0.0;
    final double refund = totalPaid - penalty;

    // 3. Define Refund Destination
    // If strict, remaining goes to Wallet. If Direct, ALL goes to Store Credit (technically Wallet but restricted conceptually, though backend puts it in wallet for now)
    final String refundType = isStrict50 ? "Wallet Refund" : "Store Credit";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Iconsax.warning_2, color: Colors.red, size: 24.sp),
            SizedBox(width: 8.w),
            Text("Cancel Plan?", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18.sp)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "This action cannot be undone. Please review the refund breakdown below:",
              style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade600, height: 1.4),
            ),
            SizedBox(height: 16.h),
            
            // --- BREAKDOWN CARD ---
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFEAECF0)),
              ),
              child: Column(
                children: [
                  _buildMathRow("Total Principal Paid", totalPaid, isBold: true),
                  Divider(height: 16.h, color: Colors.grey.shade300),
                  _buildMathRow("Less: Penalty Fee", -penalty, color: Colors.red),
                  SizedBox(height: 8.h),
                  _buildMathRow("Est. Refund Amount", refund, color: Colors.green, isBold: true),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            
            // --- REFUND METHOD NOTE ---
            Row(
              children: [
                Icon(Iconsax.wallet_check, size: 16.sp, color: Colors.grey.shade500),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    isStrict50 
                        ? "Refunded to Wallet (Withdrawable)"
                        : "Refunded as Store Credit (Cannot Withdraw)",
                    style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),
            
            // Reason Input
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                hintText: "Reason for cancellation (Optional)...",
                hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Keep Plan", style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await customerRepo.cancelPlan(
                  planId: p.id,
                  customerUid: p.customerId,
                  reason: reasonCtrl.text.isEmpty ? "User cancelled" : reasonCtrl.text,
                );
                showAppSnackbar("Plan cancelled successfully", SnackbarType.success);
              } catch (e) {
                showAppSnackbar(e.toString(), SnackbarType.error);
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            ),
            child: Text("Confirm Cancel", style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildMathRow(String label, double amount, {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: Colors.grey.shade700,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          currencyFormat.format(amount),
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: color ?? const Color(0xFF101828),
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}