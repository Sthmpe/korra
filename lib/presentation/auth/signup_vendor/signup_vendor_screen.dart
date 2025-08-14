import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _animateTo(int index) {
    _controller.animateToPage(index, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SignupVendorBloc()..add(SignupVendorInit()),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Create vendor account', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700)),
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
                  child: BlocListener<SignupVendorBloc, SignupVendorState>(
                    listenWhen: (p, c) => p.pageIndex != c.pageIndex,
                    listener: (_, s) => _animateTo(s.pageIndex),
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
                  buildWhen: (p, c) => p.pageIndex != c.pageIndex || p.loading != c.loading,
                  builder: (_, s) => _BottomNav(
                    formKey: _formKeys[s.pageIndex],
                    isLast: s.pageIndex == s.totalPages - 1,
                    loading: s.loading,
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
                Container(height: 6.h, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6.r))),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(height: 6.h, decoration: BoxDecoration(color: KorraColors.brand, borderRadius: BorderRadius.circular(6.r))),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Step ${s.pageIndex + 1} of ${s.totalPages}', style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.black54)),
                Icon(MdiIcons.storePlus, size:20.sp, color: KorraColors.brand),
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

  const _BottomNav({required this.formKey, required this.isLast, required this.loading});

  @override
  Widget build(BuildContext context) {
    Future<void> _handleNext() async {
      final ok = formKey.currentState?.validate() ?? true;
      if (!ok) return;
      if (isLast) {
        context.read<SignupVendorBloc>().add(SignupVendorSubmitPressed());
        await Future.delayed(const Duration(milliseconds: 950));
        if (!context.mounted) return;
        Get.offAll(() => const VendorShell());
      } else {
        context.read<SignupVendorBloc>().add(SignupVendorNextPressed());
      }
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: Size.fromHeight(48.h),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            onPressed: () => context.read<SignupVendorBloc>().add(SignupVendorBackPressed()),
            child: Text('Back', style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                onPressed: loading ? null : _handleNext,
                child: Text(isLast ? 'Create account' : 'Next',
                  style: GoogleFonts.inter(fontSize: 14.5.sp, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              if (loading)
                Padding(
                  padding: EdgeInsets.only(right: 14.w),
                  child: SizedBox(height: 16.r, width: 16.r,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
