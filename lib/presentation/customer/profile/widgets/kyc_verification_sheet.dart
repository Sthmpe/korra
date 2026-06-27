import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/customer/kyc/customer_kyc_bloc.dart';
import '../../../../logic/bloc/customer/kyc/customer_kyc_event.dart';
import '../../../../logic/bloc/customer/kyc/customer_kyc_state.dart';
import '../../../shared/widgets/kyc/kyc_bvn_field.dart';
import '../../../shared/widgets/kyc/kyc_dob_selector.dart';
import '../../../shared/widgets/kyc/kyc_gender_selector.dart';
import '../../../shared/widgets/kyc/kyc_nin_field.dart';
import '../../../shared/widgets/kyc/kyc_phone_section.dart';

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
          child: BlocBuilder<CustomerKycBloc, CustomerKycState>(
            builder: (context, state) {
              return Column(
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
                      Expanded(
                        child: KycGenderSelector(
                          gender: state.gender,
                          isLocked: state.isBvnVerified || state.isNinVerified,
                          onGenderChanged: (gender) {
                            context.read<CustomerKycBloc>().add(GenderChanged(gender));
                          },
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: KycDobSelector(
                          dob: state.dob,
                          isLocked: state.isBvnVerified || state.isNinVerified,
                          onDobChanged: (date) {
                            context.read<CustomerKycBloc>().add(DobChanged(date));
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  KycPhoneSection(
                    phone: state.phone,
                    isEditingPhone: state.isEditingPhone,
                    isUpdatingPhone: state.isUpdatingPhone,
                    onEditPressed: () {
                      context.read<CustomerKycBloc>().add(EditPhoneToggled());
                    },
                    onSavePressed: (phone) {
                      context.read<CustomerKycBloc>().add(SavePhoneClicked(phone));
                    },
                  ),
                  SizedBox(height: 24.h),
                  KycBvnField(
                    controller: _bvnCtl,
                    focusNode: _bvnFocus,
                    isVerificationInProgress: state.bvnVerificationInProgress,
                    isVerified: state.isBvnVerified,
                    verificationError: state.bvnVerificationError,
                    onVerifyPressed: () {
                      context.read<CustomerKycBloc>().add(VerifyBvnClicked(_bvnCtl.text.trim()));
                    },
                  ),
                  SizedBox(height: 24.h),
                  KycNinField(
                    controller: _ninCtl,
                    focusNode: _ninFocus,
                    isVerificationInProgress: state.ninVerificationInProgress,
                    isVerified: state.isNinVerified,
                    verificationError: state.ninVerificationError,
                    onVerifyPressed: () {
                      context.read<CustomerKycBloc>().add(VerifyNinClicked(_ninCtl.text.trim()));
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
