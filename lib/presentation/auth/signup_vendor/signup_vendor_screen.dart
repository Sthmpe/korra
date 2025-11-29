import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../config/constants/colors.dart';
import '../../../config/constants/sizes.dart';
import '../../../logic/bloc/auth/signup_vendor/signup_vendor_bloc.dart';
import '../../../logic/bloc/auth/signup_vendor/signup_vendor_event.dart';
import '../../../logic/bloc/auth/signup_vendor/signup_vendor_state.dart';

import '../../shared/widgets/show_app_snackbar.dart';
import '../../vendor/vendor_shell.dart';
import '../role_login/role_login_screen.dart';
import '../sgnup_failure_sheet.dart';
import 'steps_v/step_business_type.dart';
import 'steps_v/step_identity.dart';
import 'steps_v/step_personal.dart';
import 'steps_v/step_security.dart';
import 'steps_v/step_store_details.dart';
import 'steps_v/step_location.dart';
import 'steps_v/step_review_vendor.dart';

class SignupVendorScreen extends StatefulWidget {
  final bool showLeadingIcon;
  const SignupVendorScreen({
    super.key,
    this.showLeadingIcon = false,
  });

  @override
  State<SignupVendorScreen> createState() => _SignupVendorScreenState();
}

class _SignupVendorScreenState extends State<SignupVendorScreen> {
  final _controller = PageController();
  final _formKeys = List.generate(7, (_) => GlobalKey<FormState>());
  bool _kycSheetOpen = false;

