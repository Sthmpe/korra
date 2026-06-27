// lib/presentation/vendor/payout/payout_settings_screen.dart
//
// Payout Settings — dedicated screen for managing the auto-payout account.
// Completely separate from the withdraw flow.
// Saves to: vendors/{uid}/settings/auto_payout_details  (subcollection, same pattern as payout_details)
//
// PIN logic mirrors the withdraw flow exactly:
//   • No PIN yet  → TransactionPinSheet(isCreating: true)  → create_pin → save account
//   • PIN exists  → TransactionPinSheet(isCreating: false) → verify_pin → save account

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:korra/data/repository/vendors/bank_repository.dart';
import 'package:korra/data/repository/vendors/pin_repository.dart';

import '../../../../config/constants/colors.dart';
import '../../../../data/models/vendor/vendor_setting.dart';
import '../../../../data/repository/vendors/vendor_repository.dart';
import '../../../../logic/bloc/vendor/payout/bank.dart';
import '../../shared/widgets/korra_header.dart';
import '../../shared/widgets/show_app_snackbar.dart';
import '../payout/widgets/bank_selector_sheet.dart';
import '../payout/widgets/korra_button.dart';
import '../payout/widgets/transaction_pin_sheet.dart';

// ---------------------------------------------------------------------------
// Internal data class
// ---------------------------------------------------------------------------
class _AutoPayoutAccount {
  final String bankName;
  final String bankCode;
  final String accountNumber;
  final String accountName;

  const _AutoPayoutAccount({
    required this.bankName,
    required this.bankCode,
    required this.accountNumber,
    required this.accountName,
  });

  const _AutoPayoutAccount.empty()
      : bankName = '',
        bankCode = '',
        accountNumber = '',
        accountName = '';

  bool get isEmpty => accountNumber.isEmpty;

