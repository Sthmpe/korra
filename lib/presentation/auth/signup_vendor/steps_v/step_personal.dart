import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/sizes.dart';
import '../../../../config/validators/validators.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_bloc.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_event.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_state.dart';

class StepPersonal extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const StepPersonal({super.key, required this.formKey});

  @override
  State<StepPersonal> createState() => _StepPersonalState();
}

class _StepPersonalState extends State<StepPersonal> {
  late final TextEditingController _firstCtl;
  late final TextEditingController _lastCtl;
  late final TextEditingController _otherCtl;
  late final TextEditingController _phoneCtl;
  late final TextEditingController _emailCtl;

  @override
  void initState() {
    super.initState();
    final s = context.read<SignupVendorBloc>().state;
    _firstCtl = TextEditingController(text: s.ownerFirst)
      ..addListener(() => _on(OwnerFirstChanged(_firstCtl.text)));
    _lastCtl = TextEditingController(text: s.ownerLast)
      ..addListener(() => _on(OwnerLastChanged(_lastCtl.text)));
    _otherCtl = TextEditingController(text: s.ownerOther)
      ..addListener(() => _on(OwnerOtherChanged(_otherCtl.text)));
    _phoneCtl = TextEditingController(text: s.ownerPhone)
      ..addListener(() => _on(OwnerPhoneChanged(_phoneCtl.text)));
    _emailCtl = TextEditingController(text: s.email)
      ..addListener(() => _on(VendorEmailChanged(_emailCtl.text)));
  }

  void _on(SignupVendorEvent e) => context.read<SignupVendorBloc>().add(e);

  @override
  void dispose() {
    _firstCtl.dispose();
    _lastCtl.dispose();
    _otherCtl.dispose();
    _phoneCtl.dispose();
    _emailCtl.dispose();
    super.dispose();
  }

  // Future<void> _pickDob() async {
  //   final s = context.read<SignupVendorBloc>().state;
  //   final now = DateTime.now();
  //   final picked = await showDatePicker(
  //     context: context,
  //     initialDate: s.dob ?? DateTime(now.year - 20, now.month, now.day),
  //     firstDate: DateTime(now.year - 100),
  //     lastDate: DateTime(now.year - 18, now.month, now.day),
  //     helpText: 'Select date of birth',
  //     builder: (ctx, child) => Theme(data: Theme.of(ctx), child: child!),
  //   );
  //   if (picked != null) _on(DobChanged(picked));
  // }

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
          //physics: NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us about you',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 12.h),

              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: _firstCtl,
                      label: 'First name',
                      icon: Iconsax.user,
                      validator: (v) =>
                          KorraValidators.name(v, field: 'First name'),
                      type: TextInputType.name,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _field(
                      controller: _lastCtl,
                      label: 'Last name',
                      icon: Iconsax.user,
                      validator: (v) =>
                          KorraValidators.name(v, field: 'Last name'),
                      type: TextInputType.name,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              _field(
                controller: _otherCtl,
                label: 'Other name (optional)',
                icon: Iconsax.user,
                validator: KorraValidators.optionalName,
                type: TextInputType.name,
              ),
              SizedBox(height: 10.h),
              _field(
                controller: _phoneCtl,
                label: 'Phone',
                icon: Iconsax.call,
                validator: KorraValidators.phoneNg,
                type: TextInputType.phone,
              ),
              SizedBox(height: 10.h),
              _field(
                controller: _emailCtl,
                label: 'Email address',
                icon: Iconsax.sms,
                validator: KorraValidators.email,
                type: TextInputType.emailAddress,
              ),

              SizedBox(height: 12.h),

              BlocBuilder<SignupVendorBloc, SignupVendorState>(
                buildWhen: (p, c) => p.dob != c.dob || p.gender != c.gender,
                builder: (context, s) {
                  return Row(
                    children: [
                      // ---- DOB (required) ----
                      Expanded(
                        child: FormField<DateTime?>(
                          key: ValueKey(s.dob), // <— force re-init with state
                          initialValue: s.dob, // <— use state directly
                          validator: (val) {
                            if (val == null) return 'Date of birth is required';
                            final now = DateTime.now();
                            final age =
                                now.year -
                                val.year -
                                ((now.month < val.month ||
                                        (now.month == val.month &&
                                            now.day < val.day))
                                    ? 1
                                    : 0);
                            if (age < 13) return 'Must be at least 13';
                            if (age > 100) return 'Please enter a valid age';
                            return null;
                          },
                          builder: (field) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: () async {
                                    final now = DateTime.now();
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          s.dob ??
                                          DateTime(
                                            now.year - 20,
                                            now.month,
                                            now.day,
                                          ),
                                      firstDate: DateTime(now.year - 100),
                                      lastDate: DateTime(
                                        now.year - 18,
                                        now.month,
                                        now.day,
                                      ),
                                      helpText: 'Select date of birth',
                                      builder: (ctx, child) => Theme(
                                        data: Theme.of(ctx),
                                        child: child!,
                                      ),
                                    );
                                    if (picked != null) {
                                      context.read<SignupVendorBloc>().add(DobChanged(picked),);
                                      field.didChange(
                                        picked,
                                      ); // keep FormField in sync
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: Container(
                                    height: 54.h,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      color: Colors.grey.shade50,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        Icon(Iconsax.calendar, size: 18.sp),
                                        SizedBox(width: 8.w),
                                        Text(
                                          s.dob == null
                                              ? 'Date of birth'
                                              : KorraValidators.formatDate(
                                                  s.dob!,
                                                ),
                                          style: GoogleFonts.inter(
                                            fontSize: 13.5.sp,
                                            color: s.dob == null
                                                ? Colors.black54
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (field.hasError)
                                  Padding(
                                    padding: EdgeInsets.only(top: 4.h),
                                    child: Text(
                                      field.errorText!,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 10.w),

                      // ---- Gender (required) ----
                      Expanded(
                        child: DropdownButtonFormField<Gender>(
                          key: ValueKey(
                            s.gender,
                          ), // <— force re-init with state
                          value: s.gender == Gender.undisclosed
                              ? null
                              : s.gender,
                          validator: (g) => g == null ? 'Select gender' : null,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 14.h,
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            errorStyle: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: Colors.red,
                            ),
                          ),
                          dropdownColor: Colors.grey.shade200,
                          style: GoogleFonts.inter(
                            fontSize: 13.5.sp,
                            color: Colors.black87,
                          ),
                          hint: Text(
                            'Gender',
                            style: GoogleFonts.inter(fontSize: 13.5.sp),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: Gender.male,
                              child: Text('Male'),
                            ),
                            DropdownMenuItem(
                              value: Gender.female,
                              child: Text('Female'),
                            ),
                            DropdownMenuItem(
                              value: Gender.other,
                              child: Text('Other'),
                            ),
                          ],
                          onChanged: (g) {
                            if (g != null) context.read<SignupVendorBloc>().add(GenderChanged(g),);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    required TextInputType type,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      style: GoogleFonts.inter(fontSize: 13.5.sp),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 13.5.sp, color: Colors.black87),
        errorStyle: GoogleFonts.inter(fontSize: 12.sp),
        prefixIcon: Icon(icon, size: 18.sp),
        filled: true,
      ),
    );
  }
}
