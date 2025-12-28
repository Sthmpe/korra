import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_bloc.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_event.dart';

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

  final _addrFocus = FocusNode();
  final _cityFocus = FocusNode();
  final _stateFocus = FocusNode();
  final _mapFocus = FocusNode();

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
  
  @override 
  void dispose() { 
    _addrCtl.dispose(); _cityCtl.dispose(); _stateCtl.dispose(); _mapCtl.dispose(); 
    _addrFocus.dispose(); _cityFocus.dispose(); _stateFocus.dispose(); _mapFocus.dispose();
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SignupVendorBloc>().state;
    final needsPhysical = s.presence == Presence.physical || s.presence == Presence.both;

    String? _requiredIfPhysical(String? v) {
      if (!needsPhysical) return null;
      if (v == null || v.trim().isEmpty) return 'Required';
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
              'Store Location',
              style: GoogleFonts.inter(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111111),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              needsPhysical 
                  ? 'Where can customers find your shop?' 
                  : 'You selected "Online Only", so address is optional.',
              style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF666666), height: 1.4),
            ),
            SizedBox(height: 32.h),

            // --- ADDRESS (Animated visibility) ---
            // If Online Only, we could hide this, but let's keep it optional as per your old logic
            // or better: Only show if physical/both to keep UI clean.
            
            if (needsPhysical) ...[
               _PremiumInput(
                controller: _addrCtl,
                focusNode: _addrFocus,
                label: 'Street Address',
                hint: 'e.g. 123 Market Street',
                icon: Iconsax.location,
                validator: _requiredIfPhysical,
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => FocusScope.of(context).requestFocus(_cityFocus),
              ),
              SizedBox(height: 24.h),

              Row(
                children: [
                  Expanded(
                    child: _PremiumInput(
                      controller: _cityCtl,
                      focusNode: _cityFocus,
                      label: 'City',
                      hint: 'Lagos',
                      icon: Iconsax.buildings_2,
                      validator: _requiredIfPhysical,
                      textCapitalization: TextCapitalization.words,
                      onSubmitted: (_) => FocusScope.of(context).requestFocus(_stateFocus),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _PremiumInput(
                      controller: _stateCtl,
                      focusNode: _stateFocus,
                      label: 'State',
                      hint: 'Lagos',
                      icon: Iconsax.map_1,
                      validator: _requiredIfPhysical,
                      textCapitalization: TextCapitalization.words,
                      onSubmitted: (_) => FocusScope.of(context).requestFocus(_mapFocus),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              _PremiumInput(
                controller: _mapCtl,
                focusNode: _mapFocus,
                label: 'Google Maps Link (Optional)',
                hint: 'https://maps.google.com/...',
                icon: Iconsax.link_2,
                validator: (v) => (v == null || v.isEmpty) 
                    ? null 
                    : (Uri.tryParse(v)?.hasAbsolutePath ?? false) ? null : 'Enter a valid link',
                inputType: TextInputType.url,
              ),
            ] else ...[
              // --- ONLINE ONLY STATE ---
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(24.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F8FD),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Iconsax.global, size: 48.sp, color: Colors.blue.shade300),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      "You're an Online Store",
                      style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "No physical address needed. You can skip this step.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}

// --- Re-include _PremiumInput here if needed (same as previous steps) ---
class _PremiumInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType inputType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  const _PremiumInput({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.inputType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
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
            color: _isFocused
                ? Colors.white
                : const Color(0xFFF7F7F7), // Very subtle grey when inactive
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: _isFocused
                  ? KorraColors.brand
                  : const Color(0xFFE5E5E5), // Brand or light grey
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
            keyboardType: widget.inputType,
            textCapitalization: widget.textCapitalization,
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
                color: const Color(0xFFAAAAAA), // Softer placeholder
              ),
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
              // Hide error here, we can show it below if needed, or keep it simple
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