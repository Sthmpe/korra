// lib/presentation/vendor/profile/edit_vendor_profile_screen.dart
//
// Merchant Edit Profile — same feel as the customer edit screen:
// personal details are LOCKED (support-only changes), while store settings
// (description + walk-in address) are editable. The address & description
// feed the customer storefront: an address shows the "Walk-in store"
// location chip; the description shows under the store name.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/models/vendor/vendor_model.dart';
import '../../shared/widgets/korra_header.dart';
import '../../shared/widgets/show_app_snackbar.dart';

const _brand = Color(0xFFA54600);

class EditVendorProfileScreen extends StatefulWidget {
  final Vendor vendor;

  const EditVendorProfileScreen({super.key, required this.vendor});

  @override
  State<EditVendorProfileScreen> createState() => _EditVendorProfileScreenState();
}

class _EditVendorProfileScreenState extends State<EditVendorProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _descriptionCtrl = TextEditingController(text: widget.vendor.description);
    _addressCtrl = TextEditingController(text: widget.vendor.address);
    _cityCtrl = TextEditingController(text: widget.vendor.city);
    _stateCtrl = TextEditingController(text: widget.vendor.stateName);
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance
          .collection('vendors')
          .doc(widget.vendor.uid)
          .update({
        'store.description': _descriptionCtrl.text.trim(),
        'location.address': _addressCtrl.text.trim(),
        'location.city': _cityCtrl.text.trim(),
        'location.state': _stateCtrl.text.trim(),
        'updatedAt': Timestamp.now(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      showAppSnackbar("Store settings updated successfully.", SnackbarType.success);
    } catch (e) {
      debugPrint("Error saving vendor profile: $e");
      if (mounted) {
        setState(() => _saving = false);
        showAppSnackbar("Could not save changes. Please try again.", SnackbarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vendor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const KorraHeader(title: "Edit Profile", showLeadingIcon: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. LOCKED PERSONAL SECTION ---
              _sectionLabel("Personal Information (Locked)"),
              SizedBox(height: 12.h),

              _readOnlyField("Owner Name", "${v.firstName} ${v.lastName}".trim(), Icons.person),
              SizedBox(height: 12.h),
              _readOnlyField("Email Address", v.email, Icons.email),
              SizedBox(height: 12.h),
              _readOnlyField("Phone Number", v.phone, Icons.phone),
              SizedBox(height: 12.h),
              _readOnlyField("Store Name", v.storeName, Iconsax.shop),

              SizedBox(height: 20.h),
              _infoBanner("Contact support to change personal or store identity details for security reasons."),

              SizedBox(height: 32.h),

              // --- 2. EDITABLE STORE SETTINGS ---
              _sectionLabel("Store Settings"),
              SizedBox(height: 12.h),

              _textField(
                label: "Store Description",
                controller: _descriptionCtrl,
                icon: Iconsax.note_text,
                hint: "Tell customers what you sell and why they should shop with you",
                maxLines: 3,
                maxLength: 200,
                required: false,
              ),
              SizedBox(height: 16.h),

              _textField(
                label: "Store Address",
                controller: _addressCtrl,
                icon: Iconsax.location,
                hint: "Street address customers can walk into (optional)",
                required: false,
              ),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    child: _textField(
                      label: "City",
                      controller: _cityCtrl,
                      icon: Iconsax.building,
                      hint: "Ikeja",
                      required: false,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _textField(
                      label: "State",
                      controller: _stateCtrl,
                      icon: Iconsax.map,
                      hint: "Lagos",
                      required: false,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),
              Text(
                "Customers see your address as a \"Walk-in store\" location on your storefront. Leave it empty to keep your store online-only.",
                style: GoogleFonts.inter(fontSize: 11.5.sp, color: Colors.grey.shade500, height: 1.4),
              ),

              SizedBox(height: 36.h),

              // --- 3. SAVE BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: _brand,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: _saving
                      ? SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text("Save Changes",
                          style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPERS (mirrors customer edit screen) ---

  Widget _sectionLabel(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
          fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 1.0),
    );
  }

  Widget _infoBanner(String text) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18.sp, color: Colors.blue.shade700),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.blue.shade900, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyField(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: Colors.grey.shade400),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500)),
                Text(
                  value.isEmpty ? "—" : value,
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Icon(Icons.lock, size: 16.sp, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    int? maxLength,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF344054))),
        SizedBox(height: 6.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13.sp),
            prefixIcon: maxLines == 1 ? Icon(icon, size: 20.sp, color: Colors.grey.shade500) : null,
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            counterStyle: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey.shade400),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: _brand, width: 1.5)),
          ),
          validator: (val) =>
              required && (val == null || val.trim().isEmpty) ? "Required" : null,
        ),
      ],
    );
  }
}
