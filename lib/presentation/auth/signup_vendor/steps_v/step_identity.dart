import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/sizes.dart';
import '../../../../config/validators/validators.dart';
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

  void _on(SignupVendorEvent e) => context.read<SignupVendorBloc>().add(e);

  @override
  void initState() {
    super.initState();
    final s = context.read<SignupVendorBloc>().state;
    _ninCtl = TextEditingController(text: s.nin)
      ..addListener(() => _on(NinChanged(_ninCtl.text)));
    _bvnCtl = TextEditingController(text: s.bvn)
      ..addListener(() => _on(BvnChanged(_bvnCtl.text)));
  }

  @override
  void dispose() {
    _ninCtl.dispose();
    _bvnCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SignupVendorBloc>().state;

    // suffix icons (✅ if verified for the exact value, ❌ if server error)
    Widget? _ninSuffix() {
      if (s.ninVerified && s.lastVerifiedNin == s.nin) {
        return Icon(Icons.check_circle, color: Colors.green, size: 18.sp);
      }
      if (s.ninError != null) {
        return Icon(Icons.error_outline, color: Colors.red, size: 18.sp);
      }
      return null;
    }

    Widget? _bvnSuffix() {
      if (s.bvnVerified && s.lastVerifiedBvn == s.bvn) {
        return Icon(Icons.check_circle, color: Colors.green, size: 18.sp);
      }
      if (s.bvnError != null) {
        return Icon(Icons.error_outline, color: Colors.red, size: 18.sp);
      }
      return null;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KorraSizes.cardRadius.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: EdgeInsets.all(16.r),
      child: Form(
        key: widget.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verify your identity',
                  style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700)),
              SizedBox(height: 12.h),

              // NIN
              _field(
                _ninCtl,
                'NIN (11 digits)',
                Iconsax.card,
                KorraValidators.nin,
                suffix: _ninSuffix(),
                serverError: s.ninError,
              ),
              SizedBox(height: 12.h),

              // BVN
              _field(
                _bvnCtl,
                'BVN (11 digits)',
                Iconsax.finger_scan,
                KorraValidators.bvn,
                suffix: _bvnSuffix(),
                serverError: s.bvnError,
              ),

              SizedBox(height: 8.h),
              Text(
                'Your KYC helps secure your account and unlock higher limits.',
                style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Your styled field, extended to optionally show:
  /// - [suffix] (✅/❌ icon)
  /// - [serverError] (inline API error text under the input)
  Widget _field(
    TextEditingController ctl,
    String label,
    IconData icon,
    String? Function(String?) validator, {
    Widget? suffix,
    String? serverError,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: ctl,
          keyboardType: TextInputType.number,
          validator: validator,
          maxLength: 11,
          style: GoogleFonts.inter(fontSize: 13.5.sp, color: Colors.black87),
          decoration: InputDecoration(
            counterText: '',
            labelText: label,
            labelStyle: GoogleFonts.inter(fontSize: 13.5.sp, color: Colors.black87),
            errorStyle: GoogleFonts.inter(fontSize: 12.sp),
            prefixIcon: Icon(icon, size: 18.sp),
            suffixIcon: suffix,
            filled: true,
          ),
        ),
        if (serverError != null) // server-side/API error (separate from validator)
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              serverError,
              style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.red),
            ),
          ),
      ],
    );
  }
}
