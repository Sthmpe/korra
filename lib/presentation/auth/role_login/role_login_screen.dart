import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../customer/customer_shell.dart';
import '../../vendor/vendor_shell.dart';
import 'widgets/login_button.dart';
import '../../../config/constants/sizes.dart';
import '../../../logic/bloc/auth/role_login/role_login_bloc.dart';
import '../../../logic/bloc/auth/role_login/role_login_state.dart';
import '../../../logic/bloc/auth/role_login/role_login_event.dart';
import 'widgets/login_header.dart';
import 'widgets/role_selector.dart';
import 'widgets/role_divider.dart';
import 'widgets/login_fields.dart';
import 'widgets/biometric_button.dart';

// import '../../customer/customer_shell.dart';
// import '../../vendor/vendor_shell.dart';

class RoleLoginScreen extends StatelessWidget {
  const RoleLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    return BlocProvider(
      create: (_) => RoleLoginBloc(),
      child: BlocListener<RoleLoginBloc, RoleLoginState>(
        listenWhen: (p, c) => p.status != c.status || p.failure != c.failure,
        listener: (context, state) async {
          // SUCCESS → navigate using GetX
          if (state.status == LoginStatus.success) {
            if (state.role == KorraRole.vendor) {
              Get.to(() => const VendorShell());
              // Get.snackbar('Logged in', 'Vendor shell placeholder',
              //     snackPosition: SnackPosition.BOTTOM,
              //     margin: EdgeInsets.all(12.w));
            } else {
               Get.to(() => const CustomerShell());
              // Get.snackbar('Logged in', 'Customer shell placeholder',
              //     snackPosition: SnackPosition.BOTTOM,
              //     margin: EdgeInsets.all(12.w));
            }
          }

          // FAILURE → show premium sheet
          if (state.status == LoginStatus.failure && state.failure != null) {
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              builder: (_) => _KorraFailureSheet(f: state.failure!),
            );
            // user dismissed
            if (context.mounted) {
              context.read<RoleLoginBloc>().add(FailureAcknowledged());
            }
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: KorraSizes.gutter.w,
                vertical: 40.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LoginHeader(),
                  SizedBox(height: 50.h),
                  const RoleSelector(),
                  SizedBox(height: 40.h),
                  LoginFields(formKey: formKey),
                  SizedBox(height: 16.h),
                  RoleDivider(),
                  SizedBox(height: 40.h),
                  const Center(child: BiometricButton()),
                  SizedBox(height: 14.h),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                KorraSizes.gutter.w,
                0,
                KorraSizes.gutter.w,
                14.h,
              ),
              child: LoginButton(formKey: formKey),
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium failure UX (bottom sheet)
class _KorraFailureSheet extends StatelessWidget {
  final KorraFailure f;
  const _KorraFailureSheet({required this.f});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: const Color(0xFFEAE6E2), borderRadius: BorderRadius.circular(2.r))),
          SizedBox(height: 16.h),
          Icon(Icons.error_outline, size: 36.sp, color: const Color(0xFFA54600)),
          SizedBox(height: 12.h),
          Text(f.title, textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B1B))),
          SizedBox(height: 8.h),
          Text(f.message, textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w400, color: const Color(0xFF5E5E5E))),
          SizedBox(height: 20.h),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.fromHeight(48.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  side: const BorderSide(color: Color(0xFFA54600)),
                ),
                child: Text('Try again', style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w600, color: const Color(0xFFA54600))),
              ),
            ),
          ]),
          SizedBox(height: 10.h),
          Row(children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Get.to(() => const ForgotPasswordScreen());
                },
                child: Text('Forgot password?', style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1B1B1B))),
              ),
            ),
          ]),
          SizedBox(height: 6.h),
          Text('Need help? Contact support', style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF8B8B8B))),
          SizedBox(height: 6.h),
        ],
      ),
    );
  }
}
