import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../../logic/bloc/auth/role_login/role_login_bloc.dart';
import '../../../../logic/bloc/auth/role_login/role_login_event.dart';
import '../../../../logic/bloc/auth/role_login/role_login_state.dart';

class LoginFields extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const LoginFields({super.key, required this.formKey});

  @override
  State<LoginFields> createState() => _LoginFieldsState();
}

class _LoginFieldsState extends State<LoginFields> {
  late final TextEditingController _emailCtl;
  late final TextEditingController _passCtl;
  
  // Focus nodes to handle the "Pop" animation
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final s = context.read<RoleLoginBloc>().state;
    _emailCtl = TextEditingController(text: s.email);
    _passCtl = TextEditingController(text: s.password);
    
    _emailCtl.addListener(() => context.read<RoleLoginBloc>().add(EmailChanged(_emailCtl.text)));
    _passCtl.addListener(() => context.read<RoleLoginBloc>().add(PasswordChanged(_passCtl.text)));
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim());
    if (!ok) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Minimum 6 characters';
    return null;
  }

  void _goToCreateAccount(BuildContext context) {
    FocusScope.of(context).unfocus();
    final role = context.read<RoleLoginBloc>().state.role;
    if (role == KorraRole.customer) {
      Get.toNamed(Routes.customerSignup);
    } else {
      Get.toNamed(Routes.vendorSignup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          // --- EMAIL FIELD ---
          _PremiumInput(
            controller: _emailCtl,
            focusNode: _emailFocus,
            hint: 'Email address',
            icon: Iconsax.sms,
            inputType: TextInputType.emailAddress,
            autofill: const [AutofillHints.email],
            validator: _validateEmail,
            onSubmitted: (_) {
              FocusScope.of(context).requestFocus(_passFocus);
            },
          ),
          
          SizedBox(height: 16.h),

          // --- PASSWORD FIELD ---
          BlocBuilder<RoleLoginBloc, RoleLoginState>(
            buildWhen: (p, c) => p.passwordHidden != c.passwordHidden,
            builder: (context, state) {
              return _PremiumInput(
                controller: _passCtl,
                focusNode: _passFocus,
                hint: 'Password',
                icon: Iconsax.lock,
                isPassword: true,
                obscureText: state.passwordHidden,
                autofill: const [AutofillHints.password],
                validator: _validatePassword,
                onTogglePass: () => context.read<RoleLoginBloc>().add(TogglePasswordVisibility()),
                onSubmitted: (_) {
                  FocusScope.of(context).unfocus();
                  // Trigger login submit here if you want "Enter" to log in
                },
              );
            },
          ),

          SizedBox(height: 24.h),

          // --- BOTTOM LINKS ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  Get.toNamed(Routes.forgotPassword);
                },
                child: Text(
                  'Forgot password?',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5.sp,
                    color: KorraColors.textMuted, // Muted for secondary action
                  ),
                ),
              ),
              
              GestureDetector(
                onTap: () => _goToCreateAccount(context),
                child: Text(
                  'Create account',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5.sp,
                    color: KorraColors.brand, // Brand color for primary call
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// THE PREMIUM INPUT COMPONENT
// -----------------------------------------------------------------------------
class _PremiumInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final TextInputType? inputType;
  final Iterable<String>? autofill;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onTogglePass;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  const _PremiumInput({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.inputType,
    this.autofill,
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
    setState(() {
      _isFocused = widget.focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        // iOS Style: Grey fill normally, White fill when active
        color: _isFocused ? Colors.white : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _isFocused ? KorraColors.brand : Colors.transparent,
          width: 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: KorraColors.brand.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: widget.inputType,
        autofillHints: widget.autofill,
        obscureText: widget.obscureText,
        onFieldSubmitted: (v) {
          HapticFeedback.selectionClick();
          widget.onSubmitted?.call(v);
        },
        style: GoogleFonts.inter(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600, // Slightly bold input
          color: const Color(0xFF1B1B1B),
        ),
        cursorColor: KorraColors.brand,
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF9CA3AF), // Cool Grey
          ),
          prefixIcon: Icon(
            widget.icon,
            size: 20.sp,
            color: _isFocused ? KorraColors.brand : const Color(0xFF9CA3AF),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 48.w),
          
          suffixIcon: widget.isPassword
              ? IconButton(
                  splashRadius: 20,
                  onPressed: widget.onTogglePass,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      widget.obscureText ? Iconsax.eye : Iconsax.eye_slash,
                      key: ValueKey(widget.obscureText),
                      size: 20.sp,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                )
              : null,
          
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),

          
          // Handle error state visually inside the container
          errorStyle: GoogleFonts.inter(
            fontSize: 12.sp,
            color: Colors.red.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        validator: widget.validator,
      ),
    );
  }
}