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
import '../../payout/widgets/contact_support_sheet.dart';
import 'image_upload_box.dart';

class ProductEditScreen extends StatefulWidget {
  final ProductItem product;
  final VendorRepository vendors;
  final String vendorUid;

  const ProductEditScreen({
    super.key, 
    required this.product,
    required this.vendors,
    required this.vendorUid
  });

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();

  String _complianceStatus = 'active';
  String _blockMessage = '';

  late TextEditingController nameCtrl;
  late TextEditingController descCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController stockCtrl;
  late TextEditingController categoryCtrl;
  late TextEditingController codeCtrl;

  // --- 🔒 PERMISSIONS ---
  // Identity: Name, Desc, Images, Category (Locked if Approved)
  bool _canEditIdentity = true;
  // Commerce: Price, Stock (Always Open if Approved)
  bool _canEditCommerce = true;

  String? _helperMessage;

  final List<String> _categories = [
    "Mens Clothing",
    "Womens Clothing",
    "Kids & Baby",
    "Shoes & Footwear",
    "Bags & Handbags",
    "Jewelry & Watches",
    "Wigs & Hair",
    "Accessories",
    "Phones",
    "Laptops",
    "Gadgets",
    "Home Appliances",
    "Furniture",
    "Health & Beauty",
    "Food & Drinks",
    "Automotive",
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    // Init Controllers
    nameCtrl = TextEditingController(text: p.name);
    descCtrl = TextEditingController(text: p.description);
    priceCtrl = TextEditingController(
      text: p.priceText.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    stockCtrl = TextEditingController(text: p.stock.toString());
    categoryCtrl = TextEditingController(text: p.category);
    codeCtrl = TextEditingController(text: p.code);

    

    // --- DETERMINE PERMISSIONS ---
    if (p.status == ProductStatus.approved) {
      // ✅ APPROVED: Lock Identity, Allow Price/Stock change
      _canEditIdentity = false;
      _canEditCommerce = true;
      _helperMessage =
          "Product is Live. You can update Price & Stock, but Name/Description are locked.";
    } else if (p.status == ProductStatus.pending) {
      // ⏳ PENDING: Lock Everything
      _canEditIdentity = false;
      _canEditCommerce = false;
      _helperMessage = "Product is under review and cannot be edited.";
    } else if (p.status == ProductStatus.rejected) {
      // ❌ REJECTED: Unlock Everything
      _canEditIdentity = true;
      _canEditCommerce = true;
      _helperMessage =
          "This product was rejected. Please fix issues and resubmit.";
    }

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

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    stockCtrl.dispose();
    categoryCtrl.dispose();
    codeCtrl.dispose();
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
    final stock = int.tryParse(stockCtrl.text) ?? 0;

    productBloc.add(
      VendorProductsEdit(
        productCode: widget.product.code,
        name: nameCtrl.text,
        description: descCtrl.text,
        price: price,
        stock: stock,
        category: categoryCtrl.text,
        // Only send new images if identity editing is allowed
        newImages: _canEditIdentity ? imageBloc.state.images : [],
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
        child: BlocBuilder<VendorProductsBloc, VendorProductsState>(
          builder: (context, state) {
            final isLoading = state.isSubmitting ?? false;

            return Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                children: [
                  _buildRestrictionBanner(_complianceStatus, _blockMessage),

                  // 1. LIMIT HEADER (Live Feedback)
                  _buildLimitHeader(state.availableLimit),

                  // 2. HELPER MESSAGE
                  if (_helperMessage != null) ...[
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12.r),
                        //border: Border.all(color: const Color(0xFFEAECF0)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.info_circle,
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
                  _buildInput(
                    controller: nameCtrl,
                    hint: "Name",
                    enabled: _canEditIdentity,
                    validator: null,
                  ),
                  SizedBox(height: 12.h),
                  _buildInput(
                    controller: descCtrl,
                    hint: "Description",
                    maxLines: 4,
                    enabled: _canEditIdentity,
                    validator: null,
                  ),

                  SizedBox(height: 20.h),

                  // 6. PRICE & STOCK (Commerce - OPEN FOR APPROVED)
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
                              enabled:
                                  _canEditCommerce, // ✅ Editable even if Approved
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(
                                  left: 14.w,
                                  right: 4.w,
                                ),
                                child: Text(
                                  "₦",
                                  style: GoogleFonts.inter(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    color: _canEditCommerce
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 0,
                                minHeight: 0,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                CurrencyInputFormatter(),
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
                              enabled:
                                  true, // ✅ Always editable (add/remove stock)
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

                  SizedBox(height: 20.h),

                  // 7. CATEGORY (Identity - Sheet Logic Added)
                  Text("Category", style: _labelStyle()),
                  SizedBox(height: 6.h),
                  GestureDetector(
                    onTap: _canEditIdentity
                        ? () => _showCategorySheet(context)
                        : null,
                    child: AbsorbPointer(
                      child: _buildInput(
                        controller: categoryCtrl,
                        hint: "Category",
                        enabled: _canEditIdentity,
                        readOnly: true,
                        suffixIcon: _canEditIdentity
                            ? const Icon(Iconsax.arrow_down_1, size: 18)
                            : null,
                      ),
                    ),
                  ),

                  SizedBox(height: 40.h),

                  // 8. SAVE
                  _buildSubmitArea(
                    context, 
                    status: _complianceStatus, 
                    isLoading: isLoading, 
                    onSubmit: () => _saveChanges(imageBloc, productBloc, state),
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
                  "Product Edit Paused",
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

  Widget _buildSubmitArea(BuildContext context, {required String status, required bool isLoading, required VoidCallback onSubmit}) {
    // 🛑 Case 1: Restricted / Suspended (BLOCK ACTION)
    // If the account is flagged, we stop them from adding more items.
    if (status == 'restricted' || status == 'suspended' || status == 'banned') {
      return Padding(
        padding: EdgeInsets.only(top: 24.h),
        child: _buildStatusCard( 
          context,
          title: "Edit Paused",
          message: "Product editing is disabled for your account. Please contact support to resolve your status.",
          icon: Icons.lock_outline,
          accentColor: const Color(0xFFD92D20), // Premium Error Red
          buttonText: "Resolve Issue",
          onPressed: () => _showContactSheet(
            context, 
            title: "Account Support", 
            subTitle: "Product editing is restricted. Please contact us to resolve this."
          ),
        ),
      );
    }

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
                "Save Changes",
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


  Widget _buildLimitHeader(double availableLimit) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12.r),
        //border: Border.all(color: const Color(0xFFB2DDFF)),
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
        color: enabled ? const Color(0xFF101828) : Colors.grey.shade500,
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

  void _showCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
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
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: _categories.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF2F4F7)),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  return ListTile(
                    title: Text(cat, style: GoogleFonts.inter(fontSize: 15.sp)),
                    onTap: () {
                      setState(() => categoryCtrl.text = cat);
                      Navigator.pop(context);
                    },
                    trailing: categoryCtrl.text == cat
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
  }
}
