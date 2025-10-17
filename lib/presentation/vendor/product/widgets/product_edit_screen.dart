import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:korra/config/constants/colors.dart';
import 'package:korra/logic/bloc/vendor/image/image_bloc.dart';

import '../../../../config/utils/currency_formatters.dart';
import '../../../../logic/bloc/vendor/product/vendor_products_bloc.dart';
import '../../../../logic/bloc/vendor/product/vendor_products_event.dart';
import '../../../../logic/bloc/vendor/product/vendor_products_state.dart';
import '../../../shared/widgets/korra_header.dart';
import '../../../shared/widgets/show_app_snackbar.dart';
import 'image_upload_box.dart';

class ProductEditScreen extends StatefulWidget {
  final ProductItem product;
  const ProductEditScreen({super.key, required this.product});

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController nameCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController stockCtrl;
  late TextEditingController descCtrl;
  late TextEditingController codeCtrl;
  late TextEditingController _categoryCtrl;

  final List<String> _categories = [
    "mens clothing",
    "womens clothing",
    "kids & babyclothing",
    "shoes & footwear",
    "bags & handbags",
    "jewelry & watches",
    "wigs & humanhair",
    "accessories",
    "undergarments & sleepwear",
    "sportswear fitness",
    "perfumes",
    "deodorants",
    "lotions",
    "creams",
    "skincare",
    "makeup & beauty",
    "haircare products",
    "grooming & personal care",
    "gift items",
    "student backpacks",
    "stationery supplies",
    "study lamps",
    "desk items",
    "hostel essentials",
    "laptops",
    "tablets",
    "phones",
    "smart devices",
    "phone accessories",
    "audio devices",
    "tvs",
    "monitors",
    "cameras",
    "gadgets",
    "powerbanks",
    "chargers",
    "generators",
    "solar panels",
    "inverters",
    "lamps",
    "lighting",
    "small appliances",
    "large appliances",
    "kitchenware",
    "beddings",
    "mattress",
    "furniture",
    "home decor",
    "tools machines",
    "sewing machines",
    "health supplements",
    "hygiene & sanitation",
    "packaged food",
    "drinks & beverages",
    "baby clothes",
    "baby accessories",
    "babycare",
    "diapers",
    "toys & games",
    "travel bags",
    "suitcases",
    "outdoor camping",
    "car accessories",
    "motorcycle accessories",
    "general electronics",
  ];

