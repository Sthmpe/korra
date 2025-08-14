import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../config/constants/sizes.dart';
import '../../../../config/validators/validators.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_bloc.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_event.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_state.dart';

class StepOwnerLogin extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const StepOwnerLogin({super.key, required this.formKey});

  @override
  State<StepOwnerLogin> createState() => _StepOwnerLoginState();
}

class _StepOwnerLoginState extends State<StepOwnerLogin> {
  late final TextEditingController _firstCtl;
  late final TextEditingController _lastCtl;
  late final TextEditingController _phoneCtl;
  late final TextEditingController _emailCtl;
  late final TextEditingController _passCtl;
  late final TextEditingController _confCtl;

  @override
  void initState() {
    super.initState();
    final s = context.read<SignupVendorBloc>().state;
    _firstCtl = TextEditingController(text: s.ownerFirst)..addListener(() => _on(OwnerFirstChanged(_firstCtl.text)));
    _lastCtl  = TextEditingController(text: s.ownerLast)..addListener(() => _on(OwnerLastChanged(_lastCtl.text)));
    _phoneCtl = TextEditingController(text: s.ownerPhone)..addListener(() => _on(OwnerPhoneChanged(_phoneCtl.text)));
    _emailCtl = TextEditingController(text: s.email)..addListener(() => _on(VendorEmailChanged(_emailCtl.text)));
    _passCtl  = TextEditingController(text: s.password)..addListener(() => _on(VendorPasswordChanged(_passCtl.text)));
    _confCtl  = TextEditingController(text: s.confirm)..addListener(() => _on(VendorConfirmChanged(_confCtl.text)));
  }

  void _on(e) => context.read<SignupVendorBloc>().add(e);
  @override void dispose() { _firstCtl.dispose(); _lastCtl.dispose(); _phoneCtl.dispose(); _emailCtl.dispose(); _passCtl.dispose(); _confCtl.dispose(); super.dispose(); }

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
              Text('Owner & login', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700)),
              SizedBox(height: 12.h),
          
              Row(
                children: [
                  Expanded(child: TextFormField(
                    controller: _firstCtl,
                    validator: (v) => KorraValidators.name(v, field: 'First name'),
                    style: GoogleFonts.inter(fontSize: 13.5.sp),
                    decoration: InputDecoration(
                      labelText: 'First name',
                      labelStyle: GoogleFonts.inter(fontSize: 13.5.sp),
                      errorStyle: GoogleFonts.inter(fontSize: 12.sp),
                      prefixIcon: Icon(Iconsax.user, size: 18.sp),
                      filled: true,
                    ),
                  )),
                  SizedBox(width: 10.w),
                  Expanded(child: TextFormField(
                    controller: _lastCtl,
                    validator: (v) => KorraValidators.name(v, field: 'Last name'),
                    style: GoogleFonts.inter(fontSize: 13.5.sp),
                    decoration: InputDecoration(
                      labelText: 'Last name',
                      labelStyle: GoogleFonts.inter(fontSize: 13.5.sp),
                      errorStyle: GoogleFonts.inter(fontSize: 12.sp),
                      prefixIcon: Icon(Iconsax.user, size: 18.sp),
                      filled: true,
                    ),
                  )),
                ],
              ),
              SizedBox(height: 12.h),
          
              TextFormField(
                controller: _phoneCtl,
                validator: KorraValidators.phoneNg,
                style: GoogleFonts.inter(fontSize: 13.5.sp),
                decoration: InputDecoration(
                  labelText: 'Phone',
                  labelStyle: GoogleFonts.inter(fontSize: 13.5.sp),
                  errorStyle: GoogleFonts.inter(fontSize: 12.sp),
                  prefixIcon: Icon(Iconsax.call, size: 18.sp),
                  filled: true,
                ),
              ),
              SizedBox(height: 12.h),
          
              TextFormField(
                controller: _emailCtl,
                validator: KorraValidators.email,
                style: GoogleFonts.inter(fontSize: 13.5.sp),
                decoration: InputDecoration(
                  labelText: 'Email address',
                  labelStyle: GoogleFonts.inter(fontSize: 13.5.sp),
                  errorStyle: GoogleFonts.inter(fontSize: 12.sp),
                  prefixIcon: Icon(Iconsax.sms, size: 18.sp),
                  filled: true,
                ),
              ),
              SizedBox(height: 12.h),
          
              BlocBuilder<SignupVendorBloc, SignupVendorState>(
                buildWhen: (p, c) => p.hidePass != c.hidePass || p.password != c.password,
                builder: (_, s) {
                  return TextFormField(
                    controller: _passCtl,
                    obscureText: s.hidePass,
                    validator: KorraValidators.password,
                    style: GoogleFonts.inter(fontSize: 13.5.sp),
                    decoration: InputDecoration(
                      labelText: 'Password (min 8, letters & numbers)',
                      labelStyle: GoogleFonts.inter(fontSize: 13.5.sp),
                      errorStyle: GoogleFonts.inter(fontSize: 12.sp),
                      prefixIcon: Icon(MdiIcons.lockOutline, size: 18.sp),
                      suffixIcon: IconButton(
                        splashRadius: 20,
                        icon: Icon(s.hidePass ? Iconsax.eye_slash : Iconsax.eye, size: 18.sp),
                        onPressed: () => _on(ToggleVendorPassHidden()),
                      ),
                      filled: true,
                    ),
                  );
                },
              ),
              SizedBox(height: 12.h),
          
              BlocBuilder<SignupVendorBloc, SignupVendorState>(
                buildWhen: (p, c) => p.hideConf != c.hideConf || p.confirm != c.confirm || p.password != c.password,
                builder: (_, s) {
                  return TextFormField(
                    controller: _confCtl,
                    obscureText: s.hideConf,
                    validator: (v) => KorraValidators.confirm(v, s.password),
                    style: GoogleFonts.inter(fontSize: 13.5.sp),
                    decoration: InputDecoration(
                      labelText: 'Confirm password',
                      labelStyle: GoogleFonts.inter(fontSize: 13.5.sp),
                      errorStyle: GoogleFonts.inter(fontSize: 12.sp),
                      prefixIcon: Icon(MdiIcons.lockCheckOutline, size: 18.sp),
                      suffixIcon: IconButton(
                        splashRadius: 20,
                        icon: Icon(s.hideConf ? Iconsax.eye_slash : Iconsax.eye, size: 18.sp),
                        onPressed: () => _on(ToggleVendorConfHidden()),
                      ),
                      filled: true,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
