import 'package:cached_network_image/cached_network_image.dart';
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
import '../../../shared/widgets/korra_header.dart';
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
  int _currentImageIndex = 0;

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

  // ✅ FEE HELPERS
  static const double _feeRate = 0.035;
  static const double _storeFeeRate = 0.035 * 0.10; // 10% of 3.5% = 0.35%
  static const double _minStoreFee = 100.0;

  // Only charge per payment fee if item is above ₦30,000
  // Items ₦30,000 and below already had fee charged upfront at plan creation
  bool get _isPerPaymentFee => widget.plan.totalAmount > 30000;

  // Store balance portion used (always prioritized first)
  double _storeCreditPortion(double storeCredit) {
    if (_currentAmount <= 0 || storeCredit <= 0) return 0;
    return _currentAmount <= storeCredit ? _currentAmount : storeCredit;
  }

  // Cash portion after store balance is used
  double _cashPortion(double storeCredit) {
    final storePortion = _storeCreditPortion(storeCredit);
    final cash = _currentAmount - storePortion;
    return cash < 0 ? 0 : double.parse(cash.toStringAsFixed(2));
  }

  // Store balance fee — charged from wallet, minimum ₦100
  // Only on items above ₦30,000
  double _storeFee(double storeCredit) {
    if (!_isPerPaymentFee) return 0;
    final storePortion = _storeCreditPortion(storeCredit);
    if (storePortion <= 0) return 0;
    final calculated = double.parse((storePortion * _storeFeeRate).toStringAsFixed(2));
    return calculated < _minStoreFee ? _minStoreFee : calculated;
  }

  // Cash fee — no minimum, just 3.5% of cash portion
  // Only on items above ₦30,000
  double _cashFee(double storeCredit) {
    if (!_isPerPaymentFee) return 0;
    final cash = _cashPortion(storeCredit);
    if (cash <= 0) return 0;
    
    final double calculatedFee = double.parse((cash * _feeRate).toStringAsFixed(2));
    return calculatedFee > 7500.0 ? 7500.0 : calculatedFee; // 🛡️ Enforce Max Cap
  }

  // Total applied to plan = store portion (full) + cash portion minus cash fee
  double _appliedToItemFull(double storeCredit) {
    if (_currentAmount <= 0) return 0;
    final storePortion = _storeCreditPortion(storeCredit);
    final cash = _cashPortion(storeCredit);
    final cashAfterFee = cash - _cashFee(storeCredit);
    return double.parse((storePortion + cashAfterFee).toStringAsFixed(2));
  }

  // Total wallet deducted = cash portion + store balance fee
  double _totalWalletDeducted(double storeCredit) {
    final cash = _cashPortion(storeCredit);
    final storeFeeAmount = _storeFee(storeCredit);
    return double.parse((cash + storeFeeAmount).toStringAsFixed(2));
  }

  // Amount customer needs to pay to clear remaining balance including fee
  // Only relevant for per-payment fee plans with no store balance
  double get _completionGrossAmount {
    final remaining = _roundUpAmount(widget.plan.amountRemaining);
    if (remaining <= 0) return 0;
    if (!_isPerPaymentFee) return remaining;
    
    // 🛡️ Apply the cap logic to the "Pay to Complete" button
    final double uncappedGross = remaining / (1 - _feeRate);
    if ((uncappedGross - remaining) > 7500.0) {
      return double.parse((remaining + 7500.0).toStringAsFixed(2));
    }
    
    return double.parse(uncappedGross.toStringAsFixed(2));
  }

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
  // ✅ THE UPDATED MAIN CONTENT (PREMIUM SPACING)
  // =========================================================
  Widget _buildMainContent(BuildContext context) {
    // 1. Stream Wallet (Main Doc)
    return StreamBuilder(
      stream: widget.repo.streamCustomer(widget.plan.customerId),
      builder: (context, snapshotCust) {
        final walletBal = snapshotCust.data?.availableBalance ?? 0.0;
        
        // 2. Stream Store Credit (Vendor Relation)
        return StreamBuilder<double>(
          stream: widget.repo.streamStoreCredit(widget.plan.customerId, widget.plan.vendorId),
          initialData: 0.0,
          builder: (context, snapshotCredit) {
            final storeCredit = snapshotCredit.data ?? 0.0;
            
            // ✅ Logic: Combine Powers
            final totalAvailable = walletBal + storeCredit;

            final bool isOverBalance = _currentAmount > totalAvailable;
            final bool isOverRemaining = _currentAmount > (_completionGrossAmount + 0.01);
            // Allow 0.001 tolerance for floating point math
            final bool isValid = _currentAmount > 0 && !isOverBalance && !isOverRemaining; 

            return Scaffold(
              backgroundColor: Colors.white,
              appBar: KorraHeader(
                showLeadingIcon: true,
                title: "Paying for ${widget.plan.title}"
              ),
              body: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top - 88,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                  
                  _buildImageCarousel(widget.plan.imageUrls ?? []),

                  SizedBox(height: 8.h),

                  // --- BIG DISPLAY ---
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
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

                  // ✅ SPACING: Increased from 12.h to 24.h to separate Value from Status
                  // SizedBox(height: 24.h),
                  SizedBox(height: 8.h),

                  // ✅ FEE PREVIEW — only show when amount > 0 and plan is above ₦30,000
                  if (_currentAmount > 0 && _isPerPaymentFee) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 28.w),
                      child: Builder(
                        builder: (context) {
                          final sc = snapshotCredit.data ?? 0.0;
                          final storePortion = _storeCreditPortion(sc);
                          final cashPortion = _cashPortion(sc);
                          final storeFeeAmt = _storeFee(sc);
                          final cashFeeAmt = _cashFee(sc);
                          final applied = _appliedToItemFull(sc);
                          final walletDeducted = _totalWalletDeducted(sc);

                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: const Color(0xFFEAECF0), width: 0.5.w),
                            ),
                            child: Column(
                              children: [
                                // Store balance row
                                if (storePortion > 0) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Store balance used", style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade500)),
                                      Text("₦${_moneyFormat.format(storePortion)}", style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF027A48))),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Store balance fee (0.35%)", style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade400)),
                                      Text("₦${_moneyFormat.format(storeFeeAmt)} from wallet", style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500)),
                                    ],
                                  ),
                                  SizedBox(height: 6.h),
                                ],
                                // Cash fee row
                                if (cashPortion > 0) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Processing fee (3.5%)", style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade500)),
                                      Text("- ₦${_moneyFormat.format(cashFeeAmt)}", style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                                    ],
                                  ),
                                  SizedBox(height: 6.h),
                                ],
                                Divider(height: 1, color: Colors.grey.shade200),
                                SizedBox(height: 6.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Applied to your plan", style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: const Color(0xFF101828))),
                                    Text("₦${_moneyFormat.format(applied)}", style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: KorraColors.brand)),
                                  ],
                                ),
                                if (storePortion > 0) ...[
                                  SizedBox(height: 4.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Wallet deducted", style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade400)),
                                      Text("₦${_moneyFormat.format(walletDeducted)}", style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 8.h),
                  ],

                  SizedBox(height: 8.h),

                  // --- ✅ SMART STATUS PILLS ---
                  if (isOverBalance)
                    _buildStatusPill(
                      Icons.error_outline, 
                      "Insufficient Funds (Total: ₦${_moneyFormat.format(_clipAmount(totalAvailable))})", 
                      Colors.red.shade50, 
                      Colors.red,
                      width: 300.w 
                    )
                  else if (isOverRemaining)
                    _buildStatusPill(Icons.warning_amber, "Exceeds total needed to complete plan", Colors.orange.shade50, Colors.orange.shade800, width: 300.w)
                  else
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
                            Iconsax.shop, 
                            "Store: ₦${_moneyFormat.format(_clipAmount(storeCredit))}", 
                            const Color(0xFFECFDF3), 
                            const Color(0xFF027A48) 
                          ),
                        ]
                      ],
                    ),

                  SizedBox(height: 10.h),

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
                        _buildChip("Pay to Complete", _completionGrossAmount),
                      ],
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // KEYPAD
                  _buildKeypad(),

                  SizedBox(height: 12.h),

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
                              arguments: {
                                'customer': customerData,
                                'repo': widget.repo,
                              }
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
                          isOverBalance ? "Fund Wallet" : "Confirm Pay",
                          style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16.h),
                ],
              ),
                  ),
                ),
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildImageCarousel(List<dynamic> images) {
    if (images.isEmpty) return SizedBox(height: 150.h); // Reduced empty height slightly
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 230.h,
          width: double.infinity,
          child: PageView.builder(
            onPageChanged: (index) =>
                setState(() => _currentImageIndex = index),
            itemCount: images.length,
            itemBuilder: (context, index) => CachedNetworkImage(
              imageUrl: images[index],
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[100],
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 16.h,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: images
                  .asMap()
                  .entries
                  .map(
                    (entry) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentImageIndex == entry.key ? 16.0.w : 6.0.w,
                      height: 4.0.h,
                      margin: const EdgeInsets.symmetric(horizontal: 3.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: _currentImageIndex == entry.key
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill(IconData icon, String text, Color bg, Color fg, {double? width}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg, 
        borderRadius: BorderRadius.circular(20.r)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // ✅ Important: Shrinks the Row to fit the content
        children: [
          Icon(icon, size: 14.sp, color: fg),
          SizedBox(width: 6.w),
          // ✅ Change SizedBox to ConstrainedBox
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width ?? 150.w), // Sets the limit, but allows shrinking
            child: Text(
              text, 
              overflow: TextOverflow.ellipsis, 
              maxLines: 1, 
              style: GoogleFonts.inter(
                fontSize: 12.sp, 
                fontWeight: FontWeight.w600, 
                color: fg
              ),
            ),
          ),
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