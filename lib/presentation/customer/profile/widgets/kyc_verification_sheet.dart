import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/customer/kyc/customer_kyc_bloc.dart';
import '../../../../logic/bloc/customer/kyc/customer_kyc_event.dart';
import '../../../../logic/bloc/customer/kyc/customer_kyc_state.dart';

class KycVerificationSheet extends StatefulWidget {
  final void Function(String bvn, String nin) onVerificationComplete;

  const KycVerificationSheet({super.key, required this.onVerificationComplete});

  @override
  State<KycVerificationSheet> createState() => _KycVerificationSheetState();
}

class _KycVerificationSheetState extends State<KycVerificationSheet> {
  final _bvnCtl = TextEditingController();
  final _ninCtl = TextEditingController();
  final _bvnFocus = FocusNode();
  final _ninFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Pre-fill if already in state
    final state = context.read<CustomerKycBloc>().state;
    _bvnCtl.text = state.bvnInput;
    _ninCtl.text = state.ninInput;

    _bvnCtl.addListener(
      () => context.read<CustomerKycBloc>().add(BvnInputChanged(_bvnCtl.text)),
    );
    _ninCtl.addListener(
      () => context.read<CustomerKycBloc>().add(NinInputChanged(_ninCtl.text)),
    );
  }

  @override
  void dispose() {
    _bvnCtl.dispose();
    _ninCtl.dispose();
    _bvnFocus.dispose();
    _ninFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerKycBloc, CustomerKycState>(
      listenWhen: (prev, curr) =>
          (prev.isBvnVerified != curr.isBvnVerified) ||
          (prev.isNinVerified != curr.isNinVerified),
      listener: (context, state) {
        // 🚀 AUTO-CLOSE & TRIGGER ACCOUNT GENERATION
        if (state.isBvnVerified && state.isNinVerified) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
              widget.onVerificationComplete(
                state.bvnInput,
                state.ninInput,
              ); // Tells BankDetailsScreen to run Monnify logic!
            }
          });
        }
      },
      child: Container(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 16.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                "Identity Verification",
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF101828),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "To activate your wallet account, please verify your BVN and NIN. Your data is encrypted.",
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: const Color(0xFF667085),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 32.h),

              Row(
                children: [
                  Expanded(child: const _GenderSelector()),
                  SizedBox(width: 16.w),
                  Expanded(child: const _DobSelector()),
                ],
              ),
              SizedBox(height: 24.h),
              const _PhoneSection(),
              SizedBox(height: 24.h),
              _BvnField(controller: _bvnCtl, focusNode: _bvnFocus),
              SizedBox(height: 24.h),
              _NinField(controller: _ninCtl, focusNode: _ninFocus),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// REUSABLE COMPONENTS (Directly copied, just swapped to CustomerKycBloc)
// -----------------------------------------------------------------------------

