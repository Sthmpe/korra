import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/sizes.dart';
import '../../../../config/validators/validators.dart';
import '../../../../logic/bloc/auth/signup_customer/signup_customer_bloc.dart';
import '../../../../logic/bloc/auth/signup_customer/signup_customer_event.dart';

class StepIdentity extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const StepIdentity({super.key, required this.formKey});
  @override
  State<StepIdentity> createState() => _StepIdentityState();
}

class _StepIdentityState extends State<StepIdentity> {
  late final TextEditingController _ninCtl;
  late final TextEditingController _bvnCtl;

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
              _field(_ninCtl, 'NIN (11 digits)', Iconsax.card, KorraValidators.nin),
              SizedBox(height: 12.h),
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
