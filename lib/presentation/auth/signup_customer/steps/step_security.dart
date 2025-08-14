import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../config/constants/sizes.dart';
import '../../../../config/validators/validators.dart';
import '../../../../logic/bloc/auth/signup_customer/signup_customer_bloc.dart';
import '../../../../logic/bloc/auth/signup_customer/signup_customer_event.dart';
import '../../../../logic/bloc/auth/signup_customer/signup_customer_state.dart';

class StepSecurity extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const StepSecurity({super.key, required this.formKey});

  @override
  State<StepSecurity> createState() => _StepSecurityState();
}

class _StepSecurityState extends State<StepSecurity> {
  late final TextEditingController _passCtl;
  late final TextEditingController _confCtl;

  @override
  void initState() {
    super.initState();
    final s = context.read<SignupCustomerBloc>().state;
    _passCtl = TextEditingController(text: s.password)..addListener(() => _on(PasswordChangedCU(_passCtl.text)));
    _confCtl = TextEditingController(text: s.confirm)..addListener(() => _on(ConfirmPasswordChangedCU(_confCtl.text)));
  }

  void _on(SignupCustomerEvent e) => context.read<SignupCustomerBloc>().add(e);
  @override void dispose() { _passCtl.dispose(); _confCtl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
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
              Text('Secure your account', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700)),
              SizedBox(height: 12.h),
          
              BlocBuilder<SignupCustomerBloc, SignupCustomerState>(
                buildWhen: (p, c) => p.hidePassword != c.hidePassword || p.password != c.password,
                builder: (_, s) {
                  return TextFormField(
                    controller: _passCtl,
                    obscureText: s.hidePassword,
                    validator: KorraValidators.password,
                    style: GoogleFonts.inter(fontSize: 13.5.sp, color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Password (min 8, letters & numbers)',
                      labelStyle: GoogleFonts.inter(fontSize: 13.5.sp, color: Colors.black87),
                      errorStyle: GoogleFonts.inter(fontSize: 12.sp),
                      prefixIcon: Icon(MdiIcons.lockOutline, size: 18.sp),
                      suffixIcon: IconButton(
                        splashRadius: 20,
                        icon: Icon(s.hidePassword ? Iconsax.eye_slash : Iconsax.eye, size: 18.sp),
                        onPressed: () => _on(TogglePasswordVisibilityCU()),
                      ),
                      filled: true,
                    ),
                  );
                },
              ),
              SizedBox(height: 12.h),
              BlocBuilder<SignupCustomerBloc, SignupCustomerState>(
                buildWhen: (p, c) => p.hideConfirm != c.hideConfirm || p.confirm != c.confirm || p.password != c.password,
                builder: (_, s) {
                  return TextFormField(
                    controller: _confCtl,
                    obscureText: s.hideConfirm,
                    validator: (v) => KorraValidators.confirm(v, s.password),
                    style: GoogleFonts.inter(fontSize: 13.5.sp, color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Confirm password',
                      labelStyle: GoogleFonts.inter(fontSize: 13.5.sp, color: Colors.black87),
                      errorStyle: GoogleFonts.inter(fontSize: 12.sp),
                      prefixIcon: Icon(MdiIcons.lockCheckOutline, size: 18.sp),
                      suffixIcon: IconButton(
                        splashRadius: 20,
                        icon: Icon(s.hideConfirm ? Iconsax.eye_slash : Iconsax.eye, size: 18.sp),
                        onPressed: () => _on(ToggleConfirmVisibilityCU()),
                      ),
                      filled: true,
                    ),
                  );
                },
              ),
          
              SizedBox(height: 10.h),
              const _PasswordMeter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordMeter extends StatelessWidget {
  const _PasswordMeter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignupCustomerBloc, SignupCustomerState>(
      buildWhen: (p, c) => p.password != c.password,
      builder: (_, s) {
        final score = _score(s.password); // 0..1
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 6.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: SizedBox(
                height: 6.h,
                child: LinearProgressIndicator(
                  value: score,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    score < .34 ? Colors.redAccent : score < .67 ? Colors.orange : Colors.green,
                  ),
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              score < .34 ? 'Weak' : score < .67 ? 'Okay' : 'Strong',
              style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.black54),
            ),
          ],
        );
      },
    );
  }

  double _score(String v) {
    double s = 0;
    if (v.length >= 8) s += .34;
    if (RegExp(r'[A-Za-z]').hasMatch(v) && RegExp(r'\d').hasMatch(v)) s += .33;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(v)) s += .33;
    return s.clamp(0, 1);
  }
}
