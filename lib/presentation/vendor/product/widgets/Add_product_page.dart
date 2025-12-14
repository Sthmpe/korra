import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/utils/currency_formatters.dart';
import '../../../../data/repository/vendors/vendor_repository.dart';
import '../../../../logic/bloc/vendor/image/image_bloc.dart';
import '../../../../logic/bloc/vendor/product/vendor_products_bloc.dart';
import '../../../../logic/bloc/vendor/product/vendor_products_event.dart';
import '../../../../logic/bloc/vendor/product/vendor_products_state.dart';
import '../../../shared/widgets/korra_header.dart';
import '../../../shared/widgets/show_app_snackbar.dart';
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

  // Controllers
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _downPaymentCtrl = TextEditingController(); // Only for Direct

  // --- LOGIC STATE ---
  ProductModelType _selectedModel = ProductModelType.strict;
  String _selectedStrictPolicy = "50% Refund";
  String _selectedDirectPolicy = "100% Refund";
  bool _isExtensionEnabled = false; 
  bool _termsAccepted = false;
  
  // DYNAMIC DISPLAY STRINGS
  bool _canOfferExtension = false;
  String _baseDuration = "15 Days";
  String _noticePeriod = "1 Day";
  String _extensionDuration = "0 Days";
  String _totalMaxTime = "16 Days";

  final List<String> _categories = [
    "Mens Clothing", "Womens Clothing", "Kids & Baby", "Shoes & Footwear",
    "Bags & Handbags", "Jewelry & Watches", "Wigs & Hair", "Accessories",
    "Phones", "Laptops", "Gadgets", "Home Appliances", "Furniture", 
    "Health & Beauty", "Food & Drinks", "Automotive" 
  ];

  @override
  void initState() {
    super.initState();
    // Listen to price changes to update Duration & Extension logic real-time
    _priceCtrl.addListener(_updatePlanLogic);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _categoryCtrl.dispose();
    _downPaymentCtrl.dispose();
    super.dispose();
  }

  // --- 🧠 THE UPDATED LOGIC BRAIN ---
  void _updatePlanLogic() {
    final cleanPrice = double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0;
    
    int baseDays = 15;
    int noticeDays = 1;
    int extDays = 0;
    bool priceAllowsExt = false;
    
    // NEW: Invalid State Flag
    bool isPriceTooHigh = false; 

    if (cleanPrice > 100000) {
      // 🛑 Over 100k Case
      isPriceTooHigh = true;
      _totalMaxTime = "--";
      _baseDuration = "--";
      _noticePeriod = "--";
    } 
    else if (cleanPrice <= 7000) {
      baseDays = 15; noticeDays = 1; priceAllowsExt = false;
    } else if (cleanPrice <= 15000) {
      baseDays = 25; noticeDays = 2; priceAllowsExt = false;
    } else if (cleanPrice <= 20000) {
      baseDays = 30; noticeDays = 3; extDays = 7; priceAllowsExt = true;
    } else if (cleanPrice <= 25000) {
      baseDays = 30; noticeDays = 3; extDays = 15; priceAllowsExt = true;
    } else if (cleanPrice <= 35000) {
      baseDays = 45; noticeDays = 5; extDays = 15; priceAllowsExt = true;
    } else if (cleanPrice <= 50000) {
      baseDays = 45; noticeDays = 10; extDays = 21; priceAllowsExt = true;
    } else if (cleanPrice <= 75000) {
      baseDays = 90; noticeDays = 10; extDays = 21; priceAllowsExt = true;
    } else {
      baseDays = 90; noticeDays = 10; extDays = 30; priceAllowsExt = true;
    }

    // 2. APPLY "DIRECT MODEL" OVERRIDE
    // Logic: If Direct Model AND Extension is Disabled -> Notice is fixed to 3 Days
    if (_selectedModel == ProductModelType.direct) {
      if (!_isExtensionEnabled) {
        noticeDays = 3; // ✅ The override you requested
        extDays = 0;    // No extension
      } 
      // If extension IS enabled in Direct, we keep the table values
    } else {
      // STRICT MODEL: Extension is forced if price allows
      if (!priceAllowsExt) extDays = 0;
    }

    // 3. CALCULATE TOTAL
    int totalDays = baseDays + noticeDays + extDays;

    if (isPriceTooHigh) {
        // Force disable extension toggles if price is invalid
        _canOfferExtension = false;
        _isExtensionEnabled = false;
    }

    setState(() {
      _canOfferExtension = priceAllowsExt;
      
      // Update Strings
      _baseDuration = "$baseDays Days";
      _noticePeriod = "$noticeDays Days";
      _extensionDuration = "$extDays Days";
      _totalMaxTime = "$totalDays Days";
      
      // Safety: If price drops and extension no longer allowed, turn off toggle
      if (!priceAllowsExt) _isExtensionEnabled = false;
    });
  }

  void _saveProduct(ImageBloc imageBloc, VendorProductsBloc productBloc, VendorProductsState state) {
    // 1. Form Validation
    if (!_formKey.currentState!.validate()) {
      showAppSnackbar("Please check your inputs.", SnackbarType.error);
      return;
    }

    // 2. Image Validation
    if (imageBloc.state.images.isEmpty) {
      showAppSnackbar("Please add at least one product image.", SnackbarType.error);
      return;
    }

    // 3. Terms Validation
    if (!_termsAccepted) {
      showAppSnackbar("You must agree to the cancellation terms.", SnackbarType.error);
      return;
    }

    // 4. Parse Values
    final priceTxt = _priceCtrl.text.replaceAll(',', '');
    final price = double.tryParse(priceTxt) ?? 0.0;
    final stock = int.tryParse(_stockCtrl.text.replaceAll(',', '')) ?? 0;
    
    // 🛑 RULE 1: MAX PRICE CAP (₦100,000)
    if (price > 100000) {
      showAppSnackbar(
        "Single product price cannot exceed ₦100,000.", 
        SnackbarType.error
      );
      return; // Stop execution
    }

    // 🛑 RULE 2: RESERVATION LIMIT CHECK
    final totalValue = price * stock;
    if (totalValue > state.availableLimit) {
      // Format numbers for a clear error message
      final formattedTotal = NumberFormat.compact().format(totalValue);
      final formattedLimit = NumberFormat.compact().format(state.availableLimit);
      
      showAppSnackbar(
        "Total value (₦$formattedTotal) exceeds your available limit (₦$formattedLimit). Reduce stock or price.", 
        SnackbarType.error
      );
      return; // Stop execution
    }

    // 🛑 RULE 3: DIRECT MODEL CHECKS
    if (_selectedModel == ProductModelType.direct) {
       final dp = double.tryParse(_downPaymentCtrl.text.replaceAll(',', '')) ?? 0;
       
       if (dp >= price) {
         showAppSnackbar("Down payment must be less than the product price.", SnackbarType.error);
         return;
       }
       if (dp <= 0) {
         showAppSnackbar("Please enter a valid down payment.", SnackbarType.error);
         return;
       }
    }

    // ✅ If all pass, proceed to Bloc
    final finalPolicy = _selectedModel == ProductModelType.strict 
        ? _selectedStrictPolicy 
        : _selectedDirectPolicy;

    productBloc.add(
      VendorProductsAdd(
        name: _nameCtrl.text,
        description: _descCtrl.text,
        price: price,
        stock: stock,
        category: _categoryCtrl.text,
        images: imageBloc.state.images,
        termsAccepted: _termsAccepted,
        modelType: _selectedModel,
        cancellationPolicy: finalPolicy,
        extensionsEnabled: _selectedModel == ProductModelType.strict 
            ? _canOfferExtension 
            : (_canOfferExtension && _isExtensionEnabled),
        directDownPayment: _selectedModel == ProductModelType.direct 
            ? double.tryParse(_downPaymentCtrl.text.replaceAll(',', '')) 
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageBloc = context.read<ImageBloc>();
    final productBloc = context.read<VendorProductsBloc>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const KorraHeader(title: "New Product", showLeadingIcon: true),
      body: BlocListener<VendorProductsBloc, VendorProductsState>(
        listener: (context, state) {
          if (state.success == true && state.isSubmitting == false) {
            showAppSnackbar("Product created successfully!", SnackbarType.success);
            context.read<VendorProductsBloc>().add(const VendorProductsRefresh());
            Navigator.pop(context);
          } else if (state.success == false && state.isSubmitting == false) {
            showAppSnackbar(state.errorMessage ?? "Failed to create product", SnackbarType.error);
          }
        },
        child: BlocBuilder<VendorProductsBloc, VendorProductsState>(
          builder: (context, state) {
            final isLoading = state.isSubmitting ?? false;

            return Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                children: [
                  _buildLimitHeader(state.availableLimit),
                  // 1. IMAGES
                  Text("Product Photos", style: _labelStyle()),
                  SizedBox(height: 8.h),
                  BlocBuilder<ImageBloc, ImageState>(
                    builder: (context, imgState) {
                      return ImageUploadBox(editable: true, imagesUrl: const []); 
                    },
                  ),
                  SizedBox(height: 24.h),

                  // 2. DETAILS
                  Text("Details", style: _labelStyle()),
                  SizedBox(height: 8.h),
                  _buildInput(controller: _nameCtrl, hint: "Product Name"),
                  SizedBox(height: 12.h),
                  _buildInput(controller: _descCtrl, hint: "Description", maxLines: 3),
                  SizedBox(height: 24.h),

                  // 3. PRICE & DURATION (Grid)
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
                                child: Text("₦", style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                              ),
                              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      // DURATION DISPLAY (Read Only, calculated from Price)
                      // Duration Readout
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Max Duration", style: _labelStyle()),
                            SizedBox(height: 8.h),
                            Container(
                              height: 48.h,
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F4F7),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: const Color(0xFFEAECF0)),
                              ),
                              child: Text(
                                _baseDuration,
                                style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // Stock & Category Row
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
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                                  border: Border.all(color: const Color(0xFFEAECF0)),
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
                                    Icon(Iconsax.arrow_down_1, size: 16.sp, color: Colors.grey),
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
                  // DYNAMIC TIMELINE INFO
                  // ----------------------------------------------------
                  SizedBox(height: 20.h),
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFEAECF0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Timeline Breakdown", style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.black87)),
                            if (_selectedModel == ProductModelType.direct && !_isExtensionEnabled)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4.r)),
                                child: Text("Direct Mode", style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.blue.shade800, fontWeight: FontWeight.w600)),
                              )
                          ],
                        ),
                        SizedBox(height: 12.h),
                        _buildTimelineRow("Base Duration", _baseDuration),
                        _buildTimelineRow("Notice Period", _noticePeriod, isAlert: true),
                        
                        // Only show extension row if it actually adds days
                        if (_selectedModel == ProductModelType.strict && _canOfferExtension)
                           _buildTimelineRow("Extension", _extensionDuration),
                        if (_selectedModel == ProductModelType.direct && _isExtensionEnabled)
                           _buildTimelineRow("Extension", _extensionDuration),

                        Divider(height: 24.h),
                        _buildTimelineRow("Total Max Time", _totalMaxTime, isBold: true),
                        
                        SizedBox(height: 12.h),
                        Text(
                          _selectedModel == ProductModelType.direct && !_isExtensionEnabled
                            ? "Standard 3-day notice applies because extensions are disabled."
                            : "Notice Period: The customer has $_noticePeriod to respond. If no response, plan defaults to Store Credit.",
                          style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade600, height: 1.4, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32.h),
                  const Divider(color: Color(0xFFEAECF0)),
                  SizedBox(height: 24.h),

                  // 4. MODEL SELECTION (The Complex Part)
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
                    duration: const Duration(milliseconds: 0),
                    child: _selectedModel == ProductModelType.strict
                        ? _buildStrictSettings()
                        : _buildDirectSettings(),
                  ),

                  SizedBox(height: 32.h),

                  // 6. TERMS
                  GestureDetector(
                    onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _termsAccepted ? KorraColors.brand : const Color(0xFFEAECF0),
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        color: _termsAccepted ? const Color(0xFFFFF4ED) : Colors.white,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _termsAccepted ? Iconsax.tick_square : Iconsax.square,
                            size: 20.sp,
                            color: _termsAccepted ? KorraColors.brand : Colors.grey,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              "I accept the cancellation terms and agree to offer extensions if requested by the customer.",
                              style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF475467), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // 7. SUBMIT
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => _saveProduct(imageBloc, productBloc, state),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KorraColors.brand,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        disabledBackgroundColor: KorraColors.brand.withOpacity(0.6),
                      ),
                      child: isLoading 
                        ? SizedBox(width: 24.w, height: 24.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text("Create Product", style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- MODEL SPECIFIC WIDGETS ---

  Widget _buildStrictSettings() {
    return Column(
      key: const ValueKey('strict'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBox(
          "Strict Model", 
          "Down payments are auto-calculated by Korra. You only set the cancellation penalty.",
          Iconsax.shield_tick
        ),
        SizedBox(height: 20.h),
        Text("If customer defaults, you offer:", style: _labelStyle()),
        SizedBox(height: 8.h),
        _buildDropdown(
          value: _selectedStrictPolicy,
          items: ["50% Refund", "Store Credit"],
          onChanged: (v) => setState(() => _selectedStrictPolicy = v!),
        ),
        SizedBox(height: 20.h),
        // Strict Extension Info (Auto)
        Row(
          children: [
            Icon(_canOfferExtension ? Iconsax.tick_circle : Iconsax.close_circle, 
                 size: 20.sp, 
                 color: _canOfferExtension ? Colors.green : Colors.grey),
            SizedBox(width: 8.w),
            Text(
              _canOfferExtension ? "Extensions are available for this price." : "No extensions available for this price range.",
              style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
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
            color: const Color(0xFFFFF4ED), // Warning Orange
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: const Color(0xFFFFE0D0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Iconsax.warning_2, size: 20.sp, color: const Color(0xFFA54600)),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  "Recommended for repeat customers only. For new customers, use Strict Lock for better security.",
                  style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF344054), height: 1.4),
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
            child: Text("₦", style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
        ),

        SizedBox(height: 20.h),
        Text("Refund Policy (If Defaulted)", style: _labelStyle()),
        SizedBox(height: 8.h),
        _buildDropdown(
          value: _selectedDirectPolicy,
          items: ["100% Refund", "90% Refund", "80% Refund", "70% Refund", "60% Refund", "50% Refund", "Store Credit"],
          onChanged: (v) => setState(() => _selectedDirectPolicy = v!),
        ),

        if (_canOfferExtension) ...[
          SizedBox(height: 20.h),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: KorraColors.brand,
            title: Text("Allow Extension?", style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600)),
            subtitle: Text(
              "If enabled, final resolve defaults to 50% Refund or Store Credit.",
              style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
            ),
            value: _isExtensionEnabled,
            onChanged: (val) {
               setState(() => _isExtensionEnabled = val);
               _updatePlanLogic(); // ✅ RE-CALCULATE TIMELINE
            },
          ),
        ] else ...[
          SizedBox(height: 12.h),
          Text(
            "Extensions not available for this price range.",
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
          )
        ]
      ],
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildLimitHeader(double availableLimit) {
    // Parse current price input
    final priceInput = double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0.0;
    final stockInput = int.tryParse(_stockCtrl.text.replaceAll(',', '')) ?? 0;
    final totalValue = priceInput * (stockInput > 0 ? stockInput : 1); // Estimate value

    final isExceeded = totalValue > availableLimit;
    final progress = (availableLimit > 0) ? (totalValue / availableLimit).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isExceeded ? const Color(0xFFFEF3F2) : const Color(0xFFF0F9FF), // Red or Blue bg
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isExceeded ? const Color(0xFFFECDCA) : const Color(0xFFB2DDFF),
        ),
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
                  color: isExceeded ? const Color(0xFFB42318) : const Color(0xFF004EEB),
                ),
              ),
              Text(
                "₦${NumberFormat('#,##0').format(availableLimit)} Available",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: isExceeded ? const Color(0xFFB42318) : const Color(0xFF004EEB),
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
                isExceeded ? const Color(0xFFD92D20) : const Color(0xFF2E90FA),
              ),
              minHeight: 6.h,
            ),
          ),
          
          if (isExceeded) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Iconsax.warning_2, size: 14.sp, color: const Color(0xFFB42318)),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    "Product value (₦${NumberFormat.compact().format(totalValue)}) exceeds your limit.",
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: const Color(0xFFB42318),
                      fontWeight: FontWeight.w500
                    ),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }

  // --- HELPER FOR TIMELINE ---
  Widget _buildTimelineRow(String label, String value, {bool isBold = false, bool isAlert = false}) {
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
              fontWeight: isAlert ? FontWeight.w600 : FontWeight.w500
            )
          ),
          Text(
            value, 
            style: GoogleFonts.inter(
              fontSize: 13.sp, 
              color: const Color(0xFF101828), 
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500
            )
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
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isSelected ? const Color(0xFF101828) : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<String> items, required Function(String?) onChanged}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Iconsax.arrow_down_1, size: 18, color: Colors.grey),
          items: items.map((e) => DropdownMenuItem(
            value: e,
            child: Text(e, style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w500, color: const Color(0xFF101828))),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildInfoBox(String title, String desc, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFEAECF0)),
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
                Text(title, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, color: const Color(0xFF344054))),
                SizedBox(height: 4.h),
                Text(desc, style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF667085), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({required TextEditingController controller, required String hint, int maxLines = 1, Widget? prefixIcon, BoxConstraints? prefixIconConstraints, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: (v) => v!.isEmpty ? "Required" : null,
      style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w600, color: const Color(0xFF101828)),
      cursorColor: KorraColors.brand,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14.sp),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        prefixIcon: prefixIcon,
        prefixIconConstraints: prefixIconConstraints,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Color(0xFFEAECF0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Color(0xFFEAECF0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: KorraColors.brand, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Color(0xFFFDA29B))),
      ),
    );
  }

  TextStyle _labelStyle() => GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF344054));

  void _showCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            SizedBox(height: 12.h),
            Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            SizedBox(height: 16.h),
            Text("Select Category", style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700)),
            SizedBox(height: 16.h),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF2F4F7)),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  return ListTile(
                    title: Text(cat, style: GoogleFonts.inter(fontSize: 15.sp)),
                    onTap: () { setState(() => _categoryCtrl.text = cat); Navigator.pop(context); },
                    trailing: _categoryCtrl.text == cat ? const Icon(Iconsax.tick_circle, color: KorraColors.brand) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}