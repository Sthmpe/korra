import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/utils/currency_formatters.dart';
import '../../../../data/models/product_model.dart';
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
import 'product_limit_header.dart';
import 'product_model_tabs.dart';
import 'product_category_selector_sheet.dart';
import 'product_restriction_banner.dart';
import 'product_submit_area.dart';
import 'product_timeline_logic_box.dart';
import 'product_strict_settings_card.dart';
import 'product_direct_settings_card.dart';
import 'product_variants_editor.dart';

class AddProductPage extends StatefulWidget {
  final String vendorUid;

  const AddProductPage({
    super.key,
    required this.vendorUid,
  });

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  String _complianceStatus = 'active';

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
  bool _allowReservation = true;
  bool _isFeatured = false;

  // Optional flat variants; when non-empty the Stock field becomes the
  // computed sum (kept in _stockCtrl so the limit header and plan logic
  // keep reading it exactly as before).
  List<ProductVariant> _variants = [];

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

  late final VendorRepository vendors;

  @override
  void initState() {
    super.initState();
    vendors = context.read<VendorRepository>();

    // 2. Initialize the stream ONCE here
    _statsStream = vendors.streamVendorStats(widget.vendorUid);
    _priceCtrl.addListener(_updatePlanLogic);
    _stockCtrl.addListener(_updatePlanLogic);
    _durationCtrl.addListener(_onDurationInputChanged);

    _fetchComplianceStatus();
  }

  void _onVariantsChanged(List<ProductVariant> variants) {
    setState(() {
      _variants = variants;
      if (variants.isNotEmpty) {
        final total = variants.fold<int>(0, (acc, v) => acc + v.stock);
        // Mirror the sum into the Stock field so the limit header and plan
        // logic keep working off _stockCtrl unchanged.
        _stockCtrl.text = total.toString();
      }
    });
  }

