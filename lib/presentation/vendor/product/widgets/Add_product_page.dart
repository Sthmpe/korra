import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:korra/data/repository/vendors/vendor_repository.dart';

import '../../../../config/utils/currency_formatters.dart';
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

  // Images and categories
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
  String? _selectedCategory;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.inter(fontSize: 14.sp),
      decoration: _inputDecoration(label),
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration("Category"),
      value: _selectedCategory,
      dropdownColor: Colors.grey[200],
      isExpanded: false,
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
      onChanged: (val) {
        setState(() {
          _selectedCategory = val;
          _categoryCtrl.text = val ?? '';
        });
      },
      validator: (val) =>
          (val == null || val.isEmpty) ? "Select category" : null,
    );
  }

  Future<void> _saveProduct(
    ImageBloc imageBloc,
    VendorProductsBloc productBloc,
  ) async {
    try {
      if (!_formKey.currentState!.validate()) {
        showAppSnackbar("Please fill all required fields", SnackbarType.error);
        return;
      }

      String priceTxt = _priceCtrl.text.replaceAll(',', '');

      if (priceTxt.endsWith('.')) {
        priceTxt = priceTxt.substring(0, priceTxt.length - 1);
      }

      // When upload is done, VendorProductsBloc listener will fire
      productBloc.add(
        VendorProductsAdd(
          name: _nameCtrl.text,
          description: _descCtrl.text,
          price: double.tryParse(priceTxt) ?? 0,
          stock: int.tryParse(_stockCtrl.text) ?? 0,
          category: _categoryCtrl.text,
          images: imageBloc.state.images, // will be updated after upload
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

  @override
  Widget build(BuildContext context) {
    final imageBloc = context.read<ImageBloc>();
    final productBloc = context.read<VendorProductsBloc>();

    return Scaffold(
      appBar: KorraHeader(
        title: 'Add Product',
        showLeadingIcon: true,
        trailingActions: [],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<VendorProductsBloc, VendorProductsState>(
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
              } else if (state.isSubmitting == false &&
                  state.success == false) {
                final message = state.errorMessage?.isNotEmpty == true
                    ? state.errorMessage
                    : "Failed to add product";
                showAppSnackbar(
                  message ?? "Failed to add product.",
                  SnackbarType.error,
                );
              }
            },
          ),
        ],
        child: BlocBuilder<VendorProductsBloc, VendorProductsState>(
          builder: (context, productState) {
            return BlocBuilder<ImageBloc, ImageState>(
              builder: (context, imageState) {
                final isLoading = (productState.isSubmitting ?? false);

                return Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        _buildTextField(
                          controller: _nameCtrl,
                          label: "Product Name",
                          validator: (val) =>
                              val!.isEmpty ? "Enter product name" : null,
                        ),
                        SizedBox(height: 12.h),
                        _buildTextField(
                          controller: _descCtrl,
                          label: "Description",
                          maxLines: 3,
                          validator: (val) =>
                              val!.isEmpty ? "Enter description" : null,
                        ),
                        SizedBox(height: 12.h),
                        TextFormField(
                          controller: _priceCtrl,
                          style: GoogleFonts.inter(fontSize: 14.sp),
                          decoration: _inputDecoration("Price").copyWith(
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
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                            CurrencyInputFormatter(decimalRange: 2),
                          ],
                          validator: (val) =>
                              val!.isEmpty ? "Enter price" : null,
                        ),
                        SizedBox(height: 12.h),
                        _buildTextField(
                          controller: _stockCtrl,
                          label: "Quantity in Stock",
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (val) =>
                              val!.isEmpty ? "Enter quantity in stock" : null,
                        ),
                        SizedBox(height: 12.h),
                        _buildCategoryDropdown(),
                        SizedBox(height: 12.h),
                        ImageUploadBox(editable: true, imagesUrl: const []),
                        SizedBox(height: 20.h),
                        SizedBox(
                          height: 50.h,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA54600),
                              disabledBackgroundColor: Color(
                                0xFFA54600,
                              ).withOpacity(0.8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            onPressed: isLoading
                                ? null
                                : () => _saveProduct(imageBloc, productBloc),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isLoading) Spacer(),
                                Text(
                                  isLoading ? "Adding..." : "Add Product",
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
                          ),
                        ),
                      ],
                    ),
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
