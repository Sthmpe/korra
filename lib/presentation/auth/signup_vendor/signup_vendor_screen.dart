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

import '../../vendor/vendor_shell.dart';
import 'steps_v/step_business_type.dart';
import 'steps_v/step_identity.dart';
import 'steps_v/step_personal.dart';
import 'steps_v/step_security.dart';
import 'steps_v/step_store_details.dart';
import 'steps_v/step_location.dart';
import 'steps_v/step_review_vendor.dart';

class SignupVendorScreen extends StatefulWidget {
  const SignupVendorScreen({super.key});

  @override
  State<SignupVendorScreen> createState() => _SignupVendorScreenState();
}

class _SignupVendorScreenState extends State<SignupVendorScreen> {
  final _controller = PageController();
  final _formKeys = List.generate(7, (_) => GlobalKey<FormState>());
  bool _kycSheetOpen = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SignupVendorBloc()..add(SignupVendorInit()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Create vendor account',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: KorraSizes.gutter.w),
            child: Column(
              children: [
                SizedBox(height: 12.h),
                const _StepperBar(),
                SizedBox(height: 16.h),

                Expanded(
                  child: MultiBlocListener(
                    listeners: [
                      // Close sheet & animate on successful page change
                      BlocListener<SignupVendorBloc, SignupVendorState>(
                        listenWhen: (p, c) => p.pageIndex != c.pageIndex,
                        listener: (context, s) {
                          if (_kycSheetOpen) {
                            Navigator.of(
                              context,
                              rootNavigator: true,
                            ).maybePop();
                            _kycSheetOpen = false;
                          }
                          _animateTo(s.pageIndex);
                        },
                      ),
                      // Close sheet on identity failure (stay on Identity page)
                      BlocListener<SignupVendorBloc, SignupVendorState>(
                        listenWhen: (p, c) =>
                            p.ninVerifying != c.ninVerifying ||
                            p.bvnVerifying != c.bvnVerifying ||
                            p.ninError != c.ninError ||
                            p.bvnError != c.bvnError,
                        listener: (context, s) {
                          final failedNow =
                              (!s.ninVerifying && s.ninError != null) ||
                              (!s.bvnVerifying && s.bvnError != null);
                          if (failedNow && _kycSheetOpen) {
                            Navigator.of(
                              context,
                              rootNavigator: true,
                            ).maybePop();
                            _kycSheetOpen = false;
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

                SizedBox(height: 12.h),
                BlocBuilder<SignupVendorBloc, SignupVendorState>(
                  buildWhen: (p, c) =>
                      p.pageIndex != c.pageIndex || p.loading != c.loading,
                  builder: (_, s) => _BottomNav(
                    formKey: _formKeys[s.pageIndex],
                    isLast: s.pageIndex == s.totalPages - 1,
                    loading: s.loading,
                    pageIndex: s.pageIndex, // pass current step
                    openKycSheet: () {
                      if (!_kycSheetOpen) {
                        _kycSheetOpen = true;
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          isDismissible: false,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16.r),
                            ),
                          ),
                          builder: (_) => const _KycProgressSheet(),
                        );
                      }
                    },
                  ),
                ),
                SizedBox(height: 14.h),
              ],
            ),
          ),
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
        final progress = (s.pageIndex + 1) / s.totalPages;
        return Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 6.h,
                    decoration: BoxDecoration(
                      color: KorraColors.brand,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step ${s.pageIndex + 1} of ${s.totalPages}',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.black54,
                  ),
                ),
                Icon(MdiIcons.storePlus, size: 20.sp, color: KorraColors.brand),
              ],
            ),
          ],
        );
      },
    );
  }
}

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
    Future<void> handleNext() async {
      final ok = formKey.currentState?.validate() ?? true;
      if (!ok) return;

      if (isLast) {
        context.read<SignupVendorBloc>().add(SignupVendorSubmitPressed());
        await Future.delayed(const Duration(milliseconds: 950));
        if (!context.mounted) return;
        Get.offAll(() => const VendorShell());
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
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: Size.fromHeight(48.h),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            onPressed: () =>
                context.read<SignupVendorBloc>().add(SignupVendorBackPressed()),
            child: Text(
              'Back',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(48.h),
                  backgroundColor: KorraColors.brand,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: loading ? null : handleNext,
                child: Text(
                  isLast ? 'Create account' : 'Next',
                  style: GoogleFonts.inter(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (loading)
                Padding(
                  padding: EdgeInsets.only(right: 14.w),
                  child: SizedBox(
                    height: 16.r,
                    width: 16.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KycProgressSheet extends StatelessWidget {
  const _KycProgressSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        child: BlocBuilder<SignupVendorBloc, SignupVendorState>(
          buildWhen: (p, c) =>
              p.ninVerifying != c.ninVerifying ||
              p.bvnVerifying != c.bvnVerifying ||
              p.ninVerified != c.ninVerified ||
              p.bvnVerified != c.bvnVerified ||
              p.ninError != c.ninError ||
              p.bvnError != c.bvnError,
          builder: (_, s) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAE6E2),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Verifying your identity',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8.h),

                _line(
                  'NIN',
                  running: s.ninVerifying,
                  ok: s.ninVerified && s.lastVerifiedNin == s.nin,
                  err: s.ninError,
                ),
                SizedBox(height: 8.h),
                _line(
                  'BVN',
                  running: s.bvnVerifying,
                  ok: s.bvnVerified && s.lastVerifiedBvn == s.bvn,
                  err: s.bvnError,
                ),

                SizedBox(height: 10.h),
                Text(
                  'This won’t take long…',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 6.h),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _line(
    String title, {
    required bool running,
    required bool ok,
    String? err,
  }) {
    IconData icon;
    Color color;
    String subtitle;
    Widget? tail;

    if (running) {
      icon = Iconsax.timer;
      color = Colors.orange;
      subtitle = 'Checking…';
      tail = SizedBox(
        width: 16.r,
        height: 16.r,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (ok) {
      icon = Iconsax.tick_circle;
      color = Colors.green;
      subtitle = 'Verified';
    } else if (err != null) {
      icon = Iconsax.close_circle;
      color = Colors.red;
      subtitle = 'Failed';
    } else {
      icon = Iconsax.more;
      color = Colors.grey;
      subtitle = 'Waiting';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18.sp, color: color),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                err ?? subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: err != null ? Colors.red : Colors.black54,
                ),
              ),
            ],
          ),
        ),
        if (tail != null) tail,
      ],
    );
  }
}
