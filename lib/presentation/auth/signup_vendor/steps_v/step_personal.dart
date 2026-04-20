import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../../config/constants/colors.dart';
import '../../../../../config/validators/validators.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_bloc.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_event.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_state.dart';
import 'email_otp_bottom_sheetv.dart';

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

  // Focus Nodes
  final _firstFocus = FocusNode();
  final _lastFocus = FocusNode();
  final _otherFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final s = context.read<SignupVendorBloc>().state;
    _firstCtl = TextEditingController(text: s.firstName)
      ..addListener(() => _on(OwnerFirstChanged(_firstCtl.text)));
    _lastCtl = TextEditingController(text: s.lastName)
      ..addListener(() => _on(OwnerLastChanged(_lastCtl.text)));
    _otherCtl = TextEditingController(text: s.otherName)
      ..addListener(() => _on(OwnerOtherChanged(_otherCtl.text)));
    _phoneCtl = TextEditingController(text: s.phone)
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
    _firstFocus.dispose();
    _lastFocus.dispose();
    _otherFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignupVendorBloc, SignupVendorState>(
      builder: (context, state) {
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
                  'Personal Details',
                  style: GoogleFonts.inter(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111111),
                    letterSpacing: -0.8,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'We need this to verify your identity later.',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: const Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
        
                SizedBox(height: 32.h),
                
                // --- ROW: FIRST & LAST NAME ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _PremiumInput(
                        controller: _firstCtl,
                        focusNode: _firstFocus,
                        label: 'First Name',
                        hint: 'e.g. John',
                        inputType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            KorraValidators.name(v, field: 'First name'),
                        onSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_lastFocus),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: _PremiumInput(
                        controller: _lastCtl,
                        focusNode: _lastFocus,
                        label: 'Last Name',
                        hint: 'e.g. Doe',
                        inputType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            KorraValidators.name(v, field: 'Last name'),
                        onSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_otherFocus),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
        
                // --- OTHER NAME ---
                _PremiumInput(
                  controller: _otherCtl,
                  focusNode: _otherFocus,
                  label: 'Other Name',
                  hint: 'Optional',
                  inputType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  validator: KorraValidators.optionalName,
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_phoneFocus),
                ),
                SizedBox(height: 24.h),
        
                // --- PHONE ---
                _PremiumInput(
                  controller: _phoneCtl,
                  focusNode: _phoneFocus,
                  label: 'Phone Number',
                  hint: '080...',
                  inputType: TextInputType.phone,
                  validator: KorraValidators.phoneNg,
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_emailFocus),
                  suffixIcon: Icon(
                    Iconsax.call,
                    color: Colors.grey.shade400,
                    size: 20.sp,
                  ),
                ),
                SizedBox(height: 24.h),
        
                // --- EMAIL (Smart Status) ---
                _EmailField(controller: _emailCtl, focusNode: _emailFocus),
                SizedBox(height: 24.h),
        
                // --- DOB & GENDER ---
                _DobAndGenderRow(),
        
                SizedBox(height: 40.h),
              ],
            ),
          ),
        );
      }
    );
  }
}

