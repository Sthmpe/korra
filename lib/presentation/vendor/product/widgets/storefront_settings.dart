import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/constants/colors.dart';
import '../../../../data/repository/vendors/vendor_repository.dart';
import '../../../shared/widgets/show_app_snackbar.dart';

class VendorStorefrontSettings extends StatefulWidget {
  final String vendorUid;

  const VendorStorefrontSettings({super.key, required this.vendorUid});

  @override
  State<VendorStorefrontSettings> createState() => _VendorStorefrontSettingsState();
}

class _VendorStorefrontSettingsState extends State<VendorStorefrontSettings> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _slugController;
  late TextEditingController _descController;
  late TextEditingController _whatsappController;
  late TextEditingController _instagramController;
  late TextEditingController _tiktokController;
  late TextEditingController _phoneController;

  // File Upload State
  XFile? _pickedLogo;
  XFile? _pickedCover;
  String _logoUrl = '';
  String _coverUrl = '';

  bool _isLoadingData = true;
  bool _isSaving = false;
  bool _absorbOutrightFee = false;

  // The slug already saved in Firestore. Clearing the slug field must NOT
  // erase an existing slug (their store link would break) — the slug only
  // changes when the merchant actually types a new one. Merchants who never
  // had a slug can leave it empty.
  String _savedSlug = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _slugController = TextEditingController();
    _descController = TextEditingController();
    _whatsappController = TextEditingController();
    _instagramController = TextEditingController();
    _tiktokController = TextEditingController();
    _phoneController = TextEditingController();
    _loadStorefrontData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _descController.dispose();
    _whatsappController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadStorefrontData() async {
    try {
      final doc = await _firestore.collection('vendors').doc(widget.vendorUid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final storeMap = data['store'] as Map<String, dynamic>? ?? {};
        final personalMap = data['personal'] as Map<String, dynamic>? ?? {};
        final socialsMap = data['socials'] as Map<String, dynamic>? ?? {};

        setState(() {
          _nameController.text = storeMap['storeName'] ?? '';
          _savedSlug = (storeMap['slug'] ?? '').toString().trim().toLowerCase();
          _slugController.text = _savedSlug;
          _descController.text = storeMap['description'] ?? '';
          _whatsappController.text = socialsMap['whatsappGroup'] ?? '';
          _instagramController.text = socialsMap['instagram'] ?? '';
          _tiktokController.text = socialsMap['tiktok'] ?? '';
          _phoneController.text = storeMap['contactPhone'] ?? personalMap['phone'] ?? '';
          _logoUrl = storeMap['logoUrl'] ?? '';
          _coverUrl = storeMap['coverUrl'] ?? '';
          _absorbOutrightFee = storeMap['absorbOutrightFee'] ?? false;
          _isLoadingData = false;
        });
      } else {
        setState(() => _isLoadingData = false);
      }
    } catch (e) {
      debugPrint("Error loading storefront data: $e");
      showAppSnackbar("Failed to load storefront details.", SnackbarType.error);
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (picked != null) {
      setState(() {
        _pickedLogo = picked;
      });
    }
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (picked != null) {
      setState(() {
        _pickedCover = picked;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final vendorsRepo = context.read<VendorRepository>();
    // Empty field falls back to the already-saved slug: clearing the text
    // must never delete an existing store link.
    final newSlug = _effectiveSlug;

    try {
      // 0. Enforce Slug Uniqueness (only when there is a slug to check)
      if (newSlug.isNotEmpty && newSlug != _savedSlug) {
        final slugQuery = await _firestore
            .collection('vendors')
            .where('store.slug', isEqualTo: newSlug)
            .get();

        for (var doc in slugQuery.docs) {
          if (doc.id != widget.vendorUid) {
            setState(() => _isSaving = false);
            showAppSnackbar(
              "This link slug is already taken by another merchant. Please choose a different one.",
              SnackbarType.error,
            );
            return;
          }
        }
      }

      String finalLogoUrl = _logoUrl;
      String finalCoverUrl = _coverUrl;

      // 1. Upload Logo if changed
      if (_pickedLogo != null) {
        final url = await vendorsRepo.uploadToSupabase(_pickedLogo!);
        if (url != null) finalLogoUrl = url;
      }

      // 2. Upload Cover if changed
      if (_pickedCover != null) {
        final url = await vendorsRepo.uploadToSupabase(_pickedCover!);
        if (url != null) finalCoverUrl = url;
      }

      // 3. Save storefront fields in vendor document
      await vendorsRepo.saveStorefrontSettings(
        uid: widget.vendorUid,
        storeName: _nameController.text.trim(),
        description: _descController.text.trim(),
        slug: newSlug,
        logoUrl: finalLogoUrl,
        coverUrl: finalCoverUrl,
        whatsappGroup: _whatsappController.text.trim(),
        instagram: _instagramController.text.trim(),
        tiktok: _tiktokController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        absorbOutrightFee: _absorbOutrightFee,
      );

      showAppSnackbar("Storefront updated successfully!", SnackbarType.success);
      
      setState(() {
        _logoUrl = finalLogoUrl;
        _coverUrl = finalCoverUrl;
        _pickedLogo = null;
        _pickedCover = null;
        _savedSlug = newSlug;
        _slugController.text = newSlug;
        _isSaving = false;
      });
    } catch (e) {
      debugPrint("Error saving settings: $e");
      showAppSnackbar("Failed to save settings. Please try again.", SnackbarType.error);
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator(color: KorraColors.brand));
    }

    final initialLetter = _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'S';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 32.h),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ COVER BANNER BOX
            GestureDetector(
              onTap: _pickCover,
              child: Stack(
                children: [
                  Container(
                    height: 140.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      image: _pickedCover != null
                          ? DecorationImage(
                              image: kIsWeb
                                  ? NetworkImage(_pickedCover!.path)
                                  : FileImage(File(_pickedCover!.path)) as ImageProvider,
                              fit: BoxFit.cover,
                            )
                          : _coverUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(_coverUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                      gradient: _pickedCover == null && _coverUrl.isEmpty
                          ? const LinearGradient(
                              colors: [KorraColors.brand, Color(0xFFE05600)],
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: _pickedCover == null && _coverUrl.isEmpty
                        ? Text(
                            "Tap to Add Cover Banner",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.sp,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 12.w,
                    bottom: 12.h,
                    child: Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.camera_alt, color: Colors.white, size: 16.sp),
                    ),
                  ),
                ],
              ),
            ),

            // ⭕ LOGO AVATAR BOX (Overlapping)
            Transform.translate(
              offset: Offset(16.w, -35.h),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: _pickLogo,
                    child: Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3.w),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: _pickedLogo != null
                            ? Image(
                                image: kIsWeb
                                    ? NetworkImage(_pickedLogo!.path)
                                    : FileImage(File(_pickedLogo!.path)) as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            : _logoUrl.isNotEmpty
                                ? Image.network(_logoUrl, fit: BoxFit.cover)
                                : Container(
                                    color: KorraColors.brandLight,
                                    alignment: Alignment.center,
                                    child: Text(
                                      initialLetter,
                                      style: GoogleFonts.inter(
                                        fontSize: 28.sp,
                                        fontWeight: FontWeight.w800,
                                        color: KorraColors.brand,
                                      ),
                                    ),
                                  ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickLogo,
                    child: Container(
                      padding: EdgeInsets.all(5.r),
                      decoration: const BoxDecoration(
                        color: KorraColors.brand,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit, color: Colors.white, size: 12.sp),
                    ),
                  ),
                ],
              ),
            ),

            // 📝 INPUT FIELDS
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Storefront Brand Settings",
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: KorraColors.textDark,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Store Name
                  _buildLabel("Store Name"),
                  _buildTextField(
                    controller: _nameController,
                    hint: "e.g. Nike Store",
                    maxLength: 40,
                    validator: (v) {
                      final text = v?.trim() ?? '';
                      if (text.isEmpty) return "Store name is required";
                      if (text.length < 2) return "Store name must be at least 2 characters";
                      return null;
                    },
                  ),

                  // Slug
                  _buildLabel("Store Link Slug"),
                  _buildTextField(
                    controller: _slugController,
                    hint: "e.g. nike-store",
                    validator: (v) {
                      final typed = v?.trim() ?? '';
                      // Empty is fine: an existing slug is kept, and merchants
                      // without one can save without it.
                      if (typed.isEmpty) return null;
                      if (RegExp(r'[^a-zA-Z0-9\-]').hasMatch(typed)) {
                        return "Slug can only contain letters, numbers, and dashes (-)";
                      }
                      return null;
                    },
                    helperText: _effectiveSlug.isNotEmpty
                        ? "Your store link: $_storeLink"
                        : null,
                    onChanged: (val) => setState(() {}),
                  ),
                  if (_slugController.text.trim().isEmpty && _savedSlug.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      "Leaving this empty keeps your current slug \"$_savedSlug\". Type a new one to change it.",
                      style: GoogleFonts.inter(
                        fontSize: 10.5.sp,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (_effectiveSlug.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    _buildStoreLinkActions(),
                  ],

                  // Description
                  _buildLabel("Store Bio / Description"),
                  _buildTextField(
                    controller: _descController,
                    hint: "e.g. Handmade Ankara gowns, custom sizing, delivery across Lagos",
                    maxLines: 3,
                    maxLength: 160,
                    helperText: "This helps your store get found on Google.",
                    validator: (v) {
                      final text = v?.trim() ?? '';
                      if (text.isEmpty) return "Description is required";
                      if (text.length < 30) return "Description must be at least 30 characters";
                      return null;
                    },
                  ),

                  SizedBox(height: 20.h),
                  Text(
                    "Contact Channels",
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: KorraColors.textDark,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Contact Phone
                  _buildLabel("Contact Phone (Business Line)"),
                  _buildTextField(
                    controller: _phoneController,
                    hint: "e.g. +234 800 000 0000",
                    prefixIcon: Icon(Icons.phone, size: 18.sp, color: KorraColors.textHint),
                  ),

                  // WhatsApp Group
                  _buildLabel("WhatsApp Group or Direct Link"),
                  _buildTextField(
                    controller: _whatsappController,
                    hint: "e.g. https://chat.whatsapp.com/...",
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(20.r),
                      child: FaIcon(FontAwesomeIcons.whatsapp, size: 18.sp, color: KorraColors.textHint),
                    ),
                  ),

                  // Instagram
                  _buildLabel("Instagram Username"),
                  _buildTextField(
                    controller: _instagramController,
                    hint: "e.g. nike_store",
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(20.r),
                      child: FaIcon(FontAwesomeIcons.instagram, size: 18.sp, color: KorraColors.textHint),
                    ),
                  ),

                  // TikTok (replaced Twitter — David, 5 July 2026)
                  _buildLabel("TikTok Username"),
                  _buildTextField(
                    controller: _tiktokController,
                    hint: "e.g. nike_store",
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(20.r),
                      child: FaIcon(FontAwesomeIcons.tiktok, size: 18.sp, color: KorraColors.textHint),
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // ─── OUTRIGHT FEE POLICY ───
                  Text(
                    "Outright Purchase Settings",
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: KorraColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "For reservations, the 3.5% transaction fee is always paid by the customer. For outright purchases, you can choose who bears the cost.",
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.grey.shade500,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _FeeAbsorptionToggle(
                    absorbFee: _absorbOutrightFee,
                    onChanged: (val) => setState(() => _absorbOutrightFee = val),
                  ),

                  SizedBox(height: 32.h),

                  // SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KorraColors.brand,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              "Save Storefront Changes",
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
          ],
        ),
      ),
    );
  }

  // The slug that will actually be saved: what's typed, or the existing
  // saved slug when the field has been cleared.
  String get _effectiveSlug {
    final typed = _slugController.text.trim().toLowerCase();
    return typed.isNotEmpty ? typed : _savedSlug;
  }

  String get _storeLink => "https://korra.com.ng/store/$_effectiveSlug";

  Future<void> _viewStore() async {
    final uri = Uri.parse(_storeLink);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        showAppSnackbar("Could not open your store link.", SnackbarType.error);
      }
    } catch (e) {
      debugPrint("Error opening store link: $e");
      showAppSnackbar("Could not open your store link.", SnackbarType.error);
    }
  }

  /// Share + View Store side by side under the slug field — tinted pills,
  /// no border lines.
  Widget _buildStoreLinkActions() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Share.share(
              "Visit my store on Korra: $_storeLink",
              subject: _nameController.text.trim(),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: KorraColors.brandLight,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.share_outlined, size: 16.sp, color: KorraColors.brand),
                  SizedBox(width: 8.w),
                  Text(
                    "Share Store",
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: KorraColors.brand,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: GestureDetector(
            onTap: _viewStore,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront_outlined, size: 16.sp, color: const Color(0xFF344054)),
                  SizedBox(width: 8.w),
                  Text(
                    "View Store",
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF344054),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h, top: 12.h),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: KorraColors.textDark,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    Widget? prefixIcon,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
    String? helperText,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      onChanged: onChanged,
      style: GoogleFonts.inter(
        fontSize: 13.5.sp,
        fontWeight: FontWeight.w600,
        color: KorraColors.textDark,
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
        prefixIcon: prefixIcon,
        hintStyle: GoogleFonts.inter(
          fontSize: 13.5.sp,
          color: KorraColors.textHint,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: EdgeInsets.all(16.r),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: KorraColors.borderLight, width: 0.8.w),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: KorraColors.borderLight, width: 0.8.w),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: KorraColors.brand, width: 1.2.w),
        ),
      ),
    );
  }
}