  void closeAllOverlays() {
    if (Get.isOverlaysOpen) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.fastOutSlowIn, 
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            if (widget.showLeadingIcon)
              Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: IconButton(
                  onPressed: () => Get.offAll(() => const RoleLoginScreen()),
                  icon: Icon(
                    Iconsax.arrow_left,
                    size: 24.sp,
                    color: Colors.black,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            Text(
              'Create Vendor Account',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111111),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- PROGRESS BAR ---
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: KorraSizes.gutter.w,
                vertical: 12.h,
              ),
              child: const _StepperBar(),
            ),
            
             // --- FORM PAGES ---
            Expanded(
              child: MultiBlocListener(
                listeners: [
                  // 1. Page Navigation
                  BlocListener<SignupVendorBloc, SignupVendorState>(
                    listenWhen: (p, c) => p.pageIndex != c.pageIndex,
                    listener: (context, s) async {
                      if (_kycSheetOpen) {
                        await Future.delayed(
                          const Duration(milliseconds: 1500),
                        ); // Give user time to see "Success"
                        if (context.mounted) Navigator.of(context).pop();
                        _kycSheetOpen = false;
                      }
                      _animateTo(s.pageIndex);
                    },
                  ),
                  // Close sheet on identity failure (stay on Identity page)
                  BlocListener<SignupVendorBloc, SignupVendorState>(
                    listenWhen: (p, c) =>
                        (p.ninVerifying &&
                            !c.ninVerifying &&
                            c.ninError != null) ||
                        (p.bvnVerifying &&
                            !c.bvnVerifying &&
                            c.bvnError != null),
                    listener: (context, s) async {
                      if (_kycSheetOpen) {
                        await Future.delayed(const Duration(seconds: 2));
                        if (context.mounted) Navigator.of(context).pop();
                        _kycSheetOpen = false;
                      }
                    },
                  ),
                  BlocListener<SignupVendorBloc, SignupVendorState>(
                    listenWhen: (p, c) => p.status != c.status,
                    listener: (context, s) {
                      if (s.status == SignupStatus.failure) {
                        closeAllOverlays();
                        showKorraFailureSheetCustomer(
                          context,
                          title: 'Signup Failed',
                          message:
                              s.signUpError ??
                              'An unknown error occurred during signup.',
                          onRetry: () {
                            Get.offAll(
                              () => BlocProvider(
                                create: (_) => SignupVendorBloc(),
                                child: SignupVendorScreen(
                                  showLeadingIcon: true,
                                ),
                              ),
                            );
                          },
                        );
                      }
        
                      if (s.status == SignupStatus.success) {
                        showAppSnackbar(
                          'Your vendor account has been created successfully.',
                          SnackbarType.success,
                        );
                        Get.offAll(() => VendorShell(uid: s.uid));
                      }
                    },
                  ),
                ],
                child: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StepBusinessType(formKey: _formKeys[0]),
                    StepStoreDetails(formKey: _formKeys[1]),
                    StepLocation(formKey: _formKeys[2]),
                    StepPersonal(formKey: _formKeys[3]),
                    StepIdentity(formKey: _formKeys[4]),
                    StepSecurity(formKey: _formKeys[5]),
                    StepReviewVendor(formKey: _formKeys[6]),
                  ],
                ),
              ),
            ),
            
            BlocBuilder<SignupVendorBloc, SignupVendorState>(
              builder: (context, s) {
               return Padding(
                  padding: EdgeInsets.fromLTRB(
                    KorraSizes.gutter.w,
                    0,
                    KorraSizes.gutter.w,
                    16.h,
                  ),
                  child: _BottomNav(
                  formKey: _formKeys[s.pageIndex],
                  isLast: s.pageIndex == s.totalPages - 1,
                  loading: s.loading,
                  pageIndex: s.pageIndex, // pass current step
                  openKycSheet: () {
                    if (!_kycSheetOpen) {
                      _kycSheetOpen = true;
                      final bloc = context.read<SignupVendorBloc>();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        isDismissible: false,
                        enableDrag: false,
                        backgroundColor: Colors.transparent,
                        builder: (_) => BlocProvider.value(
                          value: bloc,
                          child: const _KycProgressSheet(),
                        ),
                      );
                    }
                  },
                ),
                );
              }
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperBar extends StatelessWidget {
  const _StepperBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignupVendorBloc, SignupVendorState>(
      buildWhen: (p, c) => p.pageIndex != c.pageIndex,
      builder: (_, s) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7), 
                borderRadius: BorderRadius.circular(2.r),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stepWidth = constraints.maxWidth / s.totalPages;
                  final currentWidth = stepWidth * (s.pageIndex + 1);
                  return Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        width: currentWidth,
                        decoration: BoxDecoration(
                          color: KorraColors.brand,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Step ${s.pageIndex + 1} of ${s.totalPages}',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF666666),
              ),
            ),
          ],
        );
      },
    );
  }
}


