import 'package:cached_network_image/cached_network_image.dart';
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

class CreatePlanScreen extends StatefulWidget {
  final ProductFetchResult product;
  final CustomerRepository customerRepo;
  final String customerUid;
  final Customer customer;
  final VoidCallback onJumpToHome;
  final VoidCallback onJumpToPlan;
  final double walletBalance;

  const CreatePlanScreen({
    super.key,
    required this.product,
    required this.customerRepo,
    required this.customerUid,
    required this.customer,
    required this.walletBalance,
    required this.onJumpToHome,
    required this.onJumpToPlan,
  });

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  late TextEditingController _amountCtrl;
  late FocusNode _amountFocusNode;
  final GlobalKey _scrollKey = GlobalKey();

  String? cadenceType;
  int _currentImageIndex = 0;
  bool _agreedToTerms = false;
  int _selectedGoalDays = 0;
  double userEnteredDownPayment = 0.0;
  double processingFee = 0.0;
  double totalDueNow = 0.0;

  double _roundUpAmount(double amount) {
    if (amount == 0) return 0;
    double val = amount * 100;
    val = double.parse(val.toStringAsFixed(4)); 
    return val.ceil() / 100;
  }

  // Store Credit Logic
  double _storeCredit = 0.0; // Available credit
  bool _useStoreCredit = true; // Default to true if they have credit

