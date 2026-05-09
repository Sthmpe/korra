import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../config/constants/colors.dart';
import '../../../../../config/constants/icons.dart';
import '../../../../../config/constants/paddings.dart';
import '../../../../../config/constants/sizes.dart';
import '../../../../../config/theme/gaps.dart';
import '../../../../../config/validators/validators.dart';
import '../../../../../logic/bloc/auth/signup_customer/signup_customer_bloc.dart';
import '../../../../../logic/bloc/auth/signup_customer/signup_customer_event.dart';

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

  final _firstFocus = FocusNode();
  final _lastFocus = FocusNode();
  final _otherFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final s = context.read<SignupCustomerBloc>().state;

    final user = FirebaseAuth.instance.currentUser;
    final names = user?.displayName?.split(' ') ?? [];
    final first = names.isNotEmpty ? names.first : s.firstName;
    final last = names.length > 1 ? names.sublist(1).join(' ') : s.lastName;
    final email = user?.email ?? s.email;
    final phone = user?.phoneNumber ?? s.phone;

    debugPrint('📧 Pre-filling email from FirebaseAuth: $email');
    debugPrint('📱 Pre-filling phone from FirebaseAuth: $phone');
    debugPrint('👤 Pre-filling name from FirebaseAuth: $first $last');
    debugPrint('name parts: ${names.length}, first: $first, last: $last, full: ${user?.displayName}');

    _on(FirstNameChanged(first));
    _on(LastNameChanged(last));
    _on(EmailChangedCU(email));
    _on(PhoneChanged(phone));

    _firstCtl = TextEditingController(text: first)
      ..addListener(() => _on(FirstNameChanged(_firstCtl.text)));
    _lastCtl = TextEditingController(text: last)
      ..addListener(() => _on(LastNameChanged(_lastCtl.text)));
    _otherCtl = TextEditingController(text: s.otherName)
      ..addListener(() => _on(OtherNameChanged(_otherCtl.text)));
    _phoneCtl = TextEditingController(text: phone)
      ..addListener(() => _on(PhoneChanged(_phoneCtl.text)));
    _emailCtl = TextEditingController(text: email)
      ..addListener(() => _on(EmailChangedCU(_emailCtl.text)));
  }

  void _on(SignupCustomerEvent e) => context.read<SignupCustomerBloc>().add(e);

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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: KorraPaddings.pageH,
      child: Form(
        key: widget.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Details',
              style: GoogleFonts.inter(
                fontSize: KorraSizes.font3xl.sp,
                fontWeight: KorraSizes.weightExtraBold,
                color: KorraColors.nearBlack,
                letterSpacing: KorraSizes.trackingTight,
              ),
            ),
            Gaps.h8,
            Text(
              'We need this to verify your identity later.',
              style: GoogleFonts.inter(
                fontSize: KorraSizes.fontMd.sp,
                color: KorraColors.labelGrey,
                height: KorraSizes.lineHeightMd,
              ),
            ),
            Gaps.h32,

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
                Gaps.w16,
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
            Gaps.h24,

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
            Gaps.h24,

            // --- PHONE ---
            _PremiumInput(
              controller: _phoneCtl,
              focusNode: _phoneFocus,
              label: 'Phone Number',
              hint: '080...',
              inputType: TextInputType.phone,
              suffixIcon: Icon(KorraIcons.phone, color: KorraColors.greyShade400, size: KorraSizes.iconMd.sp),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (v.trim().length != 11) return 'Enter a valid phone number';
                return null;
              },
            ),
            Gaps.h24,

            // --- EMAIL (Read-Only) ---
            _PremiumInput(
              controller: _emailCtl,
              focusNode: _emailFocus,
              label: 'Email Address',
              hint: 'you@example.com',
              readOnly: true,
              suffixIcon: Icon(KorraIcons.successOutline, color: KorraColors.receiptCredit, size: KorraSizes.iconMd.sp),
            ),

            Gaps.h40,
          ],
        ),
      ),
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
  final bool readOnly;

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
    this.readOnly = false,
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
            color: KorraColors.nearBlack,
          ),
        ),
        Gaps.h8,

        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.readOnly
                ? KorraColors.readOnlyBg
                : (_isFocused ? KorraColors.white : KorraColors.inputBgInactive),
            borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
            border: Border.all(
              color: _isFocused
                  ? KorraColors.brand
                  : KorraColors.inputBorderInactive,
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
            readOnly: widget.readOnly,
            onFieldSubmitted: (v) {
              HapticFeedback.selectionClick();
              widget.onSubmitted?.call(v);
            },
            style: GoogleFonts.inter(
              fontSize: KorraSizes.fontMdPlus.sp,
              fontWeight: KorraSizes.weightSemiBold,
              color: KorraColors.black,
            ),
            cursorColor: KorraColors.brand,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.inter(
                fontSize: KorraSizes.fontMd.sp,
                fontWeight: KorraSizes.weightRegular,
                color: KorraColors.inputPlaceholder,
              ),
              suffixIcon: widget.suffixIcon,
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
              ),
              contentPadding: KorraPaddings.inputContent,
              errorStyle: GoogleFonts.inter(
                fontSize: KorraSizes.fontSm.sp,
                fontWeight: KorraSizes.weightMedium,
              ),
            ),
            validator: widget.validator,
          ),
        ),
      ],
    );
  }
}