// ─── Fee Absorption Toggle Widget ───────────────────────────────────────────
class _FeeAbsorptionToggle extends StatelessWidget {
  final bool absorbFee;
  final ValueChanged<bool> onChanged;

  const _FeeAbsorptionToggle({required this.absorbFee, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FeeOptionCard(
          title: 'Customer Pays Fee',
          subtitle: '3.5% (max ₦7,500) added to customer\'s checkout',
          icon: Icons.person_outline_rounded,
          isSelected: !absorbFee,
          onTap: () => onChanged(false),
        ),
        SizedBox(height: 10.h),
        _FeeOptionCard(
          title: 'I Absorb the Fee',
          subtitle: '3.5% (max ₦7,500) deducted from your payout',
          icon: Icons.store_outlined,
          isSelected: absorbFee,
          onTap: () => onChanged(true),
        ),
      ],
    );
  }
}

class _FeeOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FeeOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = KorraColors.brand;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.grey.shade100.withValues(alpha: 0.7),
            width: isSelected ? 1.5 : 1,
          ),
          // boxShadow: isSelected
          //     ? [BoxShadow(color: activeColor.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]
          //     : [],
        ),
        child: Row(
          children: [
            // Icon bubble
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 16.sp,
                color: isSelected ? activeColor : Colors.grey.shade500,
              ),
            ),
            SizedBox(width: 12.w),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? activeColor : KorraColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: isSelected ? activeColor.withValues(alpha: 0.75) : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            // Radio dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 18.w,
              height: 18.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? activeColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? activeColor : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, color: Colors.white, size: 11.sp)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
