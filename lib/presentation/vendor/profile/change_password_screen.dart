import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:korra/data/repository/vendors/vendor_repository.dart';

import '../../../logic/bloc/customer/change_password_bloc.dart';
import '../../shared/widgets/korra_failure_sheet.dart';
import '../../shared/widgets/korra_header.dart';
import '../../shared/widgets/show_app_snackbar.dart';

class VendorChangePasswordScreen extends StatefulWidget {
  final VendorRepository repo;
  const VendorChangePasswordScreen({super.key, required this.repo});

  @override
  State<VendorChangePasswordScreen> createState() => _VendorChangePasswordScreenState();
}

class _VendorChangePasswordScreenState extends State<VendorChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChangePasswordBloc(changePassword: widget.repo.changePassword),
      child: BlocConsumer<ChangePasswordBloc, ChangePasswordState>(
        listener: (context, state) {
          if (state.status == ChangePassStatus.success) {
            Get.back();
            showAppSnackbar('Password updated successfully', SnackbarType.success);
          }
          if (state.status == ChangePassStatus.failure) {
            showKorraFailureSheet(context, title: 'Password Update Failed', message: state.error ?? "Error");
          }
        },
        builder: (context, state) {
          final loading = state.status == ChangePassStatus.loading;

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: const KorraHeader(title: "Change Password", showLeadingIcon: true),
            body: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle("Current Security"),
                    SizedBox(height: 12.h),
                    
                    _buildPasswordField(
                      label: "Current Password",
                      controller: _currentCtrl,
                      obscure: _obscureCurrent,
                      onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      validator: (v) => (v?.isEmpty ?? true) ? "Required" : null,
                    ),

                    SizedBox(height: 32.h),
                    _sectionTitle("New Security"),
                    SizedBox(height: 12.h),

                    _buildPasswordField(
                      label: "New Password",
                      controller: _newCtrl,
                      obscure: _obscureNew,
                      onToggle: () => setState(() => _obscureNew = !_obscureNew),
                      validator: (v) {
                        if (v == null || v.length < 6) return "Must be at least 6 characters";
                        return null;
                      },
                    ),

                    SizedBox(height: 16.h),

                    _buildPasswordField(
                      label: "Confirm New Password",
                      controller: _confirmCtrl,
                      obscure: _obscureConfirm,
                      onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (v) {
                        if (v != _newCtrl.text) return "Passwords do not match";
                        return null;
                      },
                    ),

                    SizedBox(height: 40.h),

                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: FilledButton(
                        onPressed: loading ? null : () {
                          if (_formKey.currentState!.validate()) {
                            context.read<ChangePasswordBloc>().add(
                              ChangePasswordSubmitted(_currentCtrl.text, _newCtrl.text)
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFA54600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                        child: loading 
                          ? SizedBox(width: 24.w, height: 24.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text("Update Password", style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF344054))),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            hintText: "••••••••",
            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
            errorStyle: GoogleFonts.inter(fontSize: 12.sp, color: Colors.red, fontWeight: FontWeight.w500),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFA54600), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
               borderRadius: BorderRadius.circular(12.r),
               borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Iconsax.eye_slash : Iconsax.eye,
                size: 20.sp,
                color: Colors.grey.shade500,
              ),
              onPressed: onToggle,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}