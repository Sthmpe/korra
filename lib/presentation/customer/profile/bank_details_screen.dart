import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:korra/data/models/customer/customer_ui_extentsion.dart';
import 'package:korra/data/repository/customer/customer_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:monnify_payment_sdk/monnify_payment_sdk.dart'; // 🚀 MONNIFY SDK
import 'package:share_plus/share_plus.dart';

import '../../../../data/models/customer/customer_model.dart';
import '../../../logic/bloc/customer/kyc/customer_kyc_bloc.dart';
//import '../../../logic/bloc/customer/wallet/customer_wallet_cubit.dart';
//import '../../shared/components/custom_bottom_sheet.dart';
//import '../../shared/components/custom_button.dart';
//import '../../shared/components/custom_snackbar.dart';
import 'monnify_web_helper.dart';
import '../../shared/widgets/korra_header.dart';
import '../../shared/widgets/show_app_snackbar.dart';
import 'widgets/kyc_verification_sheet.dart';

class BankDetailsScreen extends StatefulWidget {
  final Customer customer;

  const BankDetailsScreen({super.key, required this.customer});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  static const _brand = Color(0xFFA54600);
  static const _stroke = Color(0xFFEAE6E2);

  final TextEditingController _amountController = TextEditingController();
  Monnify? monnify;
  bool _isInitializingSDK = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (mounted) {
        _initMonnify();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // 🚀 INITIALIZE MONNIFY SDK
  void _initMonnify() async {
    // On Web, skip native SDK initialization completely
    if (kIsWeb) {
      setState(() => _isInitializingSDK = false);
      return;
    }

    // 1. Read IS_LIVE securely from the terminal command (--dart-define)
    // It defaults to false if you forget to pass the flag.
    const bool isLive = bool.fromEnvironment('IS_LIVE', defaultValue: false);
    debugPrint("Monnifyintialling...\n");

    // 2. Dynamically fetch the correct keys from the .env file
    final String? apiKey = isLive 
        ? dotenv.env['MONNIFY_API_KEY_LIVE'] 
        : dotenv.env['MONNIFY_API_KEY_TEST'];
        
    final String? contractCode = isLive 
        ? dotenv.env['MONNIFY_CONTRACT_CODE_LIVE'] 
        : dotenv.env['MONNIFY_CONTRACT_CODE_TEST'];

    // 3. Safety Check
    if (apiKey == null || contractCode == null || apiKey.isEmpty || contractCode.isEmpty) {
      log("CRITICAL ERROR: Monnify keys not found in .env file.");
      setState(() => _isInitializingSDK = false);
      return;
    }

    // 4. Initialize the SDK
    try {
      monnify = await Monnify.initialize(
        applicationMode: isLive ? ApplicationMode.LIVE : ApplicationMode.TEST,
        apiKey: apiKey,
        contractCode: contractCode,
      );
      debugPrint("Monnify: $monnify\n");
      setState(() => _isInitializingSDK = false);
    } catch (e) {
      log("Monnify Init Error: $e");
      setState(() => _isInitializingSDK = false);
    }
  }

  // 🚀 TRIGGER ONE-TIME FUNDING VIA SDK
  void _processInstantTopUp() async {
    final amountText = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountText) ?? 0;

    if (amount < 100) {
      showAppSnackbar("Minimum deposit is ₦100", SnackbarType.error);
      return;
    }

    final shortUid = widget.customer.uid.substring(0, 4).toUpperCase();
    final paymentReference = 'KORRA-FUND-$shortUid-${DateTime.now().millisecondsSinceEpoch}';

    // 🚀 WEB SDK FLOW (Using script tag iframe modal)
    if (kIsWeb) {
      FocusScope.of(context).unfocus();
      setState(() => _isInitializingSDK = true);

      // 1. Read IS_LIVE securely from the terminal command (--dart-define)
      const bool isLive = bool.fromEnvironment('IS_LIVE', defaultValue: false);

      // 2. Dynamically fetch the correct keys from the .env file
      final String? apiKey = isLive 
          ? dotenv.env['MONNIFY_API_KEY_LIVE'] 
          : dotenv.env['MONNIFY_API_KEY_TEST'];
          
      final String? contractCode = isLive 
          ? dotenv.env['MONNIFY_CONTRACT_CODE_LIVE'] 
          : dotenv.env['MONNIFY_CONTRACT_CODE_TEST'];

      if (apiKey == null || contractCode == null || apiKey.isEmpty || contractCode.isEmpty) {
        showAppSnackbar("Payment keys missing. Please contact support.", SnackbarType.error);
        setState(() => _isInitializingSDK = false);
        return;
      }

      try {
        initializeMonnifyWeb(
          amount: amount,
          apiKey: apiKey,
          contractCode: contractCode,
          paymentReference: paymentReference,
          email: widget.customer.email.isNotEmpty ? widget.customer.email : 'hello@korra.com.ng',
          name: widget.customer.displayName.isNotEmpty 
              ? widget.customer.displayName 
              : '${widget.customer.firstName} ${widget.customer.lastName}'.trim(),
          uid: widget.customer.uid,
          onComplete: () {
            showAppSnackbar("Deposit Initiated! Your wallet will be updated shortly.", SnackbarType.success);
            _amountController.clear();
          },
          onClose: () {
            debugPrint("Monnify JS SDK modal closed.");
          },
        );
        setState(() => _isInitializingSDK = false);
      } catch (e) {
        setState(() => _isInitializingSDK = false);
        log('Web Monnify JS SDK Error: $e');
        showAppSnackbar("Payment failed to initialize: $e", SnackbarType.error);
      }
      return;
    }

    // 🚀 MOBILE SDK FLOW
    if (monnify == null) {
      showAppSnackbar("Payment system not ready. Please try again.", SnackbarType.error);
      return;
    }

    FocusScope.of(context).unfocus(); // Close keyboard

    final transaction = TransactionDetails().copyWith(
      amount: amount,
      currencyCode: 'NGN',
      customerName: widget.customer.displayName.isNotEmpty ? widget.customer.displayName : 'Korra Guest',
      customerEmail: widget.customer.email.isNotEmpty ? widget.customer.email : 'hello@korra.com.ng',
      paymentReference: paymentReference,
      metaData: {
        "customerUid": widget.customer.uid 
      },
    );

    try {
      final response = await monnify?.initializePayment(transaction: transaction);
      
      if (response != null && (response.transactionStatus == 'PAID' || response.transactionStatus == 'SUCCESS')) {
        showAppSnackbar("Deposit Initiated! Your wallet will be updated shortly.", SnackbarType.success);
        _amountController.clear();
      } else {
        showAppSnackbar("Transaction was not completed.", SnackbarType.info);
      }
    } catch (e) {
      log('Monnify Error: $e');
      showAppSnackbar("Payment failed: $e", SnackbarType.error);
    }
  }

