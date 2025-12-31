import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptics
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../../../../../config/constants/colors.dart';
import '../../../../../data/models/customer/plans.dart';
import '../../../../../data/repository/customer/customer_repository.dart';
import '../../../../../logic/bloc/customer/plans/pay_plan_bloc.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../../data/models/customer/payment_receipt_data.dart';
import '../../../shared/widgets/show_app_snackbar.dart';

class PayPlanInputScreen extends StatefulWidget {
  final Plan plan;
  final CustomerRepository repo;

  const PayPlanInputScreen({super.key, required this.plan, required this.repo});

  @override
  State<PayPlanInputScreen> createState() => _PayPlanInputScreenState();
}

class _PayPlanInputScreenState extends State<PayPlanInputScreen> {
  String _inputString = ""; 
  final _moneyFormat = NumberFormat("#,##0.##", "en_US");

  // ✅ HELPER 1: Paid Amount (Standard 2DP Display)
  // Prevents long decimals like 5000.333333
  double _clipAmount(double amount) {
    return double.parse(amount.toStringAsFixed(2));
  }

  // ✅ HELPER 2: Remaining Balance (Always Round UP)
  // Ensures you don't lose 0.01 due to rounding down.
  // 33.333 -> 33.34
  double _roundUpAmount(double amount) {
    if (amount == 0) return 0;
    return (amount * 100).ceil() / 100;
  }

  @override
  void initState() {
    super.initState();
    // 1. Pre-fill Logic
    double initial = widget.plan.nextAmount;
    if (initial > widget.plan.amountRemaining) initial = widget.plan.amountRemaining;
    
    // Format initial value
    if (initial % 1 == 0) {
      _inputString = initial.toInt().toString();
    } else {
      _inputString = initial.toString();
    }
  }

  String get _displayValue {
    if (_inputString.isEmpty) return "0";
    List<String> parts = _inputString.split('.');
    String integerPart = parts[0];
    String formattedInt = integerPart.isEmpty ? "0" : _moneyFormat.format(int.parse(integerPart));

    if (parts.length > 1) {
      return "$formattedInt.${parts[1]}";
    } else if (_inputString.endsWith('.')) {
      return "$formattedInt.";
    }
    return formattedInt;
  }

  double get _currentAmount => double.tryParse(_inputString) ?? 0.0;

