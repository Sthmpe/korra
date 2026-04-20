import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../config/constants/colors.dart';
import '../../../../data/models/customer/payment_receipt_data.dart';
import '../../../shared/widgets/korra_header.dart';

class TransactionReceiptScreen extends StatefulWidget {
  // 🚀 Taking the parameters cleanly through the constructor
  final PaymentReceiptData data;
  final String txType;
  final double? convertedAmount;

  const TransactionReceiptScreen({
    super.key, 
    required this.data, 
    required this.txType,
    this.convertedAmount,
  });

  @override
  State<TransactionReceiptScreen> createState() => _TransactionReceiptScreenState();
}

class _TransactionReceiptScreenState extends State<TransactionReceiptScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  Future<void> _shareReceipt() async {
    setState(() => _isSharing = true);
    try {
      final Uint8List? imageBytes = await _screenshotController.capture();
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/korra_receipt_${widget.data.reference}.png').create();
        await imagePath.writeAsBytes(imageBytes);

        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: 'Transaction Receipt - Reference: ${widget.data.reference}',
        );
      }
    } catch (e) {
      debugPrint("Error sharing receipt: $e");
    } finally {
      setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    // Dynamic Header Status Logic
    bool isCompleted = widget.data.isFinished || widget.data.status == 'COMPLETED' || widget.txType == 'deposit' || widget.txType == 'plan_cancelled';
    String headerStatusText = "DEPOSIT CONFIRMED";
    
    if (widget.txType == 'deposit') headerStatusText = "WALLET FUNDED";
    if (widget.txType == 'plan_cancelled' || widget.txType == 'refund') headerStatusText = "REFUND PROCESSED";
    if (isCompleted && (widget.txType == 'installment' || widget.txType == 'plan_creation')) headerStatusText = "PLAN COMPLETED";

    final statusColor = isCompleted ? Colors.green : const Color(0xFFF79009);
    final statusBg = isCompleted ? const Color(0xFFECFDF3) : const Color(0xFFFFFAEB);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: KorraHeader(title: 'Transaction Receipt', showLeadingIcon: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 40.h),
        child: Column(
          children: [
            Screenshot(
              controller: _screenshotController,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- 1. HEADER ---
                    Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(color: KorraColors.brand.withOpacity(0.0), shape: BoxShape.circle),
                            padding: EdgeInsets.all(2.r),
                            child: Image.asset(
                              'assets/images/korra_logo_icon.webp',
                              fit: BoxFit.cover,
                              errorBuilder: (c, o, s) => Icon(Icons.account_balance_wallet_rounded, size: 24.sp, color: Color(0xFFA54600)),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            headerStatusText, 
                            style: GoogleFonts.inter(fontSize: 11.sp, letterSpacing: 1.2, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            (widget.txType == 'plan_cancelled' || widget.txType == 'refund')
                                ? currencyFormat.format(widget.convertedAmount)
                                : currencyFormat.format(widget.data.amountPaidNow),
                            style: GoogleFonts.plusJakartaSans(fontSize: 32.sp, fontWeight: FontWeight.w800, color: const Color(0xFF101828)),
                          ),
                        ],
                      ),
                    ),

                    _buildDottedLine(),

                    // --- 2. DYNAMIC DETAILS SECTION ---
                    Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        children: [
                          _detailRow("Reference ID", widget.data.reference),
                          _detailRow("Date & Time", dateFormat.format(widget.data.date)),
                          const Divider(height: 32),
                          
                          if (widget.txType == 'deposit') ...[
                            _detailRow("Transaction Type", "Wallet Funding", isBold: true),
                            _detailRow("Payment Method", "Bank Transfer"),
                            _detailRow("Destination", "Korra Wallet"),
                          ] 
                          else if (widget.txType == 'plan_cancelled' || widget.txType == 'refund') ...[
                            _detailRow("Transaction Type", "Refund", isBold: true),
                            _detailRow("Item Cancelled", widget.data.productName.isNotEmpty ? widget.data.productName : "Layaway Plan"),
                            _detailRow("Destination", "Store Balance"),
                          ] 
                          else ...[
                            _detailRow("Vendor", widget.data.vendorName),
                            _detailRow("Payment Method", widget.data.paymentMethod),
                            if (widget.data.creditUsed > 0)
                              _detailRow("Store Balance Applied", "- ${currencyFormat.format(widget.data.creditUsed)}", color: Colors.green),
                            if (widget.data.walletUsed > 0 && widget.data.creditUsed > 0)
                              _detailRow("Wallet Deducted", currencyFormat.format(widget.data.walletUsed)),
                            
                            const Divider(height: 32),
                            _detailRow("Item Paid For", widget.data.productName, isBold: true),
                            _detailRow("Total Paid So Far", currencyFormat.format(widget.data.amountPaidSoFar)),
                            _detailRow("Balance Remaining", currencyFormat.format(widget.data.balanceRemaining), 
                                       color: widget.data.balanceRemaining <= 0 ? Colors.green : const Color(0xFFD92D20)),
                            
                            if (!isCompleted && widget.data.nextDueDate != null) ...[
                              SizedBox(height: 12.h),
                              Container(
                                padding: EdgeInsets.all(12.r),
                                decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8.r)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Next Due", style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                                    Text(DateFormat('dd MMM yyyy').format(widget.data.nextDueDate!), style: GoogleFonts.plusJakartaSans(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.black)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),

                    // --- 3. FOOTER ---
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.vertical(bottom: Radius.circular(16.r))),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 🚀 Replaced Iconsax with Material Verified icon
                              Icon(Icons.verified_rounded, size: 16.sp, color: KorraColors.brand),
                              SizedBox(width: 8.w),
                              Text("Verified by Korra Systems", style: GoogleFonts.plusJakartaSans(fontSize: 12.sp, fontWeight: FontWeight.w700, color: KorraColors.brand)),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            "This receipt serves as proof of transaction. Korra serves as the transaction ledger.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey.shade400, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // 4. SHARE BUTTON
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: FilledButton.icon(
                onPressed: _isSharing ? null : _shareReceipt,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF101828),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                icon: _isSharing
                    ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    // 🚀 Replaced Iconsax with standard Material share
                    : const Icon(Icons.share_rounded, size: 20),
                label: Text(
                  _isSharing ? "Preparing..." : "Share Receipt",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF667085), fontWeight: FontWeight.w400)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: isBold ? FontWeight.w700 : FontWeight.w600, color: color ?? const Color(0xFF101828)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDottedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 6.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(
            dashCount,
            (_) => SizedBox(width: dashWidth, height: 1, child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey.shade200))),
          ),
        );
      },
    );
  }
}