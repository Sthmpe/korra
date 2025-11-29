import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptics
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../../../../../config/constants/colors.dart';
import '../../../../../data/models/customer/plans.dart';
import '../../../../../data/repository/customer/customer_repository.dart';
import '../../../../../logic/bloc/customer/plans/pay_plan_bloc.dart';
import '../../topup_screen.dart';
import 'payment_result_screen.dart';

class PayPlanInputScreen extends StatefulWidget {
  final Plan plan;
  final CustomerRepository repo;

  const PayPlanInputScreen({super.key, required this.plan, required this.repo});

  @override
  State<PayPlanInputScreen> createState() => _PayPlanInputScreenState();
}

class _PayPlanInputScreenState extends State<PayPlanInputScreen> {
  // We manage the raw string manually (e.g. "1200.5")
  String _inputString = ""; 
  
  // Format for the INTEGER part only
  final _intFormat = NumberFormat("#,##0", "en_US");

  @override
  void initState() {
    super.initState();
    // 1. Pre-fill Logic
    double initial = widget.plan.nextAmount;
    if (initial > widget.plan.amountRemaining) initial = widget.plan.amountRemaining;
    
    // Convert to string, removing trailing .0 if it's a whole number
    if (initial % 1 == 0) {
      _inputString = initial.toInt().toString();
    } else {
      _inputString = initial.toString();
    }
  }

  // --- 2. DISPLAY FORMATTER (The Engineering Magic) ---
  // This ensures "1000." shows as "1,000." and "1000.5" shows as "1,000.5"
  String get _displayValue {
    if (_inputString.isEmpty) return "0";
    
    List<String> parts = _inputString.split('.');
    String integerPart = parts[0];
    
    // Format the integer part with commas
    String formattedInt = integerPart.isEmpty ? "0" : _intFormat.format(int.parse(integerPart));

    if (parts.length > 1) {
      return "$formattedInt.${parts[1]}"; // Add decimal part back exactly as typed
    } else if (_inputString.endsWith('.')) {
      return "$formattedInt."; // Handle trailing dot
    }
    
    return formattedInt;
  }

  // Helper: Get actual double value for logic
  double get _currentAmount => double.tryParse(_inputString) ?? 0.0;