  // --- KEYPAD LOGIC (Unchanged) ---
  void _onKeyTap(String value) {
    HapticFeedback.lightImpact(); 
    if (value == '.') {
      if (_inputString.contains('.')) return;
      setState(() => _inputString += value);
      return;
    }
    if (!_inputString.contains('.') && _inputString.length >= 9) return; 
    if (_inputString.contains('.')) {
      String decimalPart = _inputString.split('.')[1];
      if (decimalPart.length >= 2) return;
    }
    setState(() {
      if (_inputString == "0" && value != '.') {
        _inputString = value;
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

  double get _smartTargetAmount {
    // 1. If backend has a valid specific target, use it.
    if (widget.plan.nextAmount > 0) return widget.plan.nextAmount;

    // 2. Otherwise, calculate based on cadence (Weekly/Monthly)
    double total = widget.plan.outstandingLoanAmount;
    if (total <= 0) return 0;

    int daysRemaining = widget.plan.planExpiryDate.difference(DateTime.now()).inDays;
    if (daysRemaining <= 0) return total; // Overdue? Pay all.

    // Determine interval (e.g., 30 days for monthly, 7 for weekly)
    int intervalDays = 30; 
    if (widget.plan.cadenceType == 'weekly') intervalDays = 7;
    if (widget.plan.cadenceType == 'bi-weekly') intervalDays = 14;
    if (widget.plan.cadenceType == 'daily') intervalDays = 1;

    // How many payments are left?
    double intervalsLeft = daysRemaining / intervalDays;
    if (intervalsLeft < 1) intervalsLeft = 1;

    // Amount per interval
    double calculated = total / intervalsLeft;

    // Round to nearest 100 for a cleaner number (e.g., 4322 -> 4400)
    return (calculated / 100).ceil() * 100.0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PayPlanBloc(repo: widget.repo),
      child: BlocConsumer<PayPlanBloc, PayPlanState>(
        listener: (context, state) {
          if (state.status == PayPlanStatus.success) {
            final isFinished = (_currentAmount + widget.plan.amountPaid) >= widget.plan.totalAmount;
            
            // ✅ Success Logic
            Get.offNamed(
              Routes.customerPaymentResult,
              arguments: {
                'isSuccess': true,
                'isPlanCompleted': isFinished,
                'amount': _currentAmount,
                'planName': widget.plan.title,
                'fullReceiptData': state.receiptData ?? PaymentReceiptData.fromPartial(
                  amount: _currentAmount, 
                  date: DateTime.now(), 
                  title: widget.plan.title
                ),
              }
            );
          } else if (state.status == PayPlanStatus.failure) {
            // ❌ Failure Logic
            Get.offNamed(
              Routes.customerPaymentResult,
              arguments: {
                'isSuccess': false,
                'errorMessage': state.errorMessage,
                'amount': _currentAmount,
                'planName': widget.plan.title,
                'fullReceiptData': state.receiptData ?? PaymentReceiptData.fromPartial(
                  amount: _currentAmount, 
                  date: DateTime.now(), 
                  title: widget.plan.title
                ),
              }
            );
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

  // =========================================================
  // ✅ THE UPDATED MAIN CONTENT
  // =========================================================
  Widget _buildMainContent(BuildContext context) {
    // 1. Stream Wallet (Main Doc)
    return StreamBuilder(
      stream: widget.repo.streamCustomer(widget.plan.customerId),
      builder: (context, snapshotCust) {
        final walletBal = snapshotCust.data?.availableBalance ?? 0.0;
        
        // 2. Stream Store Credit (Vendor Relation)
        // Make sure your repo has this method, fetching from: 
        // customers/{uid}/vendor_relations/{vendorId}/storeCredit
        return StreamBuilder<double>(
          stream: widget.repo.streamStoreCredit(widget.plan.customerId, widget.plan.vendorId),
          initialData: 0.0,
          builder: (context, snapshotCredit) {
            final storeCredit = snapshotCredit.data ?? 0.0;
            
            // ✅ Logic: Combine Powers
            final totalAvailable = walletBal + storeCredit;

            final bool isOverBalance = _currentAmount > totalAvailable;
            final bool isOverRemaining = _currentAmount > _roundUpAmount(widget.plan.amountRemaining);
            // Allow 0.001 tolerance for floating point math
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

                  // --- BIG DISPLAY ---
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text("₦", style: GoogleFonts.inter(fontSize: 32.sp, fontWeight: FontWeight.w500, color: Colors.grey.shade400)),
                          SizedBox(width: 4.w),
                          Text(
                            _displayValue, 
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

                  // --- ✅ SMART STATUS PILLS ---
                  if (isOverBalance)
                    // Logic: Even if they have credit, if total is low, show total shortfall
                    _buildStatusPill(
                      Icons.error_outline, 
                      "Insufficient Funds (Total: ₦${_moneyFormat.format(_clipAmount(totalAvailable))})", 
                      Colors.red.shade50, 
                      Colors.red
                    )
                  else if (isOverRemaining)
                    _buildStatusPill(Icons.warning_amber, "Exceeds remaining balance", Colors.orange.shade50, Colors.orange.shade800)
                  else
                    // ✅ Logic: Show split view if Store Credit exists
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatusPill(
                          Icons.account_balance_wallet, 
                          "Wallet: ₦${_moneyFormat.format(_clipAmount(walletBal))}", 
                          const Color(0xFFF2F4F7), 
                          const Color(0xFF344054)
                        ),
                        if (storeCredit > 0) ...[
                          SizedBox(width: 8.w),
                          _buildStatusPill(
                            Iconsax.shop, // Shop icon for Store Credit
                            "Credit: ₦${_moneyFormat.format(_clipAmount(storeCredit))}", 
                            const Color(0xFFECFDF3), // Light Green
                            const Color(0xFF027A48)  // Dark Green
                          ),
                        ]
                      ],
                    ),

                  const Spacer(),

                  // CHIPS (With Date Logic)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildChip(
                          "Suggested Goal", 
                          _roundUpAmount(_smartTargetAmount) 
                        ),
                        SizedBox(width: 12.w),
                        _buildChip("Full Balance", _roundUpAmount(widget.plan.amountRemaining)),
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
                            final customerData = snapshotCust.data;
                            if (customerData == null) {
                              showAppSnackbar('Please wait, data is loading...', SnackbarType.info);
                              return;
                            }
                            Get.toNamed(
                                Routes.customerBankDetails, 
                                arguments: customerData 
                              );
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

  // Updated Chip to handle Dates
  Widget _buildChip(String label, double amount) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          // Smart Format: If it's 5000.0, use "5000", else "5000.50"
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
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
          ]
        ),
        child: Column(
          children: [
            Text(
              label, 
              style: GoogleFonts.inter(
                fontSize: 11.sp, 
                color: Colors.grey.shade500, 
                fontWeight: FontWeight.w500
              )
            ),
            SizedBox(height: 2.h),
            Text(
              "₦${_moneyFormat.format(amount)}", 
              style: GoogleFonts.inter(
                fontSize: 13.sp, 
                fontWeight: FontWeight.w700, 
                color: const Color(0xFF101828)
              )
            ),
          ],
        ),
      ),
    );
  }
  
  // ... (Keypad code remains unchanged)
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

