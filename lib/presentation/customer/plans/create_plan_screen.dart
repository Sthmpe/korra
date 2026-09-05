import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:korra/data/repository/customer/plans_repository.dart';

import '../../../config/constants/colors.dart';
import '../../../config/routes/app_routes.dart';
import '../../../data/models/customer/customer_account_stats.dart';
import '../../../data/models/customer/customer_model.dart';
import '../../../data/models/customer/plans.dart';
import '../../../data/repository/customer/customer_repository.dart';
import '../../../logic/bloc/customer/plans/create_plan_bloc.dart';
import '../../../logic/bloc/customer/plans/create_plan_event.dart';
import '../../../logic/bloc/customer/plans/create_plan_state.dart';
import '../../../logic/bloc/vendor/product/vendor_products_state.dart';
import '../../shared/widgets/korra_header.dart';
import '../../shared/widgets/show_app_snackbar.dart';
import '../currency_input_formatter.dart';
import '../customer_failure_sheet.dart';
import 'widgets/penalty_explainer_sheet.dart';
import 'widgets/full_payment_success_card.dart';
import 'widgets/plan_model_pill.dart';
import 'widgets/plan_duration_card.dart';
import 'widgets/plan_liability_disclaimer.dart';
import 'widgets/plan_limit_container.dart';
import 'widgets/plan_image_carousel.dart';
import 'widgets/plan_payment_mode_toggle.dart';
import 'widgets/plan_cadence_selector.dart';
import 'widgets/plan_bottom_bar.dart';
import 'widgets/plan_liability_checkbox.dart';

class CreatePlanScreen extends StatefulWidget {
  final ProductFetchResult product;
  final String customerUid;
  final Customer customer;
  final VoidCallback onJumpToHome;
  final VoidCallback onJumpToPlan;
  final double walletBalance;

  /// Variant chosen before entering this screen ("XL / Red"); null for
  /// products without variants. Rides into PREVIEW so the server locks the
  /// plan to that variant's stock.
  final String? variantLabel;

  const CreatePlanScreen({
    super.key,
    required this.product,
    required this.customerUid,
    required this.customer,
    required this.walletBalance,
    required this.onJumpToHome,
    required this.onJumpToPlan,
    this.variantLabel,
  });

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  late final CustomerRepository customerRepo;
  late TextEditingController _amountCtrl;
  late FocusNode _amountFocusNode;
  final GlobalKey _scrollKey = GlobalKey();

  String? cadenceType;
  int _currentImageIndex = 0;
  bool _agreedToTerms = false;
  int _selectedGoalDays = 0;

  bool _blockPayments = false;

  double userEnteredDownPayment = 0.0;
  double processingFee = 0.0;
  double totalDueNow = 0.0;

  bool _isPayInFull = false;

  double _roundUpAmount(double amount) {
    if (amount == 0) return 0;
    double val = amount * 100;
    val = double.parse(val.toStringAsFixed(4)); 
    return val.ceil() / 100;
  }

  // Store Credit Logic
  double _storeCredit = 0.0; // Available credit
  bool _useStoreCredit = true; // Default to true if they have credit

  // Track how the down payment is split for fee calculation transparency
  double _amountCoveredByCredit = 0.0;
  double _amountCoveredByCash = 0.0;

  double _creditUsedForPayment = 0.0; // Actual amount to deduct from Total Due
  double _creditSweepAmount = 0.0;

