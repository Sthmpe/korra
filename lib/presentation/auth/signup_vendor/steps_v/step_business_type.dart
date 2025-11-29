import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
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
  
  final _cacFocus = FocusNode();
  final _legalFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final s = context.read<SignupVendorBloc>().state;
    _cacCtl = TextEditingController(text: s.cac)..addListener(() => _on(CacChanged(_cacCtl.text)));
    _legalCtl = TextEditingController(text: s.legalName)..addListener(() => _on(LegalNameChanged(_legalCtl.text)));
  }

  void _on(SignupVendorEvent e) => context.read<SignupVendorBloc>().add(e);
  
  @override 
  void dispose() { 
    _cacCtl.dispose(); _legalCtl.dispose(); 
    _cacFocus.dispose(); _legalFocus.dispose();
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SignupVendorBloc>().state;
    
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
              'Business Registration',
              style: GoogleFonts.inter(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111111),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Is your business registered with the CAC? This helps build trust with customers.',
              style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF666666), height: 1.4),
            ),
            SizedBox(height: 32.h),

            // --- SELECTION CARDS ---
            Row(
              children: [
                Expanded(
                  child: _SelectionCard(
                    label: 'Registered',
                    isSelected: s.registered,
                    onTap: () => _on(RegisteredToggled(true)),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _SelectionCard(
                    label: 'Unregistered',
                    isSelected: !s.registered,
                    onTap: () => _on(RegisteredToggled(false)),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 32.h),

            // --- CONDITIONAL INPUTS ---
            AnimatedCrossFade(
              firstChild: Column(
                children: [
                  _PremiumInput(
                    controller: _cacCtl,
                    focusNode: _cacFocus,
                    label: 'CAC Registration Number',
                    hint: 'RC123456',
                    icon: Iconsax.document_text,
                    validator: (v) {
                      if (!s.registered) return null; // Allow continue if unregistered
                      return (v == null || v.trim().isEmpty) ? 'CAC number is required' : null;
                    },
                    onSubmitted: (_) => FocusScope.of(context).requestFocus(_legalFocus),
                  ),
                  SizedBox(height: 24.h),
                  _PremiumInput(
                    controller: _legalCtl,
                    focusNode: _legalFocus,
                    label: 'Legal Business Name',
                    hint: 'As it appears on documents',
                    icon: Iconsax.briefcase,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) {
                      if (!s.registered) return null;
                     return KorraValidators.name(v, field: 'Legal business name');
                    }
                  ),
                ],
              ),
              secondChild: Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F8FD), // Light Blue tint
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE1F0FA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Iconsax.info_circle, color: Colors.blue.shade700, size: 20.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'You can start selling immediately with lower transaction limits. You can always add your CAC details later in Settings.',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp, 
                          height: 1.4,
                          color: Colors.blue.shade900
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: s.registered ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 300),
            ),
            
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SELECTION CARD (Radio Replacement)
// -----------------------------------------------------------------------------
class _SelectionCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56.h,
        decoration: BoxDecoration(
          color: isSelected ? KorraColors.brand.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? KorraColors.brand : const Color(0xFFE5E5E5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Iconsax.tick_circle : Iconsax.record,
              size: 20.sp,
              color: isSelected ? KorraColors.brand : const Color(0xFFAAAAAA),
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.5.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? KorraColors.brand : const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PREMIUM INPUT (Reused from StepPersonal)
// -----------------------------------------------------------------------------
class _PremiumInput extends StatefulWidget {
  // ... (Copy the exact _PremiumInput class code from StepPersonal here)
  // Or better, put it in a shared widgets file and import it!
  // I will paste it here for completeness if you want a single file copy.
  
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

        // 2. THE INPUT BOX
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