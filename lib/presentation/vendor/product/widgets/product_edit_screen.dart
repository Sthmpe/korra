import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'product_category_selector_sheet.dart';
import 'product_model_tabs.dart';
import 'product_restriction_banner.dart';
import 'product_submit_area.dart';
import 'product_timeline_logic_box.dart';
import 'product_strict_settings_card.dart';
import 'product_direct_settings_card.dart';
import 'product_variants_editor.dart';

class ProductEditScreen extends StatefulWidget {
  final ProductItem product;
  final String vendorUid;

  const ProductEditScreen({
    super.key, 
    required this.product,
    required this.vendorUid
  });

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();

  String _complianceStatus = 'active';

  late TextEditingController nameCtrl;
  late TextEditingController descCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController stockCtrl;
  late TextEditingController categoryCtrl;
  late TextEditingController codeCtrl;

  late TextEditingController _downPaymentCtrl;
  late TextEditingController _durationCtrl;
  ProductModelType _selectedModel = ProductModelType.strict;
  bool _isDirectExtensionEnabled = false;

  int _recommendedMinDays = 14;
  bool _priceAllowsExtension = false;
  int _calculatedDurationInt = 14;
  int _calculatedNoticeInt = 3;
  int _calculatedExtensionInt = 3;
  String _noticePeriod = "3 Days";
  String _extensionDuration = "None";
  String _totalMaxTime = "17 Days";
  double _currentMaxPlanLimit = 1000000;
  bool _isPriceTooHigh = false;
  late Stream<VendorStats> _statsStream;

  // --- 🔒 PERMISSIONS ---
  bool _canEditIdentity = true;
  bool _canEditCommerce = true;
  bool _allowReservation = true;
  bool _isFeatured = false;

  // Optional flat variants; when non-empty the Stock field mirrors the sum.
  List<ProductVariant> _variants = [];

  String? _helperMessage;

