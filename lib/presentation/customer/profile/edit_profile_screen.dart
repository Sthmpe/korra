import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/models/customer/customer_model.dart';
import '../../../data/repository/customer/customer_repository.dart';
import '../../../logic/bloc/customer/profile/edit_profile_bloc.dart';
import '../../shared/widgets/korra_header.dart';

class EditProfileScreen extends StatefulWidget {
  final Customer customer;

  const EditProfileScreen({super.key, required this.customer});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing data
    _addressCtrl = TextEditingController(text: widget.customer.address);
    _cityCtrl = TextEditingController(text: widget.customer.city);
    _stateCtrl = TextEditingController(text: widget.customer.stateName);
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CustomerRepository>();
    return BlocProvider(
      create: (context) => EditProfileBloc(
        repo: repo, 
        customerUid: widget.customer.uid
      ),
      child: BlocConsumer<EditProfileBloc, EditProfileState>(
        listener: (context, state) {
          if (state.status == EditStatus.success) {
            Navigator.pop(context); // Close screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Profile updated successfully"), backgroundColor: Colors.green),
            );
          } else if (state.status == EditStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? "Update failed"), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state.status == EditStatus.submitting;

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: KorraHeader(title: "Edit Profile", showLeadingIcon: true),
            body: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. LOCKED IDENTITY SECTION ---
                    _sectionLabel("Personal Information (Locked)"),
                    SizedBox(height: 12.h),
                    
                    _buildReadOnlyField("Full Name", "${widget.customer.firstName} ${widget.customer.lastName}", Icons.person),
                    SizedBox(height: 12.h),
                    _buildReadOnlyField("Email Address", widget.customer.email, Icons.email),
                    SizedBox(height: 12.h),
                    _buildReadOnlyField("Phone Number", widget.customer.phone, Icons.phone),
                    
                    SizedBox(height: 24.h),
                    _infoBanner("Contact support to change personal details for security reasons."),
                    
                    SizedBox(height: 32.h),

                    // --- 2. EDITABLE LOCATION SECTION ---
                    _sectionLabel("Address Details"),
                    SizedBox(height: 12.h),

                    _buildTextField(
                      label: "Home Address", 
                      controller: _addressCtrl, 
                      icon: Iconsax.location,
                      hint: "Enter your street address"
                    ),
                    SizedBox(height: 16.h),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: "City", 
                            controller: _cityCtrl, 
                            icon: Iconsax.building,
                            hint: "Lagos"
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: _buildTextField(
                            label: "State", 
                            controller: _stateCtrl, 
                            icon: Iconsax.map,
                            hint: "Lagos"
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 40.h),

                    // --- 3. SAVE BUTTON ---
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: FilledButton(
                        onPressed: isLoading ? null : () {
                          if (_formKey.currentState!.validate()) {
                            context.read<EditProfileBloc>().add(EditProfileSaved(
                              address: _addressCtrl.text, 
                              city: _cityCtrl.text, 
                              stateName: _stateCtrl.text
                            ));
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFA54600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                        child: isLoading 
                          ? SizedBox(width: 24.w, height: 24.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text("Save Changes", style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _sectionLabel(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 1.0),
    );
  }

  Widget _infoBanner(String text) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8.r),
        //border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18.sp, color: Colors.blue.shade700),
          SizedBox(width: 10.w),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.blue.shade900, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade50, // Greyed out background
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200.withOpacity(0.25)),
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
                Text(value, style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              ],
            ),
          ),
          Icon(Icons.lock, size: 16.sp, color: Colors.grey.shade400), // Lock icon
        ],
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, required IconData icon, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF344054))),
        SizedBox(height: 6.h),
        TextFormField(
          controller: controller,
          style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, size: 20.sp, color: Colors.grey.shade500),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.grey.shade300.withOpacity(0.35))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.grey.shade300.withOpacity(0.35))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Color(0xFFA54600), width: 1.5)),
          ),
          validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
        ),
      ],
    );
  }
}