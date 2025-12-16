import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../config/constants/colors.dart';
import '../../data/models/customer/customer_model.dart';
import '../shared/widgets/korra_header.dart';

class TopUpScreen extends StatelessWidget {
  final Customer? customer;
  const TopUpScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final map = customer?.toMap() ?? {};
    final monnify = map['monnify'] ?? {};
    
    final bankName = monnify['bankName'] ?? 'Wema Bank';
    final accountNumber = monnify['accountNumber'] ?? '0000000000';
    final accountName = monnify['accountName'] ?? 'Korra User';

    return Scaffold(
      backgroundColor: Colors.white,
      // Allow resizing so content moves up when keyboard shows
      resizeToAvoidBottomInset: true, 
      appBar: KorraHeader(
        title: 'Top-Up Wallet',
        showLeadingIcon: true,
        onBackpressed: () => Get.back(),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(height: 24.h),
                      
                      // --- 1. THE HERO CARD (Premium Dark Style) ---
                      _BankDetailsCard(
                        bankName: bankName,
                        accountNumber: accountNumber,
                        accountName: accountName,
                      ),

                      SizedBox(height: 32.h),

                      // --- 2. FEE CALCULATOR ---
                     // const _FeeCalculatorSection(),

                      SizedBox(height: 24.h),

                      // --- 3. INSTANT REFLECTION NOTE ---
                      _InfoNote(
                        icon: Iconsax.flash_1,
                        title: "Instant Reflection",
                        message: "Funds transferred to this account reflect instantly. You can start transacting immediately after transfer.",
                        color: KorraColors.brand,
                      ),
                      
                      const Spacer(), // Pushes button to bottom if space allows
                      
                      SizedBox(height: 40.h),

                      // --- BOTTOM BUTTON ---
                      SizedBox(
                        width: double.infinity,
                        height: 54.h,
                        child: ElevatedButton(
                          onPressed: () => Get.back(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                          ),
                          child: Text(
                            "I've made the transfer", 
                            style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w600)
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. FEE CALCULATOR WIDGET
// -----------------------------------------------------------------------------
class _FeeCalculatorSection extends StatefulWidget {
  const _FeeCalculatorSection();

  @override
  State<_FeeCalculatorSection> createState() => _FeeCalculatorSectionState();
}

class _FeeCalculatorSectionState extends State<_FeeCalculatorSection> {
  final _ctrl = TextEditingController();
  double _youGet = 0.0;
  double _fee = 0.0;
  final _fmt = NumberFormat("#,##0.##", "en_US");

  void _calculate(String val) {
    // Remove commas to parse
    String clean = val.replaceAll(',', '');
    
    if (clean.isEmpty || clean == '.') {
      setState(() { _youGet = 0; _fee = 0; });
      return;
    }

    double amount = double.tryParse(clean) ?? 0;
    
    // --- LOGIC: 3% Capped at 4000 ---
    double calculatedFee = amount * 0.03;
    if (calculatedFee > 4000) calculatedFee = 4000;

    setState(() {
      _fee = calculatedFee;
      _youGet = amount - calculatedFee;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Fee Calculator",
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B1B1B),
          ),
        ),
        SizedBox(height: 12.h),
        
        // INPUT FIELD
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7), // iOS Input Grey
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              Text("₦", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18.sp, color: Colors.grey.shade500)),
              SizedBox(width: 12.w),
              Expanded(
                child: TextField(
                  cursorColor: Colors.grey.shade300,
                  controller: _ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(15),
                    CurrencyInputFormatter(), // <--- Custom Formatter
                  ],
                  onChanged: _calculate,
                  style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.black),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 14.h),
                    hintText: "0.00",
                    hintStyle: GoogleFonts.inter(fontSize: 18.sp, color: Colors.grey.shade400),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),

        // RESULT & FEE NOTE
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: _youGet > 0 
            ? Padding(
                padding: EdgeInsets.only(top: 16.h),
                child: Column(
                  children: [
                    // The Math
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: const Color(0xFFEAE6E2)),
                      ),
                      child: Column(
                        children: [
                          _RowItem(label: "Service Fee (3%)", value: "-₦${_fmt.format(_fee)}", isFee: true),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            child: const Divider(height: 1, color: Color(0xFFF0F0F0)),
                          ),
                          _RowItem(label: "Amount to Wallet", value: "₦${_fmt.format(_youGet)}", isBold: true),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 16.h),

                    // The Fee Explanation Note (Styled like Instant Reflection)
                    const _InfoNote(
                      icon: Iconsax.info_circle,
                      title: "About Fees",
                      message: "A 3% processing fee is charged by our payment partner, capped at ₦4,000. We do not keep this fee.",
                      color: Colors.blueGrey, // Distinct color
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 2. REUSABLE INFO NOTE (Premium Style)
// -----------------------------------------------------------------------------
class _InfoNote extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _InfoNote({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), // Soft background
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: color, size: 20.sp),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14.sp, 
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B1B1B)
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 12.5.sp, 
                  height: 1.4,
                  color: Colors.grey.shade600
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 3. ROW ITEM (For Calculator)
// -----------------------------------------------------------------------------
class _RowItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isFee;
  final bool isBold;

  const _RowItem({
    required this.label, 
    required this.value, 
    this.isFee = false, 
    this.isBold = false
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label, 
          style: GoogleFonts.inter(
            fontSize: 13.sp, 
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500
          )
        ),
        Text(
          value, 
          style: GoogleFonts.inter(
            fontSize: 14.sp, 
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, 
            color: isFee ? Colors.red.shade600 : (isBold ? Colors.green.shade700 : Colors.black)
          )
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 4. SMART CURRENCY FORMATTER (Logic)
// -----------------------------------------------------------------------------
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');

    String clean = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');
    
    // Prevent multiple dots
    if (clean.indexOf('.') != clean.lastIndexOf('.')) return oldValue; 

    List<String> parts = clean.split('.');
    String integerPart = parts[0];
    String? decimalPart = parts.length > 1 ? parts[1] : null;

    if (integerPart.isNotEmpty) {
      final formatter = NumberFormat("#,###");
      try {
        integerPart = formatter.format(int.parse(integerPart));
      } catch (e) {}
    }

    String newText = integerPart;
    if (parts.length > 1 || clean.endsWith('.')) {
      newText += '.${decimalPart ?? ""}';
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGET: BANK CARD (Premium, Dark, Micro-interactions)
// -----------------------------------------------------------------------------
class _BankDetailsCard extends StatefulWidget {
  final String bankName;
  final String accountNumber;
  final String accountName;

  const _BankDetailsCard({
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
  });

  @override
  State<_BankDetailsCard> createState() => _BankDetailsCardState();
}

class _BankDetailsCardState extends State<_BankDetailsCard> {
  bool _isCopied = false;
  Timer? _timer;

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: widget.accountNumber));
    HapticFeedback.mediumImpact(); // Physical feel
    setState(() => _isCopied = true);
    
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 24.w),
      decoration: BoxDecoration(
        // Premium Dark Gradient - High Contrast against white bg
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C2C2E), // Charcoal
            Color(0xFF000000), // Pure Black
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Bank Name Pill
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Text(
              widget.bankName.toUpperCase(),
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.9),
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          
          SizedBox(height: 24.h),

          // Account Number & Interaction
          GestureDetector(
            onTap: _handleCopy,
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.accountNumber,
                      style: GoogleFonts.inconsolata(
                        color: Colors.white,
                        fontSize: 36.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Icon Switcher
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: _isCopied
                          ? Icon(Iconsax.tick_circle5, key: const ValueKey('check'), color: KorraColors.success, size: 24.sp)
                          : Icon(Iconsax.copy, key: const ValueKey('copy'), color: KorraColors.brand, size: 24.sp),
                    ),
                  ],
                ),
                
                SizedBox(height: 8.h),

                // Text Fade In
                AnimatedOpacity(
                  opacity: _isCopied ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    "Copied to clipboard",
                    style: GoogleFonts.inter(
                      color: KorraColors.success,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),
          
          // Account Name
          Text(
            widget.accountName,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.6),
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}