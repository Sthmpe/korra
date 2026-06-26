import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/constants/product_categories.dart';
import '../../../../config/utils/currency_formatters.dart';
import '../../../../data/models/vendor/vendor_stat.dart';
import '../../../../data/repository/vendors/vendor_repository.dart';
import '../../../../logic/bloc/vendor/image/image_bloc.dart';
import '../../../../logic/bloc/vendor/product/vendor_products_bloc.dart';
import '../../../../logic/bloc/vendor/product/vendor_products_event.dart';
import '../../../../logic/bloc/vendor/product/vendor_products_state.dart';
import '../../../shared/widgets/korra_header.dart';
import '../../../shared/widgets/show_app_snackbar.dart';
import '../../payout/widgets/contact_support_sheet.dart';
import 'image_upload_box.dart';

class AddProductPage extends StatefulWidget {
  final VendorRepository vendors;
  final String vendorUid;

  const AddProductPage({
    super.key,
    required this.vendors,
    required this.vendorUid,
  });

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  String _complianceStatus = 'active';
  String _blockMessage = '';

  // Controllers
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _downPaymentCtrl = TextEditingController(); // Only for Direct
  final _durationCtrl = TextEditingController();

  // --- LOGIC STATE ---
  ProductModelType _selectedModel = ProductModelType.strict;

  // For Direct, policy is fixed to Store Credit, but we track extension toggle
  bool _isDirectExtensionEnabled = true;

  bool _termsAccepted = false;

  bool _isPriceTooHigh = false;

  // ✅ TRACK MINIMUM VS SELECTED
  // int _minAllowedBaseDays = 14; 

  int _recommendedMinDays = 14;

  int _calculatedDurationInt = 14;
  int _calculatedNoticeInt = 1;
  int _calculatedExtensionInt = 0;


  // DYNAMIC DISPLAY STRINGS
  String _noticePeriod = "1 Days";
  String _extensionDuration = "0 Days"; // Visual only
  String _totalMaxTime = "17 Days";
  bool _priceAllowsExtension = false;

  // We need to store the current limit to use it inside listener
  double _currentMaxPlanLimit = 1000000;

  // 1. Define the stream variable here
  late Stream<VendorStats> _statsStream;

  @override
  void initState() {
    super.initState();

    // 2. Initialize the stream ONCE here
    _statsStream = widget.vendors.streamVendorStats(widget.vendorUid);
    _priceCtrl.addListener(_updatePlanLogic);
    _durationCtrl.addListener(_onDurationInputChanged);

    _fetchComplianceStatus();
  }

  Future<void> _fetchComplianceStatus() async {
    try {
      final compliance = await widget.vendors.getComplianceStatus(widget.vendorUid);
      if (mounted) {
        setState(() {
          _complianceStatus = compliance['status'] ?? 'active';
          _blockMessage = compliance['message'] ?? '';
        });
      }
    } catch (e) {
      // If error, keep default (active) or handle error
      debugPrint("Error fetching status: $e");
    }
  }

  void _onDurationInputChanged() {
    if (_isPriceTooHigh) return;

    int typedDays = int.tryParse(_durationCtrl.text) ?? 0;
    

    setState(() {
      _calculatedDurationInt = typedDays;
      int totalDays = typedDays + _calculatedNoticeInt + _calculatedExtensionInt;
      _totalMaxTime = "$totalDays Days";
    });
  }

