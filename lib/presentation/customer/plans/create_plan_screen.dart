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
import '../../../data/models/customer/cutomer_limit.dart';
import '../../../data/models/customer/plans.dart';
import '../../../data/repository/customer/customer_repository.dart';
import '../../../logic/bloc/customer/plans/create_plan_bloc.dart';
import '../../../logic/bloc/customer/plans/create_plan_event.dart';
import '../../../logic/bloc/customer/plans/create_plan_state.dart';
import '../../shared/widgets/korra_header.dart';
import '../../shared/widgets/show_app_snackbar.dart';
import '../topup_screen.dart';
import '../customer_failure_sheet.dart';

class CreatePlanScreen extends StatefulWidget {
  final ProductFetchResult product;
  final CustomerRepository customerRepo;
  final String customerUid;
  final VoidCallback onJumpToHome;
  final VoidCallback onJumpToPlan;
  final double walletBalance;

  const CreatePlanScreen({
    super.key,
    required this.product,
    required this.customerRepo,
    required this.customerUid,
    required this.walletBalance,
    required this.onJumpToHome,
    required this.onJumpToPlan,
  });

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  late TextEditingController _amountCtrl;

  // --- RESTORED UI VARIABLES ---
  late FocusNode _amountFocusNode;
  final GlobalKey _scrollKey = GlobalKey();
  // -----------------------------

  String? cadenceType;
  int _currentImageIndex = 0;
  bool _agreedToTerms = false;

  int _selectedGoalDays = 0;

  // Tracks the actual amount the user has typed/accepted
  double userEnteredDownPayment = 0.0;

  final currencyFormat = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();

