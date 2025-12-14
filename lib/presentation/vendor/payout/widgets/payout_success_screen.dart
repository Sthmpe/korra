import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'korra_button.dart';



class PayoutSuccessScreen extends StatefulWidget {
  final double amount;
  final String reference;
  final String bankName;
  final String accountNumber;
  final String accountName;

  const PayoutSuccessScreen({
    super.key,
    required this.amount,
    required this.reference,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
  });

  @override
  State<PayoutSuccessScreen> createState() => _PayoutSuccessScreenState();
}

class _PayoutSuccessScreenState extends State<PayoutSuccessScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact(); // Premium feel on entry
  }

  Future<void> _shareReceipt() async {
    setState(() => _isSharing = true);
    try {
      // 1. Capture the receipt widget
      final Uint8List imageBytes = await _screenshotController.captureFromWidget(
        _buildReceiptForExport(), // We render a specific clean version for the image
        delay: const Duration(milliseconds: 10),
        pixelRatio: 2.0, // High Res
      );

      // 2. Save and Share
      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/korra_payout_${widget.reference}.png').create();
      await imagePath.writeAsBytes(imageBytes as List<int>);

      await Share.shareXFiles(
        [XFile(imagePath.path)], 
        text: 'Payout Receipt - ₦${NumberFormat("#,##0.00").format(widget.amount)}'
      );
    } catch (e) {
      Get.snackbar("Error", "Could not share receipt");
    } finally {
      setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            children: [
              SizedBox(height: 20.h),
              
              // 1. Success Animation
              SizedBox(
                height: 120.h,
                width: 120.w,
                // Using a green check lottie. Replace URL if needed.
                child: Lottie.network(
                  'https://assets10.lottiefiles.com/packages/lf20_u4yrau.json',
                  repeat: false,
                ),
              ),
              
              SizedBox(height: 24.h),

              Text(
                "Withdrawal Successful",
                style: GoogleFonts.inter(fontSize: 22.sp, fontWeight: FontWeight.w800, color: const Color(0xFF101828)),
              ),
              SizedBox(height: 8.h),
              Text(
                "Funds successfully sent to ${widget.bankName}",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF667085)),
              ),

              SizedBox(height: 40.h),

              // 2. The Receipt Card (Visible UI)
              Container(
                padding: EdgeInsets.all(24.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: const Color(0xFFEAECF0)),
                ),
                child: Column(
                  children: [
                    Text("Amount Withdrawn", style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF667085), fontWeight: FontWeight.w600)),
                    SizedBox(height: 8.h),
                    Text(
                      "₦${NumberFormat("#,##0.00").format(widget.amount)}",
                      style: GoogleFonts.inter(fontSize: 32.sp, fontWeight: FontWeight.w800, color: const Color(0xFF101828), letterSpacing: -1),
                    ),
                    SizedBox(height: 24.h),
                    const Divider(color: Color(0xFFEAECF0)),
                    SizedBox(height: 24.h),
                    
                    _infoRow("Bank", widget.bankName),
                    SizedBox(height: 16.h),
                    _infoRow("Account", widget.accountNumber),
                    SizedBox(height: 16.h),
                    _infoRow("Name", widget.accountName), // Optional: Truncate if long
                    SizedBox(height: 16.h),
                    _infoRow("Reference", widget.reference, isMono: true),
                    SizedBox(height: 16.h),
                    _infoRow("Date", DateFormat('MMM d, y:mm a').format(DateTime.now())),
                  ],
                ),
              ),

              SizedBox(height: 40.h),

              // 3. Actions
              Row(
                children: [
                  // Share Button
                  Expanded(
                    child: SizedBox(
                      height: 54.h,
                      child: OutlinedButton(
                        onPressed: _isSharing ? null : _shareReceipt,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD0D5DD)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        ),
                        child: _isSharing 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Iconsax.export_1, size: 20, color: Color(0xFF344054)),
                                SizedBox(width: 8.w),
                                Text("Share", style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w600, color: const Color(0xFF344054))),
                              ],
                            ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  
                  // Done Button
                  Expanded(
                    child: KorraButton(
                      text: "Done",
                      onPressed: () {
                        Get.close(2); // Closes PayoutScreen + SuccessScreen
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _infoRow(String label, String value, {bool isMono = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: const Color(0xFF667085), fontSize: 14.sp)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              color: const Color(0xFF101828), 
              fontSize: 14.sp, 
              fontWeight: FontWeight.w600,
              fontFeatures: isMono ? [const FontFeature.tabularFigures()] : null,
            ),
          ),
        ),
      ],
    );
  }

  // --- RECEIPT IMAGE GENERATOR (Clean version for Sharing) ---
  Widget _buildReceiptForExport() {
    return Container(
      color: Colors.white, // White background for the image
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flash_on_rounded, color: const Color(0xFFA54600), size: 30),
              const SizedBox(width: 8),
              Text("Korra", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFFA54600))),
            ],
          ),
          const SizedBox(height: 40),
          Text("Payout Successful", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
          const SizedBox(height: 10),
          Text(
            "₦${NumberFormat("#,##0.00").format(widget.amount)}",
            style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.black),
          ),
          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 40),
          _infoRow("Beneficiary", widget.accountName),
          const SizedBox(height: 20),
          _infoRow("Bank", widget.bankName),
          const SizedBox(height: 20),
          _infoRow("Account Number", widget.accountNumber),
          const SizedBox(height: 20),
          _infoRow("Reference", widget.reference),
          const SizedBox(height: 20),
          _infoRow("Date", DateFormat('MMM d, y - h:mm a').format(DateTime.now())),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Text("Secured by Monnify", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }
}