  Future<void> _saveProduct(
    ImageBloc imageBloc,
    VendorProductsBloc productBloc,
    ProductItem product,
  ) async {
    try {
      if (!_formKey.currentState!.validate()) {
        showAppSnackbar("Please fill all required fields", SnackbarType.error);
        return;
      }

      String priceTxt = priceCtrl.text.replaceAll(',', '');

      if (priceTxt.endsWith('.')) {
        priceTxt = priceTxt.substring(0, priceTxt.length - 1);
      }

      productBloc.add(
        VendorProductsEdit(
          name: nameCtrl.text,
          description: descCtrl.text,
          price:
              double.tryParse(priceTxt.replaceAll(RegExp(r'[^0-9.]'), '')) ??
              0.0,
          stock:
              int.tryParse(stockCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
              0,
          category: _categoryCtrl.text,
          newImages: imageBloc.state.images, // will be updated after upload
          productCode: codeCtrl.text,
          existingImageUrls: product.imageUrl,
          status: product.status,
        ),
      );
    } catch (e) {
      debugPrint("Error adding product: $e");
      showAppSnackbar(
        "Error adding product. Please try again.",
        SnackbarType.error,
      );
      return;
    }
  }

  InputDecoration _inputDecoration(String label, bool enabled) => InputDecoration(
    floatingLabelBehavior: FloatingLabelBehavior.never,
    filled: true,
    fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade200,
    labelText: label,
    labelStyle: GoogleFonts.inter(
      fontSize: 14.sp,
      fontWeight: FontWeight.w500,
      color: Colors.grey[800],
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(width: 0.5.w, color: Colors.red),
      borderRadius: BorderRadius.circular(12.r),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: BorderSide(width: 0.5.w, color: Colors.red),
      borderRadius: BorderRadius.circular(12.r),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(width: 0.5.w, color: Colors.grey.shade400),
      borderRadius: BorderRadius.circular(12.r),
    ),
    errorStyle: GoogleFonts.inter(fontSize: 12.sp),
  );

  String? _selectedCategory;
  bool canEdit = true;

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    stockCtrl.dispose();
    codeCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    nameCtrl = TextEditingController(text: p.name);
    priceCtrl = TextEditingController(
      text: p.priceText.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    stockCtrl = TextEditingController(text: p.stock.toString());
    descCtrl = TextEditingController(text: p.description);
    codeCtrl = TextEditingController(text: p.code);
    _selectedCategory = p.category;
    _categoryCtrl = TextEditingController(text: p.category);

    // Determine edit permissions based on status
    if (p.status == ProductStatus.pending) canEdit = false;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final status = p.status;
    final imageBloc = context.read<ImageBloc>();
    final productBloc = context.read<VendorProductsBloc>();

    String helperText = "";
    if (status == ProductStatus.pending) {
      helperText = "This product is pending review and cannot be edited yet.";
    } else if (status == ProductStatus.approved) {
      helperText =
          "You can only update the stock for an approved product.";
    } else if (status == ProductStatus.rejected) {
      helperText =
          "This product was rejected please fix and resubmit for review.";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: KorraHeader(
        title: 'Edit Product',
        showLeadingIcon: true,
        trailingActions: [],
      ),
      body: BlocListener<VendorProductsBloc, VendorProductsState>(
        listener: (context, state) {
          if (state.isSubmitting == false && state.success == true) {
            showAppSnackbar(
              "Product added successfully!",
              SnackbarType.success,
            );

            // 🔥 Trigger refresh so VendorProductsBody updates
            context.read<VendorProductsBloc>().add(
              const VendorProductsRefresh(),
            );

            if (mounted) Navigator.pop(context);
          } else if (state.isSubmitting == false && state.success == false) {
            final message = state.errorMessage?.isNotEmpty == true
                ? state.errorMessage
                : "Failed to add product";
            showAppSnackbar(
              message ?? "Failed to add product.",
              SnackbarType.error,
            );
          }
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (helperText.isNotEmpty)
                  Text(
                    helperText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13.5.sp,
                      color: Colors.grey.shade700,
                    ),
                  ),
                if (helperText.isNotEmpty) SizedBox(height: 16.h),
                _buildTextField('Product Code', codeCtrl, enabled: false),
                SizedBox(height: 12.h),
                _buildTextField(
                  "Product Name",
                  nameCtrl,
                  enabled: status == ProductStatus.rejected,
                ),
                SizedBox(height: 12.h),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Price",
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    TextFormField(
                      controller: priceCtrl,
                      style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.black87),
                      enabled: status == ProductStatus.rejected,
                      decoration: _inputDecoration("Price", status == ProductStatus.rejected).copyWith(
                        prefixText: "₦ ",
                        prefixStyle: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        CurrencyInputFormatter(decimalRange: 2),
                      ],
                      validator: (val) => val!.isEmpty ? "Enter price" : null,
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _buildTextField(
                  "Stock",
                  stockCtrl,
                  keyboardType: TextInputType.number,
                  enabled: status != ProductStatus.pending,
                ),
                SizedBox(height: 12.h),
                _buildTextField(
                  "Description",
                  descCtrl,
                  maxLines: 4,
                  enabled: status == ProductStatus.rejected,
                ),
                SizedBox(height: 12.h),
                _buildCategoryDropdown(
                  "Category",
                  _categoryCtrl,
                  enabled: status == ProductStatus.rejected,
                ),
                SizedBox(height: 20.h),

                ImageUploadBox(
                  editable:
                      !(p.status == ProductStatus.pending ||
                          p.status == ProductStatus.approved),
                  imagesUrl: p.imageUrl,
                ),

                SizedBox(height: 25.h),

                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: BlocBuilder<VendorProductsBloc, VendorProductsState>(
                    builder: (context, productState) {
                      final isLoading = (productState.isSubmitting ?? false);

                      return ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () => _saveProduct(imageBloc, productBloc, p),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (status == ProductStatus.pending)
                              ? KorraColors.brand.withOpacity(0.8)
                              : KorraColors.brand,
                          disabledBackgroundColor: KorraColors.brand
                              .withOpacity(0.8),
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isLoading) Spacer(),
                            Text(
                              isLoading ? "Saving changes..." : "Save change",
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            if (isLoading) Spacer(),
                            if (isLoading)
                              SizedBox(
                                height: 25.h,
                                width: 25.w,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.w,
                                ),
                              ),
                            if (isLoading) SizedBox(width: 4.w),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4.h),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.black87),
          decoration: _inputDecoration(label, enabled),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(
    String label,
    TextEditingController controller, {
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4.h),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade200,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 14.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: KorraColors.brand),
            ),
          ),
          value: _selectedCategory,
          dropdownColor: Colors.grey[50],
          isExpanded: true,
          items: _categories
              .map(
                (cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(
                    cat,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: Colors.black87,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: enabled
              ? (val) {
                  setState(() {
                    _selectedCategory = val;
                    _categoryCtrl.text = val ?? '';
                  });
                }
              : null,
          validator: (val) =>
              (val == null || val.isEmpty) ? "Select category" : null,
        ),
      ],
    );
  }
}