    // --- RESTORED SCROLL LOGIC ---
    _amountFocusNode = FocusNode();
    _amountFocusNode.addListener(() {
      if (_amountFocusNode.hasFocus) {
        _scrollToInput();
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _amountFocusNode.dispose(); // Dispose focus node
    super.dispose();
  }

  // --- RESTORED SCROLL METHOD ---
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
      if (val > price) {
        val = price;
      }
      userEnteredDownPayment = val;
    });
  }

  // Helper to calculate remaining amount dynamically based on input
  double getRemainingBalance(double price) {
    return (price - userEnteredDownPayment).clamp(0.0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    final double productPrice = widget.product.data['price']?.toDouble() ?? 0.0;
    // Used for bottom padding logic
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final bool isLowTicket = productPrice < 25000;

    final bool isShortDuration = productPrice <= 25000;

    return BlocProvider(
      create: (context) =>
          CreatePlanBloc(repo: widget.customerRepo)
            ..add(LoadPlanPreview(productPrice, widget.customerUid)),

      child: BlocConsumer<CreatePlanBloc, CreatePlanState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == CreatePlanStatus.previewLoaded) {
            setState(() {
              userEnteredDownPayment = state.riskEngineUpfront;
              _amountCtrl.text = NumberFormat(
                "#,###",
              ).format(userEnteredDownPayment.toInt());

              _selectedGoalDays = state.baseDurationDays;
            });
          }
          if (state.status == CreatePlanStatus.success) {
            showAppSnackbar("Plan created successfully", SnackbarType.success);
            widget.onJumpToHome();
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
          // Loading State
          if (state.status == CreatePlanStatus.loadingPreview ||
              state.status == CreatePlanStatus.initial) {
            return Scaffold(
              backgroundColor: Colors.white,
              appBar: KorraHeader(title: 'Plan Setup'),
              body: const Center(
                child: CircularProgressIndicator(color: KorraColors.brand),
              ),
            );
          }

          final minDownPayment = state.riskEngineUpfront;
          final remainingBalance = getRemainingBalance(productPrice);
          final isFullPayment = remainingBalance <= 0;
          final isInsufficient = widget.walletBalance < userEnteredDownPayment;
          final isLowLimit = minDownPayment == 0 && productPrice != 0;

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
              backgroundColor: Colors.white,
              resizeToAvoidBottomInset: true,
              appBar: KorraHeader(title: 'Plan Setup', showLeadingIcon: true),
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
                                _buildVendorHeader(
                                  widget.product.data['storeName'] ?? 'Store',
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  widget.product.data['name'] ?? 'Product Name',
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

                                SizedBox(height: 24.h),

                                // STREAMED LIMIT STATUS
                                _buildLimitStatus(productPrice),

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

                                // --- RESTORED SCROLL KEY AND FOCUS NODE ---
                                Container(
                                  key: _scrollKey, // <--- KEY RESTORED
                                  padding: EdgeInsets.all(16.r),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
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
                                          focusNode:
                                              _amountFocusNode, // <--- FOCUS NODE RESTORED
                                          keyboardType: TextInputType.number,
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
                                            hintStyle: GoogleFonts.inter(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 12.h),

                                // Validation / Feedback
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    isLowLimit
                                        ? Text(
                                            "Clear active plans",
                                            style: GoogleFonts.inter(
                                              fontSize: 12.sp,
                                              color: Colors.red,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          )
                                        : Text(
                                            "Minimum: ${currencyFormat.format(minDownPayment)}",
                                            style: GoogleFonts.inter(
                                              fontSize: 12.sp,
                                              color:
                                                  (userEnteredDownPayment <
                                                      minDownPayment)
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
                                              "Insufficient Funds",
                                              key: const ValueKey(
                                                'insufficient',
                                              ),
                                              style: GoogleFonts.inter(
                                                fontSize: 12.sp,
                                                color: Colors.red,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            )
                                          : Text(
                                              "Remaining: ${currencyFormat.format(remainingBalance)}",
                                              key: ValueKey(remainingBalance),
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
                                  _buildStrictDeadlineCard(
                                    duration: state.baseDurationDays,
                                    canExtend: state.canExtend,
                                  ),
                                  SizedBox(height: 32.h),
                                  _buildSectionLabel("Duration Limit"),
                                  SizedBox(height: 12.h),

                                  // 3. SIMPLE DURATION DISPLAY (No Choice)
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(16.r),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(12.r),
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
                                  _buildGoalSelector(state.baseDurationDays),

                                  SizedBox(height: 32.h),

                                  _buildSectionLabel("Choose Schedule"),
                                  SizedBox(height: 12.h),

                                  // 4. DYNAMIC SCHEDULE (Based on Goal)
                                  _buildScheduleGrid(remainingBalance),

                                  _buildCommitmentMessage(
                                    state.baseDurationDays,
                                  ),
                                ] else ...[
                                  _buildFullPaymentSuccess(),
                                ],

                                if (!isLowLimit)
                                  _buildLiabilityCheckbox(
                                    _agreedToTerms,
                                    (v) => setState(
                                      () => _agreedToTerms = v ?? false,
                                    ),
                                  ),

                                _buildLiabilityDisclaimer(),
                                SizedBox(height: isKeyboardOpen ? 300.h : 40.h),
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
                      isLowLimit,
                    ),
                ],
              ),
            ),
          );
        },
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
                    text: "Limit. Late completion defaults trigger the ",
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

  Widget _buildBottomBar(
    BuildContext context,
    CreatePlanState state,
    bool isFullPayment,
    double minDown,
    bool isInsufficient,
    bool isLowLimit,
  ) {
    final bool isAmountValid = userEnteredDownPayment >= minDown;
    final bool isSchedulePicked = isFullPayment || cadenceType != null;
    final bool isFormComplete = isAmountValid && isSchedulePicked;

    // 5. VALIDATION: Must agree to terms
    final bool canProceed = isLowLimit
        ? true
        : (isFormComplete && _agreedToTerms);

    String btnText = "Pay & Start Plan";
    Color btnColor = KorraColors.brand;
    VoidCallback? customAction;
    

    if (isLowLimit) {
      // The user CANNOT afford this based on current limit. Why?
      debugPrint("has active plans: ${state.hasActivePlans}");
      if (state.hasActivePlans) {
        // CASE A: They have baggage.
        btnText = "View Outstanding Plans";
        btnColor = Colors.orange.shade800;
      } else {
        debugPrint("cutome acction: accepted");
        // CASE B: They are new/clean, just need higher limit.
        btnText = "Upgrade Account"; // Or "Fund to Upgrade"
        btnColor = const Color(0xFF0F172A); // Premium Dark
        customAction = () {
           _showUpgradePrompt(context); // Show the sheet to fund wallet
        };
      }
    } else if (isInsufficient) {
      btnText = "Top Up Wallet & Start";
      btnColor = Colors.black;
    } else if (isFullPayment) {
      btnText = "Pay Full Amount";
    }

    final VoidCallback? onPressed =
        (state.status == CreatePlanStatus.creating ||
            (!canProceed && !isInsufficient))
        ? null
        : () async {

            if (customAction != null) {
               customAction();
               return;
            }
            
            // 2. Handle Debt
            if (isLowLimit && state.hasActivePlans) {
               widget.onJumpToPlan();
               return;
            }

            if (isInsufficient) {
              //
              return;
            }
            if (isLowLimit) return;

            final newPlanRef = widget.customerRepo.db.collection('plans').doc();
            final plan = Plan.create(
              generatedId: newPlanRef.id,
              // ... (Standard Fields)
              vendorId: widget.product.data['vendorId'] ?? '',
              customerId: widget.customerUid,
              productId: widget.product.id,
              productCode: widget.product.data['code'] ?? '',
              title: widget.product.data['name'] ?? 'Unknown',
              storeName: widget.product.data['storeName'] ?? 'Unknown',
              imageUrls: List<String>.from(widget.product.data['images'] ?? []),
              totalProductPrice:
                  widget.product.data['price']?.toDouble() ?? 0.0,
              totalUpfrontPaid: userEnteredDownPayment,
              loanAmount: state.loanAmount,
              dpPercentage: state.dpPercentage,

              cadenceType: isFullPayment ? 'full_payment' : cadenceType,
              commitmentEnabled: true,

              // *** Pass the Calculated Days ***
              baseDurationDays: state.baseDurationDays,
              noticeDays: state.noticeDays,
              extensionDays: state.extensionDays,

              // Fallback for backward compatibility if needed
              durationMonths: (state.baseDurationDays / 30).ceil(),
            );

            context.read<CreatePlanBloc>().add(
              ConfirmPlanCreation(plan, userEnteredDownPayment),
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

  // THE UPGRADE SHEET
  void _showUpgradePrompt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (_) => Container(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
              child: Icon(Iconsax.wallet_add, size: 32.sp, color: Colors.blue.shade800),
            ),
            SizedBox(height: 16.h),
            Text("Increase Your Limit", style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800)),
            SizedBox(height: 8.h),
            Text(
              "This item is above your current reservation limit. To unlock higher limits instantly, fund your wallet with at least ₦20,000.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey.shade600, height: 1.4),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: FilledButton(
                onPressed: () {
                   Navigator.pop(context); // Close sheet
                   Get.to(() => TopUpScreen(customer: null)); // Go to Top Up
                },
                style: FilledButton.styleFrom(backgroundColor: KorraColors.brand),
                child: Text("Fund Wallet Now", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            )
          ],
        ),
      )
    );
  }

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

  // ✅ REAL-TIME LIMIT STATUS
  Widget _buildLimitStatus(double productPrice) {
    return StreamBuilder<CustomerLimit?>(
      // 1. Listen to the specific Limit Document
      stream: widget.customerRepo.streamCustomerLimit(widget.customerUid),
      builder: (context, snapshot) {
        // A. Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLimitContainer(
            isLoading: true,
            available: 0,
            isOverLimit: false,
          );
        }

        // B. Data Loaded
        final limitData = snapshot.data;

        // Default to 0 if no limit doc found (New user edge case)
        final total = limitData?.totalCreditLimit ?? 0.0;
        final debt = limitData?.activeDebt ?? 0.0;

        // 2. Calculate Available Logic
        // (Ensure we don't show negative numbers if debt > total temporarily)
        final double available = (total - debt).clamp(0.0, double.infinity);

        // 3. Check if Product fits in limit
        final bool isOverLimit = productPrice > available;

        return _buildLimitContainer(
          isLoading: false,
          available: available,
          isOverLimit: isOverLimit,
        );
      },
    );
  }

  // Helper to keep the StreamBuilder clean
  Widget _buildLimitContainer({
    required bool isLoading,
    required double available,
    required bool isOverLimit,
  }) {
    final color = isOverLimit
        ? Colors.orange
        : Colors.green; // Orange is less scary than Red

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isOverLimit ? Colors.orange.shade100 : const Color(0xFFF3F4F6),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: isOverLimit ? Colors.orange.shade50 : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isOverLimit
                    ? Colors.orange.shade100
                    : Colors.grey.shade200,
              ),
            ),
            child: isLoading
                ? SizedBox(
                    width: 16.sp,
                    height: 16.sp,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Iconsax.card,
                    size: 16.sp,
                    color: isOverLimit ? Colors.orange : KorraColors.text,
                  ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Reservation Limit",
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                isLoading
                    ? "Checking..."
                    : "${currencyFormat.format(available)} Available",
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: isOverLimit
                      ? Colors.orange.shade800
                      : KorraColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (!isLoading)
            Icon(
              isOverLimit ? Icons.info_outline_rounded : Icons.check_circle,
              color: color,
              size: 20.sp,
            ),
        ],
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
            itemBuilder: (context, index) => Image.network(
              images[index],
              fit: BoxFit.cover,
              errorBuilder: (c, o, s) => Container(
                color: Colors.grey[100],
                child: const Icon(Icons.image_not_supported),
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
                  storeName,
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

  Widget _buildLiabilityCheckbox(
    bool isChecked,
    ValueChanged<bool?> onChanged,
  ) {
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
                        "I agree to complete this plan within the timeline. If I fail, I accept the ",
                  ),
                  TextSpan(
                    text: "50% Non-Refundable Penalty",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD92D20),
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFFD92D20).withOpacity(0.5),
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _showPenaltyExplainer(context),
                  ),
                  const TextSpan(text: " policy."),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPenaltyExplainer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PenaltyExplainerSheet(),
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
  const _PenaltyExplainerSheet();
  @override
  Widget build(BuildContext context) {
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
                  Iconsax.shield_cross,
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
                      "The 50% Penalty",
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF101828),
                      ),
                    ),
                    Text(
                      "Why is this necessary?",
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
          _buildReasonRow(
            icon: Iconsax.shop,
            title: "Vendor Commitment",
            desc:
                "The vendor removes this item from the shelf for you. They lose other potential buyers while waiting for you.",
          ),
          SizedBox(height: 16.h),
          _buildReasonRow(
            icon: Iconsax.clock,
            title: "Time Compensation",
            desc:
                "If you default, the 50% compensates the vendor for lost time.",
          ),
          SizedBox(height: 16.h),
          _buildReasonRow(
            icon: Iconsax.wallet_check,
            title: "Your Refund",
            desc:
                "The remaining 50% is refunded to your wallet instantly. We don't hold your balance.",
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
