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
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_state.dart';

class StepSecurity extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const StepSecurity({super.key, required this.formKey});

  @override
  State<StepSecurity> createState() => _StepSecurityState();
}

class _StepSecurityState extends State<StepSecurity> {
  late final TextEditingController _passCtl;
  late final TextEditingController _confCtl;

  final _passFocus = FocusNode();
  final _confFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final s = context.read<SignupVendorBloc>().state;
    _passCtl = TextEditingController(text: s.password)
      ..addListener(() => _on(VendorPasswordChanged(_passCtl.text)));
    _confCtl = TextEditingController(text: s.confirm)
      ..addListener(() => _on(VendorConfirmChanged (_confCtl.text)));
  }

  void _on(SignupVendorEvent e) => context.read<SignupVendorBloc>().add(e);

  @override
  void dispose() {
    _passCtl.dispose();
    _confCtl.dispose();
    _passFocus.dispose();
    _confFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              'Secure your account',
              style: GoogleFonts.inter(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111111),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Create a strong password to protect your wallet.',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: const Color(0xFF666666),
                height: 1.4,
              ),
            ),
            SizedBox(height: 32.h),

            // --- PASSWORD INPUT ---
            BlocBuilder<SignupVendorBloc, SignupVendorState>(
              buildWhen: (p, c) =>
                  p.hidePass != c.hidePass || p.password != c.password,
              builder: (_, s) {
                return _PremiumInput(
                  controller: _passCtl,
                  focusNode: _passFocus,
                  label: 'Password',
                  hint: 'Min 8 chars, letters & numbers',
                  icon: Iconsax.lock,
                  isPassword: true,
                  obscureText: s.hidePass,
                  onTogglePass: () => _on(ToggleVendorPassHidden()),
                  validator: KorraValidators.password,
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_confFocus),
                );
              },
            ),

            SizedBox(height: 16.h),

            // --- PASSWORD STRENGTH METER ---
            const _PasswordMeter(),

            SizedBox(height: 24.h),

            // --- CONFIRM PASSWORD INPUT ---
            BlocBuilder<SignupVendorBloc, SignupVendorState>(
              buildWhen: (p, c) =>
                  p.hideConf != c.hideConf ||
                  p.confirm != c.confirm ||
                  p.password != c.password,
              builder: (_, s) {
                return _PremiumInput(
                  controller: _confCtl,
                  focusNode: _confFocus,
                  label: 'Confirm Password',
                  hint: 'Re-enter password',
                  icon: Iconsax.lock_circle,
                  isPassword: true,
                  obscureText: s.hideConf,
                  onTogglePass: () => _on(ToggleVendorConfHidden()),
                  validator: (v) => KorraValidators.confirm(v, s.password),
                );
              },
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. PREMIUM INPUT (Reused)
// -----------------------------------------------------------------------------
class _PremiumInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onTogglePass;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  const _PremiumInput({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.onTogglePass,
    this.validator,
    this.onSubmitted,
  });

  @override
  State<_PremiumInput> createState() => _PremiumInputState();
}

class _PremiumInputState extends State<_PremiumInput> {
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
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: _isFocused ? KorraColors.brand : const Color(0xFFE5E5E5),
              width: 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: KorraColors.brand.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            obscureText: widget.obscureText,
            onFieldSubmitted: (v) {
              HapticFeedback.selectionClick();
              widget.onSubmitted?.call(v);
            },
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1B1B1B),
            ),
            cursorColor: KorraColors.brand,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFAAAAAA),
              ),
              prefixIcon: Icon(
                widget.icon,
                size: 20.sp,
                color: _isFocused ? KorraColors.brand : const Color(0xFF9CA3AF),
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      splashRadius: 20,
                      onPressed: widget.onTogglePass,
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          widget.obscureText ? Iconsax.eye_slash : Iconsax.eye,
                          key: ValueKey(widget.obscureText),
                          size: 20.sp,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(12.r),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(12.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(12.r),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(12.r),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(12.r),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
              errorStyle: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            validator: widget.validator,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 2. MODERN PASSWORD METER
// -----------------------------------------------------------------------------
class _PasswordMeter extends StatelessWidget {
  const _PasswordMeter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignupVendorBloc, SignupVendorState>(
      buildWhen: (p, c) => p.password != c.password,
      builder: (_, s) {
        final score = _score(s.password); // 0, 1, 2, 3
        Color color;
        String label;

        if (s.password.isEmpty) {
          color = Colors.grey.shade300;
          label = "Enter password";
        } else if (score <= 1) {
          color = Colors.red;
          label = "Weak";
        } else if (score == 2) {
          color = Colors.orange;
          label = "Medium";
        } else {
          color = Colors.green;
          label = "Strong";
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(3, (index) {
                // Logic: if score is 1, light up 1 bar. If 2, light up 2.
                final isActive = (s.password.isNotEmpty) && (index < score);
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.only(right: index < 2 ? 6.w : 0),
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: isActive ? color : const Color(0xFFE5E5E5),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 6.h),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: s.password.isEmpty ? Colors.grey : color,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  int _score(String v) {
    if (v.isEmpty) return 0;
    int s = 0;
    if (v.length >= 8) s++;
    if (RegExp(r'[A-Za-z]').hasMatch(v) && RegExp(r'\d').hasMatch(v)) s++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(v)) s++;
    // Clamp to max 3 segments
    if (s > 3) s = 3;
    return s;
  }
}