// -----------------------------------------------------------------------------
// 2. BOTTOM NAVIGATION BAR
// -----------------------------------------------------------------------------
class _BottomNav extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool isLast;
  final bool loading;
  final int pageIndex;
  final VoidCallback openKycSheet;

  const _BottomNav({
    required this.formKey,
    required this.isLast,
    required this.loading,
    required this.pageIndex,
    required this.openKycSheet,
  });

  @override
  Widget build(BuildContext context) {
    void handleNext() {
      FocusScope.of(context).unfocus();
      final ok = formKey.currentState?.validate() ?? true;
      if (!ok) return;

      if (isLast) {
        if (!context.read<SignupVendorBloc>().state.toggled) {
          showAppSnackbar("Please agree to the terms to continue.", SnackbarType.warning);
          return;
        }
        context.read<SignupVendorBloc>().add(SignupVendorSubmitPressed());
        return;
      }

      // Identity step (index 4): open progress sheet; Bloc will run NIN→BVN and navigate on success
      if (pageIndex == 4) { 
        final s = context.read<SignupVendorBloc>().state;
        final ninNeeded = !(s.ninVerified && s.lastVerifiedNin == s.nin);
        final bvnNeeded = !(s.bvnVerified && s.lastVerifiedBvn == s.bvn);

        if (ninNeeded || bvnNeeded) {
          openKycSheet(); // only open when we’ll actually verify
        }
      }

      context.read<SignupVendorBloc>().add(SignupVendorNextPressed());
    }

    return Row(
      children: [
        // BACK BUTTON (Visible only after step 1)
        if (pageIndex > 0) ...[
          SizedBox(
            height: 54.h,
            width: 54.h,
            child: OutlinedButton(
              onPressed: loading
                  ? null
                  : () => context.read<SignupVendorBloc>().add(
                      SignupVendorBackPressed(),
                    ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                backgroundColor: Colors.white,
              ),
              child: Icon(Iconsax.arrow_left, color: Colors.black, size: 24.sp),
            ),
          ),
          SizedBox(width: 12.w),
        ],

        Expanded(
          child: SizedBox(
            height: 54.h,
            child: ElevatedButton(
              onPressed: loading ? null : handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: KorraColors.brand,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                disabledBackgroundColor: KorraColors.brand.withOpacity(0.5),
              ),
              child: loading
                  ? SizedBox(
                      height: 20.h,
                      width: 20.h,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      isLast ? 'Create Account' : 'Continue',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 3. PREMIUM KYC PROGRESS SHEET
// -----------------------------------------------------------------------------
class _KycProgressSheet extends StatelessWidget {
  const _KycProgressSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 32.h),
      child: SafeArea(
        top: false,
        child: BlocBuilder<SignupVendorBloc, SignupVendorState>(
          builder: (_, s) {
            final allVerified = s.ninVerified && s.bvnVerified;
            final anyError = s.ninError != null || s.bvnError != null;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 24.h),

                // Header
                Text(
                  allVerified ? "Identity Verified" : "Verifying Identity",
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111111),
                  ),
                ),
                SizedBox(height: 24.h),

                // NIN Line
                _VerificationLine(
                  title: "NIN Validation",
                  isProcessing: s.ninVerifying,
                  isSuccess: s.ninVerified && s.lastVerifiedNin == s.nin,
                  hasError: s.ninError != null,
                ),

                // Connector Line
                Container(
                  margin: EdgeInsets.only(left: 11.w), // Align with icon center
                  height: 16.h,
                  width: 2.w,
                  color: const Color(0xFFF2F2F7),
                ),

                // BVN Line
                _VerificationLine(
                  title: "BVN Validation",
                  isProcessing: s.bvnVerifying,
                  isSuccess: s.bvnVerified && s.lastVerifiedBvn == s.bvn,
                  hasError: s.bvnError != null,
                ),

                SizedBox(height: 24.h),

                // Status Footer
                if (anyError)
                  Text(
                    "Verification Failed. Please check your details.",
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else if (!allVerified)
                  Text(
                    "This usually takes a few seconds...",
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: Colors.grey,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _VerificationLine extends StatelessWidget {
  final String title;
  final bool isProcessing;
  final bool isSuccess;
  final bool hasError;

  const _VerificationLine({
    required this.title,
    required this.isProcessing,
    required this.isSuccess,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    Color bgColor;

    if (isProcessing) {
      icon = Iconsax.refresh; // Or spinner
      color = Colors.orange;
      bgColor = Colors.orange.withOpacity(0.1);
    } else if (isSuccess) {
      icon = Iconsax.tick_circle;
      color = Colors.green;
      bgColor = Colors.green.withOpacity(0.1);
    } else if (hasError) {
      icon = Iconsax.close_circle;
      color = Colors.red;
      bgColor = Colors.red.withOpacity(0.1);
    } else {
      icon = Iconsax.lock;
      color = Colors.grey;
      bgColor = Colors.grey.withOpacity(0.1);
    }

    return Row(
      children: [
        Container(
          width: 24.w,
          height: 24.w,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: isProcessing
              ? Padding(
                  padding: EdgeInsets.all(6.r),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.orange,
                  ),
                )
              : Icon(icon, size: 14.sp, color: color),
        ),
        SizedBox(width: 12.w),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111111),
          ),
        ),
        const Spacer(),
        if (isSuccess)
          Text(
            "Matched",
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
      ],
    );
  }
}