  // --- 🧠 CORE LOGIC ENGINE ---
  void _updatePlanLogic() {
    final cleanPrice = double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0;
    final double calculationCeiling = _currentMaxPlanLimit; 

    int recMinDays = 14; // Renamed to recommended
    int noticeDays = 1;  // Set to 1 day
    int extDays = 0;
    bool allowExt = false;

    _isPriceTooHigh = false;

    if (cleanPrice > calculationCeiling) {
       _isPriceTooHigh = true;
    }

    // 1. Determine Recommended Minimum Duration & Extension rules
    if (cleanPrice <= 50000) {
      recMinDays = 14; noticeDays = 1; extDays = 0; allowExt = false;
    } else if (cleanPrice <= 200000) {
        recMinDays = 21; noticeDays = 1; extDays = 3; allowExt = true;
    } else if (cleanPrice <= 500000) {
        recMinDays = 30; noticeDays = 1; extDays = 5; allowExt = true;
    } else if (cleanPrice <= 750000) {
        recMinDays = 60; noticeDays = 1; extDays = 7; allowExt = true;
    } else {
        recMinDays = 90; noticeDays = 1; extDays = 7; allowExt = true;
    }


    // 2. Accept the controller value directly
    int currentInput = int.tryParse(_durationCtrl.text) ?? 0;
    int effectiveDays = currentInput; // Removed the forced minimum override

    // 3. Apply Model Logic for Extensions
    if (_selectedModel == ProductModelType.direct) {
      if (!allowExt) {
        _isDirectExtensionEnabled = false;
        extDays = 0;
      } else if (!_isDirectExtensionEnabled) {
        extDays = 0;
      }
    } else {
      if (!allowExt) extDays = 0;
    }

   // 4. Calculate Total
    int totalDays = effectiveDays + noticeDays + extDays;

    setState(() {
      _priceAllowsExtension = allowExt;
      _recommendedMinDays = recMinDays; 
      _calculatedDurationInt = effectiveDays; 
      _calculatedNoticeInt = noticeDays;
      _calculatedExtensionInt = extDays;

      if (_isPriceTooHigh) {
         _totalMaxTime = "N/A";
         _extensionDuration = "N/A";
      } else {
        _noticePeriod = "$noticeDays Day"; // Singular for 1 Day
        _extensionDuration = allowExt ? "$extDays Days" : "None";
        _totalMaxTime = "$totalDays Days";
      }
    });
  }

  
  void _saveProduct(
    ImageBloc imageBloc,
    VendorProductsBloc productBloc,
    VendorProductsState state,
  ) {
    if (!_formKey.currentState!.validate()) {
      showAppSnackbar("Please check your inputs.", SnackbarType.error);
      return;
    }

    if (imageBloc.state.images.isEmpty) {
      showAppSnackbar(
        "Please add at least one product image.",
        SnackbarType.error,
      );
      return;
    }

    if (!_termsAccepted) {
      showAppSnackbar("You must agree to the terms.", SnackbarType.error);
      return;
    }

    final priceTxt = _priceCtrl.text.replaceAll(',', '');
    final price = double.tryParse(priceTxt) ?? 0.0;
    final stock = int.tryParse(_stockCtrl.text.replaceAll(',', '')) ?? 0;

    // Rule 1: Cap
    if (price > _currentMaxPlanLimit) {
      showAppSnackbar(
        "Single product price cannot exceed ₦${_currentMaxPlanLimit.toStringAsFixed(2)}.",
        SnackbarType.error,
      );
      return;
    }

    // Rule 2: Limit
    final totalValue = price * stock;
    if (totalValue > state.availableLimit) {
      showAppSnackbar(
        "Total value exceeds your available limit.",
        SnackbarType.error,
      );
      return;
    }

    // Rule 3: Direct Down Payment
    if (_selectedModel == ProductModelType.direct) {
      final dp =
          double.tryParse(_downPaymentCtrl.text.replaceAll(',', '')) ?? 0;
      if (dp >= price) {
        showAppSnackbar(
          "Down payment must be less than price.",
          SnackbarType.error,
        );
        return;
      }
      if (dp <= 0) {
        showAppSnackbar("Enter valid down payment.", SnackbarType.error);
        return;
      }
    }

    // ✅ ADD THIS: Rule 4: Manual Duration Check
    int finalDuration = int.tryParse(_durationCtrl.text) ?? 0;
    if (finalDuration <= 0) {
      showAppSnackbar(
        "Please enter a valid base duration.", 
        SnackbarType.error
      );
      return;
    }

    // Prepare Policy
    // Strict: User Choice (50% / Store Credit)
    // Direct: Always "Store Credit"
    final finalPolicy = "Store Credit"; // Forced for Direct

    final imageObjects = imageBloc.state.images; 

    productBloc.add(
      VendorProductsAdd(
        name: _nameCtrl.text,
        description: _descCtrl.text,
        price: price,
        stock: stock,
        category: _categoryCtrl.text,
        
        images: imageObjects, // ✅ Pass List<dynamic> directly
        
        termsAccepted: _termsAccepted,
        modelType: _selectedModel,
        cancellationPolicy: finalPolicy,
        extensionsEnabled: _selectedModel == ProductModelType.strict
            ? _priceAllowsExtension
            : (_priceAllowsExtension && _isDirectExtensionEnabled),
        directDownPayment: _selectedModel == ProductModelType.direct
            ? double.tryParse(_downPaymentCtrl.text.replaceAll(',', ''))
            : null,
        duration: _calculatedDurationInt,
        noticePeriod: _calculatedNoticeInt,
        extensionPeriod: _calculatedExtensionInt,
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _categoryCtrl.dispose();
    _downPaymentCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageBloc = context.read<ImageBloc>();
    final productBloc = context.read<VendorProductsBloc>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const KorraHeader(title: "New Product", showLeadingIcon: true),
      body: BlocListener<VendorProductsBloc, VendorProductsState>(
        listenWhen: (previous, current) => 
            previous.success != current.success || 
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          if (state.success == true) {
            // A. Clear form logic
            _nameCtrl.clear();
            _descCtrl.clear();
            _priceCtrl.clear();
            _stockCtrl.clear();
            _categoryCtrl.clear();
            _downPaymentCtrl.clear();
            // Reset image bloc
            context.read<ImageBloc>().add(ResetState()); 

            // B. Show Success Message
            showAppSnackbar("Product added successfully! 🚀", SnackbarType.success);

            // C. Navigate Back (to Product List)
           // ✅ FIX: Wait for frame to finish before Popping
            Future.delayed(const Duration(milliseconds: 800), () {
              if (context.mounted) Get.back();
            });
          //  WidgetsBinding.instance.addPostFrameCallback((_) {
          //      Get.back(); 
          //   });
          }
          
          if (state.errorMessage != null) {
            showAppSnackbar(state.errorMessage!, SnackbarType.error);
          }
        },
        child: StreamBuilder<VendorStats>(
          stream: _statsStream,
          builder: (context, snapshot) {
            // While loading, use empty stats or loading indicator
            if (snapshot.connectionState == ConnectionState.waiting) {
               return const Center(child: CircularProgressIndicator());
            }
            
            final stats = snapshot.data ?? VendorStats.empty();
            
            // 🔄 SYNC LIMIT WITH LOGIC
            // If the limit in the stream is different from our local cache, update it
            if (_currentMaxPlanLimit != stats.maxPlanAmount) {
               _currentMaxPlanLimit = stats.maxPlanAmount;
               // Trigger UI update logic safely after build
               WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _updatePlanLogic();
               });
            }
              return BlocBuilder<VendorProductsBloc, VendorProductsState>(
                builder: (context, state) {
                  final isLoading = state.isSubmitting ?? false;
            
                  return Form(
                    key: _formKey,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                      children: [
                        _buildRestrictionBanner(_complianceStatus, _blockMessage),
                        
                        _buildLimitHeader(state.availableLimit),
            
                        // 1. IMAGES
                        Text("Product Photos", style: _labelStyle()),
                        SizedBox(height: 8.h),
                        BlocBuilder<ImageBloc, ImageState>(
                          builder: (context, imgState) {
                            return ImageUploadBox(
                              editable: true,
                              imagesUrl: const [],
                            );
                          },
                        ),
                        SizedBox(height: 24.h),
            
                        // 2. DETAILS
                        Text("Details", style: _labelStyle()),
                        SizedBox(height: 8.h),
                        _buildInput(controller: _nameCtrl, hint: "Product Name"),
                        SizedBox(height: 12.h),
                        _buildInput(
                          controller: _descCtrl,
                          hint: "Description (optional)",
                          maxLines: 3,
                          validator: (value) => null,
                        ),
                        SizedBox(height: 24.h),
            
                        // 3. PRICE & DURATION GRID
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Price", style: _labelStyle()),
                                  SizedBox(height: 8.h),
                                  _buildInput(
                                    controller: _priceCtrl,
                                    hint: "0.00",
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.only(left: 14.w, right: 4.w),
                                      child: Text(
                                        "₦",
                                        style: GoogleFonts.inter(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      CurrencyInputFormatter(),
                                    ],
                                  ),
                                  // ✅ ADDED: Only show this if price is too high
                                  if (_isPriceTooHigh) ...[
                                    SizedBox(height: 4.h),
                                    Text(
                                      "Max Limit: ₦${NumberFormat('#,##0').format(_currentMaxPlanLimit)}",
                                      style: GoogleFonts.inter(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFFD92D20), // Error Red
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Base Duration (days)", style: _labelStyle()),
                                  SizedBox(height: 8.h),
                                  _buildInput(
                                    controller: _durationCtrl,
                                    hint: "e.g. $_recommendedMinDays",
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: (value) {
                                      int? val = int.tryParse(value ?? '');
                                      if (val == null || val <= 0) {
                                        return 'Enter valid duration';
                                      }
                                      return null;
                                    },
                                  ),
                                  // Warning: too long (above recommended max)
                                  if ((int.tryParse(_durationCtrl.text) ?? 0) > _recommendedMinDays) ...[
                                    SizedBox(height: 6.h),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Iconsax.warning_2, size: 12.sp, color: const Color(0xFFA54600)),
                                        SizedBox(width: 4.w),
                                        Expanded(
                                          child: Text(
                                            "Warning: Plans over $_recommendedMinDays days reduce completion rates for this price range.",
                                            style: GoogleFonts.inter(
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFFA54600),
                                              height: 1.3,
                                            ),
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
            
                        SizedBox(height: 12.h),
            
                        // STOCK & CATEGORY
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Stock", style: _labelStyle()),
                                  SizedBox(height: 8.h),
                                  _buildInput(
                                    controller: _stockCtrl,
                                    hint: "Qty",
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Category", style: _labelStyle()),
                                  SizedBox(height: 8.h),
                                  GestureDetector(
                                    onTap: () => _showCategorySheet(context),
                                    child: Container(
                                      height: 48.h,
                                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9FAFB),
                                        borderRadius: BorderRadius.circular(12.r),
                                        border: Border.all(
                                          color: const Color(0xFFEAECF0),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _categoryCtrl.text.isEmpty
                                                  ? "Select"
                                                  : _categoryCtrl.text,
                                              style: GoogleFonts.inter(
                                                fontSize: 14.sp,
                                                fontWeight: _categoryCtrl.text.isEmpty
                                                    ? FontWeight.w400
                                                    : FontWeight.w600,
                                                color: _categoryCtrl.text.isEmpty
                                                    ? Colors.grey.shade400
                                                    : const Color(0xFF101828),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Icon(
                                            Iconsax.arrow_down_1,
                                            size: 16.sp,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
            
                        // ----------------------------------------------------
                        // TIMELINE INFO
                        // ----------------------------------------------------
                        SizedBox(height: 20.h),
                        Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12.r),
                            //border: Border.all(color: const Color(0xFFEAECF0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Timeline Logic",
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              _buildTimelineRow("Base Duration", "${_calculatedDurationInt.toString()} Days"),
                              _buildTimelineRow(
                                "Notice Period",
                                _noticePeriod,
                                isAlert: true,
                              ),
                              _buildTimelineRow(
                                "Potential Extension",
                                _extensionDuration,
                              ),
                              _buildTimelineRow(
                                "Total Max Time",
                                _totalMaxTime,
                              ),
                              if (_priceAllowsExtension) ...[
                                SizedBox(height: 4.h),
                                Text(
                                  "* Extension unlocks only if customer pays 80% of the product price.",
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    color: Colors.grey.shade500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
            
                        SizedBox(height: 32.h),
                        const Divider(color: Color(0xFFEAECF0)),
                        SizedBox(height: 24.h),
            
                        // 4. MODEL SELECTION
                        Text("Sales Model", style: _labelStyle()),
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F4F7),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            children: [
                              _buildModelTab("Strict Lock", ProductModelType.strict),
                              _buildModelTab("Korra Direct", ProductModelType.direct),
                            ],
                          ),
                        ),
            
                        SizedBox(height: 20.h),
            
                        // 5. DYNAMIC MODEL SETTINGS
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _selectedModel == ProductModelType.strict
                              ? _buildStrictSettings()
                              : _buildDirectSettings(),
                        ),
            
                        SizedBox(height: 32.h),
            
                        // 6. TERMS
                        GestureDetector(
                          onTap: () =>
                              setState(() => _termsAccepted = !_termsAccepted),
                          child: Container(
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              // border: Border.all(
                              //   color: _termsAccepted
                              //       ? KorraColors.brand
                              //       : const Color(0xFFEAECF0),
                              // ),
                              borderRadius: BorderRadius.circular(12.r),
                              color: _termsAccepted
                                  ? const Color(0xFFFFF4ED)
                                  : Colors.white,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  _termsAccepted
                                      ? Iconsax.tick_square
                                      : Iconsax.square,
                                  size: 20.sp,
                                  color: _termsAccepted
                                      ? KorraColors.brand
                                      : Colors.grey,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Text(
                                    "I confirm this item is in stock and reserved for Korra customers.",
                                    style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      color: const Color(0xFF475467),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            
                        SizedBox(height: 32.h),
            
                        // 7. SUBMIT
                        _buildSubmitArea(
                          context, 
                          status: _complianceStatus, 
                          isLoading: isLoading, 
                          onSubmit: () => _saveProduct(imageBloc, productBloc, state)
                        ),
                        
                        SizedBox(height: 40.h),
                      ],
                    ),
                  );
                },
              );
          }
        ),
      ),
    );
  }

  // --- RESTRICTION BANNER ---
  Widget _buildRestrictionBanner(String status, String message) {
    // Only show the red banner if they are blocked
    if (status == 'restricted' || status == 'suspended' || status == 'banned') {
      return Container(
        margin: EdgeInsets.only(bottom: 20.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3F2), // Soft error background
          //border: Border.all(color: const Color(0xFFFEE4E2)), // Subtle red border
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lock_outline, 
              color: const Color(0xFFD92D20), 
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Product Creation Paused",
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB42318), // Darker red for header
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    
    // If active or pending, show nothing at the top to save space
    return const SizedBox.shrink(); 
  }

  // --- MODEL SPECIFIC WIDGETS ---
  Widget _buildSubmitArea(BuildContext context, {required String status, required bool isLoading, required VoidCallback onSubmit}) {
    // 🛑 Case 1: Restricted / Suspended (BLOCK ACTION)
    // If the account is flagged, we stop them from adding more items.
    if (status == 'restricted' || status == 'suspended' || status == 'banned') {
      return Padding(
        padding: EdgeInsets.only(top: 24.h),
        child: _buildStatusCard( 
          context,
          title: "Creation Paused",
          message: "New product creation is disabled for your account. Please contact support to resolve your status.",
          icon: Icons.lock_outline,
          accentColor: const Color(0xFFD92D20), // Premium Error Red
          buttonText: "Resolve Issue",
          onPressed: () => _showContactSheet(
            context, 
            title: "Account Support", 
            subTitle: "Product creation is restricted. Please contact us to resolve this."
          ),
        ),
      );
    }

    // ✅ Case 2: Active OR Pending (ALLOW ACTION)
    // We allow 'pending' users to add products so they can set up their shop 
    // while waiting for verification.
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: KorraColors.brand,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          disabledBackgroundColor: KorraColors.brand.withOpacity(0.6),
        ),
        child: isLoading
            ? SizedBox(
                width: 24.w,
                height: 24.w,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                "Create Product",
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
  
  // 💎 THE PREMIUM CARD WIDGET
  Widget _buildStatusCard(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color accentColor,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: EdgeInsets.only(top: 0.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r), // Softer corners
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4), // Soft elevation
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Icon with Soft Background
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 24.sp),
                ),
                SizedBox(width: 16.w),
                
                // 2. Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF101828), // Slate 900
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        message,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          height: 1.5, // Better readability
                          color: const Color(0xFF667085), // Slate 500
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 3. Integrated Action Button (Bottom Strip)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20.r),
                bottomRight: Radius.circular(20.r),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      buttonText,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.arrow_forward_rounded, size: 16.sp, color: accentColor),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactSheet(BuildContext context, {required String title, required String subTitle}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allows it to be taller if needed
      builder: (context) => ContactSupportSheet(title: title, subTitle: subTitle),
    );
  }

  Widget _buildStrictSettings() {
    return Column(
      key: const ValueKey('strict'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Info Card
        _buildInfoBox(
          "Strict Model",
          "Automated Plan. Korra automatically requires a 30% down payment from the customer. Any cancellations are refunded purely as Store Balance to protect your inventory.",
          Iconsax.shield_tick,
        ),

        SizedBox(height: 16.h),

        // 2. Extension Info
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 16.sp, color: Colors.blue),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                _priceAllowsExtension
                    ? "Automatic Extensions: Enabled (Customer gets extra time if 80% paid)."
                    : "Extensions: Not available for this price range.",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDirectSettings() {
    return Column(
      key: const ValueKey('direct'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4ED), // Light Orange for Manual Control
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Iconsax.setting_2, // Swapped to settings icon to imply control
                size: 20.sp,
                color: const Color(0xFFA54600),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  "Flexible Plan. You control the required down payment and extensions. Cancellations are still refunded as Store Balance.",
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFF344054),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),

        Text("Required Down Payment", style: _labelStyle()),
        SizedBox(height: 8.h),
        _buildInput(
          controller: _downPaymentCtrl,
          hint: "0.00",
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 14.w, right: 4.w),
            child: Text(
              "₦",
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CurrencyInputFormatter(),
          ],
        ),

        if (_priceAllowsExtension) ...[
          SizedBox(height: 20.h),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: KorraColors.brand,
            title: Text(
              "Allow Extension?",
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              "If enabled, gives customer extra time if they reach 80% payment.",
              style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
            ),
            value: _isDirectExtensionEnabled,
            onChanged: (val) {
              setState(() => _isDirectExtensionEnabled = val);
              _updatePlanLogic(); // Re-calc total time
            },
          ),
        ] else ...[
          SizedBox(height: 12.h),
          Text(
            "Extensions disabled for this price range.",
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildLimitHeader(double availableLimit) {
    // Parse current price input
    final priceInput =
        double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0.0;
    final stockInput = int.tryParse(_stockCtrl.text.replaceAll(',', '')) ?? 0;
    final totalValue =
        priceInput * (stockInput > 0 ? stockInput : 1); // Estimate value

    final isExceeded = totalValue > availableLimit;
    final progress = (availableLimit > 0)
        ? (totalValue / availableLimit).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isExceeded
            ? const Color(0xFFFEF3F2)
            : KorraColors.brandLight, // Red or Blue bg
        borderRadius: BorderRadius.circular(12.r),
        // border: Border.all(
        //   color: isExceeded ? const Color(0xFFFECDCA) : KorraColors.brandDark.withOpacity(0.3),
        // ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Reservation Limit",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isExceeded
                      ? const Color(0xFFB42318)
                      : KorraColors.brandDark,
                ),
              ),
              Text(
                "₦${NumberFormat('#,##0').format(availableLimit)} Available",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: isExceeded
                      ? const Color(0xFFB42318)
                      : KorraColors.brandDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation(
                isExceeded ? const Color(0xFFD92D20) : KorraColors.brandDark,
              ),
              minHeight: 6.h,
            ),
          ),

          if (isExceeded) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Iconsax.warning_2,
                  size: 14.sp,
                  color: const Color(0xFFB42318),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    "Product value (₦${NumberFormat.compact().format(totalValue)}) exceeds your limit.",
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: const Color(0xFFB42318),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- HELPER FOR TIMELINE ---
  Widget _buildTimelineRow(
    String label,
    String value, {
    bool isBold = false,
    bool isAlert = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: isAlert ? const Color(0xFFA54600) : Colors.grey.shade600,
              fontWeight: isAlert ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: const Color(0xFF101828),
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelTab(String label, ProductModelType model) {
    final isSelected = _selectedModel == model;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedModel = model);
          _updatePlanLogic(); // ✅ RE-CALCULATE TIMELINE
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 10.h),
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
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF101828)
                  : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    Widget? prefixIcon,
    BoxConstraints? prefixIconConstraints,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator ?? (v) => v!.trim().isEmpty ? "Required" : null,
      style: GoogleFonts.inter(
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF101828),
      ),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        prefixIcon: prefixIcon,
        prefixIconConstraints: prefixIconConstraints,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        errorStyle: GoogleFonts.inter(fontSize: 10.sp, color: const Color(0xFFD92D20)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFEAECF0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFEAECF0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: KorraColors.brand, width: 1.5),
        ),
      ),
    );
  }

  TextStyle _labelStyle() => GoogleFonts.inter(
    fontSize: 13.sp,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF344054),
  );

  Widget _buildInfoBox(String title, String desc, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8.r),
        //border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20.sp, color: const Color(0xFF667085)),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF344054),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFF667085),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

 void _showCategorySheet(BuildContext context) {
    // 1. Create a local copy of the categories and a controller for the search bar
    // 1. Point this to the new flatList
    List<String> filteredCategories = List.from(ProductCategories.flatList);
    final searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: DraggableScrollableSheet(
              initialChildSize: 0.7, 
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) => Column(
                children: [
                  SizedBox(height: 12.h),
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    "Select Category",
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  // ✅ NEW: SEARCH BAR
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: (query) {
                        setSheetState(() {
                          // 2. Point this to the new flatList as well
                          filteredCategories = ProductCategories.searchCategories(query);
                        });
                      },
                      style: GoogleFonts.inter(fontSize: 14.sp),
                      decoration: InputDecoration(
                        hintText: "Search categories...",
                        hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                        prefixIcon: const Icon(Iconsax.search_normal, color: Colors.grey, size: 18),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(color: Color(0xFFEAECF0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(color: Color(0xFFEAECF0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(color: KorraColors.brand),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  
                  // ✅ UPDATED: LIST VIEW USING filteredCategories
                  Expanded(
                    child: filteredCategories.isEmpty
                        ? Center(
                            child: Text(
                              "No categories found",
                              style: GoogleFonts.inter(
                                fontSize: 14.sp, 
                                color: Colors.grey.shade500,
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: filteredCategories.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: Color(0xFFF2F4F7)),
                            itemBuilder: (context, index) {
                              final cat = filteredCategories[index];
                              return ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 20.w),
                                title: Text(cat, style: GoogleFonts.inter(fontSize: 15.sp)),
                                onTap: () {
                                  // This updates the main page's state
                                  setState(() => _categoryCtrl.text = cat);
                                  Navigator.pop(context);
                                },
                                trailing: _categoryCtrl.text == cat
                                    ? const Icon(
                                        Iconsax.tick_circle,
                                        color: KorraColors.brand,
                                      )
                                    : null,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
