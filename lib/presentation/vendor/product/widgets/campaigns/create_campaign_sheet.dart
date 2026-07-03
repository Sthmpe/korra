// lib/presentation/vendor/product/widgets/campaigns/create_campaign_sheet.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../config/constants/colors.dart';
import '../../../../../config/constants/sizes.dart';
import '../../../../../data/models/product_model.dart';
import '../../../../../data/models/vendor/campaign_model.dart';
import '../../../../../data/repository/vendors/vendor_repository.dart';
import '../../../../shared/widgets/show_app_snackbar.dart';
import 'product_selector_page.dart';

class CreateCampaignSheet extends StatefulWidget {
  final String vendorId;

  const CreateCampaignSheet({
    super.key,
    required this.vendorId,
  });

  @override
  State<CreateCampaignSheet> createState() => _CreateCampaignSheetState();
}

class _CreateCampaignSheetState extends State<CreateCampaignSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _captionController = TextEditingController();
  final _customTagController = TextEditingController();
  final _discountValueController = TextEditingController();

  final List<Product> _selectedProducts = [];
  String _selectedTag = 'New Arrival';
  XFile? _campaignImage;

  bool _isUploadingImage = false;
  bool _isSaving = false;

  // Discount options
  bool _offerDiscount = false;
  String _discountType = 'percentage'; // 'percentage' | 'amount'

  final List<String> _presetTags = [
    'New Arrival',
    'Flash Sale',
    'Best Price',
    'Limited Stock',
    'Trending Now',
    'Almost Gone',
    'Restocked',
    'Weekend Special',
    'Hot Deal',
    'Just Landed',
    'Reserve Now',
    'Secure Yours',
    'Sallah Sale',
    'Black Friday',
    'Christmas Special',
    'Other (Custom Tag)...'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    _customTagController.dispose();
    _discountValueController.dispose();
    super.dispose();
  }

  Future<void> _openProductSelector() async {
    final results = await Navigator.push<List<Product>>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductSelectorPage(
          vendorId: widget.vendorId,
          initiallySelectedIds: _selectedProducts.map((p) => p.id).toList(),
        ),
      ),
    );

    if (results != null) {
      setState(() {
        _selectedProducts.clear();
        _selectedProducts.addAll(results);
      });
    }
  }

  Future<void> _pickCampaignImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (picked != null) {
      setState(() {
        _campaignImage = picked;
      });
    }
  }

  double _calculateDiscountedPrice(double originalPrice) {
    if (!_offerDiscount) return originalPrice;
    final value = double.tryParse(_discountValueController.text.trim()) ?? 0.0;
    if (_discountType == 'percentage') {
      final discount = originalPrice * (value / 100.0);
      return (originalPrice - discount).clamp(0.0, originalPrice);
    } else {
      return (originalPrice - value).clamp(0.0, originalPrice);
    }
  }

  Future<void> _submitCampaign() async {
    if (_selectedProducts.isEmpty) {
      showAppSnackbar("Please select at least one target product.", SnackbarType.error);
      return;
    }
    if (_campaignImage == null) {
      showAppSnackbar("Campaign banner photo is compulsory.", SnackbarType.error);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final repo = context.read<VendorRepository>();

    try {
      // 1. Check active campaigns limit (max 3 active within 24h)
      final activeSnap = await FirebaseFirestore.instance
          .collection('campaigns')
          .where('vendorId', isEqualTo: widget.vendorId)
          .where('sentAt', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24))))
          .get();

      if (activeSnap.docs.length >= 3) {
        if (mounted) {
          showAppSnackbar(
            "You have reached your limit of 3 active campaigns. Active campaigns expire after 24 hours.",
            SnackbarType.error,
          );
        }
        setState(() => _isSaving = false);
        return;
      }

      // 2. Upload image
      setState(() => _isUploadingImage = true);
      final imageUrl = await repo.uploadToSupabase(_campaignImage!);
      setState(() => _isUploadingImage = false);

      if (imageUrl == null) {
        throw Exception("Image upload failed.");
      }

      // 3. Resolve tag name
      final finalTag = _selectedTag == 'Other (Custom Tag)...'
          ? _customTagController.text.trim()
          : _selectedTag;

      // 4. Resolve discount fields
      final String finalDiscountType = _offerDiscount ? _discountType : 'none';
      final double finalDiscountValue = _offerDiscount 
          ? (double.tryParse(_discountValueController.text.trim()) ?? 0.0)
          : 0.0;

      // 5. Save campaign
      final campaign = Campaign(
        id: '',
        vendorId: widget.vendorId,
        productIds: _selectedProducts.map((p) => p.id).toList(),
        productTitles: _selectedProducts.map((p) => p.name).toList(),
        tag: finalTag,
        title: _titleController.text.trim(),
        caption: _captionController.text.trim(),
        imageUrl: imageUrl,
        sentAt: DateTime.now(),
        openCount: 0,
        discountType: finalDiscountType,
        discountValue: finalDiscountValue,
      );

      await repo.createCampaign(campaign);

      // 6. Apply discounted price & tag locally to the selected products in Firestore
      final batch = FirebaseFirestore.instance.batch();
      for (final product in _selectedProducts) {
        final productRef = FirebaseFirestore.instance.collection('products').doc(product.id);
        
        // Compute new price if discounted
        final double discountedPrice = _calculateDiscountedPrice(product.price);
        
        batch.update(productRef, {
          'campaignTag': finalTag, // Apply tag directly to product
          if (_offerDiscount) 'discountedPrice': discountedPrice,
          if (!_offerDiscount) 'discountedPrice': FieldValue.delete(),
        });
      }
      await batch.commit();

      if (mounted) {
        Navigator.pop(context);
        showAppSnackbar("Campaign notification launched successfully!", SnackbarType.success);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar("Failed to launch campaign: $e", SnackbarType.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploadingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isCustomTag = _selectedTag == 'Other (Custom Tag)...';

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h + keyboardHeight),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "New Marketing Campaign",
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: KorraColors.textDark,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, size: 20.sp, color: Colors.grey),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFEAECF0)),
              SizedBox(height: 12.h),

              // Product Selector Button
              Text(
                "Target Products",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 6.h),
              GestureDetector(
                onTap: _openProductSelector,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedProducts.isEmpty
                              ? "Tap to select products (In-stock only)"
                              : "${_selectedProducts.length} product${_selectedProducts.length == 1 ? '' : 's'} selected (${_selectedProducts.map((p) => p.name).join(', ')})",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: _selectedProducts.isEmpty ? Colors.grey.shade500 : KorraColors.textDark,
                            fontWeight: _selectedProducts.isEmpty ? FontWeight.w400 : FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 20.sp, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Tag Selector Dropdown
              Text(
                "Attach Tag",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 6.h),
              DropdownButtonFormField<String>(
                value: _selectedTag,
                dropdownColor: Colors.white,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                ),
                items: _presetTags.map((tag) {
                  return DropdownMenuItem(
                    value: tag,
                    child: Text(tag, style: GoogleFonts.inter(fontSize: 13.sp)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedTag = val);
                  }
                },
              ),
              if (isCustomTag) ...[
                SizedBox(height: 12.h),
                Text(
                  "Custom Tag Name",
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 6.h),
                TextFormField(
                  controller: _customTagController,
                  maxLength: 20,
                  style: GoogleFonts.inter(fontSize: 13.sp),
                  decoration: InputDecoration(
                    hintText: "Enter custom tag (max 20 chars)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  ),
                  validator: (val) {
                    if (isCustomTag && (val == null || val.trim().isEmpty)) {
                      return "Custom tag name is required";
                    }
                    if (val != null && val.trim().length > 20) {
                      return "Must be 20 characters or less";
                    }
                    return null;
                  },
                ),
              ],
              SizedBox(height: 16.h),

              // Offer Discount Section
              SwitchListTile(
                title: Text(
                  "Offer Customer Discount",
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: KorraColors.textDark,
                  ),
                ),
                subtitle: Text(
                  "Apply percentage or flat amount off selected products.",
                  style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey),
                ),
                value: _offerDiscount,
                onChanged: (val) {
                  setState(() => _offerDiscount = val);
                },
                activeColor: const Color(0xFFA54600),
                contentPadding: EdgeInsets.zero,
              ),

              if (_offerDiscount) ...[
                SizedBox(height: 12.h),
                // Premium Segmented Selector Bar
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: const Color(0xFFEAECF0)),
                  ),
                  child: Row(
                    children: [
                      // Percentage tab
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _discountType = 'percentage';
                              _discountValueController.clear();
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            decoration: BoxDecoration(
                              color: _discountType == 'percentage'
                                  ? const Color(0xFFA54600)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Percentage Off (%)",
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: _discountType == 'percentage'
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Flat Amount tab
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _discountType = 'amount';
                              _discountValueController.clear();
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            decoration: BoxDecoration(
                              color: _discountType == 'amount'
                                  ? const Color(0xFFA54600)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Flat Amount Off (₦)",
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: _discountType == 'amount'
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // Discount Value Input (Full-width)
                Text(
                  _discountType == 'percentage' ? "Discount Percentage (%)" : "Discount Amount (₦)",
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 6.h),
                TextFormField(
                  controller: _discountValueController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.inter(fontSize: 13.sp),
                  decoration: InputDecoration(
                    hintText: _discountType == 'percentage' ? "e.g. 20" : "e.g. 5000",
                    prefixText: _discountType == 'amount' ? "₦ " : null,
                    suffixText: _discountType == 'percentage' ? "%" : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  ),
                  onChanged: (_) => setState(() {}), // Trigger price preview rebuild
                  validator: (val) {
                    if (!_offerDiscount) return null;
                    if (val == null || val.trim().isEmpty) return "Value required";
                    final numValue = double.tryParse(val.trim());
                    if (numValue == null || numValue <= 0) return "Must be positive";
                    if (_discountType == 'percentage' && numValue > 99) {
                      return "Must be less than 100%";
                    }
                    // Validate flat amount is lower than selected products
                    if (_discountType == 'amount' && _selectedProducts.isNotEmpty) {
                      for (final p in _selectedProducts) {
                        if (numValue >= p.price) {
                          return "Discount exceeds price of ${p.name}";
                        }
                      }
                    }
                    return null;
                  },
                ),
                if (_selectedProducts.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  Text(
                    "Price Preview:",
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _selectedProducts.map((p) {
                        final original = p.price;
                        final discounted = _calculateDiscountedPrice(original);
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(fontSize: 12.sp, color: KorraColors.textDark),
                                ),
                              ),
                              Text(
                                "₦${original.toStringAsFixed(0)} ➔ ₦${discounted.toStringAsFixed(0)}",
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFA54600),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
              SizedBox(height: 16.h),

              // Campaign Title
              Text(
                "Campaign Title",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _titleController,
                maxLength: 20,
                style: GoogleFonts.inter(fontSize: 13.sp),
                decoration: InputDecoration(
                  hintText: "e.g. Grab 30% Off Now",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Title is required";
                  if (val.trim().length > 20) return "Must be 20 characters or less";
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Short Caption (renamed from description, 1 line only)
              Text(
                "Short Caption",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _captionController,
                maxLines: 1,
                maxLength: 40,
                keyboardType: TextInputType.text,
                style: GoogleFonts.inter(fontSize: 13.sp),
                decoration: InputDecoration(
                  hintText: "Short marketing summary (max 40 chars)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Caption is required";
                  if (val.trim().length > 40) return "Must be 40 characters or less";
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Campaign Banner Photo (Compulsory)
              Text(
                "Campaign Banner Photo *",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 6.h),
              GestureDetector(
                onTap: _pickCampaignImage,
                child: Container(
                  height: 110.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
                    border: Border.all(
                      color: _campaignImage != null ? const Color(0xFFA54600) : Colors.grey.shade300,
                      width: _campaignImage != null ? 1.5.w : 1.w,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: _campaignImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r - 1.r),
                          child: Image.file(
                            File(_campaignImage!.path),
                            height: 110.h,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 24.sp),
                            SizedBox(height: 4.h),
                            Text(
                              "Tap to pick custom marketing banner image",
                              style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 24.h),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isSaving || _isUploadingImage) ? null : _submitCampaign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA54600),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
                    ),
                    elevation: 0,
                  ),
                  child: (_isSaving || _isUploadingImage)
                      ? SizedBox(
                          height: 20.w,
                          width: 20.w,
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          "Launch Campaign Notification",
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