  final currencyFormat = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 2,
  );

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
    _amountCtrl = TextEditingController();
    _amountFocusNode = FocusNode();
    _amountFocusNode.addListener(() {
      if (_amountFocusNode.hasFocus) _scrollToInput();
    });

    _fetchStoreCredit(); // ✅ Fetch on init
  }

  // Helper to fetch credit (You might want to move this to Bloc/Repo properly later)
  Future<void> _fetchStoreCredit() async {
    if (!mounted) return;

    final vendorId = widget.product.data['vendorId'];
    
    if (vendorId != null) {
      final credit = await widget.customerRepo.getStoreCredit(
        widget.customerUid,
        vendorId,
      );

      if (mounted) {
        setState(() {
          _storeCredit = credit;
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

  void _onAmountChanged(String value) {
    final price = widget.product.data['price']?.toDouble() ?? 0.0;
    String clean = value.replaceAll(',', '');
    double val = double.tryParse(clean) ?? 0.0;

    setState(() {
      if (val > price) val = price;
      userEnteredDownPayment = _roundUpAmount(val);
      processingFee = _roundUpAmount(price * 0.035);

      totalDueNow = _roundUpAmount(userEnteredDownPayment + processingFee);
    });
  }

  debugPrintAmountCalculations() {
    final price = widget.product.data['price']?.toDouble() ?? 0.0;
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
    final double productPrice = widget.product.data['price']?.toDouble() ?? 0.0;
    final String productId = widget.product.id ?? '';
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final storeName = widget.product.data['storeName'] ?? 'Store';

    return StreamBuilder<CustomerAccountStats?>(
      stream: widget.customerRepo.streamCustomerStats(widget.customerUid),
      builder: (context, snapshot) {
        final stats =
            snapshot.data ?? CustomerAccountStats.empty(widget.customerUid);
        final isSlotsFull = stats.isSlotsFull;

        return BlocProvider(
          create: (context) =>
              CreatePlanBloc(repo: widget.customerRepo)
                ..add(LoadPlanPreview(productPrice, widget.customerUid, productId)),
          child: BlocConsumer<CreatePlanBloc, CreatePlanState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == CreatePlanStatus.previewLoaded) {
                setState(() {
                  userEnteredDownPayment = _roundUpAmount(state.riskEngineUpfront);
                  _amountCtrl.text = NumberFormat(
                    "#,###",
                  ).format(userEnteredDownPayment);
                  _selectedGoalDays = state.baseDurationDays;
                  _onAmountChanged(_amountCtrl.text); // Trigger calc
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
                  onCancel: () => Get.back(),
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

              final minDownPayment = state.riskEngineUpfront;
              if (totalDueNow == 0 && userEnteredDownPayment == 0) {
                // Init logic moved to listener or here if listener missed
              }

              final remainingBalance = getRemainingBalance(productPrice);
              final isFullPayment = remainingBalance <= 0;

              // --- 💰 PAYMENT CALCULATION LOGIC ---
              double amountToPayFromWallet = totalDueNow;
              double creditApplied = 0.0;

              if (_useStoreCredit && _storeCredit > 0) {
                // RULE: Store Credit can ONLY pay for the Principal (Down Payment).
                // The Processing Fee must ALWAYS come from the Wallet (Cash).
                
                // 1. Determine the maximum credit allowed (The Principal only)
                double maxCreditUsage = userEnteredDownPayment; 

                // 2. Calculate how much credit we actually use
                if (_storeCredit >= maxCreditUsage) {
                  // Credit covers the entire down payment
                  creditApplied = maxCreditUsage;
                } else {
                  // Credit covers only part of the down payment
                  creditApplied = _storeCredit;
                }

                // 3. The Wallet pays the difference (Fee is naturally left over)
                amountToPayFromWallet = totalDueNow - creditApplied;
                
                // Sanity Check: Ensure wallet pays at least the fee (math guarantees this, but good for safety)
                if (amountToPayFromWallet < processingFee) {
                   amountToPayFromWallet = processingFee;
                }
              }

              // 🛑 CHECK WALLET AGAINST REMAINING (After credit)
              final isInsufficient =
                  widget.walletBalance < amountToPayFromWallet;

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
                              _buildImageCarousel(
                                widget.product.data['images'] ?? [],
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
                                        _buildModelPill(modelType),
                                      ],
                                    ),
                                    SizedBox(height: 12.h),
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
                                    SizedBox(height: 8.h),
                                    Text(
                                      "Total Price: ${currencyFormat.format(productPrice)}",
                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),

                                    if (_storeCredit > 0) ...[
                                      SizedBox(height: 16.h),
                                      GestureDetector(
                                        onTap: () => setState(
                                          () => _useStoreCredit =
                                              !_useStoreCredit,
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 12.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _useStoreCredit
                                                ? KorraColors.brand.withOpacity(
                                                    0.08,
                                                  )
                                                : const Color(0xFFF9FAFB),
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                            border: Border.all(
                                              color: _useStoreCredit
                                                  ? KorraColors.brand
                                                  : const Color(0xFFEAECF0),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              // 1. Icon that clearly indicates "Store"
                                              Container(
                                                padding: EdgeInsets.all(8.r),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.grey.shade200,
                                                  ),
                                                ),
                                                child: Icon(
                                                  Iconsax.shop,
                                                  size: 18.sp,
                                                  color: KorraColors.brand,
                                                ),
                                              ),
                                              SizedBox(width: 12.w),

                                              // 2. Explicit Text
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Use $storeName Credit", // ✅ Explicit Context
                                                      style: GoogleFonts.inter(
                                                        fontSize: 13.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: const Color(
                                                          0xFF101828,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      "Available: ${currencyFormat.format(_storeCredit)}",
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12.sp,
                                                        color: Colors
                                                            .grey
                                                            .shade500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // 3. The Checkbox visual
                                              if (_useStoreCredit)
                                                Icon(
                                                  Icons.check_circle,
                                                  color: KorraColors.brand,
                                                  size: 24.sp,
                                                )
                                              else
                                                Icon(
                                                  Icons.radio_button_unchecked,
                                                  color: Colors.grey.shade400,
                                                  size: 24.sp,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],

                                    SizedBox(height: 24.h),

                                    // ✅ SLOT LIMIT STATUS
                                    _buildLimitContainer(
                                      activePlans: stats.activePlansCount,
                                      maxSlots: stats.maxSlots,
                                      isSlotsFull: isSlotsFull,
                                    ),

                                    SizedBox(height: 32.h),
                                    Text(
                                      "INITIAL DEPOSIT",
                                      style: GoogleFonts.inter(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w700,
                                        color: KorraColors.textMuted,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 12.h),

                                    // Amount Input
                                    Container(
                                      key: _scrollKey,
                                      padding: EdgeInsets.all(16.r),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                        border: Border.all(
                                          color: const Color(0xFFE5E7EB),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.02,
                                            ),
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
                                                child: TextField(
                                                  controller: _amountCtrl,
                                                  focusNode: _amountFocusNode,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  onChanged: _onAmountChanged,
                                                  inputFormatters: [
                                                    LengthLimitingTextInputFormatter(
                                                      15,
                                                    ),
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
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 8.w,
                                                          vertical: 8.h,
                                                        ),
                                                    hintText: NumberFormat(
                                                      "#,###",
                                                    ).format(minDownPayment),
                                                    hintStyle:
                                                        GoogleFonts.inter(
                                                          color: Colors
                                                              .grey
                                                              .shade300,
                                                        ),
                                                    labelText:
                                                        "Down Payment Amount",
                                                    labelStyle:
                                                        GoogleFonts.inter(
                                                          fontSize: 12.sp,
                                                          color: Colors.grey,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(top: 12.h),
                                            child: const Divider(
                                              height: 1,
                                              color: Color(0xFFF3F4F6),
                                            ),
                                          ),
                                          // 3. The Math
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "+ One-time Processing Fee (3.5%)",
                                                style: GoogleFonts.inter(
                                                  fontSize: 12.sp,
                                                  color: Colors.grey.shade500,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                currencyFormat.format(
                                                  processingFee,
                                                ),
                                                style: GoogleFonts.inter(
                                                  fontSize: 12.sp,
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),

                                          // ✅ STORE CREDIT TOGGLE (If available)
                                          if (_storeCredit > 0) ...[
                                            SizedBox(height: 12.h),
                                            GestureDetector(
                                              onTap: () => setState(
                                                () => _useStoreCredit =
                                                    !_useStoreCredit,
                                              ),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 12.w,
                                                  vertical: 8.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _useStoreCredit
                                                      ? KorraColors.brand
                                                            .withOpacity(0.1)
                                                      : Colors.grey.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        8.r,
                                                      ),
                                                  border: Border.all(
                                                    color: _useStoreCredit
                                                        ? KorraColors.brand
                                                              .withOpacity(0.3)
                                                        : Colors.grey.shade200,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      _useStoreCredit
                                                          ? Icons.check_box
                                                          : Icons
                                                                .check_box_outline_blank,
                                                      color: _useStoreCredit
                                                          ? KorraColors.brand
                                                          : Colors.grey,
                                                      size: 20.sp,
                                                    ),
                                                    SizedBox(width: 8.w),
                                                    Expanded(
                                                      child: Text(
                                                        "Use Store Credit (${currencyFormat.format(_storeCredit)})",
                                                        style: GoogleFonts.inter(
                                                          fontSize: 12.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: _useStoreCredit
                                                              ? KorraColors
                                                                    .brand
                                                              : Colors
                                                                    .grey
                                                                    .shade700,
                                                        ),
                                                      ),
                                                    ),
                                                    if (_useStoreCredit)
                                                      Text(
                                                        "-${currencyFormat.format(creditApplied)}",
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 12.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: KorraColors
                                                                  .brand,
                                                            ),
                                                      ),
                                                  ],
                                                ),
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
                                          "Minimum: ${currencyFormat.format(minDownPayment + processingFee)}",
                                          style: GoogleFonts.inter(
                                            fontSize: 12.sp,
                                            color:
                                                userEnteredDownPayment <
                                                    (minDownPayment + processingFee)
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
                                      _buildDurationCard(
                                        duration: state.baseDurationDays,
                                        canExtend: state.canExtend,
                                        type: modelType,
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
                                          border: Border.all(
                                            color: const Color(0xFFEAECF0),
                                          ),
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
                                                "You have ${state.baseDurationDays} days to complete payment.",
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
                                      SizedBox(height: 32.h),
                                      _buildSectionLabel("Set your goal"),
                                      SizedBox(height: 12.h),
                                      _buildGoalSelector(
                                        state.baseDurationDays,
                                      ),
                                      SizedBox(height: 32.h),
                                      _buildSectionLabel("Choose Schedule"),
                                      SizedBox(height: 12.h),
                                      _buildScheduleGrid(remainingBalance),
                                      _buildCommitmentMessage(
                                        state.baseDurationDays,
                                      ),
                                    ] else ...[
                                      _buildFullPaymentSuccess(),
                                    ],

                                    if (!isSlotsFull) ...[
                                      _buildLiabilityCheckbox(
                                        isChecked: _agreedToTerms,
                                        policyString: _policyString,
                                        onChanged: (v) => setState(
                                          () => _agreedToTerms = v ?? false,
                                        ),
                                      ),
                                      _buildLiabilityDisclaimer(),
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
                        _buildBottomBar(
                          context,
                          state,
                          isFullPayment,
                          minDownPayment,
                          isInsufficient,
                          processingFee,
                          isSlotsFull,
                          totalDueNow, // Pass raw total for event
                          amountToPayFromWallet, // For UI check
                          creditApplied,
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

  Widget _buildLiabilityDisclaimer() {
    return Container(
      margin: EdgeInsets.only(top: 24.h, bottom: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(
              Iconsax.info_circle,
              size: 16.sp,
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(
                    text:
                        "Disclaimer: Korra facilitates and tracks payments, and monitors vendor compliance, but is ",
                  ),
                  TextSpan(
                    text: "not liable ",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const TextSpan(
                    text:
                        "for product quality, authenticity, or delivery. All fulfillment issues are the responsibility of the vendor.",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrictDeadlineCard({
    required int duration,
    required bool canExtend,
  }) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5), // Warning Orange
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFFFDDB3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Iconsax.shield_tick,
            size: 20.sp,
            color: const Color(0xFFB95000),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: const Color(0xFF96490B),
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: "Strict "),
                  TextSpan(
                    text: "$duration-Day ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(
                    text: " Late completion defaults trigger the ",
                  ),
                  TextSpan(
                    text: "50% penalty.",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelPill(ProductModelType type) {
    final isStrict = type == ProductModelType.strict;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isStrict ? const Color(0xFFFFF7ED) : const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isStrict ? const Color(0xFFFFEDD5) : const Color(0xFFE0F2FE),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isStrict ? Iconsax.shield_tick : Icons.handshake_rounded,
            size: 14.sp,
            color: isStrict ? const Color(0xFF9A3412) : const Color(0xFF0369A1),
          ),
          SizedBox(width: 4.w),
          Text(
            isStrict ? "Strict Lock" : "Korra Direct",
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: isStrict
                  ? const Color(0xFF9A3412)
                  : const Color(0xFF0369A1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationCard({
    required int duration,
    required bool canExtend,
    required ProductModelType type,
  }) {
    // Customize text/color based on model if needed, currently both use orange for "Deadline"
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFFFDDB3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Iconsax.timer_1, size: 20.sp, color: const Color(0xFFB95000)),
          SizedBox(width: 10.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: const Color(0xFF96490B),
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: "Duration: "),
                  TextSpan(
                    text: "$duration Days.\n",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: type == ProductModelType.strict
                        ? "Failure to complete triggers the penalty."
                        : "Flexible timeline, but refund is Store Credit only.",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiabilityCheckbox({
    required bool isChecked,
    required String policyString, // Received from helper
    required ValueChanged<bool?> onChanged,
  }) {
    // Logic: Does the string contain "50%"?
    final bool is50Percent = policyString.contains("50%");

    final String highlightText = is50Percent
        ? "50% Non-Refundable Penalty"
        : "Store Credit Only Policy";

    return Padding(
      padding: EdgeInsets.only(top: 24.h, bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24.w,
            height: 24.w,
            child: Checkbox(
              value: isChecked,
              onChanged: onChanged,
              activeColor: KorraColors.brand,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(
                    text:
                        "I agree to complete this plan. If I cancel or default, I accept the ",
                  ),
                  TextSpan(
                    text: highlightText,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD92D20),
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFFD92D20).withOpacity(0.5),
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () =>
                          _showPenaltyExplainer(context, policyString),
                  ),
                  const TextSpan(text: "."),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPenaltyExplainer(BuildContext context, String policyString) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PenaltyExplainerSheet(policyString: policyString),
    );
  }

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

  // --- 🎨 NEW SLOT UI ---
  Widget _buildLimitContainer({
    required int activePlans,
    required int maxSlots,
    required bool isSlotsFull,
  }) {
    final color = isSlotsFull ? Colors.orange : Colors.green;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isSlotsFull ? Colors.orange.shade100 : const Color(0xFFF3F4F6),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: isSlotsFull ? Colors.orange.shade50 : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSlotsFull
                    ? Colors.orange.shade100
                    : Colors.grey.shade200,
              ),
            ),
            child: Icon(
              Iconsax.box,
              size: 16.sp,
              color: isSlotsFull ? Colors.orange : KorraColors.text,
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Active Slot Limit",
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                isSlotsFull
                    ? "Limit Reached ($activePlans/$maxSlots)"
                    : "$activePlans of $maxSlots Slots Used",
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: isSlotsFull
                      ? Colors.orange.shade800
                      : KorraColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            isSlotsFull ? Icons.info_outline_rounded : Icons.check_circle,
            color: color,
            size: 20.sp,
          ),
        ],
      ),
    );
  }

  // --- 🏗️ UPDATED BOTTOM BAR ---
  Widget _buildBottomBar(
    BuildContext context,
    CreatePlanState state,
    bool isFullPayment,
    double minDown,
    bool isInsufficient,
    double processingFee,
    bool isSlotsFull,
    double totalRawAmount, // For Bloc
    double walletAmount, // For Insufficient Check
    double storeCreditUsed,
  ) {
    final bool isAmountValid = (userEnteredDownPayment + processingFee) >= (minDown + processingFee);
    final bool isSchedulePicked = isFullPayment || cadenceType != null;
    final bool isFormComplete = isAmountValid && isSchedulePicked;

    final bool canProceed = !isSlotsFull && isFormComplete && _agreedToTerms;

    String btnText = "Pay & Start Plan";
    if (storeCreditUsed > 0 && walletAmount == 0) {
      btnText = "Pay with Store Credit";
    } else if (storeCreditUsed > 0) {
      btnText = "Pay Balance (${currencyFormat.format(walletAmount)})";
    }

    Color btnColor = KorraColors.brand;
    VoidCallback? customAction;

    if (isSlotsFull) {
      btnText = "View Active Plans";
      btnColor = Colors.orange.shade800;
      customAction = widget.onJumpToPlan;
    } else if (isInsufficient) {
      btnText = "Top Up Wallet & Start";
      btnColor = Colors.black;
      customAction = () {
        Get.toNamed(Routes.customerBankDetails, arguments: widget.customer);
      };
    } else if (isFullPayment && walletAmount > 0) {
      btnText = "Pay Full Amount";
    }

    final VoidCallback? onPressed =
        (state.status == CreatePlanStatus.creating ||
            (!canProceed && !isInsufficient && !isSlotsFull))
        ? null
        : () async {
            if (customAction != null) {
              customAction!();
              return;
            }

            final newPlanRef = widget.customerRepo.db.collection('plans').doc();
            final plan = Plan.create(
              generatedId: newPlanRef.id,
              vendorId: widget.product.data['vendorId'] ?? '',
              customerId: widget.customerUid,
              customerName: "${widget.customer.firstName} ${widget.customer.lastName}",
              customerPhone: widget.customer.phone,
              productId: widget.product.id,
              productCode: widget.product.data['code'] ?? '',
              title: widget.product.data['name'] ?? 'Unknown',
              storeName: widget.product.data['storeName'] ?? 'Unknown',
              imageUrls: List<String>.from(widget.product.data['images'] ?? []),
              totalProductPrice: widget.product.data['price']?.toDouble() ?? 0.0,
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

            // Pass the FULL required amount to Bloc.
            // The Backend logic we wrote earlier AUTOMATICALLY checks store credit usage.
            // So we just send the total, and backend splits it.
            // Note: If you want to force explicit credit usage, pass a flag to Bloc -> Repo -> Backend.
            // Based on backend code: 'useStoreCredit' flag is accepted but logic prioritizes logic.
            // Let's assume sending total is fine and backend handles deduction as programmed.

            if (kDebugMode) {
              final price = widget.product.data['price']?.toDouble() ?? 0.0;
              debugPrint("Price: $price");
              debugPrint("User Down Payment: $userEnteredDownPayment");
              debugPrint("Processing Fee: $processingFee");
              debugPrint("Total Raw Amount: ${_roundUpAmount(totalRawAmount)}");
              debugPrint("Wallet Amount: $walletAmount");
              debugPrint("Store Credit Used: $storeCreditUsed");
            }

            context.read<CreatePlanBloc>().add(
              ConfirmPlanCreation(plan, _roundUpAmount(totalRawAmount)),
            );
          };

    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 32.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54.h,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: btnColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          onPressed: onPressed,
          child: state.status == CreatePlanStatus.creating
              ? SizedBox(
                  height: 24.h,
                  width: 24.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  btnText,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  // other helpers _buildImageCarousel etc. here
  Widget _buildImageCarousel(List<dynamic> images) {
    if (images.isEmpty) return SizedBox(height: 200.h);
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 280.h,
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
              "Verified Vendor",
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

  Widget _buildSmartCadenceOption({
    required String label,
    required String value,
    required double calculatedAmount,
  }) {
    final isSelected = cadenceType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => cadenceType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          decoration: BoxDecoration(
            color: isSelected ? KorraColors.brand : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected ? KorraColors.brand : const Color(0xFFE5E7EB),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: KorraColors.brand.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white.withOpacity(0.9)
                      : KorraColors.textMuted,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                currencyFormat.format(calculatedAmount),
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : KorraColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlexibleOption() {
    final isSelected = cadenceType == 'flexible';
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => cadenceType = 'flexible'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10B981) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF10B981)
                  : const Color(0xFFE5E7EB),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Text(
                "Flexible",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white.withOpacity(0.9)
                      : KorraColors.textMuted,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                "Anytime",
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : KorraColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // DYNAMIC GOAL TABS
  Widget _buildGoalSelector(int maxDays) {
    List<int> options = [];
    // Only show options that fit within the Max Days
    if (maxDays >= 7) options.add(7);
    if (maxDays >= 14) options.add(14);
    if (maxDays >= 28) options.add(28);

    // Always add the Max Limit as the last option
    if (!options.contains(maxDays)) options.add(maxDays);

    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: options.map((days) {
          final isSelected = _selectedGoalDays == days;

          String label;
          if (days == 7)
            label = "1 Week";
          else if (days == 14)
            label = "2 Weeks";
          else if (days == 28)
            label = "4 Weeks";
          else
            label = "$days Days"; // Exact days (e.g. 15, 25, 90)

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedGoalDays = days;
                cadenceType = null; // Reset schedule on change
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 0),
                margin: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? KorraColors.text
                        : KorraColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScheduleGrid(double balance) {
    // Calculation based on SELECTED GOAL, not Max Limit
    final durationDays = _selectedGoalDays;

    final daily = balance / durationDays;
    final weekly = balance / (durationDays / 7);

    // Only show monthly if duration > 30 days
    final showMonthly = durationDays >= 30;
    // Only show weekly if duration >= 14 days
    final showWeekly = durationDays >= 14;

    return Column(
      children: [
        Row(
          children: [
            _buildSmartCadenceOption(
              label: "Daily",
              value: "daily",
              calculatedAmount: daily,
            ),
            SizedBox(width: 10.w),

            if (showWeekly)
              _buildSmartCadenceOption(
                label: "Weekly",
                value: "weekly",
                calculatedAmount: weekly,
              )
            else
              const Spacer(),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            if (showMonthly) ...[
              _buildSmartCadenceOption(
                label: "Monthly",
                value: "monthly",
                calculatedAmount: balance / (durationDays / 30),
              ),
              SizedBox(width: 10.w),
            ],
            _buildFlexibleOption(),
          ],
        ),
      ],
    );
  }

  Widget _buildCommitmentMessage(int days) {
    if (cadenceType == null) return const SizedBox.shrink();
    final isFlex = cadenceType == 'flexible';
    final date = DateFormat(
      'MMM d',
    ).format(DateTime.now().add(Duration(days: days)));

    return Padding(
      padding: EdgeInsets.only(top: 20.h),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: isFlex
              ? const Color(0xFFECFDF5)
              : Colors.blue.shade50.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isFlex ? const Color(0xFFA7F3D0) : Colors.blue.shade100,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isFlex ? Icons.verified_user_outlined : Icons.flag_rounded,
              color: isFlex ? const Color(0xFF059669) : Colors.blue.shade700,
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                "Finish by $date.",
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  height: 1.4,
                  color: KorraColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullPaymentSuccess() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // Green-50
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.tick_circle5,
              color: Color(0xFF16A34A),
              size: 20,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Full Payment",
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF15803D),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "No schedule needed. We'll process your order immediately.",
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    height: 1.4,
                    color: const Color(0xFF166534),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PenaltyExplainerSheet extends StatelessWidget {
  final String policyString; // "50% Refund" or "Store Credit"

  const _PenaltyExplainerSheet({required this.policyString});

  @override
  Widget build(BuildContext context) {
    final is50Percent = policyString.contains("50%");

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  is50Percent ? Iconsax.shield_cross : Iconsax.card_remove,
                  color: const Color(0xFFD92D20),
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      is50Percent ? "The 50% Penalty" : "Store Credit Only",
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF101828),
                      ),
                    ),
                    Text(
                      "Cancellation Terms",
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: const Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // REASON 1 (Universal)
          _buildReasonRow(
            icon: Iconsax.shop,
            title: "Vendor Commitment",
            desc:
                "The vendor removes this item from the shelf for you. They lose other potential buyers while waiting.",
          ),
          SizedBox(height: 16.h),

          // REASON 2 (Dynamic)
          if (is50Percent)
            _buildReasonRow(
              icon: Iconsax.clock,
              title: "Time Compensation",
              desc:
                  "If you default, the 50% fee compensates the vendor for lost time and holding costs.",
            ),

            SizedBox(height: 16.h),

            _buildReasonRow(
              icon: Iconsax.bag_2,
              title: "Use Anywhere",
              desc:
                  "Since cash refunds aren't readily available for this item, your funds will be returned as Korra Store Credit instantly.",
            ),

          SizedBox(height: 16.h),

          // REASON 3 (Dynamic)
          if (is50Percent)
            _buildReasonRow(
              icon: Iconsax.wallet_check,
              title: "Your Refund or Flexible Spending",
              desc:
                  "The remaining 50% is refunded to your wallet instantly. or you can choose to keep it as Store Credit for future purchases.",
            )
          else
            _buildReasonRow(
              icon: Iconsax.refresh_circle, // Or loop icon
              title: "Flexible Spending",
              desc:
                  "Your funds are converted to Store Credit valid only with this specific vendor. You can use it to purchase any other item from them immediately.",
            ),

          SizedBox(height: 32.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                foregroundColor: Colors.black,
              ),
              child: Text(
                "I Understand",
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildReasonRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    // ... (Keep existing implementation)
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18.sp, color: const Color(0xFF475467)),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF344054),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  height: 1.4,
                  color: const Color(0xFF667085),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
