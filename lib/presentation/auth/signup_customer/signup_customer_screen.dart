import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/constants/colors.dart';
import '../../../config/constants/sizes.dart';
import '../../../config/routes/app_routes.dart';
import '../../../logic/bloc/auth/signup_customer/signup_customer_bloc.dart';
import '../../../logic/bloc/auth/signup_customer/signup_customer_event.dart';
import '../../../logic/bloc/auth/signup_customer/signup_customer_state.dart';

import '../../shared/widgets/korra_failure_sheet.dart';
import '../../shared/widgets/show_app_snackbar.dart';
import 'steps/step_personal.dart';
import 'steps/step_identity.dart';
import 'steps/step_security.dart';
import 'steps/step_review.dart';

class SignupCustomerScreen extends StatefulWidget {
  final bool showLeadingIcon;
  const SignupCustomerScreen({super.key, this.showLeadingIcon = false});

  @override
  State<SignupCustomerScreen> createState() => _SignupCustomerScreenState();
}

class _SignupCustomerScreenState extends State<SignupCustomerScreen> {
  final _controller = PageController();
  final _formKeys = List.generate(4, (_) => GlobalKey<FormState>());
  bool _kycSheetOpen = false;

  void closeAllOverlays() {
    // Safer way to close known overlays without nuking navigation stack
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
      duration: const Duration(milliseconds: 350), // Slower = smoother
      curve: Curves.fastOutSlowIn, // iOS physics
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
                  onPressed: () => Get.offAllNamed(Routes.roleLoginScreen),
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
              'Create Customer Account',
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
                  BlocListener<SignupCustomerBloc, SignupCustomerState>(
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
                  // 2. KYC Failure Handling (Close sheet to show error on UI)
                  BlocListener<SignupCustomerBloc, SignupCustomerState>(
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
                  // 3. Signup Completion
                  BlocListener<SignupCustomerBloc, SignupCustomerState>(
                    listenWhen: (p, c) => p.status != c.status,
                    listener: (context, s) {
                      if (s.status == SignupStatus.failure) {
                        closeAllOverlays();
                        showKorraFailureSheet(
                          context,
                          title: 'Signup Failed',
                          message:
                              s.signUpError ??
                              'An unknown error occurred during signup.',
                          onRetry: () {
                            Get.offAllNamed(
                              Routes.customerSignup,
                              arguments: {'showLeadingIcon': true},
                            );
                          },
                        );
                      }
                      if (s.status == SignupStatus.success) {
                        showAppSnackbar(
                          'Account created successfully!',
                          SnackbarType.success,
                        );
                        Get.offAllNamed(Routes.customerShell);
                      }
                    },
                  ),
                ],
                child: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StepPersonal(formKey: _formKeys[0]),
                    StepIdentity(formKey: _formKeys[1]),
                    StepSecurity(formKey: _formKeys[2]),
                    StepReview(formKey: _formKeys[3]),
                  ],
                ),
              ),
            ),

            // --- BOTTOM NAVIGATION ---
            BlocBuilder<SignupCustomerBloc, SignupCustomerState>(
              builder: (context, state) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    KorraSizes.gutter.w,
                    0,
                    KorraSizes.gutter.w,
                    16.h,
                  ),
                  child: _BottomNav(
                    formKey: _formKeys[state.pageIndex],
                    isLast: state.pageIndex == state.totalPages - 1,
                    loading: state.loading,
                    pageIndex: state.pageIndex,
                    openKycSheet: () {
                      if (!_kycSheetOpen) {
                        _kycSheetOpen = true;
                        final bloc = context.read<SignupCustomerBloc>();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          isDismissible: false,
                          enableDrag: false,
                          backgroundColor: Colors.transparent,
                          builder: (_) => BlocProvider.value(
                            value: bloc, // Pass the captured bloc instance
                            child: const _KycProgressSheet(),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. PROGRESS STEPPER (Minimal & Clean)
// -----------------------------------------------------------------------------
class _StepperBar extends StatelessWidget {
  const _StepperBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignupCustomerBloc, SignupCustomerState>(
      buildWhen: (p, c) => p.pageIndex != c.pageIndex,
      builder: (_, s) {
        // Smooth animation for progress bar
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7), // Light grey track
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

      debugPrint("Debug: Attempting validation for page $pageIndex");

      final ok = formKey.currentState?.validate() ?? true;
      if (!ok) {
        debugPrint("Debug: Validation failed for page $pageIndex");
      } else {
        debugPrint("Debug: Validation succeeded for page $pageIndex");
      }
      if (!ok) return;

      if (isLast) {
        context.read<SignupCustomerBloc>().add(SignupCustomerSubmitPressed());
        return;
      }

      // Identity Logic (Step 2 -> Index 1)
      if (pageIndex == 1) {
        final s = context.read<SignupCustomerBloc>().state;
        // Only verify if not already verified
        final needsVerification =
            !(s.ninVerified && s.lastVerifiedNin == s.nin) ||
            !(s.bvnVerified && s.lastVerifiedBvn == s.bvn);

        if (needsVerification) {
          openKycSheet();
        }
      }

      debugPrint("Debug: Moving to next page from page $pageIndex");

      context.read<SignupCustomerBloc>().add(SignupCustomerNextPressed());
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
                  : () => context.read<SignupCustomerBloc>().add(
                      SignupCustomerBackPressed(),
                    ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                side: BorderSide(color: const Color(0xFFE5E7EB).withOpacity(0.45)),
                backgroundColor: Colors.white,
              ),
              child: Icon(Iconsax.arrow_left, color: Colors.black, size: 24.sp),
            ),
          ),
          SizedBox(width: 12.w),
        ],

        // NEXT / SUBMIT BUTTON
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
        child: BlocBuilder<SignupCustomerBloc, SignupCustomerState>(
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
