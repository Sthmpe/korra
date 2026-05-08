import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:korra/data/models/customer/customer_ui_extentsion.dart';
import 'package:korra/data/repository/customer/customer_repository.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../data/models/customer/customer_model.dart';
import '../../../logic/bloc/customer/kyc/customer_kyc_bloc.dart';
import '../../shared/widgets/korra_header.dart';
import '../../shared/widgets/show_app_snackbar.dart';
import 'widgets/kyc_verification_sheet.dart';

class BankDetailsScreen extends StatelessWidget {
  final Customer customer;
  final CustomerRepository repo;

  const BankDetailsScreen({super.key, required this.customer, required this.repo});

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

  void _openKycSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider(
        create: (context) => CustomerKycBloc(
          // Grab your verification repo from the main app context
          repo: repo, 
          customerUid: customer.uid,
        ),
        child: KycVerificationSheet(
          onVerificationComplete: (String verifiedBvn, String verifiedNin) async {
            // 1. CAPTURE THE NAVIGATOR BEFORE DOING ANYTHING ASYNC
            final navigator = Navigator.of(context, rootNavigator: true);

            // 2. Show a loading spinner so they know magic is happening
            showDialog(
              context: context, 
              barrierDismissible: false,
              builder: (dialogContext) => Center(
                child: Container(
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: _brand),
                      SizedBox(height: 16.h),
                      Text(
                        "Generating Wallet...",
                        style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600),
                      )
                    ],
                  ),
                ),
              ),
            );
        
            try {
              // Send EVERYTHING to the repo
              await repo.createReserveAccount(
                uid: customer.uid,
                email: customer.email,
                firstName: customer.firstName,
                lastName: customer.lastName,
                bvn: verifiedBvn,
                nin: verifiedNin,
              );
        
              // 🚀 3. USE THE SAVED NAVIGATOR TO POP (Ignores context.mounted issues)
              navigator.pop(); 
        
              // Show success message
              showAppSnackbar("Wallet activated successfully!", SnackbarType.success);
        
            } catch (e) {
              // 🚀 4. USE THE SAVED NAVIGATOR TO POP ON ERROR TOO
              navigator.pop(); 
              
              // Clean up the error message if it's a KorraException
              final errorMsg = e.toString().replaceAll('Exception:', '').trim();
              showAppSnackbar("Failed to create wallet: $errorMsg", SnackbarType.error);
            }
          }
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 THE CHECK: Does the user have a permanent account?
    final bool hasAccount = customer.accountNumber != null && customer.accountNumber!.isNotEmpty;

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

            // 2. DYNAMIC CONTENT AREA
            if (hasAccount) 
              _buildActiveAccountCard(context)
            else 
              _buildSetupAccountCard(context),

            SizedBox(height: 24.h),

            // 3. INFO BOX
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED), 
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: _brand, size: 20.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      hasAccount 
                        ? "This account is unique to you. Any money transferred here will automatically appear in your Wallet Balance instantly."
                        : "You need a dedicated Korra account to fund your wallet. This ensures your money is always safe and instantly credited.",
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

  // --- THE "NO ACCOUNT" UI ---
  Widget _buildSetupAccountCard(BuildContext context) {
    return Container(
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
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(color: _brand.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.shield_rounded, color: _brand, size: 32.sp),
          ),
          SizedBox(height: 16.h),
          Text(
            "Activate Wallet Account",
            style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: const Color(0xFF101828)),
          ),
          SizedBox(height: 8.h),
          Text(
            "To unlock your permanent funding account, we need to verify your identity to comply with CBN regulations.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey.shade600, height: 1.5),
          ),
          SizedBox(height: 32.h),
          
          // TRIGGER THE KYC SHEET
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: () => _openKycSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brand,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Text(
                "Verify Identity",
                style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- THE EXISTING ACCOUNT DETAILS UI ---
  Widget _buildActiveAccountCard(BuildContext context) {
    return Container(
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
            decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
            child: Icon(Icons.account_balance_rounded, color: Colors.blue.shade700, size: 28.sp),
          ),
          SizedBox(height: 16.h),
          Text(
            "Your Korra Account",
            style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
          ),
          SizedBox(height: 8.h),
          
          GestureDetector(
            onTap: () => _copyToClipboard(context, customer.accountNumber ?? "", "Account Number"),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  customer.accountNumber!,
                  style: GoogleFonts.inter(fontSize: 28.sp, fontWeight: FontWeight.w800, color: const Color(0xFF101828), letterSpacing: 2.0),
                ),
                SizedBox(width: 12.w),
                Icon(Icons.copy_rounded, size: 20.sp, color: _brand),
              ],
            ),
          ),

          SizedBox(height: 24.h),
          const Divider(height: 1, color: _stroke),
          SizedBox(height: 24.h),

          _detailRow("Bank Name", customer.bankName ?? "Monnify"),
          SizedBox(height: 16.h),
          _detailRow("Account Name", customer.accountName ?? customer.displayName),
          
          SizedBox(height: 32.h),

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
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        Text(value, style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF101828), fontWeight: FontWeight.w600)),
      ],
    );
  }
}