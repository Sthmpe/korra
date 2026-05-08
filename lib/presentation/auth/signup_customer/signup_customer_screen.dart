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
import 'steps/step_review.dart';

class SignupCustomerScreen extends StatefulWidget {
  final bool showLeadingIcon;
  const SignupCustomerScreen({super.key, this.showLeadingIcon = false});

  @override
  State<SignupCustomerScreen> createState() => _SignupCustomerScreenState();
}

class _SignupCustomerScreenState extends State<SignupCustomerScreen> {
  final _controller = PageController();
  final _formKeys = List.generate(2, (_) => GlobalKey<FormState>());

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
                      _animateTo(s.pageIndex);
                    },
                  ),

                  // 2. Success / failure listener
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
                    StepReview(formKey: _formKeys[1]),
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

  const _BottomNav({
    required this.formKey,
    required this.isLast,
    required this.loading,
    required this.pageIndex,
  });

  @override
  Widget build(BuildContext context) {
    void handleNext() {
      FocusScope.of(context).unfocus();

      debugPrint("Debug: Attempting validation for page $pageIndex");

      final ok = formKey.currentState?.validate() ?? true;
      if (!ok) return;

      if (isLast) {
        context.read<SignupCustomerBloc>().add(SignupCustomerSubmitPressed());
        return;
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