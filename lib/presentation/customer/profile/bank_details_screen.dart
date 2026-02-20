import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:korra/data/models/customer/customer_ui_extentsion.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../data/models/customer/customer_model.dart';
import '../../shared/widgets/korra_header.dart';
import '../../shared/widgets/show_app_snackbar.dart';

class BankDetailsScreen extends StatelessWidget {
  final Customer customer;

  const BankDetailsScreen({super.key, required this.customer});

  static const _brand = Color(0xFFA54600);
  static const _stroke = Color(0xFFEAE6E2);

  void _copyToClipboard(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    HapticFeedback.lightImpact();
    showAppSnackbar("$label copied to clipboard", SnackbarType.success);
  }

  void _shareDetails() {
    final text = 
      "Here are my Korra Wallet details:\n\n"
      "Bank: ${customer.bankName}\n"
      "Account Number: ${customer.accountNumber}\n"
      "Name: ${customer.accountName}\n\n"
      "Transfers to this account instantly top up my Korra wallet.";
    
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const KorraHeader(title: "Bank Details", showLeadingIcon: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CURRENT BALANCE HEADER
            Text(
              "CURRENT BALANCE",
              style: GoogleFonts.inter(
                fontSize: 11.sp, 
                fontWeight: FontWeight.w700, 
                color: Colors.grey.shade500,
                letterSpacing: 1.0
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              customer.formattedBalance,
              style: GoogleFonts.inter(
                fontSize: 32.sp, 
                fontWeight: FontWeight.w800, 
                color: const Color(0xFF101828),
                letterSpacing: -1.0
              ),
            ),

            SizedBox(height: 32.h),

            // 2. THE VIRTUAL ACCOUNT CARD
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: _stroke.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.account_balance_rounded, color: Colors.blue.shade700, size: 28.sp),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    "Your Korra Account",
                    style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 8.h),
                  
                  // THE BIG NUMBER
                  GestureDetector(
                    onTap: () => _copyToClipboard(context, customer.accountNumber ?? "", "Account Number"),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          customer.accountNumber ?? "Generating...",
                          style: GoogleFonts.inter(
                            fontSize: 28.sp, 
                            fontWeight: FontWeight.w800, 
                            color: const Color(0xFF101828),
                            letterSpacing: 2.0 // Monospace-ish look
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Icon(Icons.copy_rounded, size: 20.sp, color: _brand),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),
                  const Divider(height: 1, color: _stroke),
                  SizedBox(height: 24.h),

                  // DETAILS GRID
                  _detailRow("Bank Name", customer.bankName ?? "Monnify"),
                  SizedBox(height: 16.h),
                  _detailRow("Account Name", customer.accountName ?? customer.displayName),
                  
                  SizedBox(height: 32.h),

                  // SHARE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: OutlinedButton.icon(
                      onPressed: _shareDetails,
                      icon: Icon(Icons.share_rounded, size: 18.sp),
                      label: Text("Share Account Details", style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF344054),
                        side: BorderSide(color: _stroke.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                    ),
                  )
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // 3. INFO BOX
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED), // Light orange background
                borderRadius: BorderRadius.circular(12.r),
                //border: Border.all(color: const Color(0xFFFFE4C2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: _brand, size: 20.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      "This account is unique to you. Any money transferred here will automatically appear in your Wallet Balance instantly.",
                      style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF7C2D12), height: 1.4),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF101828), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}