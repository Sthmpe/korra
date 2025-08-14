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

class StepBusinessType extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const StepBusinessType({super.key, required this.formKey});

  @override
  State<StepBusinessType> createState() => _StepBusinessTypeState();
}

class _StepBusinessTypeState extends State<StepBusinessType> {
  late final TextEditingController _cacCtl;
  late final TextEditingController _legalCtl;

  @override
  void initState() {
    super.initState();
    final s = context.read<SignupVendorBloc>().state;
    _cacCtl = TextEditingController(text: s.cac)..addListener(() => _on(CacChanged(_cacCtl.text)));
    _legalCtl = TextEditingController(text: s.legalName)..addListener(() => _on(LegalNameChanged(_legalCtl.text)));
  }

  void _on(SignupVendorEvent e) => context.read<SignupVendorBloc>().add(e);
  @override void dispose() { _cacCtl.dispose(); _legalCtl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SignupVendorBloc>().state;
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
              Text('Business type', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700)),
              SizedBox(height: 12.h),
          
              Row(
                children: [
                  Expanded(
                    child: _radioTile(
                      label: 'Registered',
                      value: true,
                      group: s.registered,
                      onTap: () => _on(RegisteredToggled(true)),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _radioTile(
                      label: 'Not registered',
                      value: false,
                      group: s.registered,
                      onTap: () => _on(RegisteredToggled(false)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
          
              if (s.registered) ...[
                TextFormField(
                  controller: _cacCtl,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'CAC number is required' : null,
                  style: GoogleFonts.inter(fontSize: 13.5.sp),
                  decoration: InputDecoration(
                    labelText: 'CAC number',
                    labelStyle: GoogleFonts.inter(fontSize: 13.5.sp),
                    errorStyle: GoogleFonts.inter(fontSize: 12.sp),
                    prefixIcon: Icon(Iconsax.document_text, size: 18.sp),
                    filled: true,
                  ),
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _legalCtl,
                  validator: (v) => KorraValidators.name(v, field: 'Legal business name'),
                  style: GoogleFonts.inter(fontSize: 13.5.sp),
                  decoration: InputDecoration(
                    labelText: 'Legal business name',
                    labelStyle: GoogleFonts.inter(fontSize: 13.5.sp),
                    errorStyle: GoogleFonts.inter(fontSize: 12.sp),
                    prefixIcon: Icon(Iconsax.buildings, size: 18.sp),
                    filled: true,
                  ),
                ),
              ] else ...[
                Text('You can add CAC later. Unregistered vendors can start with limits.',
                  style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.black54)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _radioTile({required String label, required bool value, required bool group, required VoidCallback onTap}) {
    final selected = value == group;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        height: 54.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: selected ? Colors.black87 : Colors.grey.shade300),
          color: selected ? Colors.grey.shade50 : Colors.white,
        ),
        child: Row(
          children: [
            Icon(selected ? Iconsax.tick_circle : MdiIcons.circle, size: 18.sp),
            SizedBox(width: 8.w),
            Text(label, style: GoogleFonts.inter(fontSize: 13.5.sp, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
