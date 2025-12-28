// lib/presentation/vendor/settlement/widgets/vendor_receipt_screen.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../config/constants/colors.dart';
import '../../../data/models/vendor/transaction_model.dart';
import '../../shared/widgets/korra_header.dart';

class VendorReceiptScreen extends StatefulWidget {
  final TransactionModel transaction;

  const VendorReceiptScreen({super.key, required this.transaction});
  @override
  State<VendorReceiptScreen> createState() => _VendorReceiptScreenState();
}
class _VendorReceiptScreenState extends State<VendorReceiptScreen> {
  // ✅ Controller to capture the widget
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  Future<void> _shareReceipt() async {
    setState(() => _isSharing = true);

    try {
      // 1. Capture the widget
      final Uint8List? imageBytes = await _screenshotController.capture();

      if (imageBytes != null) {
        // 2. Save to temporary file
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/korra_receipt_${widget.transaction.reference}.png').create();
        await imagePath.writeAsBytes(imageBytes);

        // 3. Share the file
        // Note: Using XFile for share_plus v7+
        await Share.shareXFiles(
          [XFile(imagePath.path)], 
          text: 'Payment Receipt for Reference: ${widget.transaction.reference}'
        );
      }
    } catch (e) {
      debugPrint("Error sharing receipt: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not share receipt. Please try again.")),
      );
    } finally {
      setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    final bool isCredit = widget.transaction.amount >= 0;
    final statusColor = widget.transaction.status == 'success'
        ? Colors.green
        : Colors.orange;

    // ✅ Check if we have fee details to show
    final hasFeeDetails =
        widget.transaction.grossAmount != null &&
        widget.transaction.feeAmount != null &&
        widget.transaction.feeAmount! > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: const KorraHeader(
        title: 'Transaction Receipt',
        showLeadingIcon: true,
      ),
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
                ),
                child: Column(
                  children: [
                    // --- HEADER ---
                    Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        children: [
                          Container(
                            width: 48.w,
                            height: 48.w,
                            decoration: BoxDecoration(
                              color: isCredit
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCredit
                                  ? Iconsax.wallet_add
                                  : Iconsax.wallet_minus,
                              color: isCredit ? Colors.green : Colors.red,
                              size: 24,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            isCredit ? "SETTLEMENT RECEIVED" : "FUNDS WITHDRAWN",
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          SizedBox(height: 8.h),
              
                          // Net Amount (Actual amount added/deducted)
                          Text(
                            currencyFormat.format(widget.transaction.amount.abs()),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF101828),
                            ),
                          ),
                          SizedBox(height: 16.h),
              
                          // Status
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              //color: statusBg,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              widget.transaction.status.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildDottedLine(),
              
                    // --- DETAILS ---
                    Padding(
                      padding: EdgeInsets.all(24.0.r),
                      child: Column(
                        children: [
                          _detailRow(
                            "Transaction ID",
                            widget.transaction.reference,
                            isCopyable: true,
                          ),
                          SizedBox(height: 8.h),
                          _detailRow(
                            "Date",
                            dateFormat.format(widget.transaction.createdAt),
                          ),
                          SizedBox(height: 8.h),
                          _detailRow("Description", widget.transaction.description, isCopyable: true),
                          SizedBox(height: 8.h),
                          // Normal View
                          _detailRow("Type", _formatType(widget.transaction.type)),
                        ],
                      ),
                    ),
              
                      
                    _buildDottedLine(),
                                      
                    // ✅ FEE BREAKDOWN (Only shows if fees exist)
                    if (hasFeeDetails) ...[
                      Padding(
                        padding: EdgeInsets.all(24.0.r),
                        child: Column(
                          children: [
                            _detailRow(
                              "Order Value (Gross)",
                              currencyFormat.format(widget.transaction.grossAmount),
                            ),
                            SizedBox(height: 8.h),
                            _detailRow(
                              "Platform Fee",
                              "- ${currencyFormat.format(widget.transaction.feeAmount)}", // Explicit Minus
                              color: const Color(
                                0xFFB42318,
                              ), // Red color for deduction
                            ),
                          ],
                        ),
                      ),
                    ],
              
                    _buildDottedLine(),
                      
                    Padding(
                      padding: EdgeInsets.all(24.0.r),
                      child: _detailRow(
                        "Net Settlement",
                        currencyFormat.format(widget.transaction.amount.abs()),
                        isBold: true,
                      ),
                    ),
              
                    _buildDottedLine(),
                      
                    SizedBox(height: 16.h),       
                                      
              
                    // --- FOOTER (Same as before) ---
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(16.r),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Iconsax.verify,
                                size: 16.sp,
                                color: KorraColors.brand,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                "Verified by Korra Systems",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: KorraColors.brand,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            "This receipt confirms the settlement or withdrawal of funds.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Share Button
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
                  : const Icon(Iconsax.share, size: 20),
                label: Text(
                  _isSharing ? "Preparing..." : "Share Receipt", 
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14.sp)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatType(String type) {
    if (type.isEmpty) return type;
    return type[0].toUpperCase() + type.substring(1);
  }

  // ... (Helpers: _detailRow, _buildDottedLine) ...
  // (Paste the same helper methods from previous response here)
  Widget _detailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
    bool isCopyable = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: const Color(0xFF667085),
              fontWeight: FontWeight.w400,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: SizedBox(
                    width: 155.w,
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                        color: color ?? const Color(0xFF101828),
                      ),
                    ),
                  ),
                ),
                if (isCopyable) ...[
                  SizedBox(width: 8.w),
                  Icon(Icons.copy, size: 14.sp, color: Colors.grey.shade400),
                ],
              ],
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
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade200),
              ),
            );
          }),
        );
      },
    );
  }
}
