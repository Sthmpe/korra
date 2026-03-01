import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../config/constants/colors.dart';
import '../../../../../config/validators/validators.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_bloc.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_event.dart';

class StepIdentity extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const StepIdentity({super.key, required this.formKey});

  @override
  State<StepIdentity> createState() => _StepIdentityState();
}

class _StepIdentityState extends State<StepIdentity> {
  late final TextEditingController _ninCtl;
  late final TextEditingController _bvnCtl;
  
  final _ninFocus = FocusNode();
  final _bvnFocus = FocusNode();

  void _on(SignupVendorEvent e) => context.read<SignupVendorBloc>().add(e);

  @override
  void initState() {
    super.initState();
    final s = context.read<SignupVendorBloc>().state;
    _ninCtl = TextEditingController(text: s.nin)..addListener(() => _on(NinChanged(_ninCtl.text)));
    _bvnCtl = TextEditingController(text: s.bvn)..addListener(() => _on(BvnChanged(_bvnCtl.text)));
  }

  @override
  void dispose() {
    _ninCtl.dispose(); _bvnCtl.dispose();
    _ninFocus.dispose(); _bvnFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SignupVendorBloc>().state;

    // Status Helpers
    Widget? ninSuffix() {
      if (s.ninVerified && s.lastVerifiedNin == s.nin) {
        return Icon(Iconsax.tick_circle, color: Colors.green, size: 22.sp);
      }
      if (s.ninError != null && s.nin.length == 11) {
        return Icon(Iconsax.warning_2, color: Colors.red, size: 22.sp);
      }
      return null;
    }

    Widget? bvnSuffix() {
      if (s.bvnVerified && s.lastVerifiedBvn == s.bvn) {
        return Icon(Iconsax.tick_circle, color: Colors.green, size: 22.sp);
      }
      if (s.bvnError != null && s.bvn.length == 11) {
        return Icon(Iconsax.warning_2, color: Colors.red, size: 22.sp);
      }
      return null;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Form(
        key: widget.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Identity Verification',
              style: GoogleFonts.inter(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111111),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'To keep Korra secure, we need to verify your identity using your NIN and BVN.',
              style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF666666), height: 1.4),
            ),
            SizedBox(height: 32.h),

            // --- NIN FIELD ---
            _IdentityInput(
              controller: _ninCtl,
              focusNode: _ninFocus,
              label: 'National Identity Number (NIN)',
              hint: '11-digit number',
              icon: Iconsax.card,
              validator: KorraValidators.nin,
              suffixIcon: ninSuffix(),
              serverError: (s.ninVerified || s.nin.length != 11) ? null : s.ninError,
            ),

            SizedBox(height: 24.h),

            // --- BVN FIELD ---
            _IdentityInput(
              controller: _bvnCtl,
              focusNode: _bvnFocus,
              label: 'Bank Verification Number (BVN)',
              hint: '11-digit number',
              icon: Iconsax.finger_scan,
              validator: KorraValidators.bvn,
              suffixIcon: bvnSuffix(),
              serverError: (s.bvnVerified || s.bvn.length != 11) ? null : s.bvnError,
            ),

            SizedBox(height: 24.h),
            
            // --- SECURITY NOTE ---
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F8FD), // Light Blue tint
                borderRadius: BorderRadius.circular(12.r),
                //border: Border.all(color: const Color(0xFFE1F0FA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Iconsax.shield_tick, color: Colors.blue.shade700, size: 20.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Your data is encrypted and securely stored. We only use this for identity verification.',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp, 
                        height: 1.4,
                        color: Colors.blue.shade900
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PREMIUM IDENTITY INPUT
// -----------------------------------------------------------------------------
class _IdentityInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final String? serverError;

  const _IdentityInput({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.suffixIcon,
    this.serverError,
  });

  @override
  State<_IdentityInput> createState() => _IdentityInputState();
}

class _IdentityInputState extends State<_IdentityInput> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocus);
    super.dispose();
  }

  void _handleFocus() {
    setState(() => _isFocused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.serverError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111111),
          ),
        ),
        SizedBox(height: 8.h),

        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isFocused ? Colors.white : const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: hasError 
                  ? Colors.red 
                  : _isFocused ? KorraColors.brand : const Color(0xFFE5E5E5),
              width: 1
            ),
            boxShadow: _isFocused && !hasError
                ? [
                    BoxShadow(
                      color: KorraColors.brand.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: TextInputType.number,
            maxLength: 11,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: GoogleFonts.inter(
              fontSize: 16.sp, // Larger numbers for easier reading
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0, // Spacing for numbers
              color: const Color(0xFF1B1B1B),
            ),
            cursorColor: KorraColors.brand,
            decoration: InputDecoration(
              counterText: '', // Hide character counter
              hintText: widget.hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 15.sp,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFAAAAAA),
                letterSpacing: 0,
              ),
              prefixIcon: Icon(
                widget.icon, 
                size: 20.sp, 
                color: _isFocused ? KorraColors.brand : const Color(0xFF9CA3AF)
              ),
              suffixIcon: widget.suffixIcon,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(16.r),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(16.r), 
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(16.r),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(16.r),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(16.r),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              errorStyle: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            validator: widget.validator,
          ),
        ),
        
        if (widget.serverError != null)
          Padding(
            padding: EdgeInsets.only(left: 4.w, top: 6.h),
            child: Text(
              widget.serverError!,
              style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }
}