  final currencyFormat = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 2,
  );

  double get productPrice {
    final data = widget.product.data;
    final discount = data['discountedPrice']?.toDouble() ?? 0.0;
    final base = data['price']?.toDouble() ?? 0.0;
    // A timed campaign's discount lapses at campaignEndsAt; charge full price
    // once it has ended so an expired promo never sets the plan price.
    if (discount > 0 && _campaignDiscountActive(data)) return discount;
    return base;
  }

  /// Absent end time = untimed campaign (or an already-gated value) = valid.
  bool _campaignDiscountActive(Map<String, dynamic> data) {
    final ends = data['campaignEndsAt'];
    if (ends == null) return true;
    DateTime? end;
    if (ends is Timestamp) {
      end = ends.toDate();
    } else if (ends is DateTime) {
      end = ends;
    }
    return end == null || DateTime.now().isBefore(end);
  }

  ProductModelType get modelType {
    final typeStr = widget.product.data['modelType'] as String? ?? 'strict';
    return typeStr == 'direct'
        ? ProductModelType.direct
        : ProductModelType.strict;
  }

  String get _policyString {
    // RULE A: If it is Direct, it is ALWAYS Store Credit (Ignore DB string)
    if (modelType == ProductModelType.direct) {
      return "Store Credit";
    }

    // RULE B: If Strict, read the vendor's choice from DB.
    // Default to "50% Refund" if missing (Safety net for Strict)
    return widget.product.data['cancellationPolicy'] as String? ?? "Store Credit";
  }

  @override
  void initState() {
    super.initState();
    customerRepo = context.read<CustomerRepository>();
    _amountCtrl = TextEditingController();
    _amountFocusNode = FocusNode();
    _amountFocusNode.addListener(() {
      if (_amountFocusNode.hasFocus) _scrollToInput();
    });

    // 1. Calculate initial fee immediately (assuming 0 credit for now)
    // This ensures a fee shows up even before credit loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _recalculateFees(); 
    });

    // 2. Fetch credit (which will trigger a recalc when it arrives)
    _fetchStoreCredit(); // ✅ Fetch on init
    _fetchMerchantCompliance(); // ✅ Fetch on init
  }

  // Helper to fetch credit (You might want to move this to Bloc/Repo properly later)
  Future<void> _fetchStoreCredit() async {
    if (!mounted) return;

    final vendorId = widget.product.data['vendorId'];
    
    if (vendorId != null) {
      final credit = await customerRepo.getStoreCredit(
        widget.customerUid,
        vendorId,
      );

      if (mounted) {
        setState(() {
          _storeCredit = credit;
          // Recalculate fees now that we know the credit balance
          _recalculateFees();
        });
      }
    }
  }

  // Helper to fetch merchant compliance status
  Future<void> _fetchMerchantCompliance() async {
    if (!mounted) return;

    final vendorId = widget.product.data['vendorId'];
    
    if (vendorId != null) {
      // 1. Call your clean repository function
      final compliance = await customerRepo.getComplianceStatus(vendorId);

      if (mounted) {
        setState(() {
          // 2. Extract the data from the Map
          final isExplicitlyBlocked = compliance['blockPayments'] == true ? true : false;
          final status = compliance['status'];

          // 3. Set your state: Block if toggle is true, OR if severe status/error
          _blockPayments = isExplicitlyBlocked || 
                           status == 'suspended' || 
                           status == 'banned';
        });
      }
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _scrollToInput() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_scrollKey.currentContext != null) {
        Scrollable.ensureVisible(
          _scrollKey.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.3,
        );
      }
    });
  }

  // --- 🧠 CORE FEE LOGIC START ---

  // 1. Helper: The "Zone" Logic for Standard Fees
  double _calculateStandardFee(double amount) {
    if (amount <= 0) return 0.0;
    
    // Calculate raw 3.5%
    double rawFee = amount * 0.035;

    // Zone 1 (Small): Fee < 30k -> Pay Exact
    if (rawFee < 30000) return rawFee;

    // Zone 2 (Sweet Spot): Fee 30k - 60k -> Pay Flat 30k
    if (rawFee >= 30000 && rawFee < 60000) return 30000;

    // Zone 3 (High Ticket): Fee > 60k -> Pay Flat 60k
    return 60000;
  }

  // 2. The Master Calculator
  void _recalculateFees() {
    final double totalProductPrice = productPrice;
    final bool isAbove30k = totalProductPrice > 30000;

    if (_isPayInFull) {
      // ─── PAY IN FULL ───────────────────────────────────────────────────────
      // Store balance allowed. Applied first, cash covers the rest.
      userEnteredDownPayment = totalProductPrice;

      if (_storeCredit > 0) {
        _creditSweepAmount = math.min(_storeCredit, totalProductPrice);
      } else {
        _creditSweepAmount = 0.0;
      }

      final double cashPortionOfPrice = totalProductPrice - _creditSweepAmount;

      // Cash fee: 3.5% of cash portion — added on top, no minimum
      double feeCashPart = cashPortionOfPrice > 0
          ? _calculateStandardFee(cashPortionOfPrice)
          : 0.0;

      // Store balance fee: 0.35% of store portion — added on top, minimum ₦100
      double feeCreditPart = 0.0;
      if (_creditSweepAmount > 0) {
        final double rawStoreFee = _creditSweepAmount * 0.035 * 0.10;
        feeCreditPart = math.max(rawStoreFee, 100.0);
      }

      setState(() {
        processingFee = _roundUpAmount(feeCashPart + feeCreditPart);
        // Wallet pays: cash portion + all fees (fee is added on top, not deducted)
        totalDueNow = _roundUpAmount(cashPortionOfPrice + processingFee);
        _amountCoveredByCredit = _creditSweepAmount;
        _amountCoveredByCash = cashPortionOfPrice;
      });

    } else {
      // ─── INSTALLMENT PLAN ─────────────────────────────────────────────────
      // Store balance BLOCKED — fresh cash only for deposit
      _creditSweepAmount = 0.0;
      _amountCoveredByCredit = 0.0;
      _amountCoveredByCash = userEnteredDownPayment;

      double fee = 0.0;

      if (!isAbove30k) {
        // Items ≤ ₦30k: fee = 3.5% of TOTAL PRODUCT PRICE — collected upfront once
        fee = _calculateStandardFee(totalProductPrice);
      } else {
        // Items > ₦30k: fee = 3.5% of INITIAL DEPOSIT AMOUNT — added on top
        fee = userEnteredDownPayment > 0
            ? _roundUpAmount(userEnteredDownPayment * 0.035)
            : 0.0;
      }

      setState(() {
        processingFee = fee;
        // Wallet pays: deposit + fee (fee is added on top)
        totalDueNow = _roundUpAmount(userEnteredDownPayment + processingFee);
      });
    }

    if (kDebugMode) {
      debugPrint("--- FEE CALC ---");
      debugPrint("Product Price: $totalProductPrice | Above 30k: $isAbove30k");
      debugPrint("Pay in Full: $_isPayInFull");
      debugPrint("Credit Sweep: $_creditSweepAmount");
      debugPrint("Deposit: $userEnteredDownPayment");
      debugPrint("Processing Fee: $processingFee");
      debugPrint("Total Due Now: $totalDueNow");
    }
  }

  // --- 🧠 CORE FEE LOGIC END ---

  void _onAmountChanged(String value) {
    final price = productPrice;
    String clean = value.replaceAll(',', '');
    double val = double.tryParse(clean) ?? 0.0;

    // Cap at product price
    if (val > price) val = price;

    setState(() {
      userEnteredDownPayment = _roundUpAmount(val);
    });

    // Recalculate fees — needed for above ₦30k installment where fee is on deposit amount
    _recalculateFees();
  }

  debugPrintAmountCalculations() {
    final price = productPrice;
    debugPrint("Price: $price");
    debugPrint("User Down Payment: $userEnteredDownPayment");
    debugPrint("Processing Fee: $processingFee");
    debugPrint("Total Due Now: $totalDueNow");
  }

  double getRemainingBalance(double price) {
    return _roundUpAmount((price - userEnteredDownPayment).clamp(0.0, double.infinity));
  }

  @override
  Widget build(BuildContext context) {
    final double productPrice = this.productPrice;
    final String productId = widget.product.id ?? '';
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final storeName = widget.product.data['storeName'] ?? 'Store';

    return StreamBuilder<CustomerAccountStats?>(
      stream: customerRepo.streamCustomerStats(widget.customerUid),
      builder: (context, snapshot) {
        final stats =
            snapshot.data ?? CustomerAccountStats.empty(widget.customerUid);
        final isSlotsFull = stats.isSlotsFull;

        // =====================================================================
        // 1. EXTRACT AND CLEAN MERCHANT SETTINGS
        // =====================================================================
        // A. Base Duration (Saved as a String like "14 Days" under 'baseDuration')
        int? parsedMerchantDuration;
        final String? baseDurationString = widget.product.data['baseDuration'] as String?;
        if (baseDurationString != null) {
          final match = RegExp(r'\d+').firstMatch(baseDurationString);
          if (match != null) parsedMerchantDuration = int.tryParse(match.group(0)!);
        }

        // B. Extensions Enabled (Saved as a bool under 'extensionsEnabled')
        final bool? parsedAllowExtension = widget.product.data['extensionsEnabled'] as bool?;

        // C. Notice Days (Saved as a String like "1 Days" under 'noticePeriod')
        int? parsedNoticeDays;
        final String? noticeString = widget.product.data['noticePeriod'] as String?;
        if (noticeString != null) {
          final match = RegExp(r'\d+').firstMatch(noticeString);
          if (match != null) parsedNoticeDays = int.tryParse(match.group(0)!);
        }

        // D. Extension Days (Reverse math using totalMaxTime)
        int? parsedExtensionDays;
        final String? totalString = widget.product.data['totalMaxTime'] as String?;
        if (parsedAllowExtension == true && totalString != null && parsedMerchantDuration != null && parsedNoticeDays != null) {
          final match = RegExp(r'\d+').firstMatch(totalString);
          if (match != null) {
            final totalDays = int.tryParse(match.group(0)!) ?? 0;
            // Reverse math: extDays = totalDays - baseDays - noticeDays
            parsedExtensionDays = totalDays - parsedMerchantDuration - parsedNoticeDays;
            if (parsedExtensionDays < 0) parsedExtensionDays = 0; 
          }
        } else {
          parsedExtensionDays = 0;
        }

        return BlocProvider(
          create: (context) =>
              CreatePlanBloc(repo: customerRepo)
                ..add(LoadPlanPreview(
                  productPrice,
                  widget.customerUid,
                  productId,
                  parsedMerchantDuration,
                  parsedAllowExtension,
                  parsedExtensionDays,
                  parsedNoticeDays,
                  variantLabel: widget.variantLabel,
                )),
          child: BlocConsumer<CreatePlanBloc, CreatePlanState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            buildWhen: (previous, current) =>
                previous.status != current.status ||
                previous.riskEngineUpfront != current.riskEngineUpfront ||
                previous.baseDurationDays != current.baseDurationDays ||
                previous.canExtend != current.canExtend ||
                previous.loanAmount != current.loanAmount ||
                previous.dpPercentage != current.dpPercentage ||
                previous.noticeDays != current.noticeDays ||
                previous.extensionDays != current.extensionDays,
            listener: (context, state) {
              if (state.status == CreatePlanStatus.previewLoaded) {
               setState(() {
                  // Determine Sweep based on loaded credit
                  double sweep = 0.0;
                  if (_useStoreCredit && _storeCredit > 0) {
                    sweep = (_storeCredit >= productPrice) ? productPrice : _storeCredit;
                  }
                  
                  // Set initial value to the higher of (Risk Min) or (Sweep)
                  double startValue = math.max(state.riskEngineUpfront, sweep);
                  
                  userEnteredDownPayment = _roundUpAmount(startValue);
                  _amountCtrl.text = NumberFormat("#,###").format(userEnteredDownPayment);
                  _selectedGoalDays = state.baseDurationDays;
                  
                  // Trigger calc
                  _recalculateFees(); 
                });
              }
              if (state.status == CreatePlanStatus.success) {
                // 1. Hide Keyboard
                FocusScope.of(context).unfocus();

                // 2. Show Success Message
                showAppSnackbar(
                  "Plan created successfully!",
                  SnackbarType.success,
                );

                // 3. Close the Create Screen (Go back)
                Navigator.of(context).pop(); 
                
                // 4. Switch the Bottom Tab to "Plans" so they see it
                widget.onJumpToPlan();
              }
              if (state.status == CreatePlanStatus.error) {
                showKorraFailureSheetCustomer(
                  context,
                  title: 'Plan creation error',
                  message: state.errorMessage ?? "Failed to create plan",
                  isDismissible: true,
                  onCancel: () => Navigator.pop(context),
                );
              }
            },
            builder: (context, state) {
              if (state.status == CreatePlanStatus.loadingPreview ||
                  state.status == CreatePlanStatus.initial) {
                return const Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(
                    child: CircularProgressIndicator(color: KorraColors.brand),
                  ),
                );
              }

              // 1. Get Risk Engine Min
              final double riskMin = state.riskEngineUpfront;
              
              // 2. Determine the "True Floor"
              // The user effectively starts at the Credit Sweep amount if it's higher than Risk Min
              final double effectiveMinDownPayment = math.max(riskMin, _creditSweepAmount);

              final remainingBalance = getRemainingBalance(productPrice);
              final isFullPayment = remainingBalance <= 0;

              // 💰 WALLET CHECK LOGIC
              // We pay whatever the Credit Sweep didn't cover, plus the fee.
              double creditUsed = _creditSweepAmount;
              
              double amountToPayFromWallet = totalDueNow; 
              // (Note: totalDueNow was calculated in _recalculateFees as: (UserDP - Sweep) + Fee)
              
              final isInsufficient = widget.walletBalance < amountToPayFromWallet;
              
              // UI VALIDATION FLAG
              // User must be at least at the effective minimum (which accounts for the sweep)
              final bool isAmountValid = userEnteredDownPayment >= effectiveMinDownPayment;

              return GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Scaffold(
                  backgroundColor: Colors.white,
                  resizeToAvoidBottomInset: true,
                  appBar: KorraHeader(
                    title: 'Plan Setup',
                    showLeadingIcon: true,
                  ),
                  body: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PlanImageCarousel(
                                images: widget.product.data['images'] ?? [],
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20.w,
                                  vertical: 24.h,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. VENDOR + MODEL HEADER
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildVendorHeader(
                                          widget.product.data['storeName'] ??
                                              'Store',
                                        ),
                                        PlanModelPill(modelType: modelType),
                                      ],
                                    ),
                                    SizedBox(height: 14.h),
                                    Text(
                                      widget.product.data['name'] ??
                                          'Product Name',
                                      style: GoogleFonts.inter(
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.w800,
                                        color: KorraColors.text,
                                        height: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 12.h),
                                    Text(
                                      currencyFormat.format(productPrice),
                                      style: GoogleFonts.inter(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),

                                    SizedBox(height: 20.h),

                                   // 1. THE NEW PREMIUM TOGGLE
                                    PlanPaymentModeToggle(
                                      isPayInFull: _isPayInFull,
                                      onChanged: (val) {
                                        setState(() {
                                          _isPayInFull = val;
                                          if (!val) {
                                            userEnteredDownPayment = state.riskEngineUpfront;
                                            _amountCtrl.text = NumberFormat("#,###").format(userEnteredDownPayment);
                                          }
                                          _recalculateFees();
                                        });
                                      },
                                    ),
                                    
                                    // 2. THE STORE BALANCE UI
                                    if (_storeCredit > 0) ...[
                                      SizedBox(height: 16.h),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                        decoration: BoxDecoration(
                                          color: _isPayInFull 
                                              ? const Color(0xFFF0FDF4) // Green tint if active
                                              : const Color(0xFFFFF7ED), // Orange tint if locked
                                          borderRadius: BorderRadius.circular(12.r),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(8.r),
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                _isPayInFull ? Iconsax.wallet_check : Iconsax.lock,
                                                size: 18.sp,
                                                color: _isPayInFull ? Colors.green : Colors.orange.shade600,
                                              ),
                                            ),
                                            SizedBox(width: 12.w),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Store Balance: ${currencyFormat.format(_storeCredit)}", 
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13.sp,
                                                      fontWeight: FontWeight.w600,
                                                      color: const Color(0xFF101828),
                                                    ),
                                                  ),
                                                  Text(
                                                    _isPayInFull
                                                      ? "Unlocked! Applied to your full payment."
                                                      : "Locked for installments. Select 'Pay in Full' to use.",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11.sp,
                                                      color: _isPayInFull ? Colors.green.shade700 : Colors.orange.shade700,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (_isPayInFull)
                                              Icon(Icons.check_circle, color: Colors.green, size: 20.sp),
                                          ],
                                        ),
                                      ),
                                    ],

                                    SizedBox(height: 24.h),

                                    // SLOT LIMIT STATUS
                                    PlanLimitContainer(
                                      activePlans: stats.activePlansCount,
                                      maxSlots: stats.maxSlots,
                                      isSlotsFull: isSlotsFull,
                                    ),

                                    SizedBox(height: 32.h),
                                    Text(
                                      _isPayInFull ? "PAYMENT SUMMARY" : "INITIAL DEPOSIT",
                                      style: GoogleFonts.inter(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w700,
                                        color: KorraColors.textMuted,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 12.h),

                                    // 3. THE DEPOSIT BOX (Hides typing if Pay in Full)
                                    Container(
                                      key: _scrollKey,
                                      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 0.w),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.02),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                "₦",
                                                style: GoogleFonts.inter(
                                                  fontSize: 24.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: KorraColors.black,
                                                ),
                                              ),
                                              SizedBox(width: 4.w),
                                              Expanded(
                                                // If Pay in Full, just show text. If Installment, show the TextField.
                                                child: _isPayInFull
                                                    ? Text(
                                                        currencyFormat.format(productPrice).replaceAll('₦', ''),
                                                        style: GoogleFonts.inter(
                                                          fontSize: 36.sp,
                                                          fontWeight: FontWeight.w800,
                                                          color: KorraColors.black,
                                                        ),
                                                      )
                                                    : TextField(
                                                        controller: _amountCtrl,
                                                        focusNode: _amountFocusNode,
                                                        keyboardType: TextInputType.number,
                                                        onChanged: _onAmountChanged,
                                                        inputFormatters: [
                                                          LengthLimitingTextInputFormatter(15),
                                                          CurrencyInputFormatter(),
                                                        ],
                                                        style: GoogleFonts.inter(
                                                          fontSize: 36.sp,
                                                          fontWeight: FontWeight.w800,
                                                          color: KorraColors.black,
                                                          height: 1.0,
                                                        ),
                                                        decoration: InputDecoration(
                                                          border: InputBorder.none,
                                                          isDense: true,
                                                          contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                                                          hintText: NumberFormat("#,###").format(effectiveMinDownPayment),
                                                          hintStyle: GoogleFonts.inter(color: Colors.grey.shade300),
                                                          labelText: "",
                                                        ),
                                                      ),
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(top: 12.h),
                                            child: const Divider(
                                              height: 0,
                                              color: Color(0xFFF3F4F6),
                                            ),
                                          ),
                                          // Service Fee Row
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "+ Service Fee",
                                                style: GoogleFonts.inter(
                                                  fontSize: 12.sp,
                                                  color: Colors.grey.shade500,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                currencyFormat.format(processingFee),
                                                style: GoogleFonts.inter(
                                                  fontSize: 12.sp,
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Show breakdown of savings if mixed
                                          if (_amountCoveredByCredit > 0 && _amountCoveredByCash > 0)
                                            Padding(
                                               padding: EdgeInsets.only(top: 4.h),
                                               child: Row(
                                                 mainAxisAlignment: MainAxisAlignment.end,
                                                 children: [
                                                   Icon(Iconsax.flash_1, size: 9.5.sp, color: Colors.green),
                                                   SizedBox(width: 4.w),
                                                   Text(
                                                     "Fair Split",
                                                     style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.green, fontWeight: FontWeight.w600),
                                                   )
                                                 ],
                                               ),
                                            ),

                                          // SHOW CREDIT USAGE ROW
                                          if (creditUsed > 0) ...[
                                            SizedBox(height: 12.h),
                                            Container(
                                              //padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                              decoration: BoxDecoration(
                                                color: KorraColors.brand.withOpacity(0.0),
                                                borderRadius: BorderRadius.circular(8.r),
                                                border: Border.all(color: KorraColors.brand.withOpacity(0.0)),
                                              ),
                                              child: Row(
                                                children: [
                                                  //Icon(Icons.check_box, color: KorraColors.brand, size: 20.sp),
                                                  //SizedBox(width: 8.w),
                                                  Expanded(
                                                    child: Text(
                                                      "Store Balance Applied",
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12.sp,
                                                        fontWeight: FontWeight.w600,
                                                        color: KorraColors.brand,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    "-${currencyFormat.format(creditUsed)}",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12.sp,
                                                      fontWeight: FontWeight.w700,
                                                      color: KorraColors.brand,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],

                                          SizedBox(height: 12.h),

                                          // TOTAL DUE ROW
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Net Payable Now",
                                                style: GoogleFonts.inter(
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: KorraColors.text,
                                                ),
                                              ),
                                              Text(
                                                currencyFormat.format(
                                                  amountToPayFromWallet,
                                                ),
                                                style: GoogleFonts.inter(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w800,
                                                  color: KorraColors.brand,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: 12.h),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Minimum: ${currencyFormat.format(effectiveMinDownPayment + processingFee)}",
                                          style: GoogleFonts.inter(
                                            fontSize: 12.sp,
                                            color:
                                                !isAmountValid
                                                ? Colors.red
                                                : Colors.grey.shade500,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          child: isInsufficient
                                              ? Text(
                                                  "Insufficient Wallet Balance",
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12.sp,
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                )
                                              : Text(
                                                  "Remaining: ${currencyFormat.format(remainingBalance)}",
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12.sp,
                                                    color: KorraColors.brand,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 40.h),

                                    if (!isFullPayment) ...[
                                      // DYNAMIC DEADLINE CARD
                                      PlanDurationCard(
                                        duration: state.baseDurationDays,
                                        canExtend: state.canExtend,
                                        modelType: modelType,
                                      ),
                                      SizedBox(height: 32.h),

                                      _buildSectionLabel("Duration"),
                                      SizedBox(height: 12.h),
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.all(16.r),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF9FAFB),
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                          // border: Border.all(
                                          //   color: const Color(0xFFEAECF0),
                                          // ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Iconsax.timer_1,
                                              color: KorraColors.brand,
                                              size: 20.sp,
                                            ),
                                            SizedBox(width: 12.w),
                                            Expanded(
                                              child: Text(
                                                "${state.baseDurationDays} days allocation to complete payment.",
                                                style: GoogleFonts.inter(
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _buildSectionLabel("Set your goal"),
                                      SizedBox(height: 12.h),
                                      PlanGoalSelector(
                                        maxDays: state.baseDurationDays,
                                        selectedGoalDays: _selectedGoalDays,
                                        onChanged: (days) {
                                          setState(() {
                                            _selectedGoalDays = days;
                                            cadenceType = null; // Reset schedule on change
                                          });
                                        },
                                      ),
                                      SizedBox(height: 32.h),
                                      _buildSectionLabel("Choose Schedule"),
                                      SizedBox(height: 12.h),
                                      PlanCadenceSelector(
                                        cadenceType: cadenceType,
                                        selectedGoalDays: _selectedGoalDays,
                                        remainingBalance: remainingBalance,
                                        onChanged: (val) {
                                          setState(() {
                                            cadenceType = val;
                                          });
                                        },
                                        currencyFormat: currencyFormat,
                                      ),
                                      PlanCommitmentMessage(
                                        cadenceType: cadenceType,
                                        days: state.baseDurationDays,
                                      ),
                                    ] else ...[
                                      const FullPaymentSuccessCard(),
                                    ],

                                    if (!isSlotsFull) ...[
                                      PlanLiabilityCheckbox(
                                        isChecked: _agreedToTerms,
                                        policyString: _policyString,
                                        onChanged: (v) => setState(
                                          () => _agreedToTerms = v ?? false,
                                        ),
                                      ),
                                      const PlanLiabilityDisclaimer(),
                                    ],
                                    SizedBox(
                                      height: isKeyboardOpen ? 300.h : 40.h,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isKeyboardOpen)
                        PlanBottomBar(
                          status: state.status,
                          isSlotsFull: isSlotsFull,
                          isInsufficient: isInsufficient,
                          isFullPayment: isFullPayment,
                          walletAmount: amountToPayFromWallet,
                          storeCreditUsed: creditUsed,
                          userEnteredDownPayment: userEnteredDownPayment,
                          processingFee: processingFee,
                          minDown: effectiveMinDownPayment,
                          cadenceType: cadenceType,
                          agreedToTerms: _agreedToTerms,
                          currencyFormat: currencyFormat,
                          onJumpToPlan: widget.onJumpToPlan,
                          onFundWallet: () {
                            Get.toNamed(Routes.customerBankDetails, arguments: widget.customer);
                          },
                          onPayPressed: () async {
                            debugPrint("Block Payments Check: $_blockPayments");
                            
                            if (_blockPayments) {
                              showKorraFailureSheetCustomer(
                                context,
                                title: 'Merchant Flagged for Review.',
                                message: "Transactions paused due to a trust and compliance issue. This store is currently flagged for violating Korra's operational terms. All payments to this store are blocked until the merchant resolves the restrictions on their portal.",
                                isDismissible: true,
                                onCancel: () => Navigator.pop(context),
                              );
                              return;
                            }

                            final newPlanRef = customerRepo.firestore.collection('plans').doc();
                            final plan = Plan.create(
                              generatedId: newPlanRef.id,
                              vendorId: widget.product.data['vendorId'] ?? '',
                              customerId: widget.customerUid,
                              customerName: "${widget.customer.firstName} ${widget.customer.lastName}",
                              customerEmail: widget.customer.email,
                              customerPhone: widget.customer.phone,
                              productId: widget.product.id,
                              productCode: widget.product.data['code'] ?? '',
                              title: widget.product.data['name'] ?? 'Unknown',
                              storeName: widget.product.data['storeName'] ?? 'Unknown',
                              imageUrls: List<String>.from(widget.product.data['images'] ?? []),
                              totalProductPrice: productPrice,
                              totalUpfrontPaid: userEnteredDownPayment,
                              processingFee: processingFee,
                              loanAmount: state.loanAmount,
                              dpPercentage: state.dpPercentage,
                              cadenceType: isFullPayment ? 'full_payment' : cadenceType,
                              commitmentEnabled: true,
                              baseDurationDays: state.baseDurationDays,
                              noticeDays: state.noticeDays,
                              extensionDays: state.extensionDays,
                              durationMonths: (state.baseDurationDays / 30).ceil(),
                              cancellationPolicy: _policyString,
                              modelType: modelType == ProductModelType.strict ? 'strict' : 'direct',
                            );

                            final double totalRawAmount = userEnteredDownPayment + processingFee;

                            context.read<CreatePlanBloc>().add(
                              ConfirmPlanCreation(plan, _roundUpAmount(totalRawAmount)),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }




  // Widget _buildStrictDeadlineCard({
  //   required int duration,
  //   required bool canExtend,
  // }) {
  //   return Container(
  //     padding: EdgeInsets.all(12.r),
  //     decoration: BoxDecoration(
  //       color: const Color(0xFFFFF4E5), // Warning Orange
  //       borderRadius: BorderRadius.circular(12.r),
  //       border: Border.all(color: const Color(0xFFFFDDB3)),
  //     ),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Icon(
  //           Iconsax.shield_tick,
  //           size: 20.sp,
  //           color: const Color(0xFFB95000),
  //         ),
  //         SizedBox(width: 10.w),
  //         Expanded(
  //           child: RichText(
  //             text: TextSpan(
  //               style: GoogleFonts.inter(
  //                 fontSize: 12.sp,
  //                 color: const Color(0xFF96490B),
  //                 height: 1.4,
  //               ),
  //               children: [
  //                 const TextSpan(text: "Strict "),
  //                 TextSpan(
  //                   text: "$duration-Day ",
  //                   style: const TextStyle(fontWeight: FontWeight.bold),
  //                 ),
  //                 const TextSpan(
  //                   text: " Late completion defaults trigger the ",
  //                 ),
  //                 TextSpan(
  //                   text: "50% penalty.",
  //                   style: TextStyle(
  //                     fontWeight: FontWeight.bold,
  //                     color: Colors.red.shade800,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }







  // THE UPGRADE SHEET
  // void _showUpgradePrompt(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: Colors.white,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
  //     builder: (_) => Container(
  //       padding: EdgeInsets.all(24.r),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Container(
  //             padding: EdgeInsets.all(16.r),
  //             decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
  //             child: Icon(Iconsax.wallet_add, size: 32.sp, color: Colors.blue.shade800),
  //           ),
  //           SizedBox(height: 16.h),
  //           Text("Increase Your Limit", style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800)),
  //           SizedBox(height: 8.h),
  //           Text(
  //             "This item is above your current reservation limit. To unlock higher limits instantly, fund your wallet with at least ₦20,000.",
  //             textAlign: TextAlign.center,
  //             style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey.shade600, height: 1.4),
  //           ),
  //           SizedBox(height: 24.h),
  //           SizedBox(
  //             width: double.infinity,
  //             height: 50.h,
  //             child: FilledButton(
  //               onPressed: () {
  //                  Navigator.pop(context); // Close sheet
  //                  Get.to(() => TopUpScreen(customer: null)); // Go to Top Up
  //               },
  //               style: FilledButton.styleFrom(backgroundColor: KorraColors.brand),
  //               child: Text("Fund Wallet Now", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
  //             ),
  //           )
  //         ],
  //       ),
  //     )
  //   );
  // }

  Widget _buildSectionLabel(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
        color: KorraColors.textMuted,
        letterSpacing: 1.2,
      ),
    );
  }






  Widget _buildVendorHeader(String storeName) {
    return Row(
      children: [
        Container(
          height: 40.h,
          width: 40.w,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              storeName.isNotEmpty ? storeName[0].toUpperCase() : 'S',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  storeName ?? 'Store',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: KorraColors.text,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(Icons.verified, size: 14.sp, color: Colors.blue),
              ],
            ),
            Text(
              "Verified Merchant",
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: KorraColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

}