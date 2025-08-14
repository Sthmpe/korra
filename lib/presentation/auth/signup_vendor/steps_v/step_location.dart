import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/sizes.dart';
// import '../../../../config/validators/validators.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_bloc.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_event.dart';
// import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_state.dart';

class StepLocation extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const StepLocation({super.key, required this.formKey});

  @override
  State<StepLocation> createState() => _StepLocationState();
}

class _StepLocationState extends State<StepLocation> {
  late final TextEditingController _addrCtl;
  late final TextEditingController _cityCtl;
  late final TextEditingController _stateCtl;
  late final TextEditingController _mapCtl;

  @override
  void initState() {
    super.initState();
    final s = context.read<SignupVendorBloc>().state;
    _addrCtl = TextEditingController(text: s.address)..addListener(() => _on(AddressChanged(_addrCtl.text)));
    _cityCtl = TextEditingController(text: s.city)..addListener(() => _on(CityChanged(_cityCtl.text)));
    _stateCtl = TextEditingController(text: s.stateName)..addListener(() => _on(StateChangedVD(_stateCtl.text)));
    _mapCtl  = TextEditingController(text: s.mapsLink)..addListener(() => _on(MapsLinkChanged(_mapCtl.text)));
  }

  void _on(SignupVendorEvent e) => context.read<SignupVendorBloc>().add(e);
  @override void dispose() { _addrCtl.dispose(); _cityCtl.dispose(); _stateCtl.dispose(); _mapCtl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SignupVendorBloc>().state;

    final needsPhysical = s.presence == Presence.physical || s.presence == Presence.both;

    String? _requiredIfPhysical(String? v) {
      if (!needsPhysical) return null;
      if (v == null || v.trim().isEmpty) return 'Required for physical presence';
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
              Text('Store location', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700)),
              SizedBox(height: 12.h),
          
              TextFormField(
                controller: _addrCtl,
                validator: _requiredIfPhysical,
                style: GoogleFonts.inter(fontSize: 13.5.sp),
                decoration: InputDecoration(
                  labelText: 'Address',
                  labelStyle: GoogleFonts.inter(fontSize: 13.5.sp),
                  errorStyle: GoogleFonts.inter(fontSize: 12.sp),
                  prefixIcon: Icon(Iconsax.location, size: 18.sp),
                  filled: true,
                ),
              ),
              SizedBox(height: 12.h),
          
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityCtl,
                      validator: _requiredIfPhysical,
                      style: GoogleFonts.inter(fontSize: 13.5.sp),
                      decoration: InputDecoration(
                        labelText: 'City',
                        labelStyle: GoogleFonts.inter(fontSize: 13.5.sp),
                        errorStyle: GoogleFonts.inter(fontSize: 12.sp),
                        prefixIcon: Icon(Iconsax.buildings_2, size: 18.sp),
                        filled: true,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: TextFormField(
                      controller: _stateCtl,
                      validator: _requiredIfPhysical,
                      style: GoogleFonts.inter(fontSize: 13.5.sp),
                      decoration: InputDecoration(
                        labelText: 'State',
                        labelStyle: GoogleFonts.inter(fontSize: 13.5.sp),
                        errorStyle: GoogleFonts.inter(fontSize: 12.sp),
                        prefixIcon: Icon(Iconsax.map, size: 18.sp),
                        filled: true,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
          
              TextFormField(
                controller: _mapCtl,
                validator: (v) => v == null || v.isEmpty ? null
                    : (Uri.tryParse(v)?.hasAbsolutePath ?? false) ? null : 'Enter a valid link',
                style: GoogleFonts.inter(fontSize: 13.5.sp),
                decoration: InputDecoration(
                  labelText: 'Google Maps link (optional)',
                  labelStyle: GoogleFonts.inter(fontSize: 13.5.sp),
                  errorStyle: GoogleFonts.inter(fontSize: 12.sp),
                  prefixIcon: Icon(Iconsax.link_21, size: 18.sp),
                  filled: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