  void _copyToClipboard(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    HapticFeedback.lightImpact();
    showAppSnackbar("$label copied to clipboard", SnackbarType.success);
  }

  void _shareDetails() {
    final text = 
      "Here are my Korra Wallet details:\n\n"
      "Bank: ${widget.customer.bankName}\n"
      "Account Number: ${widget.customer.accountNumber}\n"
      "Name: ${widget.customer.accountName}\n\n"
      "Transfers to this account instantly top up my Korra wallet.";
    
    Share.share(text);
  }

  void _openKycSheet(BuildContext context) {
    final repo = context.read<CustomerRepository>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider(
        create: (blocContext) => CustomerKycBloc(
          repo: repo, 
          customerUid: widget.customer.uid,
        ),
        child: KycVerificationSheet(
          onVerificationComplete: (String verifiedBvn, String verifiedNin) async {
            final navigator = Navigator.of(context, rootNavigator: true);

            showDialog(
              context: context, 
              barrierDismissible: false,
              builder: (dialogContext) => Center(
                child: Container(
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: _brand),
                      SizedBox(height: 16.h),
                      Text("Generating Wallet...", style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600))
                    ],
                  ),
                ),
              ),
            );
        
            try {
              await repo.createReserveAccount(
                uid: widget.customer.uid,
                email: widget.customer.email,
                firstName: widget.customer.firstName,
                lastName: widget.customer.lastName,
                bvn: verifiedBvn,
                nin: verifiedNin,
              );
              navigator.pop(); 
              showAppSnackbar("Wallet activated successfully!", SnackbarType.success);
            } catch (e) {
              navigator.pop(); 
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
    final bool hasAccount = widget.customer.accountNumber != null && widget.customer.accountNumber!.isNotEmpty;

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
              style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 1.0),
            ),
            SizedBox(height: 8.h),
            Text(
              widget.customer.formattedBalance,
              style: GoogleFonts.inter(fontSize: 32.sp, fontWeight: FontWeight.w800, color: const Color(0xFF101828), letterSpacing: -1.0),
            ),

            SizedBox(height: 32.h),

            if (!hasAccount) ...[
              _buildInstantTopUpCard(),

              SizedBox(height: 32.h),

              Row(
                children: [
                  Expanded(child: Divider(color: _stroke.withOpacity(0.5))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Text("OR", style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade400)),
                  ),
                  Expanded(child: Divider(color: _stroke.withOpacity(0.5))),
                ],
              ),

              SizedBox(height: 32.h),

              Text(
                "PERMANENT ACCOUNT",
                style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 1.0),
              ),
              SizedBox(height: 12.h),
              _buildSetupAccountCard(context),

            ] else ...[
              // --- PERMANENT USER VIEW (Clean, Bank-Only UI) ---
              Text(
                "YOUR ACCOUNT DETAILS",
                style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 1.0),
              ),
              SizedBox(height: 12.h),
              _buildActiveAccountCard(context),
            ],

            SizedBox(height: 24.h),

            // INFO BOX
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12.r)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: _brand, size: 20.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      hasAccount 
                        ? "Transfers to your dedicated account are automatically credited to your Korra Wallet instantly."
                        : "You need a dedicated Korra account to fund your wallet via regular bank transfer. Verify your identity to unlock it.",
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

  // 🚀 THE NEW MONNIFY SDK CARD
  Widget _buildInstantTopUpCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _stroke.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8.r)),
                child: Icon(Icons.flash_on_rounded, color: Colors.green.shade600, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Text("Instant Top-Up", style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: const Color(0xFF101828))),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            "Fund your wallet instantly using your debit card or a temporary bank transfer.",
            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade500, height: 1.4),
          ),
          SizedBox(height: 24.h),
          
          // Amount Input
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: GoogleFonts.plusJakartaSans(fontSize: 24.sp, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              prefixText: "₦ ",
              prefixStyle: GoogleFonts.plusJakartaSans(fontSize: 24.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade400),
              hintText: "0.00",
              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 24.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade300),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: _stroke.withOpacity(0.5))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: _brand)),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Trigger Button
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: FilledButton(
              onPressed: _isInitializingSDK ? null : _processInstantTopUp,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF101828), // Dark button to contrast with brand color
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: _isInitializingSDK
                ? SizedBox(height: 20.h, width: 20.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text("Pay with Card / Transfer", style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // --- EXISTING SETUP ACCOUNT CARD ---
  Widget _buildSetupAccountCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _stroke.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(color: _brand.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.shield_rounded, color: _brand, size: 32.sp),
          ),
          SizedBox(height: 16.h),
          Text("Activate Wallet Account", style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: const Color(0xFF101828))),
          SizedBox(height: 8.h),
          Text(
            "To unlock your permanent funding account, we need to verify your identity to comply with CBN regulations.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey.shade600, height: 1.5),
          ),
          SizedBox(height: 32.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: () => _openKycSheet(context),
              style: ElevatedButton.styleFrom(backgroundColor: _brand, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
              child: Text("Verify Identity", style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // --- EXISTING ACTIVE ACCOUNT CARD ---
  Widget _buildActiveAccountCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _stroke.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
            child: Icon(Icons.account_balance_rounded, color: Colors.blue.shade700, size: 28.sp),
          ),
          SizedBox(height: 16.h),
          Text("Your Korra Account", style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: () => _copyToClipboard(context, widget.customer.accountNumber ?? "", "Account Number"),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.customer.accountNumber!, style: GoogleFonts.inter(fontSize: 28.sp, fontWeight: FontWeight.w800, color: const Color(0xFF101828), letterSpacing: 2.0)),
                SizedBox(width: 12.w),
                Icon(Icons.copy_rounded, size: 20.sp, color: _brand),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          const Divider(height: 1, color: _stroke),
          SizedBox(height: 24.h),
          _detailRow("Bank Name", widget.customer.bankName ?? "Monnify"),
          SizedBox(height: 16.h),
          _detailRow("Account Name", widget.customer.accountName ?? widget.customer.displayName),
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