  // --- 3. KEYPAD LOGIC ---
  void _onKeyTap(String value) {
    HapticFeedback.lightImpact(); 

    // Handle Decimal Point
    if (value == '.') {
      if (_inputString.contains('.')) return; // Prevent double dots
      setState(() => _inputString += value);
      return;
    }

    // Handle Numbers
    // A. Check Max Length (to prevent UI overflow)
    if (!_inputString.contains('.') && _inputString.length >= 9) return; 

    // B. Check Decimal Precision (Max 2 decimal places)
    if (_inputString.contains('.')) {
      String decimalPart = _inputString.split('.')[1];
      if (decimalPart.length >= 2) return; // Block input if already 2dp
    }

    setState(() {
      if (_inputString == "0" && value != '.') {
        _inputString = value; // Replace initial 0
      } else {
        _inputString += value;
      }
    });
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();
    if (_inputString.isNotEmpty) {
      setState(() {
        _inputString = _inputString.substring(0, _inputString.length - 1);
        if (_inputString.isEmpty) _inputString = "0";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PayPlanBloc(repo: widget.repo),
      child: BlocConsumer<PayPlanBloc, PayPlanState>(
        listener: (context, state) {
          if (state.status == PayPlanStatus.success) {
            final isFinished = (_currentAmount + widget.plan.amountPaid) >= widget.plan.totalAmount;
            Get.off(() => PaymentResultScreen(
              isSuccess: true, 
              isPlanCompleted: isFinished, 
              amount: _currentAmount,
              planName: widget.plan.title,
            ));
          } else if (state.status == PayPlanStatus.failure) {
            Get.off(() => PaymentResultScreen(
              isSuccess: false, 
              errorMessage: state.errorMessage,
              amount: _currentAmount,
              planName: widget.plan.title,
            ));
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              _buildMainContent(context),
              if (state.status == PayPlanStatus.loading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                )
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return StreamBuilder(
      stream: widget.repo.streamCustomer(widget.plan.customerId),
      builder: (context, snapshot) {
        final walletBal = snapshot.data?.availableBalance ?? 0.0;
        
        final bool isOverBalance = _currentAmount > walletBal;
        final bool isOverRemaining = _currentAmount > widget.plan.amountRemaining;
        final bool isValid = _currentAmount > 0 && !isOverBalance && !isOverRemaining;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: const BackButton(color: Colors.black),
          ),
          body: Column(
            children: [
              Text(
                "Paying for ${widget.plan.title}",
                style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13.sp, fontWeight: FontWeight.w500),
              ),
              
              const Spacer(),

              // --- BIG DISPLAY (Uses _displayValue) ---
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "₦", 
                        style: GoogleFonts.inter(
                          fontSize: 32.sp, 
                          fontWeight: FontWeight.w500, 
                          color: Colors.grey.shade400
                        )
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _displayValue, // ✅ Using the smart formatted getter
                        style: GoogleFonts.inter(
                          fontSize: 56.sp,
                          fontWeight: FontWeight.w700, 
                          color: const Color(0xFF101828),
                          letterSpacing: -1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12.h),

              if (isOverBalance)
                _buildStatusPill(Icons.error_outline, "Insufficient Wallet Balance", Colors.red.shade50, Colors.red)
              else if (isOverRemaining)
                _buildStatusPill(Icons.warning_amber, "Exceeds remaining balance", Colors.orange.shade50, Colors.orange.shade800)
              else
                _buildStatusPill(Icons.account_balance_wallet, "Balance: ₦${_intFormat.format(walletBal)}", const Color(0xFFF2F4F7), const Color(0xFF344054)),

              const Spacer(),

              // CHIPS
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildChip("Next Due", widget.plan.nextAmount),
                    SizedBox(width: 12.w),
                    _buildChip("Full Balance", widget.plan.amountRemaining),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // KEYPAD
              _buildKeypad(),

              SizedBox(height: 16.h),

              // ACTION BUTTON
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: FilledButton(
                    onPressed: () {
                      if (isOverBalance) {
                        Get.to(() => TopUpScreen(customer: snapshot.data));
                      } else if (isValid) {
                        context.read<PayPlanBloc>().add(PayInstallmentConfirmed(
                          planId: widget.plan.id,
                          customerUid: widget.plan.customerId,
                          amount: _currentAmount,
                        ));
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: isOverBalance ? Colors.black : KorraColors.brand,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      elevation: 0,
                    ),
                    child: Text(
                      isOverBalance ? "Top Up Wallet" : "Confirm Pay",
                      style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      }
    );
  }

  Widget _buildStatusPill(IconData icon, String text, Color bg, Color fg) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20.r)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: fg),
          SizedBox(width: 6.w),
          Text(text, style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }

  Widget _buildChip(String label, double amount) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          // Reset string to exact amount (removing trailing .0 if integer)
          if (amount % 1 == 0) {
            _inputString = amount.toInt().toString();
          } else {
            _inputString = amount.toString();
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0,2))]
        ),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            Text("₦${_intFormat.format(amount)}", style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, color: const Color(0xFF101828))),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          _buildKeyRow(['1', '2', '3']),
          SizedBox(height: 16.h),
          _buildKeyRow(['4', '5', '6']),
          SizedBox(height: 16.h),
          _buildKeyRow(['7', '8', '9']),
          SizedBox(height: 16.h),
          _buildKeyRow(['.', '0', '⌫']),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((k) {
        return Expanded(
          child: InkWell(
            onTap: () {
              if (k == '⌫') {
                _onBackspace();
              } else if (k == '.') {
                _onKeyTap('.');
              } else {
                _onKeyTap(k);
              }
            },
            borderRadius: BorderRadius.circular(30),
            child: Container(
              height: 50.h,
              alignment: Alignment.center,
              child: k == '⌫' 
                ? const Icon(Icons.backspace_outlined, size: 22)
                : Text(k, style: GoogleFonts.inter(fontSize: 24.sp, fontWeight: FontWeight.w600, color: const Color(0xFF101828))),
            ),
          ),
        );
      }).toList(),
    );
  }
}