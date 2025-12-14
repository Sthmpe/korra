import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/utils/currency_formatters.dart';
import '../../../../logic/bloc/vendor/image/image_bloc.dart';
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

  late TextEditingController nameCtrl;
  late TextEditingController descCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController stockCtrl;
  late TextEditingController categoryCtrl;
  late TextEditingController codeCtrl;

  // Permissions
  bool _canEditDetails = true;
  String? _helperMessage;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    
    // Init Controllers
    nameCtrl = TextEditingController(text: p.name);
    descCtrl = TextEditingController(text: p.description);
    // Strip symbols for raw editing
    priceCtrl = TextEditingController(text: p.priceText.replaceAll(RegExp(r'[^0-9.]'), ''));
    stockCtrl = TextEditingController(text: p.stock.toString());
    categoryCtrl = TextEditingController(text: p.category);
    codeCtrl = TextEditingController(text: p.code);
    
    // Determine Logic
    if (p.status == ProductStatus.approved) {
      _canEditDetails = false;
      _helperMessage = "Active products cannot be renamed. Only stock can be updated.";
    } else if (p.status == ProductStatus.pending) {
      _canEditDetails = false;
      _helperMessage = "Product is under review.";
    } else if (p.status == ProductStatus.rejected) {
      _canEditDetails = true;
      _helperMessage = "This product was rejected. Please fix issues and resubmit.";
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose(); descCtrl.dispose(); priceCtrl.dispose();
    stockCtrl.dispose(); categoryCtrl.dispose(); codeCtrl.dispose();
    super.dispose();
  }

  void _saveChanges(ImageBloc imageBloc, VendorProductsBloc productBloc, VendorProductsState state) {
    if (!_formKey.currentState!.validate()) {
      showAppSnackbar("Please check your inputs", SnackbarType.error);
      return;
    }

    final priceTxt = priceCtrl.text.replaceAll(',', '');
    final price = double.tryParse(priceTxt) ?? 0.0;
    final stock = int.tryParse(stockCtrl.text) ?? 0;

    // 🛑 LIMIT CHECK
    // Logic: Calculate the CHANGE in value. 
    // Old Value = OldPrice * OldStock. New Value = NewPrice * NewStock.
    // Difference = NewValue - OldValue.
    // If Difference > AvailableLimit -> Block.
    
    // Note: Since 'availableLimit' in state is "what's left", we need to see if the *increase* fits.
    // However, keeping it simple: Total Value > (Limit + OldValue) is technically the check.
    // But for UI simplicity, we can just check if new value is insane.
    // Better logic: Let server handle complex checks. UI just warns.
    
    final totalValue = price * stock;
    
    // Rough Client-Side Check (Optional but helpful)
    // We assume state.availableLimit is accurate. 
    // If this product's value increased, we check if we have room.
    // (Skipping complex math here to rely on Server Limit Check for safety)

    productBloc.add(
      VendorProductsEdit(
        productCode: widget.product.code,
        name: nameCtrl.text,
        description: descCtrl.text,
        price: price,
        stock: stock,
        category: categoryCtrl.text,
        newImages: _canEditDetails ? imageBloc.state.images : [],
        existingImageUrls: widget.product.imageUrl,
        status: widget.product.status,
      ),
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
        listener: (context, state) {
          if (state.success == true && state.isSubmitting == false) {
            showAppSnackbar("Changes saved successfully", SnackbarType.success);
            context.read<VendorProductsBloc>().add(const VendorProductsRefresh());
            Navigator.pop(context);
          } else if (state.success == false && state.isSubmitting == false) {
            showAppSnackbar(state.errorMessage ?? "Failed to save", SnackbarType.error);
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
                  
                  // 1. LIMIT HEADER (Live Feedback)
                  _buildLimitHeader(state.availableLimit),

                  // 2. HELPER MESSAGE
                  if (_helperMessage != null) ...[
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: const Color(0xFFEAECF0)),
                      ),
                      child: Row(
                        children: [
                          Icon(Iconsax.info_circle, size: 20.sp, color: Colors.grey.shade600),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              _helperMessage!,
                              style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade700, height: 1.4),
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
                    readOnly: true
                  ),
                  SizedBox(height: 20.h),

                  // 4. IMAGES
                  Text("Product Photos", style: _labelStyle()),
                  SizedBox(height: 6.h),
                  BlocBuilder<ImageBloc, ImageState>(
                    builder: (context, imgState) {
                      return ImageUploadBox(
                        editable: _canEditDetails, 
                        imagesUrl: widget.product.imageUrl,
                      ); 
                    },
                  ),
                  SizedBox(height: 24.h),

                  // 5. DETAILS
                  Text("Details", style: _labelStyle()),
                  SizedBox(height: 6.h),
                  _buildInput(
                    controller: nameCtrl, 
                    hint: "Name", 
                    enabled: _canEditDetails,
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  SizedBox(height: 12.h),
                  _buildInput(
                    controller: descCtrl, 
                    hint: "Description", 
                    maxLines: 4, 
                    enabled: _canEditDetails,
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),

                  SizedBox(height: 20.h),

                  // 6. PRICE & STOCK
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
                              // Price locked if approved (security)
                              enabled: _canEditDetails, 
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(left: 14.w, right: 4.w), 
                                child: Text("₦", style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w600, color: _canEditDetails ? Colors.grey.shade600 : Colors.grey.shade400)),
                              ),
                              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                CurrencyInputFormatter()
                              ],
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
                              enabled: true, // Always editable!
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  // 7. CATEGORY
                  Text("Category", style: _labelStyle()),
                  SizedBox(height: 6.h),
                  _buildInput(
                    controller: categoryCtrl,
                    hint: "Category",
                    enabled: _canEditDetails,
                    readOnly: true, 
                    suffixIcon: _canEditDetails ? const Icon(Iconsax.arrow_down_1, size: 18) : null,
                  ),

                  SizedBox(height: 40.h),

                  // 8. SAVE
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => _saveChanges(imageBloc, productBloc, state),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KorraColors.brand,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        disabledBackgroundColor: KorraColors.brand.withOpacity(0.6),
                      ),
                      child: isLoading 
                        ? SizedBox(width: 24.w, height: 24.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text("Save Changes", style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildLimitHeader(double availableLimit) {
    // Basic Estimation Logic
    // In edit mode, we are modifying existing limit usage.
    // Calculating "Exact" availability is complex client-side.
    // We just show "Remaining" here as a guide.
    
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFB2DDFF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Reservation Limit",
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF004EEB),
            ),
          ),
          Text(
            "₦${NumberFormat('#,##0').format(availableLimit)} Available",
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF004EEB),
            ),
          ),
        ],
      ),
    );
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
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.inter(
        fontSize: 15.sp, 
        fontWeight: FontWeight.w600, 
        color: enabled ? const Color(0xFF101828) : Colors.grey.shade500
      ),
      cursorColor: KorraColors.brand,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF2F4F7),
        prefixIcon: prefixIcon,
        prefixIconConstraints: prefixIconConstraints,
        suffixIcon: suffixIcon,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Color(0xFFEAECF0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Color(0xFFEAECF0))),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Colors.transparent)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: KorraColors.brand, width: 1.5)),
      ),
    );
  }
}