  String get maskedNumber {
    if (accountNumber.length < 4) return accountNumber;
    return '•••• ${accountNumber.substring(accountNumber.length - 4)}';
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class PayoutSettingsScreen extends StatefulWidget {
  final String vendorUid;

  const PayoutSettingsScreen({
    super.key,
    required this.vendorUid,
  });

  @override
  State<PayoutSettingsScreen> createState() => _PayoutSettingsScreenState();
}

class _PayoutSettingsScreenState extends State<PayoutSettingsScreen> {
  // ── Load state ─────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _loadError;

  List<Bank> _bankList = [];
  _AutoPayoutAccount _saved = const _AutoPayoutAccount.empty();
  bool _hasPinSet = false;

  // ── Pending (held in memory until PIN confirmed) ───────────────────────────
  Bank? _pendingBank;
  String? _pendingAccountNumber;
  String? _pendingAccountName;

  // ── Save state ─────────────────────────────────────────────────────────────
  bool _isSaving = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  late final VendorRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = context.read<VendorRepository>();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _loadError = null; });
    try {
      final results = await Future.wait([
        _repo.getBankList(),
        _repo.getVendorSettings(widget.vendorUid, forceRefresh: true),
        _loadSavedAccount(),
      ]);

      final settings = results[1] as VendorSettings;

      setState(() {
        _bankList  = results[0] as List<Bank>;
        _hasPinSet = settings.isPinSet;
        _saved     = results[2] as _AutoPayoutAccount;
      });
    } catch (e) {
      setState(() => _loadError = "Could not load details. Check your connection.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<_AutoPayoutAccount> _loadSavedAccount() async {
    final doc = await _repo.firestore
        .collection('vendors')
        .doc(widget.vendorUid)
        .collection('settings')
        .doc('auto_payout_details')
        .get();

    if (!doc.exists || doc.data() == null) return const _AutoPayoutAccount.empty();

    final data = doc.data()!;
    if ((data['accountNumber'] as String? ?? '').isEmpty) return const _AutoPayoutAccount.empty();

    return _AutoPayoutAccount(
      bankName:      data['bankName']      as String? ?? '',
      bankCode:      data['bankCode']      as String? ?? '',
      accountNumber: data['accountNumber'] as String? ?? '',
      accountName:   data['accountName']   as String? ?? '',
    );
  }

  // ── Step 1: Bank selector ──────────────────────────────────────────────────
  void _showBankSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BankSelectorSheet(
        banks: _bankList,
        onValidate: (bankCode, accountNumber) =>
            _repo.verifyBankAccount(
              bankCode: bankCode,
              accountNumber: accountNumber,
            ),
        onConfirm: (bank, accountNumber, accountName) {
          Navigator.pop(context);
          setState(() {
            _pendingBank          = bank;
            _pendingAccountNumber = accountNumber;
            _pendingAccountName   = accountName;
          });
          _showPinSheet();
        },
      ),
    );
  }

  // ── Step 2: PIN gate ───────────────────────────────────────────────────────
  void _showPinSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionPinSheet(
        isCreating: !_hasPinSet,
        onSubmit: (pin) {
          Navigator.pop(context);
          if (!_hasPinSet) {
            _createPinThenSave(pin);
          } else {
            _verifyPinThenSave(pin);
          }
        },
        onCancel: () {
          Navigator.pop(context);
          setState(() {
            _pendingBank          = null;
            _pendingAccountNumber = null;
            _pendingAccountName   = null;
          });
        },
      ),
    );
  }

  // ── Step 3a: No PIN yet → create it ───────────────────────────────────────
  Future<void> _createPinThenSave(String pin) async {
    setState(() => _isSaving = true);
    try {
      await _repo.setTransactionPin(widget.vendorUid, pin);
      setState(() => _hasPinSet = true);
      _repo.cachedSettings = null;
      await _saveAccountToFirestore();
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      final raw = e.toString().replaceAll('Exception:', '').trim();
      showAppSnackbar(_translateError(raw.toLowerCase()), SnackbarType.error);
    }
  }

  // ── Step 3b: PIN exists → verify it ───────────────────────────────────────
  Future<void> _verifyPinThenSave(String pin) async {
    if (_pendingBank == null) return;
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Session expired. Please log in again.");

      final idToken   = await user.getIdToken(true);
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final hmac      = Hmac(sha256, utf8.encode(_repo.korraSecret));
      final signature = hmac.convert(utf8.encode(timestamp)).toString();

      final response = await _repo.fx.invoke(
        'vendor-transaction-ops',
        headers: {
          'x-korra-timestamp': timestamp,
          'x-korra-signature': signature,
          'firebase-token':    'Bearer $idToken',
        },
        body: {
          'type': 'verify_pin',
          'uid':  widget.vendorUid,
          'pin':  pin,
        },
      );

      if (response.data['success'] != true) {
        final serverError = (response.data['error'] as String? ?? '').toLowerCase();
        throw Exception(_translateError(serverError));
      }

      await _saveAccountToFirestore();
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      final raw = e.toString().replaceAll('Exception:', '').trim();
      showAppSnackbar(_translateError(raw.toLowerCase()), SnackbarType.error);
    }
  }

  // ── Error translator ───────────────────────────────────────────────────────
  String _translateError(String raw) {
    if (raw.contains('incorrect pin') || raw.contains('invalid pin') || raw.contains('wrong pin')) {
      return "Incorrect PIN. Please try again.";
    }
    if (raw.contains('pin not set') || raw.contains('no pin')) {
      return "No transaction PIN found. Please make a withdrawal first to set one up.";
    }
    if (raw.contains('session expired') || raw.contains('token') || raw.contains('unauthorized')) {
      return "Session expired. Please log out and log back in.";
    }
    if (raw.contains('socketexception') || raw.contains('network') ||
        raw.contains('connection') || raw.contains('failed host lookup')) {
      return "Connection failed. Check your internet and try again.";
    }
    if (raw.contains('timeout')) {
      return "Request timed out. Please try again.";
    }
    if (raw.contains('signature') || raw.contains('replay')) {
      return "Security check failed. Please try again.";
    }
    if (raw.contains('function') || raw.contains('internal') || raw.contains('500')) {
      return "Server error. Please try again in a moment.";
    }
    return raw.isNotEmpty ? raw : "Something went wrong. Please try again.";
  }

  // ── Step 4: Write to Firestore subcollection ───────────────────────────────
  Future<void> _saveAccountToFirestore() async {
    if (_pendingBank == null ||
        _pendingAccountNumber == null ||
        _pendingAccountName == null) return;

    try {
      await _repo.firestore
          .collection('vendors')
          .doc(widget.vendorUid)
          .collection('settings')
          .doc('auto_payout_details')
          .set({
        'bankName':      _pendingBank!.name,
        'bankCode':      _pendingBank!.code,
        'accountNumber': _pendingAccountNumber!,
        'accountName':   _pendingAccountName!,
        'updatedAt':     FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final newAccount = _AutoPayoutAccount(
        bankName:      _pendingBank!.name,
        bankCode:      _pendingBank!.code,
        accountNumber: _pendingAccountNumber!,
        accountName:   _pendingAccountName!,
      );

      setState(() {
        _saved                = newAccount;
        _pendingBank          = null;
        _pendingAccountNumber = null;
        _pendingAccountName   = null;
        _isSaving             = false;
      });

      if (mounted) showAppSnackbar("Auto-payout account updated.", SnackbarType.success);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) showAppSnackbar("Failed to save. Please try again.", SnackbarType.error);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: KorraHeader(title: "Payout Account", showLeadingIcon: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: KorraColors.brand))
          : _loadError != null
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.wifi_square, size: 48.sp, color: Colors.grey.shade400),
            SizedBox(height: 16.h),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey.shade600),
            ),
            SizedBox(height: 24.h),
            KorraButton(text: "Try Again", onPressed: _load),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "CURRENT PAYOUT ACCOUNT",
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: const Color(0xFF98A2B3),
            ),
          ),
          SizedBox(height: 12.h),

          _buildVaultCard(),

          SizedBox(height: 12.h),

          Row(
            children: [
              Icon(Iconsax.shield_tick, size: 13.sp, color: Colors.grey.shade500),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  _hasPinSet
                      ? "PIN required every time this account is changed."
                      : "You'll create a transaction PIN to secure this account.",
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 40.h),

          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Iconsax.info_circle, size: 18.sp, color: KorraColors.brand),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    "This account receives your automatic settlements. "
                    "It is separate from your quick-withdraw account. "
                    "Never share your PIN with anyone.",
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: const Color(0xFF7A3B00),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 40.h),

          KorraButton(
            text: _saved.isEmpty ? "Add Payout Account" : "Change Account",
            isLoading: _isSaving,
            onPressed: _bankList.isEmpty ? null : _showBankSelector,
          ),

          if (_bankList.isEmpty) ...[
            SizedBox(height: 12.h),
            Center(
              child: Text(
                "Bank list unavailable. Tap to retry.",
                style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
              ),
            ),
          ],

          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildVaultCard() {
    final hasAccount = !_saved.isEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B3A00), Color(0xFFA54600), Color(0xFF5C2600)],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA54600).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0, bottom: -40.h, top: 10,
            child: Icon(
              Iconsax.bank5,
              color: Colors.white.withOpacity(0.08),
              size: 150.sp,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Iconsax.bank5, color: Colors.white, size: 18.sp),
                        SizedBox(width: 8.w),
                        Text(
                          "AUTO-PAYOUT ACCOUNT",
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        hasAccount ? "SECURED" : "NOT SET",
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 28.h),

                if (hasAccount) ...[
                  Text(
                    _saved.bankName.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    _saved.maskedNumber,
                    style: GoogleFonts.inter(
                      fontSize: 26.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _saved.accountName,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: Colors.white.withOpacity(0.75),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else ...[
                  Row(
                    children: [
                      Icon(
                        Iconsax.add_circle,
                        color: Colors.white.withOpacity(0.6),
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "No account linked yet",
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: Colors.white.withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}