// -----------------------------------------------------------------------------
// 1. THE NEW PREMIUM INPUT (Clean, Label Outside, Solid Fill)
// -----------------------------------------------------------------------------
class _PremiumInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final TextInputType inputType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final Widget? suffixIcon;

  const _PremiumInput({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    this.inputType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onSubmitted,
    this.suffixIcon,
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
        // 1. THE LABEL (Outside)
        Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111111), // Solid black for label
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
              suffixIcon: widget.suffixIcon,
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

// -----------------------------------------------------------------------------
// 2. EMAIL FIELD (Uses Premium Input)
// -----------------------------------------------------------------------------
class _EmailField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const _EmailField({required this.controller, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignupVendorBloc, SignupVendorState>(
      buildWhen: (p, c) =>
          p.emailChecking != c.emailChecking ||
          p.emailUnused != c.emailUnused ||
          p.emailError != c.emailError ||
          p.emailOtpVerified != c.emailOtpVerified || // 🚀 Added
          p.sendingEmailOtp != c.sendingEmailOtp,     // 🚀 Added
      builder: (context, s) {
        
        Widget? suffix;
        
        if (s.emailChecking || s.sendingEmailOtp) {
          // 1. Loading State
          suffix = Padding(
            padding: EdgeInsets.all(12.r),
            child: const SizedBox(
              height: 16, width: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: KorraColors.brand),
            ),
          );
        } else if (s.emailError != null && !s.emailUnused) {
          // 2. Error State
          suffix = Icon(Iconsax.close_circle, color: Colors.red, size: 20.sp);
        } else if (s.emailUnused && s.emailOtpVerified) {
          // 3. Fully Verified State!
          suffix = Icon(Iconsax.tick_circle, color: Colors.green, size: 20.sp);
        } else if (s.emailUnused && !s.emailOtpVerified) {
          // 4. 🚀 Unused but NOT verified -> Show "Verify" Button
          suffix = Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    // Send the OTP via BLoC
                    context.read<SignupVendorBloc>().add(SignupVendorSendEmailOtpPressed());
                    
                    // Open the Bottom Sheet
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      isDismissible: false, // Force them to close it via the button
                      enableDrag: false, // Prevent swipe down to dismiss
                      backgroundColor: Colors.transparent,
                      builder: (_) => BlocProvider.value(
                        value: context.read<SignupVendorBloc>(),
                        child: const EmailOtpBottomSheet(),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: KorraColors.brand.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Text(
                      "Verify",
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: KorraColors.brand,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PremiumInput(
              controller: controller,
              focusNode: focusNode,
              label: 'Email Address',
              hint: 'you@example.com',
              inputType: TextInputType.emailAddress,
              suffixIcon: suffix,
            ),
            
            // Below-field helper text
            Padding(
              padding: EdgeInsets.only(left: 4.w, top: 6.h),
              child: Text(
                s.emailChecking ? 'Checking email…'
                  : s.emailOtpVerified ? 'Email verified and secure'
                  : s.emailUnused ? 'Email is available. Please verify it.'
                  : s.emailError != null ? s.emailError!
                  : 'Enter your email address',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: s.emailChecking ? KorraColors.brand
                      : s.emailOtpVerified ? Colors.green
                      : s.emailUnused ? KorraColors.brand
                      : s.emailError != null ? Colors.red
                      : KorraColors.brand,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 3. DOB & GENDER ROW (With Validators & Error Styles)
// -----------------------------------------------------------------------------
class _DobAndGenderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignupVendorBloc, SignupVendorState>(
      // Optimization: Only rebuild if dob or gender changes
      buildWhen: (p, c) => p.dob != c.dob || p.gender != c.gender,
      builder: (context, s) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- DATE PICKER FORM FIELD ---
            Expanded(
              flex: 3,
              child: FormField<DateTime>(
                initialValue: s.dob,
                validator: (value) {
                  // Validate directly against the Bloc state to ensure accuracy
                  if (s.dob == null) return "Date required";
                  // Optional: Age Check
                  final age = DateTime.now().year - s.dob!.year;
                  if (age < 18) return "18+ only";
                  return null;
                },
                builder: (FormFieldState<DateTime> field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date of Birth',
                        style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF111111)),
                      ),
                      SizedBox(height: 8.h),
                      
                      GestureDetector(
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: s.dob ?? DateTime(now.year - 20, now.month, now.day),
                            firstDate: DateTime(now.year - 100),
                            lastDate: DateTime(now.year - 13),
                            builder: (ctx, child) => Theme(
                              data: Theme.of(ctx).copyWith(
                                colorScheme: const ColorScheme.light(primary: KorraColors.brand),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            // Update Bloc
                            context.read<SignupVendorBloc>().add(DobChanged(picked));
                            // Tell FormField it changed (removes error if valid)
                            field.didChange(picked);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 52.h,
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              // 🔥 RED BORDER ON ERROR
                              color: field.hasError ?const Color.fromARGB(255, 196, 32, 20) : const Color(0xFFE5E5E5),
                              width: field.hasError ? 1.0 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                s.dob == null ? 'Select Date' : DateFormat('dd MMM yyyy').format(s.dob!),
                                style: GoogleFonts.inter(
                                  fontSize: 15.sp,
                                  fontWeight: s.dob == null ? FontWeight.w400 : FontWeight.w600,
                                  color: s.dob == null ? const Color(0xFFAAAAAA) : const Color(0xFF1B1B1B),
                                ),
                              ),
                              Icon(Iconsax.calendar_1, size: 18.sp, color: Colors.grey.shade400),
                            ],
                          ),
                        ),
                      ),
                      
                      // 🔥 STYLED ERROR TEXT
                      if (field.hasError)
                        Padding(
                          padding: EdgeInsets.only(top: 6.h, left: 4.w),
                          child: Text(
                            field.errorText!,
                            style: GoogleFonts.inter(fontSize: 12.sp, color: const Color.fromARGB(255, 196, 32, 20), fontWeight: FontWeight.w500),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            SizedBox(width: 16.w),

            // --- GENDER DROPDOWN FORM FIELD ---
            Expanded(
              flex: 2,
              child: FormField<Gender>(
                initialValue: s.gender,
                validator: (value) {
                  // Validate against Bloc State
                  if (s.gender == Gender.undisclosed) return "Required";
                  return null;
                },
                builder: (FormFieldState<Gender> field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gender',
                        style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF111111)),
                      ),
                      SizedBox(height: 8.h),
                      
                      Container(
                        height: 52.h,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            // 🔥 RED BORDER ON ERROR
                            color: field.hasError ? const Color.fromARGB(255, 196, 32, 20) : const Color(0xFFE5E5E5)
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Gender>(
                            value: s.gender == Gender.undisclosed ? null : s.gender,
                            hint: Text(
                              'Select',
                              style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w400, color: const Color(0xFFAAAAAA)),
                            ),
                            icon: Icon(Iconsax.arrow_down_1, size: 16.sp, color: Colors.grey.shade400),
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            items: [
                              DropdownMenuItem(
                                value: Gender.male,
                                child: Text('Male', style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1B1B1B))),
                              ),
                              DropdownMenuItem(
                                value: Gender.female,
                                child: Text('Female', style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1B1B1B))),
                              ),
                            ],
                            onChanged: (g) {
                              if (g != null) {
                                context.read<SignupVendorBloc>().add(GenderChanged(g));
                                field.didChange(g); // Clear error state
                              }
                            },
                          ),
                        ),
                      ),

                      // 🔥 STYLED ERROR TEXT
                      if (field.hasError)
                        Padding(
                          padding: EdgeInsets.only(top: 6.h, left: 4.w),
                          child: Text(
                            field.errorText!,
                            style: GoogleFonts.inter(fontSize: 12.sp, color: const Color.fromARGB(255, 196, 32, 20), fontWeight: FontWeight.w500),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
