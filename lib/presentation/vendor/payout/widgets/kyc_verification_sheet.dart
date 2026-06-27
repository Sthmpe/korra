import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../config/constants/colors.dart';
import '../../../../logic/bloc/vendor/payout/payout_bloc.dart';
import '../../../../logic/bloc/vendor/payout/payout_event.dart';
import '../../../../logic/bloc/vendor/payout/payout_state.dart';
import '../../../shared/widgets/kyc/kyc_bvn_field.dart';
import '../../../shared/widgets/kyc/kyc_dob_selector.dart';
import '../../../shared/widgets/kyc/kyc_gender_selector.dart';
import '../../../shared/widgets/kyc/kyc_nin_field.dart';
import '../../../shared/widgets/kyc/kyc_phone_section.dart';

class KycVerificationSheet extends StatefulWidget {
  const KycVerificationSheet({super.key});

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
    // Pre-fill if they already verified one of them previously
    final state = context.read<PayoutBloc>().state;
    if (state.lastVerifiedBvn != null) _bvnCtl.text = state.lastVerifiedBvn!;
    if (state.lastVerifiedNin != null) _ninCtl.text = state.lastVerifiedNin!;
    
    // Listeners to update the BLoC so the "Verify" button appears
    _bvnCtl.addListener(() => context.read<PayoutBloc>().add(BvnInputChanged(_bvnCtl.text)));
    _ninCtl.addListener(() => context.read<PayoutBloc>().add(NinInputChanged(_ninCtl.text)));
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
    return BlocListener<PayoutBloc, PayoutState>(
      listenWhen: (prev, curr) => 
          (prev.isBvnVerified != curr.isBvnVerified) || 
          (prev.isNinVerified != curr.isNinVerified),
      listener: (context, state) {
        // 🚀 AUTO-CLOSE: If both are verified, close the sheet automatically!
        if (state.isBvnVerified && state.isNinVerified) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          });
        }
      },
      child: Container(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 16.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24.h, // Pushes up with keyboard
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: BlocBuilder<PayoutBloc, PayoutState>(
            builder: (context, state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
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
                    "To comply with CBN regulations, please verify your BVN and NIN. Your data is encrypted and secure.",
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: const Color(0xFF667085),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 32.h),
              
                  // --- GENDER & DOB ROW ---
                  Row(
                    children: [
                      Expanded(
                        child: KycGenderSelector(
                          gender: state.gender,
                          isLocked: state.isBvnVerified || state.isNinVerified,
                          onGenderChanged: (gender) {
                            context.read<PayoutBloc>().add(GenderChanged(gender));
                          },
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: KycDobSelector(
                          dob: state.dob,
                          isLocked: state.isBvnVerified || state.isNinVerified,
                          onDobChanged: (date) {
                            context.read<PayoutBloc>().add(DobChanged(date));
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
              
                  // Phone Number Editor
                  KycPhoneSection(
                    phone: state.phone,
                    isEditingPhone: state.isEditingPhone,
                    isUpdatingPhone: state.isUpdatingPhone,
                    onEditPressed: () {
                      context.read<PayoutBloc>().add(EditPhoneToggled());
                    },
                    onSavePressed: (phone) {
                      context.read<PayoutBloc>().add(SavePhoneClicked(phone));
                    },
                  ),
                  SizedBox(height: 24.h),
              
                  // BVN Field
                  KycBvnField(
                    controller: _bvnCtl,
                    focusNode: _bvnFocus,
                    isVerificationInProgress: state.bvnVerificationInProgress,
                    isVerified: state.isBvnVerified,
                    verificationError: state.bvnVerificationError,
                    onVerifyPressed: () {
                      context.read<PayoutBloc>().add(VerifyBvnClicked(_bvnCtl.text.trim()));
                    },
                  ),
                  SizedBox(height: 24.h),
              
                  // NIN Field
                  KycNinField(
                    controller: _ninCtl,
                    focusNode: _ninFocus,
                    isVerificationInProgress: state.ninVerificationInProgress,
                    isVerified: state.isNinVerified,
                    verificationError: state.ninVerificationError,
                    onVerifyPressed: () {
                      context.read<PayoutBloc>().add(VerifyNinClicked(_ninCtl.text.trim()));
                    },
                  ),
                  
                  SizedBox(height: 10.h),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