  Future<void> _fetchComplianceStatus() async {
    try {
      final compliance = await vendors.getComplianceStatus(widget.vendorUid);
      if (mounted) {
        setState(() {
          _complianceStatus = compliance['status'] ?? 'active';
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
    final stock = _variants.isNotEmpty
        ? _variants.fold<int>(0, (acc, v) => acc + v.stock)
        : int.tryParse(_stockCtrl.text.replaceAll(',', '')) ?? 0;

    // Variant sanity: unique labels, at least one unit somewhere.
    if (_variants.isNotEmpty) {
      final labels = _variants.map((v) => v.label.toLowerCase()).toSet();
      if (labels.length != _variants.length) {
        showAppSnackbar("Variant labels must be unique.", SnackbarType.error);
        return;
      }
      if (stock <= 0) {
        showAppSnackbar("Add stock to at least one variant.", SnackbarType.error);
        return;
      }
    }

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
    // ✅ Rule 4: Manual Duration Check (only if installments are enabled)
    if (_allowReservation) {
      int finalDuration = int.tryParse(_durationCtrl.text) ?? 0;
      if (finalDuration <= 0) {
        showAppSnackbar(
          "Please enter a valid base duration.", 
          SnackbarType.error
        );
        return;
      }
    }

    // Prepare Policy
    final finalPolicy = "Store Credit";

    final imageObjects = imageBloc.state.images; 

    productBloc.add(
      VendorProductsAdd(
        name: _nameCtrl.text,
        description: _descCtrl.text,
        price: price,
        stock: stock,
        category: _categoryCtrl.text,
        images: imageObjects,
        termsAccepted: _termsAccepted,
        modelType: _allowReservation ? _selectedModel : ProductModelType.strict,
        cancellationPolicy: finalPolicy,
        extensionsEnabled: _allowReservation
            ? (_selectedModel == ProductModelType.strict
                ? _priceAllowsExtension
                : (_priceAllowsExtension && _isDirectExtensionEnabled))
            : false,
        directDownPayment: _allowReservation
            ? (_selectedModel == ProductModelType.direct
                ? double.tryParse(_downPaymentCtrl.text.replaceAll(',', ''))
                : null)
            : null,
        duration: _allowReservation ? _calculatedDurationInt : 0,
        noticePeriod: _allowReservation ? _calculatedNoticeInt : 0,
        extensionPeriod: _allowReservation ? _calculatedExtensionInt : 0,
        allowReservation: _allowReservation,
        isFeatured: _isFeatured,
        variants: _variants,
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
                buildWhen: (previous, current) =>
                    previous.isSubmitting != current.isSubmitting ||
                    previous.availableLimit != current.availableLimit,
                builder: (context, state) {
                  final isLoading = state.isSubmitting ?? false;
            
                  return Form(
                    key: _formKey,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                      children: [
                        ProductRestrictionBanner(
                          status: _complianceStatus,
                          title: "Product Creation Paused",
                        ),
                        
                        ProductLimitHeader(
                          availableLimit: state.availableLimit,
                          price: double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0.0,
                          stock: int.tryParse(_stockCtrl.text.replaceAll(',', '')) ?? 0,
                        ),
            
                        // 1. IMAGES
                        Text("Product Photos", style: _labelStyle()),
                        SizedBox(height: 8.h),
                        BlocBuilder<ImageBloc, ImageState>(
                          builder: (context, imgState) {
                            return const ImageUploadBox(
                              editable: true,
                              imagesUrl: [],
                            );
                          },
                        ),
                        SizedBox(height: 24.h),
            
                        // 2. DETAILS
                        Text("Details", style: _labelStyle()),
                        SizedBox(height: 8.h),
                        _buildInput(
                          controller: _nameCtrl,
                          hint: "Product Name",
                          maxLength: 60,
                          validator: (v) {
                            final text = v?.trim() ?? '';
                            if (text.isEmpty) return "Product title is required";
                            if (text.length < 3) return "Product title must be at least 3 characters";
                            return null;
                          },
                        ),
                        SizedBox(height: 12.h),
                        _buildInput(
                          controller: _descCtrl,
                          hint: "e.g. Premium leather sandals, available in 5 colors, true to size",
                          maxLines: 3,
                          maxLength: 200,
                          helperText: "This helps your product get found on Google.",
                          validator: (v) {
                            final text = v?.trim() ?? '';
                            if (text.isEmpty) return "Description is required";
                            if (text.length < 30) return "Description must be at least 30 characters";
                            return null;
                          },
                        ),
                        SizedBox(height: 24.h),                      // 3. ALLOW INSTALLMENTS SWITCH
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Allow Installments (Reservation)", style: _labelStyle()),
                                  SizedBox(height: 4.h),
                                  Text(
                                    "Let customers buy this product using installment plans.",
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5.sp,
                                      color: Colors.grey.shade600,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _allowReservation,
                              activeThumbColor: const Color(0xFFA54600),
                              onChanged: (val) {
                                setState(() {
                                  _allowReservation = val;
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),

                        // Featured Product switch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Feature this product", style: _labelStyle()),
                                  SizedBox(height: 4.h),
                                  Text(
                                    "Showcase this product prominently in a dedicated section on your storefront.",
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5.sp,
                                      color: Colors.grey.shade600,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isFeatured,
                              activeThumbColor: const Color(0xFFA54600),
                              onChanged: (val) {
                                setState(() {
                                  _isFeatured = val;
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),

                        // 4. DYNAMIC PRICE, STOCK, DURATION & CATEGORY FIELDS
                        if (!_allowReservation) ...[
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
                                    if (_isPriceTooHigh) ...[
                                      SizedBox(height: 4.h),
                                      Text(
                                        "Max Limit: ₦${NumberFormat('#,##0').format(_currentMaxPlanLimit)}",
                                        style: GoogleFonts.inter(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFFD92D20),
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
                            ],
                          ),
                          SizedBox(height: 24.h),
                          Text("Category", style: _labelStyle()),
                          SizedBox(height: 8.h),
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                                ),
                                builder: (ctx) => ProductCategorySelectorSheet(
                                  selectedCategory: _categoryCtrl.text,
                                  onCategorySelected: (cat) {
                                    setState(() => _categoryCtrl.text = cat);
                                  },
                                ),
                              );
                            },
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _categoryCtrl.text.isEmpty ? "Select" : _categoryCtrl.text,
                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        fontWeight: _categoryCtrl.text.isEmpty ? FontWeight.w400 : FontWeight.w600,
                                        color: _categoryCtrl.text.isEmpty ? Colors.grey.shade400 : const Color(0xFF101828),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
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
                                    if (_isPriceTooHigh) ...[
                                      SizedBox(height: 4.h),
                                      Text(
                                        "Max Limit: ₦${NumberFormat('#,##0').format(_currentMaxPlanLimit)}",
                                        style: GoogleFonts.inter(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFFD92D20),
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
                                    if ((int.tryParse(_durationCtrl.text) ?? 0) > _recommendedMinDays) ...[
                                      SizedBox(height: 6.h),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFA54600)),
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
                          SizedBox(height: 24.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Category", style: _labelStyle()),
                                    SizedBox(height: 8.h),
                                    GestureDetector(
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                                          ),
                                          builder: (ctx) => ProductCategorySelectorSheet(
                                            selectedCategory: _categoryCtrl.text,
                                            onCategorySelected: (cat) {
                                              setState(() => _categoryCtrl.text = cat);
                                            },
                                          ),
                                        );
                                      },
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
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _categoryCtrl.text.isEmpty ? "Select" : _categoryCtrl.text,
                                                style: GoogleFonts.inter(
                                                  fontSize: 14.sp,
                                                  fontWeight: _categoryCtrl.text.isEmpty ? FontWeight.w400 : FontWeight.w600,
                                                  color: _categoryCtrl.text.isEmpty ? Colors.grey.shade400 : const Color(0xFF101828),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const Icon(
                                              Icons.arrow_drop_down,
                                              size: 20,
                                              color: Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                flex: 4,
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
                            ],
                          ),
                        ],
                        SizedBox(height: 24.h),

                        // VARIANTS (optional): sizes/colors with per-variant
                        // stock; when present the Stock field above becomes
                        // the computed total.
                        ProductVariantsEditor(
                          onChanged: _onVariantsChanged,
                        ),
                        SizedBox(height: 24.h),

                        if (_allowReservation) ...[
                          // ----------------------------------------------------
                          // TIMELINE INFO
                          // ----------------------------------------------------
                          SizedBox(height: 20.h),
                          ProductTimelineLogicBox(
                            calculatedDurationInt: _calculatedDurationInt,
                            noticePeriod: _noticePeriod,
                            extensionDuration: _extensionDuration,
                            totalMaxTime: _totalMaxTime,
                            priceAllowsExtension: _priceAllowsExtension,
                          ),
              
                          SizedBox(height: 32.h),
                          const Divider(color: Color(0xFFEAECF0)),
                          SizedBox(height: 24.h),
              
                          // 4. MODEL SELECTION
                          Text("Sales Model", style: _labelStyle()),
                          SizedBox(height: 12.h),
                          ProductModelTabs(
                            selectedModel: _selectedModel,
                            onModelChanged: (model) {
                              setState(() => _selectedModel = model);
                              _updatePlanLogic(); // ✅ RE-CALCULATE TIMELINE
                            },
                          ),
              
                          SizedBox(height: 20.h),
              
                          // 5. DYNAMIC MODEL SETTINGS
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _selectedModel == ProductModelType.strict
                                ? ProductStrictSettingsCard(
                                    priceAllowsExtension: _priceAllowsExtension,
                                  )
                                : ProductDirectSettingsCard(
                                    downPaymentCtrl: _downPaymentCtrl,
                                    priceAllowsExtension: _priceAllowsExtension,
                                    isDirectExtensionEnabled: _isDirectExtensionEnabled,
                                    onExtensionChanged: (val) {
                                      setState(() => _isDirectExtensionEnabled = val);
                                      _updatePlanLogic();
                                    },
                                  ),
                          ),
                        ],
            
                        SizedBox(height: 32.h),
            
                        // 6. TERMS
                        GestureDetector(
                          onTap: () =>
                              setState(() => _termsAccepted = !_termsAccepted),
                          child: Container(
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
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
                        ProductSubmitArea(
                          status: _complianceStatus,
                          isLoading: isLoading,
                          buttonText: "Create Product",
                          onSubmit: () => _saveProduct(imageBloc, productBloc, state),
                          onResolveSupport: () => _showContactSheet(
                            context,
                            title: "Account Support",
                            subTitle: "Product creation is restricted. Please contact us to resolve this.",
                          ),
                          pausedTitle: "Creation Paused",
                          pausedMessage: "New product creation is disabled for your account. Please contact support to resolve your status.",
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





  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int? maxLength,
    String? helperText,
    Widget? prefixIcon,
    BoxConstraints? prefixIconConstraints,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
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
        helperText: helperText,
        helperStyle: GoogleFonts.inter(
          fontSize: 10.5.sp,
          color: KorraColors.brand,
          fontWeight: FontWeight.w600,
        ),
        counterStyle: GoogleFonts.inter(
          fontSize: 10.5.sp,
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
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

  void _showContactSheet(BuildContext context, {required String title, required String subTitle}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ContactSupportSheet(title: title, subTitle: subTitle),
    );
  }
}
