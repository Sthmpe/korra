import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

// import '../../../../config/constants/sizes.dart';
import '../../../../logic/bloc/auth/role_login/role_login_bloc.dart';
import '../../../../logic/bloc/auth/role_login/role_login_event.dart';
import '../../../../logic/bloc/auth/role_login/role_login_state.dart';
import '../../signup_customer/signup_customer_screen.dart';
import '../../signup_vendor/signup_vendor_screen.dart';


class LoginFields extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const LoginFields({super.key, required this.formKey});

  @override
  State<LoginFields> createState() => _LoginFieldsState();
}

class _LoginFieldsState extends State<LoginFields> {
  late final TextEditingController _emailCtl;
  late final TextEditingController _passCtl;

  @override
  void initState() {
    super.initState();
    final s = context.read<RoleLoginBloc>().state;
    _emailCtl = TextEditingController(text: s.email);
    _passCtl  = TextEditingController(text: s.password);
    _emailCtl.addListener(() =>
        context.read<RoleLoginBloc>().add(EmailChanged(_emailCtl.text)));
    _passCtl.addListener(() =>
        context.read<RoleLoginBloc>().add(PasswordChanged(_passCtl.text)));
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
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
    final role = context.read<RoleLoginBloc>().state.role;
    if (role == KorraRole.customer) {
      Get.to(() => const SignupCustomerScreen());
    } else {
      Get.to(() => const SignupVendorScreen());
    }
}

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          TextFormField(
            controller: _emailCtl,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(fontSize: 13.5.sp),
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            decoration: InputDecoration(
              labelText: 'Email address',
              labelStyle: GoogleFonts.inter(fontSize: 13.5.sp),
              prefixIcon: Icon(Iconsax.sms, size: 18.sp),
              errorStyle: GoogleFonts.inter(fontSize: 12.sp),
            ),
            validator: _validateEmail,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: 12.h),
      
          BlocBuilder<RoleLoginBloc, RoleLoginState>(
            buildWhen: (p, c) => p.passwordHidden != c.passwordHidden,
            builder: (context, state) {
              return TextFormField(
                controller: _passCtl,
                obscureText: state.passwordHidden,
                autofillHints: const [AutofillHints.password],
                style: GoogleFonts.inter(fontSize: 13.5.sp),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: GoogleFonts.inter(fontSize: 13.5.sp),
                  prefixIcon: Icon(MdiIcons.lockOutline, size: 18.sp),
                  errorStyle: GoogleFonts.inter(fontSize: 12.sp),
                  suffixIcon: IconButton(
                    splashRadius: 20,
                    onPressed: () => context.read<RoleLoginBloc>().add(TogglePasswordVisibility()),
                    icon: Icon(
                      state.passwordHidden ? Iconsax.eye_slash : Iconsax.eye,
                      size: 18.sp,
                    ),
                  ),
                ),
                validator: _validatePassword,
                onFieldSubmitted: (_) => HapticFeedback.selectionClick(),
              );
            },
          ),
            
          Row(
            children: [
              TextButton(
                onPressed: () {},
                child: Text('Forgot password?',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.5.sp)),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _goToCreateAccount(context),
                child: Text('Create account',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5.sp)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
