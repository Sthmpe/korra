import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui'; // For FontFeature

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

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
      // 1. Capture the VISIBLE screen content inside the Screenshot widget
      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 50),
        pixelRatio: 3.0, // Ultra High Res for sharing
      );

      if (imageBytes == null) throw Exception("Failed to take screenshot");

      // 2. Save to Temp Dir
      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/korra_receipt_${widget.reference}.png').create();
      await imagePath.writeAsBytes(imageBytes);

      // 3. Share
      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: 'Payout Receipt - ₦${NumberFormat("#,##0.00").format(widget.amount)}',
      );
    } catch (e) {
      Get.snackbar(
        "Sharing Failed", 
        "Could not generate receipt image.",
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red,
      );
    } finally {
      setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Cool Grey Background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            children: [
              
              // ✅ WRAP EVERYTHING WE WANT TO SHARE IN THE SCREENSHOT WIDGET
              Screenshot(
                controller: _screenshotController,
                child: Container(
                  // Ensure the background color matches the Scaffold so it looks seamless
                  color: const Color(0xFFF9FAFB), 
                  padding: EdgeInsets.only(top: 20.h, bottom: 20.h),
                  child: Column(
                    children: [
                      // --- 1. ANIMATION & HEADER ---
                      Center(
                        child: SizedBox(
                          height: 120.h, 
                          width: 120.h,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // BACKGROUND SEAL (THE "GEAR TEETH")
                              ...List.generate(3, (index) {
                                return Transform.rotate(
                                  angle: index * (pi / 3), 
                                  child: Container(
                                    height: 85.w,
                                    width: 85.w,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFAE6), // Light Success Green
                                      borderRadius: BorderRadius.circular(18.r), 
                                    ),
                                  ),
                                );
                              }),

                              // FOREGROUND OVERLAY (NATIVE POP ANIMATION)
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.elasticOut,
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      width: 60.w,
                                      height: 60.w,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0x1A079455),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.check_rounded,
                                          size: 40.sp, 
                                          color: const Color(0xFF079455),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        "Withdrawal Successful",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF101828),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "Your funds are sent to your bank.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: const Color(0xFF667085),
                        ),
                      ),

                      SizedBox(height: 32.h),

                      // --- 2. RECEIPT CARD ---
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF101828).withOpacity(0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Total Amount",
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF98A2B3),
                                letterSpacing: 1.0,
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              "₦${NumberFormat("#,##0.00").format(widget.amount)}",
                              style: GoogleFonts.inter(
                                fontSize: 32.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF101828),
                                letterSpacing: -1.5,
                              ),
                            ),
                            SizedBox(height: 24.h),
                            const Divider(color: Color(0xFFEAECF0)),
                            SizedBox(height: 24.h),

                            // Destination Info Box
                            Container(
                              padding: EdgeInsets.all(16.r),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Column(
                                children: [
                                  _infoRow("To", widget.accountName, isBold: true),
                                  SizedBox(height: 12.h),
                                  _infoRow("Bank", widget.bankName),
                                  SizedBox(height: 12.h),
                                  _infoRow("Account", widget.accountNumber),
                                ],
                              ),
                            ),
                            
                            SizedBox(height: 20.h),
                            
                            // Technical Details
                            _infoRow("Reference", widget.reference, isMono: true),
                            SizedBox(height: 12.h),
                            _infoRow("Date", DateFormat('MMM d, y • h:mm a').format(DateTime.now())),

                             SizedBox(height: 24.h),
                             // Secured By Footer
                             Row(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 Icon(Icons.lock, size: 14.sp, color: const Color(0xFF98A2B3)),
                                 SizedBox(width: 6.w),
                                 Text(
                                   "Secured by Monnify",
                                   style: GoogleFonts.inter(
                                     fontSize: 12.sp,
                                     fontWeight: FontWeight.w500,
                                     color: const Color(0xFF98A2B3),
                                   ),
                                 ),
                                 SizedBox(width: 8.w),
                                 Image.asset(
                                   'assets/images/moniepoint-inc-icon.png',
                                   height: 40.h,
                                   fit: BoxFit.contain,
                                 ),
                               ],
                             ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // --- 3. ACTIONS (These are OUTSIDE the screenshot) ---
              Row(
                children: [
                  // Share Button
                  Expanded(
                    child: SizedBox(
                      height: 56.h,
                      child: OutlinedButton(
                        onPressed: _isSharing ? null : _shareReceipt,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD0D5DD)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          backgroundColor: Colors.white,
                        ),
                        child: _isSharing 
                          ? SizedBox(
                              width: 20.h, 
                              height: 20.h, 
                              child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.black)
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Iconsax.export_1, size: 20.sp, color: const Color(0xFF344054)),
                                SizedBox(width: 8.w),
                                Text(
                                  "Share",
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF344054),
                                  ),
                                ),
                              ],
                            ),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 12.w),

                  // Done Button
                  Expanded(
                    child: SizedBox(
                      height: 56.h,
                      child: FilledButton(
                        // ✅ BLANK SCREEN BUG FIXED HERE 
                        onPressed: () => Get.until((route) => route.isFirst),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF101828), // Dark Brand Color
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          elevation: 0,
                        ),
                        child: Text(
                          "Done",
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER: INFO ROW ---
  Widget _infoRow(String label, String value, {bool isMono = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start, // Align to top for long names
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF667085),
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              color: const Color(0xFF101828),
              fontSize: 13.sp,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              // Use monospace features for Reference IDs so letters align
              fontFeatures: isMono ? [const FontFeature.tabularFigures()] : null,
            ),
          ),
        ),
      ],
    );
  }
}