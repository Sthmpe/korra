import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart'; // Capture widget as image
import 'package:share_plus/share_plus.dart'; // Native share sheet
import 'package:path_provider/path_provider.dart'; // To save temp image

class TransactionReceiptScreen extends StatefulWidget {
  final double amount;
  final String planName;
  final DateTime date;

  const TransactionReceiptScreen({
    super.key,
    required this.amount,
    required this.planName,
    required this.date,
  });

  @override
  State<TransactionReceiptScreen> createState() => _TransactionReceiptScreenState();
}

class _TransactionReceiptScreenState extends State<TransactionReceiptScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  Future<void> _shareReceipt() async {
    setState(() => _isSharing = true); // Show loading state if needed

    try {
      // 1. Capture the widget invisible to user (or the visible one)
      // We capture the visible card context for WYSIWYG
      final Uint8List? imageBytes = await _screenshotController.capture();

      if (imageBytes != null) {
        // 2. Save to temp file
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/korra_receipt.png').create();
        await imagePath.writeAsBytes(imageBytes);

        // 3. Share
        await Share.shareXFiles([XFile(imagePath.path)], text: 'Transaction Receipt for ${widget.planName}');
      }
    } catch (e) {
      debugPrint("Share Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not generate receipt image")));
    } finally {
      setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7), // Grey background sets the stage
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4F7),
        elevation: 0,
        leading: CloseButton(color: Colors.black, onPressed: () => Navigator.pop(context)),
        title: Text("Transaction Receipt", style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 16.sp)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            children: [
              // --- THE RECEIPT CARD (CAPTURED WIDGET) ---
              Screenshot(
                controller: _screenshotController,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r), // Smooth modern corners
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8))
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Korra Logo Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Replace with Image.asset('assets/korra_logo.png')
                          Icon(Icons.flash_on_rounded, color: const Color(0xFFA54600), size: 24.sp), 
                          SizedBox(width: 6.w),
                          Text("Korra", style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800, color: const Color(0xFFA54600), letterSpacing: -0.5)),
                        ],
                      ),
                      SizedBox(height: 32.h),

                      // 2. Success Animation Placeholder
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(color: const Color(0xFFECFDF5), shape: BoxShape.circle),
                        child: Icon(Icons.check_rounded, color: const Color(0xFF059669), size: 40.sp),
                      ),
                      SizedBox(height: 16.h),
                      Text("Payment Successful", style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w600, color: const Color(0xFF101828))),
                      SizedBox(height: 8.h),
                      Text(
                        "₦${NumberFormat("#,##0.00").format(widget.amount)}", 
                        style: GoogleFonts.inter(fontSize: 32.sp, fontWeight: FontWeight.w800, color: const Color(0xFF101828), letterSpacing: -1)
                      ),
                      
                      SizedBox(height: 32.h),
                      const Divider(color: Color(0xFFEAECF0), thickness: 1),
                      SizedBox(height: 32.h),
                      
                      // 3. Details Grid
                      _infoRow("Beneficiary", widget.planName),
                      SizedBox(height: 16.h),
                      _infoRow("Date", DateFormat('MMM d, yyyy').format(widget.date)),
                      SizedBox(height: 16.h),
                      _infoRow("Time", DateFormat('h:mm a').format(widget.date)),
                      SizedBox(height: 16.h),
                      _infoRow("Reference", "TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}"),
                      SizedBox(height: 16.h),
                      _infoRow("Status", "Successful", color: const Color(0xFF059669)),

                      SizedBox(height: 40.h),

                      // 4. Security Footer (Inside Receipt)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: const Color(0xFFF2F4F7)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 12.sp, color: Colors.grey),
                            SizedBox(width: 6.w),
                            Text("Secured by ", style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade600)),
                            // Monnify Text Logo
                            Text("Monnify", style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w800, color: const Color(0xFF003366))),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),

              SizedBox(height: 32.h),

              // --- ACTION BUTTONS (Outside Screenshot) ---
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: FilledButton.icon(
                  onPressed: _isSharing ? null : _shareReceipt,
                  icon: _isSharing 
                    ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                  label: Text(_isSharing ? "Generating..." : "Share Receipt", style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFA54600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    elevation: 0,
                  ),
                ),
              ),
              
              SizedBox(height: 16.h),
              
              TextButton(
                onPressed: () {
                  // Navigate to Report Issue
                },
                child: Text("Report an issue", style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: const Color(0xFF667085), fontSize: 14.sp)),
        SizedBox(width: 24.w),
        Expanded(
          child: Text(
            value, 
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              color: color ?? const Color(0xFF101828), 
              fontSize: 14.sp, 
              fontWeight: FontWeight.w600
            ),
          ),
        ),
      ],
    );
  }
}