  late final VendorRepository _vendors;

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _onVariantsChanged(List<ProductVariant> variants) {
    setState(() {
      _variants = variants;
      if (variants.isNotEmpty) {
        final total = variants.fold<int>(0, (acc, v) => acc + v.stock);
        // Mirror the sum into the Stock field so the limit math and UI
        // keep reading stockCtrl unchanged.
        stockCtrl.text = total.toString();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _vendors = context.read<VendorRepository>();
    final p = widget.product;

    _statsStream = _vendors.streamVendorStats(widget.vendorUid);

    // Init Controllers
    nameCtrl = TextEditingController(text: p.name);
    descCtrl = TextEditingController(text: p.description);
    priceCtrl = TextEditingController(
      text: p.priceText.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    stockCtrl = TextEditingController(text: p.stock.toString());
    _variants = List<ProductVariant>.from(p.variants);
    categoryCtrl = TextEditingController(text: p.category);
    codeCtrl = TextEditingController(text: p.code);
    _allowReservation = p.allowReservation;
    _isFeatured = p.isFeatured;
    _selectedModel = p.modelType;
    _downPaymentCtrl = TextEditingController(
      text: p.directDownPayment != null
          ? p.directDownPayment!.toStringAsFixed(0)
          : '',
    );
    final baseDurationStr = p.baseDuration.replaceAll(RegExp(r'[^0-9]'), '');
    _durationCtrl = TextEditingController(text: baseDurationStr);

    _isDirectExtensionEnabled = p.extensionsEnabled;

    priceCtrl.addListener(_onTextChanged);
    stockCtrl.addListener(_onTextChanged);
    priceCtrl.addListener(_updatePlanLogic);
    _durationCtrl.addListener(_onDurationInputChanged);
    _downPaymentCtrl.addListener(_onTextChanged);

    // --- DETERMINE PERMISSIONS ---
    if (p.status == ProductStatus.approved) {
      _canEditIdentity = false;
      _canEditCommerce = true;
      _helperMessage =
          "Product is Live. You can update Price & Stock, but Name/Description are locked.";
    } else if (p.status == ProductStatus.pending) {
      _canEditIdentity = false;
      _canEditCommerce = false;
      _helperMessage = "Product is under review and cannot be edited.";
    } else if (p.status == ProductStatus.rejected) {
      _canEditIdentity = true;
      _canEditCommerce = true;
      _helperMessage =
          "This product was rejected. Please fix issues and resubmit.";
    }

    _fetchComplianceStatus();
    _updatePlanLogic();
  }

  void _onDurationInputChanged() {
    _updatePlanLogic();
  }

  void _updatePlanLogic() {
    final cleanPrice = double.tryParse(priceCtrl.text.replaceAll(',', '')) ?? 0;
    final double calculationCeiling = _currentMaxPlanLimit; 

    int recMinDays = 14;
    int noticeDays = 1;
    int extDays = 0;
    bool allowExt = false;

    _isPriceTooHigh = false;

    if (cleanPrice > calculationCeiling) {
       _isPriceTooHigh = true;
    }

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

    int currentInput = int.tryParse(_durationCtrl.text) ?? 0;
    int effectiveDays = currentInput;

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
        _noticePeriod = "$noticeDays Day";
        _extensionDuration = allowExt ? "$extDays Days" : "None";
        _totalMaxTime = "$totalDays Days";
      }
    });
  }

  Future<void> _fetchComplianceStatus() async {
    try {
      final compliance = await _vendors.getComplianceStatus(widget.vendorUid);
      if (mounted) {
        setState(() {
          _complianceStatus = compliance['status'] ?? 'active';
        });
      }
    } catch (e) {
      debugPrint("Error fetching status: $e");
    }
  }

  TextStyle _labelStyle() {
    return GoogleFonts.inter(
      fontSize: 13.sp,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF344054),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    bool enabled = true,
    bool readOnly = false,
    int maxLines = 1,
    int? maxLength,
    String? helperText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    BoxConstraints? prefixIconConstraints,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      maxLength: enabled ? maxLength : null,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.inter(
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
        color: enabled ? const Color(0xFF101828) : Colors.grey.shade500,
      ),
      cursorColor: KorraColors.brand,
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
        errorStyle: GoogleFonts.inter(fontSize: 10.sp, color: const Color(0xFFD92D20)),
        filled: true,
        fillColor: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF2F4F7),
        prefixIcon: prefixIcon,
        prefixIconConstraints: prefixIconConstraints,
        suffixIcon: suffixIcon,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFEAECF0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFEAECF0)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: KorraColors.brand, width: 1.5),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    stockCtrl.dispose();
    categoryCtrl.dispose();
    codeCtrl.dispose();
    _downPaymentCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  void _saveChanges(
    ImageBloc imageBloc,
    VendorProductsBloc productBloc,
    VendorProductsState state,
  ) {
    if (!_formKey.currentState!.validate()) {
      showAppSnackbar("Please check your inputs", SnackbarType.error);
      return;
    }

    final priceTxt = priceCtrl.text.replaceAll(',', '');
    final price = double.tryParse(priceTxt) ?? 0.0;
    final stock = _variants.isNotEmpty
        ? _variants.fold<int>(0, (acc, v) => acc + v.stock)
        : int.tryParse(stockCtrl.text) ?? 0;

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

    productBloc.add(
      VendorProductsEdit(
        productCode: widget.product.code,
        name: nameCtrl.text,
        description: descCtrl.text,
        price: price,
        stock: stock,
        category: categoryCtrl.text,
        newImages: _canEditIdentity ? imageBloc.state.images : [],
        existingImageUrls: widget.product.imageUrl,
        status: widget.product.status,
        allowReservation: _allowReservation,
        modelType: _allowReservation ? _selectedModel : ProductModelType.strict,
        cancellationPolicy: "Store Credit",
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
        isFeatured: _isFeatured,
        variants: _variants,
      ),
    );
  }

  void _showContactSheet(BuildContext context, {required String title, required String subTitle}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ContactSupportSheet(title: title, subTitle: subTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageBloc = context.read<ImageBloc>();
    final productBloc = context.read<VendorProductsBloc>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const KorraHeader(title: "Edit Product", showLeadingIcon: true),
      body: BlocListener<VendorProductsBloc, VendorProductsState>(
        listenWhen: (previous, current) => previous.success != current.success,
        listener: (context, state) {
          if (state.success == true && state.isSubmitting == false) {
            showAppSnackbar("Changes saved successfully", SnackbarType.success);
            context.read<VendorProductsBloc>().add(
              const VendorProductsRefresh(),
            );
            Navigator.pop(context);
          } else if (state.success == false && state.isSubmitting == false) {
            showAppSnackbar(
              state.errorMessage ?? "Failed to save",
              SnackbarType.error,
            );
          }
        },
        child: StreamBuilder<VendorStats>(
          stream: _statsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final stats = snapshot.data ?? VendorStats.empty();
            if (_currentMaxPlanLimit != stats.maxPlanAmount) {
              _currentMaxPlanLimit = stats.maxPlanAmount;
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
                        title: "Product Edit Paused",
                      ),

                      // 1. LIMIT HEADER (Live Feedback)
                      ProductLimitHeader(
                        availableLimit: state.availableLimit,
                        price: double.tryParse(priceCtrl.text.replaceAll(',', '')) ?? 0.0,
                        stock: int.tryParse(stockCtrl.text.replaceAll(',', '')) ?? 0,
                      ),

                      // 2. HELPER MESSAGE
                      if (_helperMessage != null) ...[
                        Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20.sp,
                                color: Colors.grey.shade600,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  _helperMessage!,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    color: Colors.grey.shade700,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24.h),
                      ],

                      // 3. READ ONLY CODE
                      Text("Product Code", style: _labelStyle()),
                      SizedBox(height: 6.h),
                      _buildInput(
                        controller: codeCtrl,
                        hint: "Code",
                        enabled: false,
                        readOnly: true,
                      ),
                      SizedBox(height: 20.h),

                      // 4. IMAGES (Identity)
                      Text("Product Photos", style: _labelStyle()),
                      SizedBox(height: 6.h),
                      BlocBuilder<ImageBloc, ImageState>(
                        builder: (context, imgState) {
                          return ImageUploadBox(
                            editable: _canEditIdentity,
                            imagesUrl: widget.product.imageUrl,
                          );
                        },
                      ),
                      SizedBox(height: 24.h),

                      // 5. DETAILS (Identity)
                      Text("Details", style: _labelStyle()),
                      SizedBox(height: 6.h),
                      // Name and description are permanently locked on edit
                      // (David, 10 July 2026): identity is set at creation and
                      // never changes afterwards, regardless of status.
                      _buildInput(
                        controller: nameCtrl,
                        hint: "Name",
                        enabled: false,
                        readOnly: true,
                      ),
                      SizedBox(height: 12.h),
                      _buildInput(
                        controller: descCtrl,
                        hint: "Description",
                        maxLines: 4,
                        enabled: false,
                        readOnly: true,
                      ),

                      SizedBox(height: 24.h),
                      // 6. ALLOW INSTALLMENTS SWITCH (Moved to top of details)
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

                      // Featured switch
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

                      // 7. DYNAMIC PRICE, STOCK, DURATION & CATEGORY FIELDS
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
                                  SizedBox(height: 6.h),
                                  _buildInput(
                                    controller: priceCtrl,
                                    hint: "0.00",
                                    enabled: _canEditCommerce,
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.only(left: 14.w, right: 4.w),
                                      child: Text(
                                        "₦",
                                        style: GoogleFonts.inter(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w600,
                                          color: _canEditCommerce ? Colors.grey.shade600 : Colors.grey.shade400,
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
                                  SizedBox(height: 6.h),
                                  _buildInput(
                                    controller: stockCtrl,
                                    hint: "Qty",
                                    enabled: true,
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
                        SizedBox(height: 6.h),
                        GestureDetector(
                          onTap: _canEditIdentity
                              ? () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                                    ),
                                    builder: (ctx) => ProductCategorySelectorSheet(
                                      selectedCategory: categoryCtrl.text,
                                      onCategorySelected: (cat) {
                                        setState(() => categoryCtrl.text = cat);
                                      },
                                    ),
                                  );
                                }
                              : null,
                          child: AbsorbPointer(
                            child: _buildInput(
                              controller: categoryCtrl,
                              hint: "Category",
                              enabled: _canEditIdentity,
                              readOnly: true,
                              suffixIcon: _canEditIdentity ? const Icon(Icons.arrow_drop_down, size: 20) : null,
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
                                  SizedBox(height: 6.h),
                                  _buildInput(
                                    controller: priceCtrl,
                                    hint: "0.00",
                                    enabled: _canEditCommerce,
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.only(left: 14.w, right: 4.w),
                                      child: Text(
                                        "₦",
                                        style: GoogleFonts.inter(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w600,
                                          color: _canEditCommerce ? Colors.grey.shade600 : Colors.grey.shade400,
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
                                  SizedBox(height: 6.h),
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
                                  SizedBox(height: 6.h),
                                  GestureDetector(
                                    onTap: _canEditIdentity
                                        ? () {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                                              ),
                                              builder: (ctx) => ProductCategorySelectorSheet(
                                                selectedCategory: categoryCtrl.text,
                                                onCategorySelected: (cat) {
                                                  setState(() => categoryCtrl.text = cat);
                                                },
                                              ),
                                            );
                                          }
                                        : null,
                                    child: AbsorbPointer(
                                      child: _buildInput(
                                        controller: categoryCtrl,
                                        hint: "Category",
                                        enabled: _canEditIdentity,
                                        readOnly: true,
                                        suffixIcon: _canEditIdentity ? const Icon(Icons.arrow_drop_down, size: 20) : null,
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
                                  SizedBox(height: 6.h),
                                  _buildInput(
                                    controller: stockCtrl,
                                    hint: "Qty",
                                    enabled: true,
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

                      // VARIANTS (optional): editable any time after listing;
                      // the Stock field above becomes the computed total.
                      ProductVariantsEditor(
                        initialVariants: widget.product.variants,
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

                        // Sales Model Selection
                        Text("Sales Model", style: _labelStyle()),
                        SizedBox(height: 12.h),
                        ProductModelTabs(
                          selectedModel: _selectedModel,
                          onModelChanged: (model) {
                            setState(() => _selectedModel = model);
                            _updatePlanLogic();
                          },
                        ),
                        SizedBox(height: 20.h),

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

                      // 8. SAVE
                      ProductSubmitArea(
                        status: _complianceStatus,
                        isLoading: isLoading,
                        buttonText: "Save Changes",
                        onSubmit: () => _saveChanges(imageBloc, productBloc, state),
                        onResolveSupport: () => _showContactSheet(
                          context,
                          title: "Account Support",
                          subTitle: "Product edit is restricted. Please contact us to resolve this.",
                        ),
                        pausedTitle: "Edit Paused",
                        pausedMessage: "Product editing is disabled for your account. Please contact support to resolve your status.",
                      ),

                      SizedBox(height: 32.h),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
