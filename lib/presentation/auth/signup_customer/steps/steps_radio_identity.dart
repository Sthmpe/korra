import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/constants/sizes.dart';
import '../../../../config/validators/validators.dart';
import '../../../../logic/bloc/auth/signup_customer/signup_customer_bloc.dart';
import '../../../../logic/bloc/auth/signup_customer/signup_customer_event.dart';

enum IdentityType { nin, bvn }

class StepIdentity extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const StepIdentity({super.key, required this.formKey});
  @override
  State<StepIdentity> createState() => _StepIdentityState();
}

class _StepIdentityState extends State<StepIdentity> {
  late final TextEditingController _ninCtl;
  late final TextEditingController _bvnCtl;
  IdentityType _selectedType = IdentityType.nin;

  @override
  void initState() {
    super.initState();
    final s = context.read<SignupCustomerBloc>().state;
    _ninCtl = TextEditingController(text: s.nin)..addListener(() => _on(NinChanged(_ninCtl.text)));
    _bvnCtl = TextEditingController(text: s.bvn)..addListener(() => _on(BvnChanged(_bvnCtl.text)));
  }
  void _on(SignupCustomerEvent e) => context.read<SignupCustomerBloc>().add(e);
  @override void dispose() { _ninCtl.dispose(); _bvnCtl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    // final ctl = _selectedType == IdentityType.nin ? _ninCtl : _bvnCtl;

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
              Text('Verify your identity', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700)),
              SizedBox(height: 12.h),
              Text(
                'Select identification type',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8.h),

              /// --- Radio Buttons ---
              Row(
                children: [
                  Expanded(
                    child: _optionButton(
                      label: 'NIN',
                      value: IdentityType.nin,
                      icon: Iconsax.card,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _optionButton(
                      label: 'BVN',
                      value: IdentityType.bvn,
                      icon: Iconsax.finger_scan,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              /// --- Single Dynamic Field (controlled by selection) ---
              // TextFormField(
              //   controller: ctl,
              //   keyboardType: TextInputType.number,
              //   validator: _selectedType == IdentityType.nin
              //       ? KorraValidators.nin
              //       : KorraValidators.bvn,
              //   maxLength: 11,
              //   style: GoogleFonts.inter(fontSize: 13.5.sp, color: Colors.black87),
              //   decoration: InputDecoration(
              //     counterText: '',
              //     labelText: _selectedType == IdentityType.nin
              //         ? 'Enter your NIN'
              //         : 'Enter your BVN',
              //     labelStyle:
              //         GoogleFonts.inter(fontSize: 13.5.sp, color: Colors.black87),
              //     errorStyle: GoogleFonts.inter(fontSize: 12.sp),
              //     prefixIcon: Icon(
              //       _selectedType == IdentityType.nin
              //           ? Iconsax.card
              //           : Iconsax.finger_scan,
              //       size: 18.sp,
              //     ),
              //     filled: true,
              //   ),
              // ),

              if (_selectedType == IdentityType.nin)
                _field(_ninCtl, 'NIN (11 digits)', Iconsax.card, KorraValidators.nin),
              // SizedBox(height: 12.h),
              if (_selectedType == IdentityType.bvn)
              _field(_bvnCtl, 'BVN (11 digits)', Iconsax.finger_scan, KorraValidators.bvn),
              SizedBox(height: 8.h),
              Text('Your KYC helps secure your account and unlock higher limits.',
                style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }

  /// --- Custom Option Button ---
  Widget _optionButton({
    required String label,
    required IdentityType value,
    required IconData icon,
  }) {
    final isSelected = _selectedType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = value;
        });
        FocusScope.of(context).unfocus();
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? KorraColors.brand : Colors.grey.shade300,
            width: isSelected ? 1.6 : 1.0,
          ),
          color: isSelected ? KorraColors.brand : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18.sp,
              color: isSelected ? KorraColors.brand : Colors.black54,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? KorraColors.brand
                      : Colors.black.withOpacity(0.8),
                ),
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off_outlined,
              color: isSelected ? KorraColors.brand : Colors.grey,
              size: 18.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctl, String label, IconData icon, String? Function(String?) validator) {
    return TextFormField(
      controller: ctl,
      keyboardType: TextInputType.number,
      validator: validator,
      maxLength: 11,
      style: GoogleFonts.inter(fontSize: 13.5.sp, color: Colors.black87),
      decoration: InputDecoration(
        counterText: '',
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 13.5.sp, color: Colors.black87),
        errorStyle: GoogleFonts.inter(fontSize: 12.sp),
        prefixIcon: Icon(icon, size: 18.sp),
        filled: true,
      ),
    );
  }
}