class _BvnField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const _BvnField({required this.controller, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerKycBloc, CustomerKycState>(
      buildWhen: (p, c) =>
          p.bvnInput != c.bvnInput ||
          p.bvnVerificationInProgress != c.bvnVerificationInProgress ||
          p.isBvnVerified != c.isBvnVerified ||
          p.bvnVerificationError != c.bvnVerificationError,
      builder: (context, s) {
        Widget? suffix;
        bool isValidLength = controller.text.trim().length == 11;

        if (s.bvnVerificationInProgress) {
          suffix = Padding(
            padding: EdgeInsets.all(12.r),
            child: const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: KorraColors.brand,
              ),
            ),
          );
        } else if (s.isBvnVerified) {
          suffix = Icon(Iconsax.tick_circle, color: Colors.green, size: 20.sp);
        } else if (isValidLength) {
          suffix = Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    context.read<CustomerKycBloc>().add(
                      VerifyBvnClicked(controller.text.trim()),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
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
              label: 'Bank Verification Number (BVN)',
              hint: '11-digit BVN',
              inputType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              readOnly: s.isBvnVerified || s.bvnVerificationInProgress,
              suffixIcon: suffix,
            ),
            Padding(
              padding: EdgeInsets.only(left: 4.w, top: 6.h),
              child: Text(
                s.bvnVerificationInProgress
                    ? 'Verifying BVN...'
                    : s.isBvnVerified
                    ? 'BVN successfully verified'
                    : s.bvnVerificationError != null
                    ? s.bvnVerificationError!
                    : 'Dial *565*0# to check your BVN',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: s.bvnVerificationInProgress
                      ? KorraColors.brand
                      : s.isBvnVerified
                      ? Colors.green
                      : s.bvnVerificationError != null
                      ? Colors.red
                      : const Color(0xFF667085),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NinField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const _NinField({required this.controller, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerKycBloc, CustomerKycState>(
      buildWhen: (p, c) =>
          p.ninInput != c.ninInput ||
          p.ninVerificationInProgress != c.ninVerificationInProgress ||
          p.isNinVerified != c.isNinVerified ||
          p.ninVerificationError != c.ninVerificationError,
      builder: (context, s) {
        Widget? suffix;
        bool isValidLength = controller.text.trim().length == 11;

        if (s.ninVerificationInProgress) {
          suffix = Padding(
            padding: EdgeInsets.all(12.r),
            child: const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: KorraColors.brand,
              ),
            ),
          );
        } else if (s.isNinVerified) {
          suffix = Icon(Iconsax.tick_circle, color: Colors.green, size: 20.sp);
        } else if (isValidLength) {
          suffix = Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    context.read<CustomerKycBloc>().add(
                      VerifyNinClicked(controller.text.trim()),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
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
              label: 'National Identity Number (NIN)',
              hint: '11-digit NIN',
              inputType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              readOnly: s.isNinVerified || s.ninVerificationInProgress,
              suffixIcon: suffix,
            ),
            Padding(
              padding: EdgeInsets.only(left: 4.w, top: 6.h),
              child: Text(
                s.ninVerificationInProgress
                    ? 'Verifying NIN...'
                    : s.isNinVerified
                    ? 'NIN successfully verified'
                    : s.ninVerificationError != null
                    ? s.ninVerificationError!
                    : 'Dial *346# to check your NIN',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: s.ninVerificationInProgress
                      ? KorraColors.brand
                      : s.isNinVerified
                      ? Colors.green
                      : s.ninVerificationError != null
                      ? Colors.red
                      : const Color(0xFF667085),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DobSelector extends StatelessWidget {
  const _DobSelector();
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerKycBloc, CustomerKycState>(
      buildWhen: (p, c) => p.dob != c.dob || p.isBvnVerified != c.isBvnVerified,
      builder: (context, s) {
        final hasDob = s.dob != null;
        final isLocked = s.isBvnVerified || s.isNinVerified;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Date of Birth",
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111111),
              ),
            ),
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: isLocked
                  ? null
                  : () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000),
                        firstDate: DateTime(1930),
                        lastDate: DateTime.now(),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: KorraColors.brand,
                              onPrimary: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (date != null)
                        context.read<CustomerKycBloc>().add(DobChanged(date));
                    },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: isLocked
                      ? const Color(0xFFF9FAFB)
                      : const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        hasDob
                            ? "${s.dob!.day}/${s.dob!.month}/${s.dob!.year}"
                            : "DD/MM/YYYY",
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: hasDob
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: hasDob
                              ? const Color(0xFF1B1B1B)
                              : const Color(0xFFAAAAAA),
                        ),
                      ),
                    ),
                    Icon(
                      Iconsax.calendar_1,
                      size: 20.sp,
                      color: const Color(0xFF667085),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GenderSelector extends StatelessWidget {
  const _GenderSelector();
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerKycBloc, CustomerKycState>(
      buildWhen: (p, c) =>
          p.gender != c.gender || p.isBvnVerified != c.isBvnVerified,
      builder: (context, s) {
        final isLocked = s.isBvnVerified || s.isNinVerified;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Gender",
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111111),
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                _buildChip(context, "Male", s.gender, isLocked),
                SizedBox(width: 8.w),
                _buildChip(context, "Female", s.gender, isLocked),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildChip(
    BuildContext context,
    String label,
    String? currentGender,
    bool isLocked,
  ) {
    final isSelected = label == currentGender;
    return Expanded(
      child: GestureDetector(
        onTap: isLocked
            ? null
            : () => context.read<CustomerKycBloc>().add(GenderChanged(label)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            color: isSelected
                ? KorraColors.brand.withOpacity(0.1)
                : (isLocked
                      ? const Color(0xFFF9FAFB)
                      : const Color(0xFFF7F7F7)),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? KorraColors.brand : const Color(0xFFE5E5E5),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? KorraColors.brand : const Color(0xFF667085),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneSection extends StatefulWidget {
  const _PhoneSection();
  @override
  State<_PhoneSection> createState() => _PhoneSectionState();
}

class _PhoneSectionState extends State<_PhoneSection> {
  late TextEditingController _phoneCtl;
  @override
  void initState() {
    super.initState();
    _phoneCtl = TextEditingController(
      text: context.read<CustomerKycBloc>().state.phone,
    );
  }

  @override
  void dispose() {
    _phoneCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomerKycBloc, CustomerKycState>(
      listenWhen: (p, c) => p.phone != c.phone,
      listener: (context, state) {
        if (_phoneCtl.text != state.phone) _phoneCtl.text = state.phone;
      },
      buildWhen: (p, c) =>
          p.phone != c.phone ||
          p.isEditingPhone != c.isEditingPhone ||
          p.isUpdatingPhone != c.isUpdatingPhone,
      builder: (context, s) {
        if (!s.isEditingPhone) {
          return Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(Iconsax.call, size: 20.sp, color: const Color(0xFF667085)),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Registered Phone Number",
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF667085),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        s.phone.isEmpty ? "No number added" : s.phone,
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF101828),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      context.read<CustomerKycBloc>().add(EditPhoneToggled()),
                  child: Text(
                    "Edit",
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: KorraColors.brand,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Update Phone Number",
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111111),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: KorraColors.brand),
                    ),
                    child: TextFormField(
                      controller: _phoneCtl,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1B1B1B),
                      ),
                      decoration: InputDecoration(
                        hintText: "080...",
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: const Color(0xFFAAAAAA),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                context.read<CustomerKycBloc>().add(
                  SavePhoneClicked(_phoneCtl.text),
                );
              },
              child: Container(
                height: 50.h,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                decoration: BoxDecoration(
                  color: KorraColors.brand,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                alignment: Alignment.center,
                child: s.isUpdatingPhone
                    ? SizedBox(
                        height: 20.r,
                        width: 20.r,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "Save",
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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
// PREMIUM INPUT WIDGET
// -----------------------------------------------------------------------------
class _PremiumInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final TextInputType inputType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final bool readOnly;

  const _PremiumInput({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    this.inputType = TextInputType.text,
    this.inputFormatters,
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

  void _handleFocus() => setState(() => _isFocused = widget.focusNode.hasFocus);

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
            color: widget.readOnly
                ? const Color(0xFFF9FAFB)
                : (_isFocused ? Colors.white : const Color(0xFFF7F7F7)),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: _isFocused && !widget.readOnly
                  ? KorraColors.brand
                  : const Color(0xFFE5E5E5),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: widget.inputType,
            inputFormatters: widget.inputFormatters,
            readOnly: widget.readOnly,
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: widget.readOnly
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF1B1B1B),
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 14.sp,
                color: const Color(0xFFAAAAAA),
              ),
              suffixIcon: widget.suffixIcon,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
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
            ),
          ),
        ),
      ],
    );
  }
}
